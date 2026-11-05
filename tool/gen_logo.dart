// Erzeugt das Logo von LearnwithLeoni: Leoni und Kumachan Wange an Wange.
//
//   dart run tool/gen_logo.dart
//
// Ausgabe:
//   assets/logo/logo.svg   – freigestellt (für die App)
//   assets/logo/icon.svg   – quadratisch mit Hintergrund (für App-Symbole)
import 'dart:io';

import 'gen_kuma.dart' as kuma;
import 'gen_leoni.dart' as leoni;

const ink = '#685A4E';
const vanilla = '#F0EADA';
const coconut = '#F1EEE6';
const wood = '#D7CAB0';
const sand = '#E3D8C2';
const lemon = '#DCD494';
const blush = '#E9B7A3';

/// Weicher Kiesel als Hintergrund und Zuschnitt.
const pebble =
    'M256,34 C356,30 452,84 474,188 C494,286 462,392 372,446 '
    'C290,494 176,488 104,430 C34,374 18,270 46,180 C72,96 156,38 256,34 Z';

String leoniBust() => '''
<g transform="translate(-72 24) scale(2.4)">
  ${leoni.hairBack}
  ${leoni.neck}
  ${leoni.torso}
  ${leoni.jewellery}
  ${leoni.faceBase}
  ${leoni.browsSoft}
  ${leoni.eyesHappy}
  ${leoni.mouthOpen}
  ${leoni.hairFront}
  ${leoni.cap}
</g>''';

String kumaBust() => '''
<g transform="rotate(-10 352 296) translate(147 132) scale(2.05)">
  ${kuma.body}
  ${kuma.collarPart}
  ${kuma.heart(113, 142)}
  <g transform="translate(0 6)">${kuma.head(happy: true)}</g>
</g>''';

String heart(num x, num y, num s) =>
    '<path transform="translate($x $y) scale($s)" '
    'd="M0,-4 C-3,-8 -8,-6 -6,-1 C-5,2 0,5 0,5 C0,5 5,2 6,-1 C8,-6 3,-8 0,-4 Z" '
    'fill="$blush" stroke="$ink" stroke-width="0.5"/>';

String sparkle(num x, num y, num r) =>
    '<path d="M$x,${y - 7 * r} L${x + 2.2 * r},${y - 2.2 * r} L${x + 7 * r},$y '
    'L${x + 2.2 * r},${y + 2.2 * r} L$x,${y + 7 * r} L${x - 2.2 * r},${y + 2.2 * r} '
    'L${x - 7 * r},$y L${x - 2.2 * r},${y - 2.2 * r} Z" fill="$lemon" stroke="$ink" stroke-width="2.2"/>';

/// Die beiden auf dem Kiesel – im Koordinatensystem 512 × 512.
String scene() => '''
<defs>
  <clipPath id="pebble"><path d="$pebble"/></clipPath>
</defs>
<path d="$pebble" fill="$vanilla"/>
<g clip-path="url(#pebble)">
  <ellipse cx="256" cy="520" rx="260" ry="90" fill="$sand"/>
  <g stroke="$ink" stroke-width="2" stroke-linejoin="round" stroke-linecap="round">
    ${leoniBust()}
    ${kumaBust()}
  </g>
</g>
<path d="$pebble" fill="none" stroke="$wood" stroke-width="7"/>
${heart(262, 92, 4.2)}
${sparkle(96, 150, 2.1)}
${sparkle(424, 128, 1.5)}''';

void main() {
  Directory('assets/logo').createSync(recursive: true);
  File('assets/logo/logo.svg').writeAsStringSync(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">\n'
    '<!-- LearnwithLeoni – Leoni und Kumachan, erzeugt von tool/gen_logo.dart -->\n'
    '${scene()}\n</svg>\n',
  );
  // App-Symbol: voller Hintergrund, Motiv in der sicheren Zone (80 %).
  File('assets/logo/icon.svg').writeAsStringSync(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">\n'
    '<rect width="512" height="512" fill="$coconut"/>\n'
    '<g transform="translate(46 46) scale(0.82)">\n${scene()}\n</g>\n</svg>\n',
  );
  stdout.writeln('assets/logo/logo.svg, assets/logo/icon.svg');
}
