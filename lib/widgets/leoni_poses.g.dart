// GENERIERT von tool/gen_leoni.dart – nicht von Hand ändern.
import 'figure.dart';

/// Posen der Comic-Figur mit ihren Animationsbildern.
enum LeoniPose implements FigurePose {
  /// Winken
  wave(
    ['wave_0.svg', 'wave_1.svg', 'wave_2.svg', 'wave_3.svg', 'wave_4.svg'],
    [700, 220, 220, 220, 220],
    'wave_blink.svg',
  ),

  /// Daumen hoch
  thumbs(['thumbs_0.svg', 'thumbs_1.svg'], [900, 260], null),

  /// Jubeln
  cheer(['cheer_0.svg', 'cheer_1.svg'], [300, 300], null),

  /// Aufmuntern
  encourage(
    [
      'encourage_0.svg',
      'encourage_1.svg',
      'encourage_2.svg',
      'encourage_3.svg',
    ],
    [800, 240, 240, 240],
    'encourage_blink.svg',
  ),

  /// Nachdenken
  think(
    ['think_0.svg', 'think_1.svg', 'think_2.svg', 'think_3.svg'],
    [450, 450, 900, 900],
    'think_blink.svg',
  ),

  /// Herz
  heart(['heart_0.svg', 'heart_1.svg'], [600, 600], null),

  /// Schulterzucken
  shrug(['shrug_0.svg', 'shrug_1.svg'], [900, 450], 'shrug_blink.svg'),

  /// Klatschen
  clap(['clap_0.svg', 'clap_1.svg'], [200, 180], null),

  /// Zeigen
  point(['point_0.svg', 'point_1.svg'], [900, 300], 'point_blink.svg'),

  /// Lesen
  read(['read_0.svg', 'read_1.svg'], [1200, 900], 'read_blink.svg'),

  /// Freudensprung
  kick(['kick_0.svg', 'kick_1.svg'], [420, 420], null);

  const LeoniPose(this.frames, this.ms, this.blink);

  /// Dateinamen in assets/leoni/.
  @override
  final List<String> frames;

  /// Anzeigedauer pro Bild in Millisekunden.
  @override
  final List<int> ms;

  /// Bild mit geschlossenen Augen, falls die Pose blinzeln kann.
  @override
  final String? blink;

  @override
  String get folder => 'leoni';

  @override
  double get aspect => 220 / 360;
}
