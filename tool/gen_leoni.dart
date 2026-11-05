// Erzeugt die Posen der Comic-Figur als SVG-Einzelbilder in assets/leoni/
// und die Übersicht assets/leoni/poses.json (Bilder + Dauer pro Bild).
//
//   dart run tool/gen_leoni.dart
//
// Alle Posen teilen Körper, Kopf, Haare und Mütze. Pro Pose gibt es mehrere
// Bilder für die Animation (z. B. Arm hin und her) und ein Blinzel-Bild.
import 'dart:convert';
import 'dart:io';

const skin = '#F3DCC8';
const cloth = '#F4F9FF';
const ink = '#685A4E';
const dark = '#2E2621';
const gold = '#C49A3A';
const hair = '#DCD1B9';
const hairLine = '#A99E88';
const blush = '#E9B7A3';
const lemon = '#DCD494';
const wood = '#D7CAB0';
const pearl = '#FBF8F1';

String n(num v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

String sleeve(String d) =>
    '<path d="$d" fill="none" stroke-width="18"/>\n'
    '<path d="$d" fill="none" stroke="$cloth" stroke-width="14"/>';

String hand(num cx, num cy, {num rx = 7, num ry = 6.5}) =>
    '<ellipse cx="${n(cx)}" cy="${n(cy)}" rx="${n(rx)}" ry="${n(ry)}" fill="$skin"/>';

/// Offene Hand, Handfläche zum Betrachter, Finger nach oben.
/// [thumbRight]: Daumen zeigt nach rechts (vom Betrachter aus).
String openHand(num cx, num cy, {bool thumbRight = true, num rot = 0}) {
  final s = thumbRight ? 1 : -1;
  final fingers = [
    'M${n(-4.5 * s)},-4 L${n(-5.6 * s)},-13.5',
    'M${n(-1.5 * s)},-5 L${n(-1.7 * s)},-16',
    'M${n(1.7 * s)},-5 L${n(2.1 * s)},-15.5',
    'M${n(4.6 * s)},-4 L${n(5.8 * s)},-12',
  ];
  final thumb =
      'M${n(5 * s)},3 C${n(8.5 * s)},1.5 ${n(10.5 * s)},-1.5 ${n(11.5 * s)},-5';
  final all = [...fingers, thumb];
  return '<g transform="translate(${n(cx)} ${n(cy)}) rotate(${n(rot)})">\n'
      '${all.map((d) => '<path d="$d" fill="none" stroke-width="5.6"/>').join('\n')}\n'
      '<path d="M-6.5,6 C-8.5,0 -7.5,-4 -5.5,-6 L5.5,-6 C7.5,-4 8.5,0 6.5,6 C4.5,9.5 -4.5,9.5 -6.5,6 Z" fill="$skin"/>\n'
      '${all.map((d) => '<path d="$d" fill="none" stroke="$skin" stroke-width="3.4"/>').join('\n')}\n'
      '</g>';
}

String rotate(num deg, num cx, num cy, String body) => deg == 0
    ? body
    : '<g transform="rotate(${n(deg)} ${n(cx)} ${n(cy)})">\n$body\n</g>';

String shift(num dx, num dy, String body) => dx == 0 && dy == 0
    ? body
    : '<g transform="translate(${n(dx)} ${n(dy)})">\n$body\n</g>';

String sparkle(num x, num y, {num r = 1}) =>
    '<path d="M${n(x)},${n(y - 7 * r)} L${n(x + 2.2 * r)},${n(y - 2.2 * r)} L${n(x + 7 * r)},${n(y)} '
    'L${n(x + 2.2 * r)},${n(y + 2.2 * r)} L${n(x)},${n(y + 7 * r)} L${n(x - 2.2 * r)},${n(y + 2.2 * r)} '
    'L${n(x - 7 * r)},${n(y)} L${n(x - 2.2 * r)},${n(y - 2.2 * r)} Z" fill="$lemon" stroke-width="1.2"/>';

String smallHeart(num x, num y, {num s = 1, num opacity = 0.9}) =>
    '<path transform="translate(${n(x)} ${n(y)}) scale(${n(s)})" '
    'd="M0,-4 C-3,-8 -8,-6 -6,-1 C-5,2 0,5 0,5 C0,5 5,2 6,-1 C8,-6 3,-8 0,-4 Z" '
    'fill="$blush" stroke-width="1.2" opacity="${n(opacity)}"/>';

// --- Teile, die alle Posen gemeinsam haben -------------------------------

const shadow =
    '<ellipse cx="110" cy="342" rx="56" ry="5" fill="$wood" stroke="none" opacity="0.55"/>';

const hairBack =
    '<path d="M80,76 C74,104 74,134 68,156 C80,162 96,160 104,154 L116,154 C124,160 140,162 152,156 C146,134 146,104 140,76 Z" fill="$hair"/>';

const neck =
    '<path d="M102,114 L102,130 C106,135 114,135 118,130 L118,114 Z" fill="$skin"/>';

const skirt =
    '''
<path d="M78,214 L142,214 C150,250 156,290 162,320 L58,320 C64,290 70,250 78,214 Z" fill="$cloth"/>
<path d="M96,232 C94,262 92,290 90,318" fill="none" stroke-width="1.2" opacity="0.6"/>
<path d="M124,232 C126,262 128,290 130,318" fill="none" stroke-width="1.2" opacity="0.6"/>''';

const leftFoot =
    '''
<path d="M84,319 L84,330 L99,330 L99,319 Z" fill="#FFFFFF"/>
<path d="M100,328 C92,327 80,328 77,333 C76,339 84,341 100,341 C104,341 105,332 100,328 Z" fill="$dark" stroke="$dark"/>
<path d="M86,333 L94,333" stroke="$cloth" stroke-width="1.2"/>''';

const rightFoot =
    '''
<path d="M121,319 L121,330 L136,330 L136,319 Z" fill="#FFFFFF"/>
<path d="M120,328 C128,327 140,328 143,333 C144,339 136,341 120,341 C116,341 115,332 120,328 Z" fill="$dark" stroke="$dark"/>
<path d="M126,333 L134,333" stroke="$cloth" stroke-width="1.2"/>''';

const legsStanding = '$skirt\n$leftFoot\n$rightFoot';

const torso =
    '''
<path d="M80,132 C92,124 128,124 140,132 C150,140 152,150 150,160 L146,220 C124,226 96,226 74,220 L70,160 C68,150 70,140 80,132 Z" fill="$cloth"/>
<path d="M100,127 L110,146 L120,127" fill="none"/>
<path d="M74,207 C96,213 124,213 146,207" fill="none" stroke-width="1.6"/>
<circle cx="110" cy="162" r="1.8" fill="$wood"/>
<circle cx="110" cy="182" r="1.8" fill="$wood"/>''';

/// Perlenkette und feine Goldkette mit Anhänger.
final jewellery = [
  '<path d="M99,130 C102,147 118,147 121,130" fill="none" stroke="$gold" stroke-width="1.1"/>',
  '<circle cx="110" cy="144.5" r="2" fill="$gold" stroke="none"/>',
  for (final (x, y) in const [
    (101.0, 130.6),
    (103.1, 133.1),
    (105.5, 134.8),
    (108.0, 135.8),
    (110.5, 136.0),
    (113.0, 135.6),
    (115.3, 134.4),
    (117.4, 132.5),
    (119.1, 130.2),
  ])
    '<circle cx="${n(x)}" cy="${n(y)}" r="1.55" fill="$pearl" stroke="$hairLine" stroke-width="0.6"/>',
].join('\n');

const strap =
    '<path d="M86,132 L150,210" fill="none" stroke="$dark" stroke-width="3"/>';

const bag =
    '''
<g stroke="$dark">
  <path d="M156,206 C156,195 178,195 178,206" fill="none" stroke-width="2.4"/>
  <rect x="140" y="206" width="54" height="44" rx="6" fill="#FFFFFF" stroke-width="2.6"/>
  <path d="M140,206 L194,206 L194,222 C180,228 154,228 140,222 Z" fill="#F0EADA" stroke-width="2.2"/>
  <rect x="151" y="221" width="6" height="10" rx="1" fill="$dark"/>
  <rect x="177" y="221" width="6" height="10" rx="1" fill="$dark"/>
  <rect x="150" y="233" width="34" height="12" rx="3" fill="none" stroke-width="1.8"/>
  <path d="M194,232 C198,234 199,238 197,241" fill="none" stroke-width="1.2"/>
</g>
<circle cx="196" cy="245" r="4.2" fill="$lemon" stroke-width="1.4"/>''';

const faceBase =
    '''
<ellipse cx="110" cy="88" rx="26" ry="30" fill="$skin"/>
<circle cx="96" cy="103" r="5" fill="$blush" stroke="none" opacity="0.65"/>
<circle cx="124" cy="103" r="5" fill="$blush" stroke="none" opacity="0.65"/>
<path d="M110,95 C109,99 109,101 112,102" fill="none" stroke-width="1.4"/>''';

/// Lange, glatte Haare mit seitlichem Pony (Curtain Bangs) unter der Mütze.
const hairFront =
    '''
<path d="M88,74 C82,92 80,112 77,132 C75,142 73,148 70,152 C78,155 88,152 94,146 C91,124 92,100 99,80 Z" fill="$hair" stroke-width="1.6"/>
<path d="M132,74 C138,92 140,112 143,132 C145,142 147,148 150,152 C142,155 132,152 126,146 C129,124 128,100 121,80 Z" fill="$hair" stroke-width="1.6"/>
<path d="M94,78 C91,83 90,88 89,94 C92,91 95,86 97,80 Z" fill="$hair" stroke-width="1.3"/>
<path d="M126,78 C129,83 130,88 131,94 C128,91 125,86 123,80 Z" fill="$hair" stroke-width="1.3"/>
<path d="M88,98 C85,116 83,132 79,146" fill="none" stroke="$hairLine" stroke-width="1"/>
<path d="M132,98 C135,116 137,132 141,146" fill="none" stroke="$hairLine" stroke-width="1"/>
<circle cx="86" cy="106" r="4.6" fill="none" stroke="$gold" stroke-width="1.9"/>
<circle cx="134" cy="106" r="4.6" fill="none" stroke="$gold" stroke-width="1.9"/>''';

/// Schiebermütze im Stil einer Kangol 504 (ohne Logo).
const cap = '''
<path d="M79,72 C76,58 90,48 112,47 C134,46 147,55 144,67 C143,72 138,74 131,72 C118,69 100,69 88,72 C84,73 80,75 79,72 Z" fill="#BFAE8E"/>
<path d="M85,63 C99,57 125,56 140,62" fill="none" stroke-width="0.9" opacity="0.5"/>
<path d="M92,55 C104,51 122,50 134,53" fill="none" stroke-width="0.8" opacity="0.35"/>
<path d="M86,72 C100,68 122,68 137,72 C137,77 128,80 111,80 C95,80 86,77 86,72 Z" fill="#AE9C7B"/>
<path d="M92,75.5 C104,73.5 118,73.5 131,75.5" fill="none" stroke-width="0.8" opacity="0.45"/>''';

// --- Gesichtsausdrücke ---------------------------------------------------

const browsNormal = '''
<path d="M94,84 C98,81 103,81 106,83" fill="none" stroke-width="1.6"/>
<path d="M114,83 C117,81 122,81 126,84" fill="none" stroke-width="1.6"/>''';
const browsRaised = '''
<path d="M94,82 C98,78 103,78 106,80" fill="none" stroke-width="1.6"/>
<path d="M114,80 C117,78 122,78 126,82" fill="none" stroke-width="1.6"/>''';
const browsSoft = '''
<path d="M94,83 C98,82 103,82 106,84" fill="none" stroke-width="1.6"/>
<path d="M114,84 C117,82 122,82 126,83" fill="none" stroke-width="1.6"/>''';
const browsThink = '''
<path d="M94,83 C98,80 103,80 106,82" fill="none" stroke-width="1.6"/>
<path d="M114,81 C117,81 122,82 126,85" fill="none" stroke-width="1.6"/>''';

String eyesAt(num dx, num dy) =>
    '''
<ellipse cx="${n(100 + dx)}" cy="${n(92 + dy)}" rx="2.4" ry="3" fill="$ink" stroke="none"/>
<ellipse cx="${n(120 + dx)}" cy="${n(92 + dy)}" rx="2.4" ry="3" fill="$ink" stroke="none"/>
<circle cx="${n(100.8 + dx)}" cy="${n(90.8 + dy)}" r="0.8" fill="#FFFFFF" stroke="none"/>
<circle cx="${n(120.8 + dx)}" cy="${n(90.8 + dy)}" r="0.8" fill="#FFFFFF" stroke="none"/>''';

final eyesOpen = eyesAt(0, 0);
const eyesHappy = '''
<path d="M96.5,93 C98,89.5 102,89.5 103.5,93" fill="none" stroke-width="1.8"/>
<path d="M116.5,93 C118,89.5 122,89.5 123.5,93" fill="none" stroke-width="1.8"/>''';
const eyesClosed = '''
<path d="M96.5,92 C98.5,94 101.5,94 103.5,92" fill="none" stroke-width="1.8"/>
<path d="M116.5,92 C118.5,94 121.5,94 123.5,92" fill="none" stroke-width="1.8"/>''';
final eyesWink =
    '''
<ellipse cx="100" cy="92" rx="2.4" ry="3" fill="$ink" stroke="none"/>
<circle cx="100.8" cy="90.8" r="0.8" fill="#FFFFFF" stroke="none"/>
<path d="M116.5,93 C118,89.5 122,89.5 123.5,93" fill="none" stroke-width="1.8"/>''';

const mouthOpen =
    '<path d="M102,107 C106,114 114,114 118,107 Z" fill="#C97F6E" stroke-width="1.6"/>';
const mouthBig =
    '<path d="M100,106 C103,118 117,118 120,106 Z" fill="#C97F6E" stroke-width="1.6"/>';
const mouthSoft =
    '<path d="M103,107 C107,111.5 113,111.5 117,107" fill="none" stroke-width="1.8"/>';
const mouthThink =
    '<path d="M105,109 C108,108 112,108 115,107" fill="none" stroke-width="1.8"/>';
const mouthShrug =
    '<path d="M104,109 C107,111 111,107 116,108" fill="none" stroke-width="1.8"/>';

// --- Posen ---------------------------------------------------------------

class Frame {
  const Frame({
    this.behind = '',
    this.overFace = '',
    this.extras = '',
    this.legs,
    required this.ms,
  });

  /// Arme vor dem Körper, hinter dem Kopf.
  final String behind;

  /// Hände vor dem Gesicht.
  final String overFace;
  final String extras;
  final String? legs;
  final int ms;
}

class Pose {
  const Pose({
    required this.name,
    required this.title,
    required this.frames,
    required this.eyes,
    required this.brows,
    required this.mouth,
    this.handOnBag = true,
    this.blink = true,
  });

  final String name;
  final String title;
  final List<Frame> frames;
  final String eyes;
  final String brows;
  final String mouth;
  final bool handOnBag;

  /// Blinzel-Bild erzeugen (nicht bei geschlossenen, lachenden Augen).
  final bool blink;
}

const armToBag = 'M142,138 C150,160 153,180 151,197';
const armRelaxedLeft = 'M80,140 C72,160 70,180 72,198';

String waveArm(num deg) => rotate(deg, 80, 140, '''
${sleeve('M80,140 C62,146 50,140 47,108')}
${openHand(46, 97, thumbRight: true, rot: -6)}''');

String waveLines(num o) =>
    '''
<path d="M${n(29 - o)},82 C${n(25 - o)},88 ${n(25 - o)},96 ${n(29 - o)},102" fill="none" stroke-width="1.6" opacity="0.6"/>
<path d="M${n(21 - o)},78 C${n(15 - o)},88 ${n(15 - o)},100 ${n(21 - o)},108" fill="none" stroke-width="1.6" opacity="0.4"/>''';

String thumbsArm(num deg) => rotate(
  deg,
  80,
  140,
  '''
${sleeve('M80,140 C64,150 56,142 57,120')}
<path d="M49,118 C49,110 53,107 58,107 C64,107 67,111 66,118 C66,124 62,127 57,127 C52,127 49,124 49,118 Z" fill="$skin"/>
<path d="M60,108 C59,100 61,94 64.5,94.5 C68,95 67.5,101 65,108" fill="$skin"/>
<path d="M51,116 L62,116 M51,121 L62,121" fill="none" stroke-width="1.1" opacity="0.6"/>''',
);

String cheerArms(num deg) =>
    '''
${rotate(-deg, 80, 140, '${sleeve('M80,140 C66,128 56,108 51,88')}\n${hand(49, 81, rx: 7.5, ry: 8)}')}
${rotate(deg, 142, 138, '${sleeve('M142,138 C156,126 164,108 169,88')}\n${hand(171, 81, rx: 7.5, ry: 8)}')}''';

String fistArm(num deg) => rotate(
  deg,
  80,
  140,
  '''
${sleeve('M80,140 C64,152 56,144 58,124')}
<path d="M50,121 C50,113 54,110 59,110 C65,110 68,114 67,121 C67,127 63,130 58,130 C53,130 50,127 50,121 Z" fill="$skin"/>
<path d="M52,117 L64,117 M52,122 L64,122" fill="none" stroke-width="1.1" opacity="0.6"/>''',
);

const thinkHand =
    '''
<path d="M101,124 C100,118 104,114 109,114 C114,114 117,118 116,123 C115,128 111,130 107,129 C104,129 101,127 101,124 Z" fill="$skin"/>
<path d="M104,117 C106,114 110,113 113,115" fill="none" stroke-width="1.2" opacity="0.7"/>''';

String thoughtDots(int count) => [
  '<circle cx="150" cy="44" r="3" fill="$cloth" stroke-width="1.4"/>',
  '<circle cx="160" cy="32" r="4.5" fill="$cloth" stroke-width="1.4"/>',
  '<circle cx="174" cy="18" r="6.5" fill="$cloth" stroke-width="1.4"/>',
].take(count).join('\n');

String heartHands(num dy) =>
    '''
${sleeve('M80,140 C74,160 86,174 100,172')}
${sleeve('M142,138 C148,160 134,174 120,172')}''';

String heartExtras(num dy) =>
    '''
<path d="M110,180 C98,173 93,164 98,157 C102,152 108,154 110,159 C112,154 118,152 122,157 C127,164 122,173 110,180 Z" fill="$blush" stroke-width="1.8"/>
${hand(100, 168, rx: 6.5, ry: 6)}
${hand(120, 168, rx: 6.5, ry: 6)}
${smallHeart(58, 74 + dy)}
${smallHeart(166, 60 + dy * 1.4, s: 0.75, opacity: 0.8)}''';

String shrugArms(num dy) => shift(
  0,
  dy,
  '''
${sleeve('M80,140 C66,156 54,160 46,150')}
<ellipse cx="41" cy="147" rx="8.5" ry="5.2" transform="rotate(-18 41 147)" fill="$skin"/>
<path d="M44,142 C46,138 49,137 51,139" fill="none" stroke-width="1.6"/>
${sleeve('M142,138 C156,156 168,160 176,150')}
<ellipse cx="181" cy="147" rx="8.5" ry="5.2" transform="rotate(18 181 147)" fill="$skin"/>
<path d="M178,142 C176,138 173,137 171,139" fill="none" stroke-width="1.6"/>''',
);

String clapArms(num gap) =>
    '''
${sleeve('M80,140 C76,160 88,170 ${n(110 - gap - 5)},168')}
${sleeve('M142,138 C146,160 134,170 ${n(110 + gap + 5)},168')}
<ellipse cx="${n(110 - gap)}" cy="166" rx="5.5" ry="8" transform="rotate(-12 ${n(110 - gap)} 166)" fill="$skin"/>
<ellipse cx="${n(110 + gap)}" cy="166" rx="5.5" ry="8" transform="rotate(12 ${n(110 + gap)} 166)" fill="$skin"/>''';

const clapLines = '''
<path d="M96,150 L92,144 M110,146 L110,139 M124,150 L128,144" fill="none" stroke-width="1.6" opacity="0.6"/>''';

String pointArm(num deg) => rotate(
  deg,
  142,
  138,
  '''
${sleeve('M142,138 C160,134 170,120 176,104')}
<path d="M179,96 L183,82" fill="none" stroke-width="5.6"/>
<ellipse cx="178" cy="100" rx="7.5" ry="7" fill="$skin"/>
<path d="M179,96 L183,82" fill="none" stroke="$skin" stroke-width="3.4"/>
<path d="M172,99 C175,101 178,101 181,99" fill="none" stroke-width="1.1" opacity="0.6"/>''',
);

String readCard(num deg) =>
    '''
${sleeve('M80,140 C74,160 82,172 94,170')}
${sleeve('M142,138 C148,160 138,172 126,170')}
${rotate(deg, 110, 165, '''
<rect x="90" y="150" width="40" height="28" rx="4" fill="#FFFFFF"/>
<path d="M97,159 L114,159 M97,166 L123,166 M97,172 L108,172" fill="none" stroke-width="1.4" opacity="0.6"/>
<circle cx="124" cy="158" r="2.4" fill="$lemon" stroke-width="1"/>
${hand(92, 168, rx: 5.5, ry: 6.5)}
${hand(128, 168, rx: 5.5, ry: 6.5)}''')}''';

/// Fröhlicher Kick: ein Bein nach hinten, Rock schwingt.
String kickLegs(num deg) =>
    '''
${rotate(deg, 92, 300, '''
<path d="M84,300 L82,322 L96,323 L98,300 Z" fill="#FFFFFF"/>
<path d="M97,320 C89,318 78,320 75,325 C74,331 82,333 97,333 C101,333 102,324 97,320 Z" fill="$dark" stroke="$dark"/>''')}
<path d="M78,214 L142,214 C152,248 160,286 168,314 C140,322 96,322 62,316 C66,288 70,250 78,214 Z" fill="$cloth"/>
<path d="M98,232 C98,262 98,290 98,318" fill="none" stroke-width="1.2" opacity="0.6"/>
<path d="M126,232 C130,262 134,290 138,316" fill="none" stroke-width="1.2" opacity="0.6"/>
$rightFoot''';

String kickArms(num deg) =>
    '''
${rotate(-deg, 80, 140, '${sleeve('M80,140 C66,126 58,106 54,84')}\n${openHand(53, 72, thumbRight: true, rot: -10)}')}
${sleeve('M142,138 C158,146 170,150 182,146')}
${hand(187, 145, rx: 7, ry: 6)}''';

final poses = <Pose>[
  Pose(
    name: 'wave',
    title: 'Winken',
    eyes: eyesOpen,
    brows: browsNormal,
    mouth: mouthOpen,
    frames: [
      Frame(behind: waveArm(0), extras: waveLines(0), ms: 700),
      Frame(behind: waveArm(-11), extras: waveLines(4), ms: 220),
      Frame(behind: waveArm(0), extras: waveLines(0), ms: 220),
      Frame(behind: waveArm(-11), extras: waveLines(4), ms: 220),
      Frame(behind: waveArm(0), extras: waveLines(0), ms: 220),
    ],
  ),
  Pose(
    name: 'thumbs',
    title: 'Daumen hoch',
    eyes: eyesWink,
    brows: browsNormal,
    mouth: mouthOpen,
    blink: false,
    frames: [
      Frame(behind: thumbsArm(0), extras: _rays(0), ms: 900),
      Frame(behind: thumbsArm(-7), extras: _rays(1), ms: 260),
    ],
  ),
  Pose(
    name: 'cheer',
    title: 'Jubeln',
    eyes: eyesHappy,
    brows: browsRaised,
    mouth: mouthBig,
    handOnBag: false,
    blink: false,
    frames: [
      Frame(behind: cheerArms(0), extras: _cheerExtras(0), ms: 300),
      Frame(behind: cheerArms(7), extras: _cheerExtras(1), ms: 300),
    ],
  ),
  Pose(
    name: 'encourage',
    title: 'Aufmuntern',
    eyes: eyesOpen,
    brows: browsSoft,
    mouth: mouthSoft,
    frames: [
      Frame(behind: fistArm(0), extras: sparkle(40, 110, r: 0.65), ms: 800),
      Frame(behind: fistArm(-10), extras: sparkle(38, 104, r: 0.8), ms: 240),
      Frame(behind: fistArm(0), extras: sparkle(40, 110, r: 0.65), ms: 240),
      Frame(behind: fistArm(-10), extras: sparkle(38, 104, r: 0.8), ms: 240),
    ],
  ),
  Pose(
    name: 'think',
    title: 'Nachdenken',
    eyes: eyesAt(1, -2),
    brows: browsThink,
    mouth: mouthThink,
    frames: [
      for (final dots in [1, 2, 3, 3])
        Frame(
          behind: sleeve('M80,140 C86,156 98,146 106,126'),
          overFace: thinkHand,
          extras: thoughtDots(dots),
          ms: dots == 3 ? 900 : 450,
        ),
    ],
  ),
  Pose(
    name: 'heart',
    title: 'Herz',
    eyes: eyesHappy,
    brows: browsSoft,
    mouth: mouthOpen,
    handOnBag: false,
    blink: false,
    frames: [
      Frame(behind: heartHands(0), extras: heartExtras(0), ms: 600),
      Frame(behind: heartHands(0), extras: heartExtras(-4), ms: 600),
    ],
  ),
  Pose(
    name: 'shrug',
    title: 'Schulterzucken',
    eyes: eyesOpen,
    brows: browsRaised,
    mouth: mouthShrug,
    handOnBag: false,
    frames: [
      Frame(behind: shrugArms(0), ms: 900),
      Frame(behind: shrugArms(-4), ms: 450),
    ],
  ),
  Pose(
    name: 'clap',
    title: 'Klatschen',
    eyes: eyesHappy,
    brows: browsRaised,
    mouth: mouthBig,
    handOnBag: false,
    blink: false,
    frames: [
      Frame(behind: clapArms(9), ms: 200),
      Frame(behind: clapArms(3), extras: clapLines, ms: 180),
    ],
  ),
  Pose(
    name: 'point',
    title: 'Zeigen',
    eyes: eyesAt(2, -1),
    brows: browsNormal,
    mouth: mouthOpen,
    handOnBag: false,
    frames: [
      Frame(
        behind: '${sleeve(armRelaxedLeft)}\n${hand(72, 204)}\n${pointArm(0)}',
        ms: 900,
      ),
      Frame(
        behind: '${sleeve(armRelaxedLeft)}\n${hand(72, 204)}\n${pointArm(-5)}',
        ms: 300,
      ),
    ],
  ),
  Pose(
    name: 'read',
    title: 'Lesen',
    eyes: eyesAt(0, 2),
    brows: browsSoft,
    mouth: mouthSoft,
    handOnBag: false,
    frames: [
      Frame(behind: readCard(0), ms: 1200),
      Frame(behind: readCard(3), ms: 900),
    ],
  ),
  Pose(
    name: 'kick',
    title: 'Freudensprung',
    eyes: eyesHappy,
    brows: browsRaised,
    mouth: mouthBig,
    handOnBag: false,
    blink: false,
    frames: [
      Frame(
        behind: kickArms(0),
        legs: kickLegs(0),
        extras: sparkle(30, 56, r: 0.7),
        ms: 420,
      ),
      Frame(
        behind: kickArms(6),
        legs: kickLegs(-16),
        extras: sparkle(28, 50, r: 0.85),
        ms: 420,
      ),
    ],
  ),
];

String _rays(int o) =>
    '<path d="M${40 - o},96 L${36 - o},92 M${44 - o},88 L${42 - o},${82 - o} M${36 - o},104 L${30 - o},103" '
    'fill="none" stroke="$ink" stroke-width="1.6" opacity="0.6"/>';

String _cheerExtras(int f) =>
    '''
<path d="M30,62 L34,70 M24,78 L32,80 M40,52 L42,60" fill="none" stroke-width="1.8" opacity="${f == 0 ? 0.7 : 0.4}"/>
<path d="M190,62 L186,70 M196,78 L188,80 M180,52 L178,60" fill="none" stroke-width="1.8" opacity="${f == 0 ? 0.4 : 0.7}"/>
${sparkle(60, f == 0 ? 47 : 43, r: f == 0 ? 0.8 : 0.95)}
${sparkle(162, f == 0 ? 38 : 42, r: f == 0 ? 0.65 : 0.5)}''';

String build(Pose p, Frame f, {bool closedEyes = false}) {
  final rightArm = p.handOnBag
      ? '${sleeve(armToBag)}\n$bag\n${hand(151, 203)}'
      : bag;
  final body = [
    shadow,
    hairBack,
    neck,
    f.legs ?? legsStanding,
    torso,
    jewellery,
    strap,
    rightArm,
    f.behind,
    faceBase,
    p.brows,
    closedEyes ? eyesClosed : p.eyes,
    p.mouth,
    hairFront,
    cap,
    f.overFace,
    f.extras,
  ].where((s) => s.isNotEmpty).join('\n');
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 220 360" width="220" height="360">\n'
      '<!-- Leoni, Pose „${p.title}“ – erzeugt von tool/gen_leoni.dart -->\n'
      '<g stroke="$ink" stroke-width="2" stroke-linejoin="round" stroke-linecap="round">\n'
      '$body\n</g>\n</svg>\n';
}

void main() {
  final dir = Directory('assets/leoni');
  for (final f in dir.listSync()) {
    if (f.path.endsWith('.svg')) f.deleteSync();
  }
  final manifest = <String, Object>{};
  for (final p in poses) {
    final files = <String>[];
    for (final (i, f) in p.frames.indexed) {
      final file = '${p.name}_$i.svg';
      File('${dir.path}/$file').writeAsStringSync(build(p, f));
      files.add(file);
    }
    String? blink;
    if (p.blink) {
      blink = '${p.name}_blink.svg';
      File('${dir.path}/$blink')
          .writeAsStringSync(build(p, p.frames.first, closedEyes: true));
    }
    manifest[p.name] = {
      'title': p.title,
      'frames': files,
      'ms': [for (final f in p.frames) f.ms],
      'blink': ?blink,
    };
    stdout.writeln(
      '${p.name}: ${files.length} Bilder${blink != null ? ' + Blinzeln' : ''}',
    );
  }
  // Dart-Übersicht für die App, damit die Bilder ohne Laden bekannt sind.
  final out = StringBuffer()
    ..writeln('// GENERIERT von tool/gen_leoni.dart – nicht von Hand ändern.')
    ..writeln("import 'figure.dart';")
    ..writeln()
    ..writeln('/// Posen der Comic-Figur mit ihren Animationsbildern.')
    ..writeln('enum LeoniPose implements FigurePose {');
  for (final p in poses) {
    final m = manifest[p.name]! as Map<String, Object?>;
    out.writeln('  /// ${p.title}');
    out.writeln(
      '  ${p.name}(${jsonEncode(m['frames'])}, ${jsonEncode(m['ms'])}, '
      '${m['blink'] == null ? 'null' : "'${m['blink']}'"}),',
    );
  }
  out
    ..writeln('  ;')
    ..writeln()
    ..writeln('  const LeoniPose(this.frames, this.ms, this.blink);')
    ..writeln()
    ..writeln('  /// Dateinamen in assets/leoni/.')
    ..writeln('  @override')
    ..writeln('  final List<String> frames;')
    ..writeln()
    ..writeln('  /// Anzeigedauer pro Bild in Millisekunden.')
    ..writeln('  @override')
    ..writeln('  final List<int> ms;')
    ..writeln()
    ..writeln(
      '  /// Bild mit geschlossenen Augen, falls die Pose blinzeln kann.',
    )
    ..writeln('  @override')
    ..writeln('  final String? blink;')
    ..writeln()
    ..writeln('  @override')
    ..writeln("  String get folder => 'leoni';")
    ..writeln()
    ..writeln('  @override')
    ..writeln('  double get aspect => 220 / 360;')
    ..writeln('}');
  File('lib/widgets/leoni_poses.g.dart')
      .writeAsStringSync(out.toString().replaceAll('"', "'"));
}
