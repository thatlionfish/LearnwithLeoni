// Erzeugt Kumachan (Leonis gehäkelte Bärin) als SVG-Einzelbilder in
// assets/kuma/ und die Übersicht lib/widgets/kuma_poses.g.dart.
//
//   dart run tool/gen_kuma.dart
import 'dart:io';
import 'dart:math';

const ink = '#685A4E';
const mauve = '#8E7486';
const mauveDark = '#6F5869';
const mauveLight = '#A38D9C';
const paw = '#F1DCD6';
const collar = '#EFD6E2';
const heartPink = '#E7A9B9';
const nose = '#5B4A3E';
const button = '#FBF8F1';
const wood = '#D7CAB0';
const lemon = '#DCD494';

String n(num v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

String limb(String d, {String fill = mauve}) =>
    '<path d="$d" fill="none" stroke-width="19"/>\n'
    '<path d="$d" fill="none" stroke="$fill" stroke-width="15"/>';

String pawAt(num x, num y, {num r = 8}) =>
    '<circle cx="${n(x)}" cy="${n(y)}" r="${n(r)}" fill="$paw"/>';

String heart(num x, num y, {num s = 1, String fill = heartPink}) =>
    '<path transform="translate(${n(x)} ${n(y)}) scale(${n(s)})" '
    'd="M0,-3 C-2.5,-8 -9,-6 -7.5,0 C-6.5,3.5 0,8 0,8 C0,8 6.5,3.5 7.5,0 C9,-6 2.5,-8 0,-3 Z" '
    'fill="$fill" stroke-width="1.3"/>';

String rotate(num deg, num cx, num cy, String body) => deg == 0
    ? body
    : '<g transform="rotate(${n(deg)} ${n(cx)} ${n(cy)})">\n$body\n</g>';

String shift(num dx, num dy, String body) => dx == 0 && dy == 0
    ? body
    : '<g transform="translate(${n(dx)} ${n(dy)})">\n$body\n</g>';

/// Kleine Maschen als Andeutung der Häkelarbeit.
String stitches(
  Random r, {
  required num cx,
  required num cy,
  required num rx,
  required num ry,
  int count = 14,
}) {
  final b = StringBuffer();
  for (var i = 0; i < count; i++) {
    final a = r.nextDouble() * 2 * pi;
    final d = sqrt(r.nextDouble());
    final x = cx + cos(a) * rx * d * 0.85, y = cy + sin(a) * ry * d * 0.85;
    b.writeln(
      '<path d="M${n(x - 1.6)},${n(y - 1)} L${n(x)},${n(y + 1)} L${n(x + 1.6)},${n(y - 1)}" '
      'fill="none" stroke="$mauveDark" stroke-width="0.8" opacity="0.45"/>',
    );
  }
  return b.toString();
}

// --- Körperteile ---------------------------------------------------------

const shadow =
    '<ellipse cx="100" cy="290" rx="48" ry="5" fill="$wood" stroke="none" opacity="0.55"/>';

const legs =
    '''
<path d="M78,186 C73,220 69,254 67,277 C66,289 85,291 87,280 C89,256 92,222 97,190 Z" fill="$mauve"/>
<path d="M122,186 C127,220 131,254 133,277 C134,289 115,291 113,280 C111,256 108,222 103,190 Z" fill="$mauve"/>
<path d="M68,282 C72,287 82,288 86,283" fill="none" stroke="$paw" stroke-width="3"/>
<path d="M114,283 C118,288 128,287 132,282" fill="none" stroke="$paw" stroke-width="3"/>''';

const body = '''
<path d="M74,118 C66,140 64,175 74,195 C86,212 114,212 126,195 C136,175 134,140 126,118 C116,108 84,108 74,118 Z" fill="$mauve"/>''';

const collarPart =
    '''
<path d="M82,111 C94,119 106,119 118,111 C119,117 112,123 100,123 C88,123 81,117 82,111 Z" fill="$collar"/>
<path d="M88,117 L90,121 M96,119 L97,123 M104,119 L103,123 M112,117 L110,121" fill="none" stroke-width="0.9" opacity="0.5"/>''';

const ears =
    '''
<circle cx="68" cy="46" r="13" fill="$mauve"/>
<circle cx="132" cy="46" r="13" fill="$mauve"/>
<circle cx="69" cy="47" r="6.5" fill="$mauveDark" stroke="none" opacity="0.55"/>
<circle cx="131" cy="47" r="6.5" fill="$mauveDark" stroke="none" opacity="0.55"/>''';

String buttonEye(num x, num y) =>
    '''
<circle cx="${n(x)}" cy="${n(y)}" r="7.2" fill="$button" stroke-width="1.6"/>
<circle cx="${n(x - 2)}" cy="${n(y - 2)}" r="1" fill="$ink" stroke="none"/>
<circle cx="${n(x + 2)}" cy="${n(y - 2)}" r="1" fill="$ink" stroke="none"/>
<circle cx="${n(x - 2)}" cy="${n(y + 2)}" r="1" fill="$ink" stroke="none"/>
<circle cx="${n(x + 2)}" cy="${n(y + 2)}" r="1" fill="$ink" stroke="none"/>
<path d="M${n(x - 2)},${n(y - 2)} L${n(x + 2)},${n(y + 2)} M${n(x + 2)},${n(y - 2)} L${n(x - 2)},${n(y + 2)}" fill="none" stroke="$ink" stroke-width="0.7" opacity="0.7"/>''';

String head({bool happy = false}) =>
    '''
$ears
<circle cx="100" cy="72" r="34" fill="$mauve"/>
${stitches(Random(3), cx: 100, cy: 66, rx: 30, ry: 26, count: 10)}
<ellipse cx="100" cy="85" rx="15.5" ry="12.5" fill="$mauveLight"/>
<ellipse cx="100" cy="80.5" rx="7.2" ry="5.6" fill="$nose" stroke="$nose"/>
<path d="M100,86 L100,89.5" fill="none" stroke-width="1.4"/>
${happy ? '<path d="M93.5,89 C97,95 103,95 106.5,89 Z" fill="#C97F6E" stroke-width="1.4"/>' : '<path d="M95,89.5 C98,92.5 102,92.5 105,89.5" fill="none" stroke-width="1.4"/>'}
${buttonEye(84, 65)}
${buttonEye(116, 65)}''';

String sleepyHead() =>
    '''
$ears
<circle cx="100" cy="72" r="34" fill="$mauve"/>
${stitches(Random(3), cx: 100, cy: 66, rx: 30, ry: 26, count: 10)}
<ellipse cx="100" cy="85" rx="15.5" ry="12.5" fill="$mauveLight"/>
<ellipse cx="100" cy="80.5" rx="7.2" ry="5.6" fill="$nose" stroke="$nose"/>
<path d="M97,90 C99,91 101,91 103,90" fill="none" stroke-width="1.4"/>
${buttonEye(84, 65)}
${buttonEye(116, 65)}
<path d="M76.8,65.5 A7.2,7.2 0 0 1 91.2,65.5 Z" fill="$mauveDark" stroke-width="1.6"/>
<path d="M108.8,65.5 A7.2,7.2 0 0 1 123.2,65.5 Z" fill="$mauveDark" stroke-width="1.6"/>
<path d="M78,68 C80,69.5 82,70 84,70 M110,68 C112,69.5 114,70 116,70" fill="none" stroke-width="1" opacity="0.6"/>''';

// Arme: Schulter links (80,126), rechts (120,126).
String armLeftOut() =>
    '${limb('M80,126 C64,131 50,139 39,146')}\n${pawAt(36, 148)}';
String armRightOut() =>
    '${limb('M120,126 C136,131 150,139 161,146')}\n${pawAt(164, 148)}';
String armLeftUp() =>
    '${limb('M80,126 C66,116 58,100 54,84')}\n${pawAt(53, 78)}';
String armRightUp() =>
    '${limb('M120,126 C134,116 142,100 146,84')}\n${pawAt(147, 78)}';

String zzz(int step) => [
  for (final (i, (x, y, s)) in const [
    (140.0, 40.0, 7.0),
    (152.0, 26.0, 9.0),
    (166.0, 10.0, 11.0),
  ].indexed)
    if (i < step)
      '<path d="M${n(x)},${n(y)} h${n(s)} l-${n(s)},${n(s)} h${n(s)}" fill="none" stroke-width="1.8" opacity="${n(0.5 + i * 0.2)}"/>',
].join('\n');

/// Kleines Häkelquadrat zwischen den Pfoten (eine Runde Lemon Grass innen).
const crochetPiece =
    '<path d="M88,141 C93,139.5 102,139.5 108,141 C109.5,146 109.5,153 108,158 '
    'C102,159.5 93,159.5 88,158 C86.5,153 86.5,146 88,141 Z" fill="#E3D8C2" stroke-width="1.6"/>\n'
    '<path d="M93,145.5 C96,144.8 100,144.8 103,145.5 C103.7,148.5 103.7,151.5 103,154.5 '
    'C100,155.2 96,155.2 93,154.5 C92.3,151.5 92.3,148.5 93,145.5 Z" fill="$lemon" stroke-width="1.2"/>\n'
    '<path d="M90,149.5 h2 M104,149.5 h2 M98,142.5 v1.6 M98,156 v1.6" fill="none" stroke-width="1" opacity="0.6"/>';

/// Häkelnadel aus Holz, Griff in der rechten Pfote.
const crochetHook =
    '<path d="M114,150 L97,128" fill="none" stroke="$wood" stroke-width="3.4"/>\n'
    '<path d="M114,150 L97,128" fill="none" stroke-width="0.9" opacity="0.55"/>\n'
    '<path d="M97,128 c-1.6,-2.2 -0.6,-4.2 1.4,-3.6" fill="none" stroke-width="1.6"/>';

/// Wollknäuel unten links, der Faden läuft hinauf zum Häkelstück.
const yarnBall =
    '<path d="M88,158 C70,190 40,214 46,248" fill="none" stroke="#C9B48F" stroke-width="1.6"/>\n'
    '<circle cx="44" cy="266" r="17" fill="#E3D8C2" stroke-width="1.8"/>\n'
    '<path d="M30,258 C38,250 52,252 58,262 M28,268 C38,258 54,262 60,272 '
    'M34,279 C40,270 52,270 56,281 M40,250 C36,262 38,274 46,283" '
    'fill="none" stroke="#C9B48F" stroke-width="1.3"/>';

String sparkle(num x, num y, {num r = 1}) =>
    '<path d="M${n(x)},${n(y - 7 * r)} L${n(x + 2.2 * r)},${n(y - 2.2 * r)} L${n(x + 7 * r)},${n(y)} '
    'L${n(x + 2.2 * r)},${n(y + 2.2 * r)} L${n(x)},${n(y + 7 * r)} L${n(x - 2.2 * r)},${n(y + 2.2 * r)} '
    'L${n(x - 7 * r)},${n(y)} L${n(x - 2.2 * r)},${n(y - 2.2 * r)} Z" fill="$lemon" stroke-width="1.2"/>';

/// Ein Bild: Körper-Drehung/Verschiebung, Arme, Kopf und Extras.
String figure({
  String arms = '',
  String? headPart,
  num bodyRot = 0,
  num bodyDy = 0,
  num headRot = 0,
  String chestHeart = '',
  String extras = '',
  num shadowScale = 1,
}) {
  final chest = chestHeart.isEmpty ? heart(113, 142) : chestHeart;
  final inner = [
    legs,
    body,
    stitches(Random(7), cx: 100, cy: 165, rx: 28, ry: 40),
    // Kurzer Hals: der Kopf sitzt nah am Körper, der Kragen liegt darauf.
    '<path d="M88,98 C87,106 87,114 86,121 C94,125 106,125 114,121 C113,114 113,106 112,98 Z" fill="$mauve"/>',
    collarPart,
    // Ein grosses Herz (Pose „Herz drücken“) liegt vor den Pfoten.
    if (chestHeart.isEmpty) chest,
    arms,
    if (chestHeart.isNotEmpty) chest,
    rotate(headRot, 100, 112, shift(0, 6, headPart ?? head())),
  ].join('\n');
  final shadowSvg = shadowScale == 1
      ? shadow
      : '<ellipse cx="100" cy="290" rx="${n(48 * shadowScale)}" ry="5" fill="$wood" stroke="none" opacity="0.45"/>';
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 300" width="200" height="300">\n'
      '<!-- Kumachan – erzeugt von tool/gen_kuma.dart -->\n'
      '<g stroke="$ink" stroke-width="2" stroke-linejoin="round" stroke-linecap="round">\n'
      '$shadowSvg\n'
      '${rotate(bodyRot, 100, 286, shift(0, bodyDy, inner))}\n'
      '$extras\n</g>\n</svg>\n';
}

/// Kumachan liegt in ihrer Decke (Rolle quer): nur Kopf und Kragen schauen
/// heraus, der Kopf zur Seite geneigt. Drehpunkt (100,112) = Mitte der Rolle.
const snugTilt = -38;

String snugFigure(String headPart, {String extras = ''}) =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 300" width="200" height="300">\n'
    '<!-- Kumachan – erzeugt von tool/gen_kuma.dart -->\n'
    '<g stroke="$ink" stroke-width="2" stroke-linejoin="round" stroke-linecap="round">\n'
    '${rotate(snugTilt, 100, 112, [
      '<path d="M88,98 C87,106 87,114 86,121 C94,125 106,125 114,121 C113,114 113,106 112,98 Z" fill="$mauve"/>',
      collarPart,
      shift(0, 6, headPart),
    ].join('\n'))}\n'
    '$extras\n</g>\n</svg>\n';

/// Zzz über dem liegenden Kopf.
String snugZzz(int step) => [
  for (final (i, (x, y, s)) in const [
    (52.0, 40.0, 7.0),
    (40.0, 25.0, 9.0),
    (26.0, 8.0, 11.0),
  ].indexed)
    if (i < step)
      '<path d="M${n(x)},${n(y)} h${n(s)} l-${n(s)},${n(s)} h${n(s)}" fill="none" stroke-width="1.8" opacity="${n(0.5 + i * 0.2)}"/>',
].join('\n');

class Pose {
  const Pose(this.name, this.title, this.frames);
  final String name;
  final String title;
  final List<(String, int)> frames;
}

final poses = <Pose>[
  Pose('idle', 'Da sein', [
    (figure(arms: '${armLeftOut()}\n${armRightOut()}', bodyRot: -2), 1300),
    (figure(arms: '${armLeftOut()}\n${armRightOut()}', bodyRot: 2), 1300),
  ]),
  Pose('wave', 'Winken', [
    for (final (deg, ms) in const [
      (0, 600),
      (-14, 230),
      (0, 230),
      (-14, 230),
      (0, 230),
    ])
      (
        figure(
          arms: '${armLeftOut()}\n${rotate(deg, 120, 126, armRightUp())}',
          headPart: head(happy: true),
          headRot: -4,
        ),
        ms,
      ),
  ]),
  Pose('cheer', 'Hüpfen', [
    (
      figure(
        arms: '${armLeftUp()}\n${armRightUp()}',
        headPart: head(happy: true),
      ),
      260,
    ),
    (
      figure(
        arms:
            '${rotate(-8, 80, 126, armLeftUp())}\n${rotate(8, 120, 126, armRightUp())}',
        headPart: head(happy: true),
        bodyDy: -14,
        shadowScale: 0.75,
        extras: '${sparkle(36, 54, r: 0.8)}\n${sparkle(166, 46, r: 0.65)}',
      ),
      260,
    ),
  ]),
  Pose('hug', 'Herz drücken', [
    for (final (s, ms) in const [
      (1.0, 520),
      (1.18, 260),
      (1.0, 260),
      (1.18, 260),
    ])
      (
        figure(
          arms:
              '${limb('M80,126 C74,142 84,154 95,152')}\n${limb('M120,126 C126,142 116,154 105,152')}'
              '\n${pawAt(95, 151, r: 7)}\n${pawAt(105, 151, r: 7)}',
          chestHeart: heart(100, 140, s: 2.1 * s),
          headPart: head(happy: true),
        ),
        ms,
      ),
  ]),
  Pose('dance', 'Tanzen', [
    for (final (deg, armDeg) in const [(-7, -10), (7, 10)])
      (
        figure(
          arms:
              '${rotate(armDeg, 80, 126, armLeftUp())}\n${rotate(armDeg, 120, 126, armRightOut())}',
          headPart: head(happy: true),
          bodyRot: deg,
          headRot: deg,
        ),
        420,
      ),
  ]),
  Pose('crochet', 'Häkeln', [
    for (final (hook, ms) in const [(0, 380), (-16, 300), (0, 380), (-16, 300)])
      (
        figure(
          // Beide Pfoten vor der Brust: links das Häkelstück, rechts die Nadel.
          arms:
              '${limb('M80,126 C70,140 76,152 88,154')}\n'
              '${limb('M120,126 C132,138 126,150 114,150')}\n'
              '$crochetPiece\n'
              '${pawAt(88, 153, r: 7)}\n'
              '${rotate(hook, 114, 150, crochetHook)}\n'
              '${pawAt(114, 150, r: 7)}',
          headPart: head(happy: true),
          headRot: hook == 0 ? 3 : 5,
          extras: yarnBall,
        ),
        ms,
      ),
  ]),
  Pose('sleepy', 'Schlafen', [
    for (final step in [1, 2, 3, 3])
      (
        figure(
          arms:
              '${limb('M80,126 C74,146 78,166 84,178')}\n${pawAt(85, 182)}'
              '\n${limb('M120,126 C126,146 122,166 116,178')}\n${pawAt(115, 182)}',
          headPart: sleepyHead(),
          headRot: 10,
          extras: zzz(step),
        ),
        step == 3 ? 1100 : 600,
      ),
  ]),
  // In der Decke: erst wach und zufrieden, ab einer dicken Rolle schläft sie.
  Pose('snug', 'Eingekuschelt', [
    (snugFigure(head(happy: true)), 1800),
    (snugFigure(rotate(4, 100, 72, head(happy: true))), 1400),
  ]),
  Pose('snugSleepy', 'Eingekuschelt schlafen', [
    for (final step in [1, 2, 3, 3])
      (
        snugFigure(sleepyHead(), extras: snugZzz(step)),
        step == 3 ? 1100 : 600,
      ),
  ]),
];

void main() {
  final dir = Directory('assets/kuma')..createSync(recursive: true);
  for (final f in dir.listSync()) {
    if (f.path.endsWith('.svg')) f.deleteSync();
  }
  final out = StringBuffer()
    ..writeln('// GENERIERT von tool/gen_kuma.dart – nicht von Hand ändern.')
    ..writeln("import 'figure.dart';")
    ..writeln()
    ..writeln('/// Posen von Kumachan, Leonis gehäkelter Bärin.')
    ..writeln('enum KumaPose implements FigurePose {');
  for (final p in poses) {
    final files = <String>[];
    for (final (i, (svg, _)) in p.frames.indexed) {
      final file = '${p.name}_$i.svg';
      File('${dir.path}/$file').writeAsStringSync(svg);
      files.add("'$file'");
    }
    out
      ..writeln('  /// ${p.title}')
      ..writeln(
        '  ${p.name}([${files.join(', ')}], [${p.frames.map((f) => f.$2).join(', ')}]),',
      );
    stdout.writeln('${p.name}: ${files.length} Bilder');
  }
  out
    ..writeln('  ;')
    ..writeln()
    ..writeln('  const KumaPose(this.frames, this.ms);')
    ..writeln()
    ..writeln('  @override')
    ..writeln('  final List<String> frames;')
    ..writeln()
    ..writeln('  @override')
    ..writeln('  final List<int> ms;')
    ..writeln()
    ..writeln('  /// Knopfaugen blinzeln nicht.')
    ..writeln('  @override')
    ..writeln('  String? get blink => null;')
    ..writeln()
    ..writeln('  @override')
    ..writeln("  String get folder => 'kuma';")
    ..writeln()
    ..writeln('  /// Seitenverhältnis Breite/Höhe der Bilder.')
    ..writeln('  @override')
    ..writeln('  double get aspect => 200 / 300;')
    ..writeln('}');
  File('lib/widgets/kuma_poses.g.dart').writeAsStringSync(out.toString());
}
