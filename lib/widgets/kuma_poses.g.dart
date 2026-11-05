// GENERIERT von tool/gen_kuma.dart – nicht von Hand ändern.
import 'figure.dart';

/// Posen von Kumachan, Leonis gehäkeltem Bären.
enum KumaPose implements FigurePose {
  /// Da sein
  idle(['idle_0.svg', 'idle_1.svg'], [1300, 1300]),

  /// Winken
  wave(
    ['wave_0.svg', 'wave_1.svg', 'wave_2.svg', 'wave_3.svg', 'wave_4.svg'],
    [600, 230, 230, 230, 230],
  ),

  /// Hüpfen
  cheer(['cheer_0.svg', 'cheer_1.svg'], [260, 260]),

  /// Herz drücken
  hug(
    ['hug_0.svg', 'hug_1.svg', 'hug_2.svg', 'hug_3.svg'],
    [520, 260, 260, 260],
  ),

  /// Tanzen
  dance(['dance_0.svg', 'dance_1.svg'], [420, 420]),

  /// Schlafen
  sleepy(
    ['sleepy_0.svg', 'sleepy_1.svg', 'sleepy_2.svg', 'sleepy_3.svg'],
    [600, 600, 1100, 1100],
  );

  const KumaPose(this.frames, this.ms);

  @override
  final List<String> frames;

  @override
  final List<int> ms;

  /// Knopfaugen blinzeln nicht.
  @override
  String? get blink => null;

  @override
  String get folder => 'kuma';

  /// Seitenverhältnis Breite/Höhe der Bilder.
  @override
  double get aspect => 200 / 300;
}
