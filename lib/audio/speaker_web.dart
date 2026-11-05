import 'dart:js_interop';

import 'package:web/web.dart' as web;

web.HTMLAudioElement? _current;

/// Nur in der Werkstatt unter Windows genutzt.
String? localRoot;

bool get available => true;

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
  if (text == null || text.isEmpty) return;
  final synth = web.window.speechSynthesis;
  final u = web.SpeechSynthesisUtterance(text)
    ..lang = lang
    ..rate = rate;
  // Eine passende Stimme wählen, falls der Browser eine anbietet.
  final voices = synth.getVoices().toDart;
  for (final v in voices) {
    if (v.lang == lang) {
      u.voice = v;
      break;
    }
  }
  synth.speak(u);
}

Future<void> playFile(String absolutePath) async {}

void stop() {
  _current?.pause();
  _current = null;
  web.window.speechSynthesis.cancel();
}
