import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

web.HTMLAudioElement? _current;
Timer? _gapTimer;

/// Zählt Wiedergaben, damit eine abgebrochene nicht weiterspricht.
int _generation = 0;

/// Nur in der Werkstatt unter Windows genutzt.
String? localRoot;

bool get available => true;

/// Pause an einer Lücke (`___`) im vorgelesenen Text.
const _gap = Duration(milliseconds: 900);

final Map<String, web.SpeechSynthesisVoice?> _chosen = {};

/// Wartet, bis der Browser seine Stimmen geladen hat (Chrome liefert beim
/// ersten Aufruf eine leere Liste – dann würde die Systemstimme genommen,
/// auf einem japanischen Windows z. B. eine japanische).
Future<List<web.SpeechSynthesisVoice>> _voices() async {
  final synth = web.window.speechSynthesis;
  var voices = synth.getVoices().toDart;
  if (voices.isNotEmpty) return voices;
  final done = Completer<void>();
  synth.onvoiceschanged = ((web.Event _) {
    if (!done.isCompleted) done.complete();
  }).toJS;
  await done.future.timeout(const Duration(seconds: 3), onTimeout: () {});
  voices = synth.getVoices().toDart;
  return voices;
}

/// Beste Stimme für [lang]: natürliche bzw. Online-Stimmen bevorzugt.
int _score(web.SpeechSynthesisVoice v, String lang) {
  final vl = v.lang.replaceAll('_', '-').toLowerCase();
  final want = lang.toLowerCase();
  if (!vl.startsWith(want.split('-').first)) return -1;
  final name = v.name.toLowerCase();
  var s = 0;
  if (vl == want) s += 30;
  if (vl == 'de-de') s += 10; // Standarddeutsch ist am deutlichsten.
  if (name.contains('natural') || name.contains('neural')) s += 60;
  if (name.contains('online')) s += 25;
  if (name.contains('google')) s += 35;
  if (name.contains('premium') || name.contains('enhanced')) s += 30;
  if (!v.localService) s += 5;
  return s;
}

Future<web.SpeechSynthesisVoice?> _voiceFor(String lang) async {
  if (_chosen.containsKey(lang)) return _chosen[lang];
  final voices = await _voices();
  web.SpeechSynthesisVoice? best;
  var bestScore = -1;
  for (final v in voices) {
    final s = _score(v, lang);
    if (s > bestScore) {
      best = v;
      bestScore = s;
    }
  }
  // Nur cachen, wenn die Liste geladen war (sonst später nochmal suchen).
  if (voices.isNotEmpty) _chosen[lang] = best;
  return best;
}

Future<void> play({
  String? url,
  String? text,
  required String lang,
  required double rate,
}) async {
  stop();
  if (url != null) {
    final audio = web.HTMLAudioElement()
      ..src = url
      ..playbackRate = rate;
    _current = audio;
    await audio.play().toDart;
    return;
  }
  if (text == null || text.trim().isEmpty) return;
  final voice = await _voiceFor(lang);
  web.SpeechSynthesisUtterance utter(String part) {
    final u = web.SpeechSynthesisUtterance(part)
      ..lang = voice?.lang ?? lang
      ..rate = rate * 0.95;
    if (voice != null) u.voice = voice;
    return u;
  }

  // Satz für Satz sprechen: Chromes Online-Stimmen brechen lange Texte sonst
  // nach etwa 15 Sekunden ab. An einer Lücke „___“ summt die Stimme
  // „Hm hm hm“, damit klar ist: hier fehlt ein Wort.
  final segments = <(String, Duration)>[]; // (Text, Pause danach)
  const short = Duration(milliseconds: 120);
  final parts = text.split('___');
  for (var p = 0; p < parts.length; p++) {
    final sentences = [
      for (final s in parts[p].split(RegExp(r'(?<=[.!?…])\s+|\n+')))
        if (RegExp(r'[A-Za-zÄÖÜäöüß0-9]').hasMatch(s)) s.trim(),
    ];
    final gapFollows = p < parts.length - 1;
    for (var i = 0; i < sentences.length; i++) {
      final last = i == sentences.length - 1;
      segments.add((sentences[i], last && gapFollows ? _gap ~/ 3 : short));
    }
    if (gapFollows) segments.add((_hum, _gap ~/ 3));
  }
  _speakFrom(segments, 0, utter, _generation);
}

/// Wird an einer Lücke gesprochen.
const _hum = 'Hm hm hm';

void _speakFrom(
  List<(String, Duration)> segments,
  int i,
  web.SpeechSynthesisUtterance Function(String) utter,
  int generation,
) {
  if (i >= segments.length || generation != _generation) return;
  final (part, pause) = segments[i];
  final u = utter(part);
  if (part == _hum) u.pitch = 1.15; // leicht höher, wie ein fragendes Summen
  if (i < segments.length - 1) {
    u.onend = ((web.Event _) {
      _gapTimer = Timer(
        pause,
        () => _speakFrom(segments, i + 1, utter, generation),
      );
    }).toJS;
  }
  web.window.speechSynthesis.speak(u);
}

Future<void> playFile(String absolutePath) async {}

void stop() {
  _generation++;
  _gapTimer?.cancel();
  _current?.pause();
  _current = null;
  web.window.speechSynthesis.cancel();
}
