// Probesätze zum Vergleich der Microsoft-Stimmen (nicht für die App).
//
//   dart run tool/tts_probe.dart
//
// Schreibt MP3s nach werkstatt/probe/ (nicht veröffentlicht):
//   1-katja-*.mp3         – Stimme wie jetzt in der App (de-DE-KatjaNeural)
//   2-seraphina-*.mp3     – neuere Stimme, gratis (de-DE-SeraphinaMultilingualNeural)
//   3-seraphina-hd-*.mp3  – HD-Stimme (de-DE-Seraphina:DragonHDLatestNeural),
//                           nur wenn AZURE_SPEECH_HD_KEY/-REGION gesetzt sind
import 'dart:convert';
import 'dart:io';

const probes = {
  'satz': 'Ernst Ludwig Kirchner war ein expressionistischer Maler.',
  'luecke': 'In Berlin malte Kirchner das hektische Leben der … hm, hm, hm … .',
  'dialog':
      'Wusstest du, dass Ernst Ludwig Kirchner in der Schweiz gelebt hat? '
      'Ja, in Davos! Er kam 1917 krank aus Berlin in die Berge.',
};

Future<void> main() async {
  final env = _readEnv();
  final out = Directory('werkstatt/probe')..createSync(recursive: true);
  final normal = (env['AZURE_SPEECH_KEY'], env['AZURE_SPEECH_REGION']);
  final hd = (env['AZURE_SPEECH_HD_KEY'], env['AZURE_SPEECH_HD_REGION']);

  final runs = <(String, String, (String?, String?), bool)>[
    ('1-katja', 'de-DE-KatjaNeural', normal, false),
    ('2-seraphina', 'de-DE-SeraphinaMultilingualNeural', normal, false),
    ('3-seraphina-hd', 'de-DE-Seraphina:DragonHDLatestNeural', hd, true),
  ];
  for (final (prefix, voice, (key, region), isHd) in runs) {
    if (key == null || key.isEmpty || region == null || region.isEmpty) {
      stdout.writeln('$prefix: übersprungen (kein Schlüssel dafür)');
      continue;
    }
    for (final MapEntry(key: name, value: text) in probes.entries) {
      // HD-Stimmen betonen selbst; Tempo nur bei den normalen Stimmen anpassen.
      final body = isHd
          ? _esc(text)
          : '<prosody rate="-6%">${_esc(text)}</prosody>';
      final ssml =
          '<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" '
          'xml:lang="de-DE"><voice name="$voice">$body</voice></speak>';
      final file = File('${out.path}/$prefix-$name.mp3');
      try {
        await _synthesize(key, region, ssml, file);
        stdout.writeln('erzeugt: ${file.path}');
      } on HttpException catch (e) {
        stdout.writeln('$prefix-$name: FEHLER ${e.message}');
      }
    }
  }
}

String _esc(String t) =>
    t.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

Map<String, String> _readEnv() {
  final map = <String, String>{...Platform.environment};
  final f = File('werkstatt/azure-speech.env');
  if (f.existsSync()) {
    for (final line in f.readAsLinesSync()) {
      final i = line.indexOf('=');
      if (i < 0 || line.trimLeft().startsWith('#')) continue;
      final v = line.substring(i + 1).trim();
      if (v.isNotEmpty) map[line.substring(0, i).trim()] = v;
    }
  }
  return map;
}

Future<void> _synthesize(
  String key,
  String region,
  String ssml,
  File out,
) async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(
      Uri.parse(
        'https://$region.tts.speech.microsoft.com/cognitiveservices/v1',
      ),
    );
    req.headers
      ..set('Ocp-Apim-Subscription-Key', key)
      ..set('Content-Type', 'application/ssml+xml')
      ..set('X-Microsoft-OutputFormat', 'audio-24khz-48kbitrate-mono-mp3')
      ..set('User-Agent', 'learnwithleoni-tts-probe');
    req.add(utf8.encode(ssml));
    final res = await req.close();
    final bytes = await res.fold<List<int>>([], (a, b) => a..addAll(b));
    if (res.statusCode != 200) {
      throw HttpException(
        '${res.statusCode}: ${utf8.decode(bytes, allowMalformed: true)}',
      );
    }
    out.writeAsBytesSync(bytes);
  } finally {
    client.close();
  }
}
