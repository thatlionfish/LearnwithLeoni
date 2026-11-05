// Werkstatt unter Windows: Aufnahmen direkt aus dem Projektordner abspielen.
import 'package:audioplayers/audioplayers.dart';

/// Projektordner, von der Werkstatt gesetzt (enthält `web/`).
String? localRoot;

AudioPlayer? _player;

bool get available => localRoot != null;

Future<void> play({
  String? url,
  String? text,
  required String lang,
  required double rate,
}) async {
  final root = localRoot;
  // Keine Computerstimme unter Windows.
  if (url == null || root == null) return;
  final player = _player ??= AudioPlayer();
  await player.stop();
  await player.setPlaybackRate(rate);
  await player.play(DeviceFileSource('$root/web/$url'));
}

Future<void> playFile(String absolutePath) async {
  final player = _player ??= AudioPlayer();
  await player.stop();
  await player.setPlaybackRate(1);
  await player.play(DeviceFileSource(absolutePath));
}

void stop() {
  _player?.stop();
}
