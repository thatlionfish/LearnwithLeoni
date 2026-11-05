import 'speaker_stub.dart'
    if (dart.library.js_interop) 'speaker_web.dart'
    if (dart.library.io) 'speaker_io.dart'
    as impl;

/// Spielt Audio ab: eine Aufnahme aus dem Schülerordner oder – im Browser,
/// falls es für einen hochdeutschen Text noch keine gibt – die Computerstimme.
abstract final class Speaker {
  /// Ob überhaupt etwas abgespielt werden kann.
  static bool get available => impl.available;

  /// Werkstatt: Projektordner, damit Aufnahmen lokal gefunden werden.
  static set localRoot(String? root) => impl.localRoot = root;

  /// [url] relativ zur App, z. B. `data/students/demo/audio/termin.m4a`.
  /// Ohne [url] wird [text] vorgelesen ([lang] z. B. `de-DE` oder `de-CH`).
  static Future<void> play({
    String? url,
    String? text,
    String lang = 'de-DE',
    double rate = 1,
  }) => impl.play(url: url, text: text, lang: lang, rate: rate);

  /// Werkstatt: eine Datei direkt abspielen (frische Aufnahme anhören).
  static Future<void> playFile(String absolutePath) =>
      impl.playFile(absolutePath);

  static void stop() => impl.stop();
}
