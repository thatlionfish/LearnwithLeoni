// Erzeugt natürliche Aufnahmen mit Microsofts neuronalen Stimmen (Azure AI
// Speech) für alle hochdeutschen Inhalte unter web/data:
//
//   - Wort (mit Artikel)          → card.audio       (nur wenn Leoni nichts aufgenommen hat)
//   - Beispielsatz                → card.exampleAudio
//   - Lückensatz mit „Hm hm hm“   → card.gapAudio    (Hör-Kreuzworträtsel)
//   - Kumachans Umschreibung      → card.hintAudio
//   - Hörtexte, Dialoge mit verschiedenen Stimmen → listening.audio
//
// Aufruf:
//   dart run tool/tts.dart            # erzeugt, was fehlt oder sich geändert hat
//   dart run tool/tts.dart --dry      # zeigt nur, was erzeugt würde
//   dart run tool/tts.dart --force    # alles neu erzeugen
//
// Schlüssel: Datei werkstatt/azure-speech.env (nie veröffentlicht) mit
//   AZURE_SPEECH_KEY=...
//   AZURE_SPEECH_REGION=switzerlandnorth
// oder als Umgebungsvariablen gleichen Namens.
import 'dart:convert';
import 'dart:io';

import 'package:learnwithleoni/data/models.dart';
import 'package:learnwithleoni/learn/exercises.dart' show gapInExample;

/// Standardstimme für Hochdeutsch; mit "voice": "de-CH" im Schülerprofil
/// spricht die Schweizer Stimme.
const voiceDe = 'de-DE-KatjaNeural';
const voiceCh = 'de-CH-LeniNeural';

/// Stimmen für Dialoge: Leoni spricht Schweizer Hochdeutsch.
const leoniVoice = 'de-CH-LeniNeural';
const femaleVoices = [
  'de-DE-KatjaNeural',
  'de-DE-AmalaNeural',
  'de-DE-LouisaNeural',
];
const maleVoices = [
  'de-DE-ConradNeural',
  'de-DE-KillianNeural',
  'de-DE-RalfNeural',
];

/// Etwas langsamer als normal – natürlich, aber gut verständlich.
const rate = '-6%';
const ttsDir = 'audio/tts';

late final String key;
late final String region;
final dry = <String>{};
var force = false;
var showSsml = false;
var chars = 0;
var made = 0;
var skipped = 0;

Future<void> main(List<String> args) async {
  if (args.contains('--dry')) dry.add('yes');
  force = args.contains('--force');
  showSsml = args.contains('--ssml');
  final creds = _readCredentials();
  if (creds == null && dry.isEmpty) {
    stderr.writeln(
      'Kein Schlüssel gefunden. Lege werkstatt/azure-speech.env an '
      '(Vorlage: werkstatt/azure-speech.env.example).',
    );
    exitCode = 2;
    return;
  }
  if (creds != null) {
    key = creds.$1;
    region = creds.$2;
  }

  final students = Directory('web/data/students');
  for (final dir in students.listSync().whereType<Directory>()) {
    final student = jsonDecode(
      File('${dir.path}/student.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final voice = student['voice'] == 'de-CH' ? voiceCh : voiceDe;
    final manifestFile = File('${dir.path}/$ttsDir/index.json');
    final manifest = manifestFile.existsSync()
        ? (jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>)
        : <String, dynamic>{};

    for (final setId in (student['sets'] as List).cast<String>()) {
      final setFile = File('${dir.path}/sets/$setId.json');
      final set =
          jsonDecode(setFile.readAsStringSync()) as Map<String, dynamic>;
      if (set['variety'] == 'gsw') continue; // Bündnerdütsch spricht nur Leoni.
      var changed = false;

      Future<String?> make(
        String name,
        String ssmlBody, {
        String v = voiceDe,
      }) async {
        final rel = '$ttsDir/$setId-$name.mp3';
        final ssml = _ssml(ssmlBody, voice: v);
        final hash = _hash(ssml);
        final file = File('${dir.path}/$rel');
        if (!force && manifest[rel] == hash && file.existsSync()) {
          skipped++;
          return rel;
        }
        chars += ssmlBody.length;
        if (dry.isNotEmpty) {
          stdout.writeln('  würde erzeugen: $rel');
          if (showSsml) stdout.writeln('    $ssml');
          return file.existsSync() ? rel : null;
        }
        await _synthesize(ssml, file);
        manifest[rel] = hash;
        made++;
        stdout.writeln('  erzeugt: $rel');
        return rel;
      }

      for (final card in (set['cards'] as List).cast<Map<String, dynamic>>()) {
        final id = card['id'] as String;
        final term = card['term'] as String;

        // Wort – nie über Leonis eigene Aufnahme schreiben.
        final own = card['audio'] as String?;
        if (own == null || own.startsWith('$ttsDir/')) {
          final rel = await make(id, _say(term), v: voice);
          if (rel != null && card['audio'] != rel) {
            card['audio'] = rel;
            changed = true;
          }
        }

        final example = card['example'] as String?;
        if (example != null) {
          final rel = await make('$id-satz', _say(example), v: voice);
          if (rel != null && card['exampleAudio'] != rel) {
            card['exampleAudio'] = rel;
            changed = true;
          }
          final gap = gapInExample(VocabCard.fromJson(card));
          if (gap != null) {
            final parts = gap.sentence.split('___');
            final body =
                '${_say(parts[0])}<break time="250ms"/>'
                '<prosody pitch="+8%" rate="-10%">hm, hm, hm</prosody>'
                '<break time="250ms"/>${_say(parts.length > 1 ? parts[1] : '')}';
            final relGap = await make('$id-luecke', body, v: voice);
            if (relGap != null && card['gapAudio'] != relGap) {
              card['gapAudio'] = relGap;
              changed = true;
            }
          }
        }

        final hint = card['hint'] as String?;
        if (hint != null) {
          final rel = await make('$id-tipp', _say(hint), v: voice);
          if (rel != null && card['hintAudio'] != rel) {
            card['hintAudio'] = rel;
            changed = true;
          }
        }
      }

      for (final l
          in ((set['listening'] as List?) ?? const [])
              .cast<Map<String, dynamic>>()) {
        final own = l['audio'] as String?;
        if (own != null && !own.startsWith('$ttsDir/')) continue;
        final rel = await make(
          l['id'] as String,
          _dialog(l['text'] as String),
          v: voice,
        );
        if (rel != null && l['audio'] != rel) {
          l['audio'] = rel;
          changed = true;
        }
      }

      if (changed && dry.isEmpty) {
        setFile.writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert(set)}\n',
        );
        stdout.writeln(
          '${dir.uri.pathSegments.where((s) => s.isNotEmpty).last}/$setId aktualisiert',
        );
      }
    }
    if (dry.isEmpty && manifest.isNotEmpty) {
      manifestFile.parent.createSync(recursive: true);
      manifestFile.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
      );
    }
  }
  stdout.writeln(
    '${dry.isNotEmpty ? 'Probelauf' : 'Fertig'}: $made erzeugt, $skipped unverändert, '
    'ca. $chars Zeichen${dry.isNotEmpty ? ' würden gesendet' : ''}.',
  );
}

/// Dialog: Zeilen „Name: Text“ bekommen je eine eigene Stimme.
String _dialog(String text) {
  final voices = <String, String>{};
  var f = 0, m = 0;
  final out = StringBuffer();
  for (final line in text.split('\n')) {
    final match = RegExp(r'^([^:]{1,20}):\s*(.*)$').firstMatch(line.trim());
    final name = match?.group(1)?.trim();
    final said = (match?.group(2) ?? line).trim();
    if (said.isEmpty) continue;
    final v = name == null
        ? voiceDe
        : voices.putIfAbsent(name, () {
            if (name.toLowerCase() == 'leoni') return leoniVoice;
            final female = RegExp(r'(a|e|in|i)$').hasMatch(name.toLowerCase());
            return female
                ? femaleVoices[f++ % femaleVoices.length]
                : maleVoices[m++ % maleVoices.length];
          });
    out.write(
      '</prosody></voice><voice name="$v"><prosody rate="$rate">${_say(said)}<break time="450ms"/>',
    );
  }
  // Der äusserste <voice>-Rahmen kommt aus _ssml; leere Hülle am Anfang entfernen.
  return out.toString();
}

String _ssml(String body, {required String voice}) {
  var inner =
      '<voice name="$voice"><prosody rate="$rate">$body</prosody></voice>';
  // Dialoge öffnen eigene <voice>-Blöcke; leere Blöcke wegräumen.
  inner = inner.replaceAll(
    RegExp(r'<voice name="[^"]+"><prosody rate="[^"]+"></prosody></voice>'),
    '',
  );
  return '<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="de-DE">$inner</speak>';
}

String _say(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _hash(String s) {
  // Einfacher, stabiler Hash (FNV-1a, 64 Bit) – genügt zum Erkennen von Änderungen.
  var h = 0xcbf29ce484222325;
  for (final b in utf8.encode(s)) {
    h ^= b;
    h = (h * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  }
  return h.toRadixString(16);
}

(String, String)? _readCredentials() {
  var k = Platform.environment['AZURE_SPEECH_KEY'];
  var r = Platform.environment['AZURE_SPEECH_REGION'];
  final f = File('werkstatt/azure-speech.env');
  if (f.existsSync()) {
    for (final line in f.readAsLinesSync()) {
      final i = line.indexOf('=');
      if (i < 0 || line.trimLeft().startsWith('#')) continue;
      final name = line.substring(0, i).trim();
      final value = line.substring(i + 1).trim();
      if (name == 'AZURE_SPEECH_KEY' && value.isNotEmpty) k = value;
      if (name == 'AZURE_SPEECH_REGION' && value.isNotEmpty) r = value;
    }
  }
  if (k == null || k.isEmpty || r == null || r.isEmpty) return null;
  return (k, r);
}

Future<void> _synthesize(String ssml, File out) async {
  final client = HttpClient();
  try {
    for (var attempt = 1; ; attempt++) {
      final req = await client.postUrl(
        Uri.parse(
          'https://$region.tts.speech.microsoft.com/cognitiveservices/v1',
        ),
      );
      req.headers
        ..set('Ocp-Apim-Subscription-Key', key)
        ..set('Content-Type', 'application/ssml+xml')
        ..set('X-Microsoft-OutputFormat', 'audio-24khz-48kbitrate-mono-mp3')
        ..set('User-Agent', 'learnwithleoni-tts');
      req.add(utf8.encode(ssml));
      final res = await req.close();
      final bytes = await res.fold<List<int>>([], (a, b) => a..addAll(b));
      if (res.statusCode == 200) {
        out.parent.createSync(recursive: true);
        out.writeAsBytesSync(bytes);
        await Future<void>.delayed(const Duration(milliseconds: 150));
        return;
      }
      if ((res.statusCode == 429 || res.statusCode >= 500) && attempt < 5) {
        await Future<void>.delayed(Duration(seconds: attempt * 2));
        continue;
      }
      throw HttpException(
        'Azure TTS ${res.statusCode}: ${utf8.decode(bytes, allowMalformed: true)}',
      );
    }
  } finally {
    client.close();
  }
}
