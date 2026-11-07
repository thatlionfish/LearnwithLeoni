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

/// Kumachan mit seiner Decke: Je mehr Quadrate angenäht sind, desto höher
/// reicht die Decke – bis er sich ganz einkuschelt und einschläft.
class KumaBlanket extends StatelessWidget {
  const KumaBlanket({
    super.key,
    required this.work,
    this.height = 220,
    this.animateFrom,
  });

  final CrochetWork work;
  final double height;

  /// Anzahl Quadrate an der Decke vor der Lernrunde (für die Animation).
  final int? animateFrom;

  @override
  Widget build(BuildContext context) {
    final squares = work.currentBlanket;
    final n = squares.length;
    final width = height * 0.86;
    Widget scene(double shown) {
      final snuggled = shown / CrochetWork.perBlanket >= 0.45;
      return SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            KumaFigure(
              pose: snuggled ? KumaPose.sleepy : KumaPose.crochet,
              height: height,
            ),
            if (shown > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: height * 0.015,
                child: CustomPaint(
                  size: Size(width, height * 0.58),
                  painter: _BlanketPainter([
                    for (final s in squares) yarnFor(s.key),
                  ], shown),
                ),
              ),
          ],
        ),
      );
    }

    final from = animateFrom;
    if (from == null || from >= n || MediaQuery.disableAnimationsOf(context)) {
      return scene(n.toDouble());
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: from.toDouble(), end: n.toDouble()),
      duration: Duration(milliseconds: 900 + 500 * (n - from)),
      curve: Curves.easeInOutCubic,
      builder: (context, v, _) => scene(v),
    );
  }
}

class _BlanketPainter extends CustomPainter {
  _BlanketPainter(this.colors, this.shown);

  /// Farben jedes angenähten Quadrats.
  final List<List<Color>> colors;

  /// Wie viele Quadrate sichtbar sind (Zwischenwerte beim Annähen).
  final double shown;

  @override
  void paint(Canvas canvas, Size size) {
    const cols = CrochetWork.columns;
    const rows = CrochetWork.perBlanket ~/ cols;
    final w = size.width / cols;
    final h = size.height / rows;
    final full = shown.floor();
    final filledRows = (shown / cols).ceil();
    if (filledRows == 0) return;

    // Leiser Schatten unter der Decke.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          2,
          size.height - filledRows * h + 3,
          size.width - 4,
          filledRows * h,
        ),
        const Radius.circular(8),
      ),
      Paint()
        ..color = LeoColors.chocolate.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Der Stoff der Decke unter den vollen Reihen, mit genähtem Rand –
    // so wirken die Quadrate wie zusammengehäkelt, nicht wie Kacheln.
    final fullRows = full ~/ cols;
    if (fullRows > 0) {
      final base = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -1.5,
          size.height - fullRows * h - 1.5,
          size.width + 3,
          fullRows * h + 3,
        ),
        const Radius.circular(6),
      );
      canvas.drawRRect(base, Paint()..color = const Color(0xFFE3D8C2));
      final seam = Paint()
        ..color = LeoColors.chocolate.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      for (final m in (Path()..addRRect(base)).computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 5) {
          canvas.drawPath(m.extractPath(d, min(d + 2.6, m.length)), seam);
        }
      }
    }

    for (var i = 0; i < min(shown.ceil(), colors.length); i++) {
      final row = i ~/ cols;
      final col = i % cols;
      // Leicht unregelmässig, wie von Hand zusammengenäht.
      final jitter = Random(i * 31 + 7);
      final rect = Rect.fromLTWH(
        col * w + (jitter.nextDouble() - 0.5) * 1.2,
        size.height - (row + 1) * h + (jitter.nextDouble() - 0.5) * 1.2,
        w,
        h,
      );
      final t = i < full ? 1.0 : shown - full;
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.scale(w / h * 0.98, 0.98);
      canvas.scale(0.6 + 0.4 * t);
      final r = Rect.fromCenter(center: Offset.zero, width: h, height: h);
      canvas.saveLayer(
        r.inflate(2),
        Paint()..color = Colors.white.withValues(alpha: t),
      );
      paintGranny(
        canvas,
        r,
        Leitner.secure.toDouble(),
        colors[i],
        outline: false,
      );
      canvas.restore();
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BlanketPainter old) =>
      old.shown != shown || old.colors.length != colors.length;
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
