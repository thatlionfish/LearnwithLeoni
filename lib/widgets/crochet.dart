import 'dart:math';

import 'package:flutter/material.dart';

import '../data/leitner.dart';
import '../learn/crochet.dart';
import '../ui/colors.dart';
import '../ui/theme.dart';
import 'leoni.dart';

/// Wolle: die Beigetöne der App und Kumachans eigene Farben.
const _yarn = [
  Color(0xFFF0EADA), // Vanilla Ice
  Color(0xFFE3D8C2), // Sand
  Color(0xFFD7CAB0), // Wood Ash
  Color(0xFFEFD6E2), // Kumachans Kragen
  Color(0xFFF1DCD6), // Kumachans Pfoten
  Color(0xFFA38D9C), // Kumachan hell
  Color(0xFFF4F9FF), // Bright White
];

/// Mitte eines Quadrats – hier darf Lemon Grass als Detail leuchten.
const _centers = [LeoColors.lemonGrass, Color(0xFFEFD6E2), Color(0xFF8E7486)];

/// Stabile Farben pro Wort (gleiche Farben bei jedem Öffnen).
List<Color> yarnFor(String key) {
  var h = 0x811c9dc5;
  for (final c in key.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0x7fffffff;
  }
  final r = Random(h);
  final colors = <Color>[_centers[r.nextInt(_centers.length)]];
  while (colors.length < Leitner.boxes) {
    final c = _yarn[r.nextInt(_yarn.length)];
    if (c != colors.last) colors.add(c);
  }
  return colors;
}

/// Malt ein Häkelquadrat in [rect]. [rounds] 0–5 (auch Zwischenwerte für die
/// Animation), 6 = fertig mit Rand.
void paintGranny(
  Canvas canvas,
  Rect rect,
  double rounds,
  List<Color> colors, {
  bool outline = true,
}) {
  final c = rect.center;
  final half = rect.shortestSide / 2 * 0.96;
  final ring = half / Leitner.boxes;
  final ink = LeoColors.chocolate;

  RRect box(double r) => RRect.fromRectAndRadius(
    Rect.fromCenter(center: c, width: r * 2, height: r * 2),
    Radius.circular(max(1.5, r * 0.28)),
  );

  // Wo das Quadrat einmal hinkommt: zarte gestrichelte Linie.
  if (outline && rounds < Leitner.secure) {
    final dash = Paint()
      ..color = LeoColors.woodAsh
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(box(half));
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 6) {
        canvas.drawPath(m.extractPath(d, min(d + 3, m.length)), dash);
      }
    }
  }

  for (var k = 1; k <= Leitner.boxes; k++) {
    final t = (rounds - (k - 1)).clamp(0.0, 1.0);
    if (t <= 0) break;
    final inner = ring * (k - 1);
    final outer = inner + ring * t;
    final paint = Paint()
      ..color = colors[(k - 1) % colors.length].withValues(
        alpha: 0.35 + 0.65 * t,
      );
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(box(outer));
    if (k > 1) path.addRRect(box(inner));
    canvas.drawPath(path, paint);
    // Maschen: kleine Striche quer über die Runde, in Dreiergruppen.
    if (ring > 3 && t > 0.6) {
      final stitch = Paint()
        ..color = ink.withValues(alpha: 0.22)
        ..strokeWidth = max(0.7, ring * 0.12)
        ..strokeCap = StrokeCap.round;
      final mid = (inner + outer) / 2;
      final groups = k == 1 ? 0 : k;
      for (var side = 0; side < 4; side++) {
        for (var g = 0; g < groups; g++) {
          final along = -mid + (2 * mid) * (g + 0.5) / groups;
          for (var s = -1; s <= 1; s++) {
            final a = along + s * ring * 0.28;
            final p = switch (side) {
              0 => Offset(c.dx + a, c.dy - mid),
              1 => Offset(c.dx + mid, c.dy + a),
              2 => Offset(c.dx - a, c.dy + mid),
              _ => Offset(c.dx - mid, c.dy - a),
            };
            final dir = side.isEven ? const Offset(0, 1) : const Offset(1, 0);
            canvas.drawLine(p - dir * ring * 0.3, p + dir * ring * 0.3, stitch);
          }
        }
      }
    }
  }

  // Fertig: ein Rand in Schokolade, als wäre er angenäht.
  if (rounds >= Leitner.secure) {
    canvas.drawRRect(
      box(half),
      Paint()
        ..color = ink.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.2, half * 0.07),
    );
  }
}

class _GrannyPainter extends CustomPainter {
  _GrannyPainter(this.rounds, this.colors);

  final double rounds;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) =>
      paintGranny(canvas, Offset.zero & size, rounds, colors);

  @override
  bool shouldRepaint(_GrannyPainter old) =>
      old.rounds != rounds || old.colors != colors;
}

/// Ein Wort als Häkelquadrat. Mit [from] wachsen die Runden sichtbar an.
class GrannySquare extends StatelessWidget {
  const GrannySquare({
    super.key,
    required this.square,
    this.size = 64,
    this.from,
    this.delay = Duration.zero,
  });

  final CrochetSquare square;
  final double size;

  /// Runden vor der Lernrunde – dann wird das Häkeln animiert.
  final int? from;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final colors = yarnFor(square.key);
    final to = square.rounds.toDouble();
    Widget paint(double r) => CustomPaint(
      size: Size.square(size),
      painter: _GrannyPainter(r, colors),
    );
    if (from == null || MediaQuery.disableAnimationsOf(context)) {
      return paint(to);
    }
    final total = const Duration(milliseconds: 1400) + delay;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: from!.toDouble(), end: to),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      builder: (context, r, _) => paint(r),
    );
  }
}

/// Kumachan, eingewickelt in ihre Decke wie ein Dürüm: Die Rolle liegt quer,
/// Kumachan liegt in der Mitte darin, nur ihr Kopf schaut vorne heraus. Mit
/// jedem sicheren Wort wird die Rolle dicker – ohne Ende.
class KumaRoll extends StatelessWidget {
  const KumaRoll({
    super.key,
    required this.work,
    this.height = 220,
    this.animateFrom,
    this.unrolled = 0,
  });

  final CrochetWork work;
  final double height;

  /// Quadrate an der Decke vor der Lernrunde (für die Animation).
  final int? animateFrom;

  /// 0 = ganz eingewickelt, 1 = ganz ausgerollt (Animation beim Ausrollen).
  final double unrolled;

  /// Ab so vielen Quadraten ist es gemütlich genug zum Schlafen.
  static const _sleepAt = 24.0;

  /// Breite : Höhe der Szene.
  static const aspect = 1.42;

  @override
  Widget build(BuildContext context) {
    final n = work.attached.length;
    // Aussen liegen die neuesten Quadrate.
    final colors = [for (final s in work.attached.reversed) yarnFor(s.key)];

    Widget scene(double count, double h) {
      final w = h * aspect;
      final shown = count * (1 - unrolled);
      if (shown <= 0.01) {
        // Noch keine Decke oder ganz ausgerollt: Kumachan steht.
        return SizedBox(
          width: w,
          height: h,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: KumaFigure(
              pose: unrolled > 0 ? KumaPose.cheer : KumaPose.crochet,
              height: h,
            ),
          ),
        );
      }
      final g = _RollGeometry(Size(w, h), shown);
      final pose = unrolled > 0.05 || shown < _sleepAt
          ? KumaPose.snug
          : KumaPose.snugSleepy;
      final fh = g.headFigureHeight;
      return SizedBox(
        width: w,
        height: h,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _RollPainter(colors, shown, g)),
            ),
            // Drehpunkt der Pose (100,112 von 200×300) liegt in der Rolle.
            Positioned(
              left: g.neck.dx - fh / 3,
              top: g.neck.dy - fh * 112 / 300,
              child: IgnorePointer(child: KumaFigure(pose: pose, height: fh)),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxWidth.isFinite
            ? min(height, c.maxWidth / aspect)
            : height;
        final from = animateFrom;
        if (from == null ||
            from >= n ||
            MediaQuery.disableAnimationsOf(context)) {
          return scene(n.toDouble(), h);
        }
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: from.toDouble(), end: n.toDouble()),
          duration: Duration(milliseconds: 900 + 400 * min(n - from, 8)),
          curve: Curves.easeInOutCubic,
          builder: (context, v, _) => scene(v, h),
        );
      },
    );
  }
}

/// Masse der liegenden Rolle – gemeinsam für Malen und Kopf.
class _RollGeometry {
  _RollGeometry(this.size, double count)
    : cy = size.height * 0.56,
      headR = size.height * 0.15,
      xl = size.width * 0.33,
      xr = size.width * 0.86,
      // Dicker ohne Ende, aber immer langsamer.
      r = size.height * min(0.43, 0.2 + 0.06 * log(1 + count / 4));

  final Size size;

  /// Mitte der Rolle (senkrecht).
  final double cy;

  /// Kopfgrösse von Kumachan.
  final double headR;

  /// Vorne (offen, Kopf) und hinten (zu).
  final double xl, xr;

  /// Halbe Dicke der Rolle.
  final double r;

  /// Die Enden sind leicht schräg zu sehen.
  double get erx => r * 0.32;

  /// Neigung des Kopfes in den Posen `snug` (`snugTilt` in tool/gen_kuma.dart).
  static const _tilt = -38 * pi / 180;

  /// Kumachans Kopf liegt mitten in der offenen Seite der Rolle.
  Offset get headCenter => Offset(xl - headR * 0.22, cy);

  /// Drehpunkt der Pose (Hals), vom Kopf aus gesehen.
  Offset get neck =>
      headCenter + Offset(-sin(_tilt), cos(_tilt)) * headR;

  /// Höhe der Pose, damit der Kopf [headR] gross ist (Kopfradius 34 von 300).
  double get headFigureHeight => headR * 300 / 34;
}

class _RollPainter extends CustomPainter {
  _RollPainter(this.colors, this.count, this.g);

  /// Farben der Quadrate, das neueste zuerst (liegt aussen).
  final List<List<Color>> colors;

  /// Wie viele Quadrate (Zwischenwerte beim Wachsen und Ausrollen).
  final double count;

  final _RollGeometry g;

  @override
  void paint(Canvas canvas, Size size) {
    if (count <= 0 || colors.isEmpty) return;
    final ink = LeoColors.chocolate;
    final cy = g.cy, r = g.r, xl = g.xl, xr = g.xr, erx = g.erx;
    final span = xr - xl;

    // Schatten am Boden.
    canvas.drawOval(
      Rect.fromLTRB(xl - erx * 1.2, cy + r * 0.9, xr + erx * 1.3, cy + r * 1.12),
      Paint()
        ..color = ink.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Der Mantel: von vorne bis zum runden, geschlossenen Ende hinten.
    final body = Path()
      ..moveTo(xl, cy - r)
      ..lineTo(xr, cy - r)
      ..arcTo(
        Rect.fromCenter(center: Offset(xr, cy), width: erx * 2, height: r * 2),
        -pi / 2,
        pi,
        false,
      )
      ..lineTo(xl, cy + r)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFFE3D8C2));
    canvas.save();
    canvas.clipPath(body);

    // Quadrate rund um die Rolle: oben und unten schmaler (Zylinder).
    const rows = 7;
    final cell = r * 2 / rows;
    var idx = 0;
    for (var x = xr + erx; x > xl - cell; x -= cell) {
      for (var i = 0; i < rows; i++) {
        final a0 = -pi / 2 + i * pi / rows;
        final y0 = cy + r * sin(a0);
        final y1 = cy + r * sin(a0 + pi / rows);
        final rect = Rect.fromLTRB(x - cell, y0, x, y1);
        canvas.save();
        canvas.translate(rect.center.dx, rect.center.dy);
        canvas.scale(1, max(0.05, rect.height / cell));
        paintGranny(
          canvas,
          Rect.fromCenter(center: Offset.zero, width: cell, height: cell),
          Leitner.secure.toDouble(),
          colors[idx % colors.length],
          outline: false,
        );
        canvas.restore();
        idx++;
      }
    }

    // Rundung: oben und unten dunkler, oben ein Hauch Licht.
    canvas.drawRect(
      Rect.fromLTRB(xl - erx, cy - r, xr + erx, cy + r),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ink.withValues(alpha: 0.26),
            ink.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.14),
            ink.withValues(alpha: 0),
            ink.withValues(alpha: 0.32),
          ],
          stops: const [0, 0.22, 0.34, 0.62, 1],
        ).createShader(Rect.fromLTRB(0, cy - r, 1, cy + r)),
    );
    // Hinten biegt sich die Rolle weg.
    canvas.drawRect(
      Rect.fromLTRB(xr - erx, cy - r, xr + erx, cy + r),
      Paint()
        ..shader = LinearGradient(
          colors: [ink.withValues(alpha: 0), ink.withValues(alpha: 0.22)],
        ).createShader(Rect.fromLTRB(xr - erx, 0, xr + erx, 1)),
    );

    final seam = Paint()
      ..color = ink.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    void dashed(Path p) {
      for (final m in p.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 5) {
          canvas.drawPath(m.extractPath(d, min(d + 2.6, m.length)), seam);
        }
      }
    }

    // Schräg herumgewickelt wie ein Dürüm: Der Rand der äussersten Lage
    // läuft diagonal über die Rolle und wirft einen leisen Schatten.
    final wrapEdge = Path()
      ..moveTo(xl + span * 0.1, cy + r * 1.02)
      ..cubicTo(
        xl + span * 0.3,
        cy + r * 0.45,
        xl + span * 0.46,
        cy - r * 0.35,
        xl + span * 0.68,
        cy - r * 1.02,
      );
    canvas.drawPath(
      wrapEdge.shift(const Offset(3, 0)),
      Paint()
        ..color = ink.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    dashed(wrapEdge);
    canvas.restore();
    dashed(body);

    // Der Zipfel der Decke steht hinten oben ab, wie beim Dürüm das Papier.
    if (count >= 10) {
      final lift = min(r * 0.6, size.height * 0.12);
      final a = Offset(xr - span * 0.28, cy - r * 0.97);
      final b = Offset(xr - span * 0.03, cy - r * 0.99);
      final tip = Offset(xr - span * 0.06, cy - r - lift);
      final corner = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(
          a.dx + (tip.dx - a.dx) * 0.35,
          cy - r - lift * 0.6,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(b.dx + span * 0.03, cy - r - lift * 0.4, b.dx, b.dy)
        ..close();
      canvas.drawPath(corner, Paint()..color = const Color(0xFFE3D8C2));
      canvas.save();
      canvas.clipPath(corner);
      paintGranny(
        canvas,
        Rect.fromCenter(
          center: Offset(xr - span * 0.12, cy - r - lift * 0.35),
          width: lift * 1.1,
          height: lift * 1.1,
        ),
        Leitner.secure.toDouble(),
        colors.first,
        outline: false,
      );
      canvas.restore();
      canvas.drawPath(
        corner,
        Paint()
          ..color = ink.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    // Vorne ist die Rolle offen: die Lagen der Decke als zarte Ringe,
    // je mehr Quadrate, desto mehr Lagen. In der Mitte liegt Kumachan.
    final face = Rect.fromCenter(
      center: Offset(xl, cy),
      width: erx * 2,
      height: r * 2,
    );
    canvas.drawOval(face, Paint()..color = const Color(0xFFEFE6D4));
    final hole = min(r * 0.9, g.headR * 1.12);
    final layers = (count / 10).ceil().clamp(1, 8);
    for (var k = layers; k >= 1; k--) {
      final rr = hole + (r - hole) * k / layers;
      final ring = Rect.fromCenter(
        center: Offset(xl, cy),
        width: rr * 2 * erx / r,
        height: rr * 2,
      );
      if (k % 3 == 0) {
        final yarn = colors[(k * 5) % colors.length];
        canvas.drawOval(
          ring,
          Paint()..color = yarn[2 % yarn.length].withValues(alpha: 0.55),
        );
      }
      canvas.drawOval(
        ring,
        Paint()
          ..color = ink.withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
    canvas.drawOval(
      face,
      Paint()
        ..color = ink.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(xl, cy),
        width: hole * 2 * erx / r,
        height: hole * 2,
      ),
      Paint()..color = const Color(0xFF6F5869),
    );
  }

  @override
  bool shouldRepaint(_RollPainter old) =>
      old.count != count ||
      old.colors.length != colors.length ||
      old.g.size != g.size;
}

/// Die ausgerollte Decke: alle fertigen Quadrate, 6 breit, mit den Wörtern.
class UnrolledBlanket extends StatelessWidget {
  const UnrolledBlanket({super.key, required this.squares});

  /// Das älteste zuerst.
  final List<CrochetSquare> squares;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const cols = CrochetWork.columns;
      final cell = (box.maxWidth - 12) / cols;
      return CustomPaint(
        foregroundPainter: _SeamPainter(),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFE3D8C2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Wrap(
            children: [
              for (final s in squares)
                SizedBox(
                  width: cell,
                  child: Tooltip(
                    message: '${s.card.term} – ${s.card.translation}',
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        children: [
                          GrannySquare(square: s, size: cell - 4),
                          Text(
                            stripArticleForLabel(s.card.term),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: sans(
                              min(12, cell * 0.15),
                              weight: 600,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// Auf der Decke ohne Artikel, damit das Wort aufs Quadrat passt.
String stripArticleForLabel(String term) =>
    term.replaceFirst(RegExp(r'^(der|die|das)\s+'), '');

class _SeamPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final seam = Paint()
      ..color = LeoColors.chocolate.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(2),
          const Radius.circular(9),
        ),
      );
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 5) {
        canvas.drawPath(m.extractPath(d, min(d + 2.6, m.length)), seam);
      }
    }
  }

  @override
  bool shouldRepaint(_SeamPainter old) => false;
}

/// Die Rolle, die beim Ausrollen über die Decke nach unten wandert.
class RollEdge extends StatelessWidget {
  const RollEdge({super.key, required this.thickness});

  final double thickness;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(double.infinity, thickness),
    painter: _RollEdgePainter(),
  );
}

class _RollEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 1) return;
    final r = size.height / 2;
    final bar = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(r));
    canvas.drawRRect(
      bar,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF0EADA),
            const Color(0xFFE3D8C2),
            LeoColors.woodAsh,
          ],
        ).createShader(Offset.zero & size),
    );
    final ink = Paint()
      ..color = LeoColors.chocolate.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(bar, ink);
    // Spiralen an beiden Enden.
    for (final x in [r, size.width - r]) {
      for (var k = 1; k <= 3; k++) {
        canvas.drawCircle(Offset(x, r), r * k / 3.4, ink);
      }
    }
  }

  @override
  bool shouldRepaint(_RollEdgePainter old) => false;
}

/// Kleine Zeile unter einem Quadrat: das Wort.
class SquareLabel extends StatelessWidget {
  const SquareLabel(this.text, {super.key, this.width = 84});

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: sans(12.5, weight: 560, height: 1.2),
    ),
  );
}
