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

/// Kumachan, eingewickelt in ihre Decke wie in einen Döner: Mit den ersten
/// Quadraten reicht die Rolle bis zu den Füssen, mit [_chinAt] bis zum Kinn –
/// danach wird sie immer dicker, ohne Ende. Oben sieht man die Spirale.
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

  /// So viele Quadrate reichen bis zum Kinn.
  static const _chinAt = 24.0;

  @override
  Widget build(BuildContext context) {
    final n = work.attached.length;
    // Aussen liegen die neuesten Quadrate.
    final colors = [for (final s in work.attached.reversed) yarnFor(s.key)];
    final width = height * 0.9;

    Widget scene(double count) {
      final shown = count * (1 - unrolled);
      final wrapped = shown / _chinAt >= 0.6;
      final pose = unrolled > 0.25
          ? KumaPose.cheer
          : (wrapped ? KumaPose.sleepy : KumaPose.crochet);
      return SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            KumaFigure(pose: pose, height: height),
            if (shown > 0.01)
              Positioned.fill(
                child: CustomPaint(
                  painter: _RollPainter(colors, shown, paws: wrapped),
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
      duration: Duration(milliseconds: 900 + 400 * min(n - from, 8)),
      curve: Curves.easeInOutCubic,
      builder: (context, v, _) => scene(v),
    );
  }
}

class _RollPainter extends CustomPainter {
  _RollPainter(this.colors, this.count, {required this.paws});

  /// Farben der Quadrate, das neueste zuerst (liegt aussen).
  final List<List<Color>> colors;

  /// Wie viele Quadrate (Zwischenwerte beim Wachsen und Ausrollen).
  final double count;

  /// Kumachan hält den Rand mit beiden Pfoten.
  final bool paws;

  @override
  void paint(Canvas canvas, Size size) {
    if (count <= 0 || colors.isEmpty) return;
    final h = size.height, w = size.width, cx = w / 2;
    final ink = LeoColors.chocolate;
    final bottom = h * 0.975;
    final chin = h * 0.44;
    final reach = min(1.0, count / KumaRoll._chinAt);
    // Dicke wächst ohne Ende – langsamer, je dicker die Rolle schon ist.
    // Ein Dürüm bleibt schlank: die Dicke wächst langsam, aber ohne Ende.
    final rx = min(w * 0.47, h * (0.19 + 0.017 * sqrt(count)));
    final ry = rx * 0.17;
    final top = bottom - ry - reach * (bottom - ry - chin);

    // Schatten am Boden.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, bottom),
        width: rx * 2.2,
        height: ry * 1.4,
      ),
      Paint()
        ..color = ink.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Der Mantel der Rolle.
    final body = Path()
      ..moveTo(cx - rx, top)
      ..lineTo(cx - rx, bottom - ry)
      ..arcTo(
        Rect.fromCenter(
          center: Offset(cx, bottom - ry),
          width: rx * 2,
          height: ry * 2,
        ),
        pi,
        -pi,
        false,
      )
      ..lineTo(cx + rx, top)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFFE3D8C2));
    canvas.save();
    canvas.clipPath(body);

    // Quadrate rund um die Rolle: an den Seiten schmaler (Zylinder).
    const cols = 7;
    final rowH = rx * 2 / cols;
    var idx = 0;
    for (var y = bottom; y > top - rowH; y -= rowH) {
      for (var i = 0; i < cols; i++) {
        final a0 = -pi / 2 + i * pi / cols;
        final x0 = cx + rx * sin(a0);
        final x1 = cx + rx * sin(a0 + pi / cols);
        final cell = Rect.fromLTRB(x0, y - rowH, x1, y);
        canvas.save();
        canvas.translate(cell.center.dx, cell.center.dy);
        canvas.scale(max(0.05, cell.width / rowH), 1);
        paintGranny(
          canvas,
          Rect.fromCenter(center: Offset.zero, width: rowH, height: rowH),
          Leitner.secure.toDouble(),
          colors[idx % colors.length],
          outline: false,
        );
        canvas.restore();
        idx++;
      }
    }

    // Rundung: Seiten dunkler, vorne ein Hauch Licht.
    canvas.drawRect(
      Rect.fromLTRB(cx - rx, top - ry, cx + rx, bottom + ry),
      Paint()
        ..shader = LinearGradient(
          colors: [
            ink.withValues(alpha: 0.28),
            ink.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.12),
            ink.withValues(alpha: 0),
            ink.withValues(alpha: 0.28),
          ],
          stops: const [0, 0.28, 0.42, 0.7, 1],
        ).createShader(Rect.fromLTRB(cx - rx, 0, cx + rx, 1)),
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
    final span = bottom - ry - top;
    final wrapEdge = Path()
      ..moveTo(cx - rx * 1.02, top + span * 0.82)
      ..cubicTo(
        cx - rx * 0.35,
        top + span * 0.62,
        cx + rx * 0.15,
        top + span * 0.3,
        cx + rx * 0.62,
        top + ry * 0.4,
      );
    canvas.drawPath(
      wrapEdge.shift(const Offset(0, 3)),
      Paint()
        ..color = ink.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    dashed(wrapEdge);
    canvas.restore();
    dashed(body);

    // Oben schauen die Lagen der Decke um Kumachan heraus – zarte Ringe,
    // je mehr Quadrate, desto mehr Lagen.
    final rim = Rect.fromCenter(
      center: Offset(cx, top),
      width: rx * 2,
      height: ry * 2,
    );
    final hole = min(rx * 0.8, h * 0.118);
    canvas.drawOval(rim, Paint()..color = const Color(0xFFEFE6D4));
    final layers = (count / 10).ceil().clamp(1, 8);
    for (var k = layers; k >= 1; k--) {
      final r = hole + (rx - hole) * k / layers;
      final ring = Rect.fromCenter(
        center: Offset(cx, top),
        width: r * 2,
        height: r * 2 * ry / rx,
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
      rim,
      Paint()
        ..color = ink.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Der Zipfel der Decke steht oben ab, wie beim Dürüm das Papier.
    if (reach >= 0.6) {
      final a = Offset(cx + rx * 0.38, top + ry * 0.55);
      final b = Offset(cx + rx * 0.95, top + ry * 0.2);
      final tip = Offset(cx + rx * 0.86, top - ry * 2.6);
      final corner = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(cx + rx * 0.55, top - ry * 1.2, tip.dx, tip.dy)
        ..quadraticBezierTo(cx + rx * 1.02, top - ry * 0.9, b.dx, b.dy)
        ..close();
      canvas.drawPath(corner, Paint()..color = const Color(0xFFE3D8C2));
      canvas.save();
      canvas.clipPath(corner);
      final c = colors.first;
      paintGranny(
        canvas,
        Rect.fromCenter(
          center: Offset(cx + rx * 0.74, top - ry * 0.7),
          width: rx * 0.5,
          height: rx * 0.5,
        ),
        Leitner.secure.toDouble(),
        c,
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
    // Innen steckt Kumachan.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, top),
        width: hole * 2,
        height: hole * 2 * ry / rx,
      ),
      Paint()..color = const Color(0xFF6F5869),
    );

    if (paws) {
      for (final dx in [-0.72, 0.72]) {
        final p = Offset(cx + dx * hole, top - ry * 0.25);
        final radius = h * 0.036;
        canvas.drawCircle(p, radius, Paint()..color = const Color(0xFFF1DCD6));
        canvas.drawCircle(
          p,
          radius,
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
        final toe = Paint()
          ..color = ink.withValues(alpha: 0.55)
          ..strokeWidth = 1.1
          ..strokeCap = StrokeCap.round;
        for (final tx in [-0.35, 0.0, 0.35]) {
          canvas.drawLine(
            p + Offset(tx * radius, -radius * 0.75),
            p + Offset(tx * radius, -radius * 0.35),
            toe,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_RollPainter old) =>
      old.count != count ||
      old.paws != paws ||
      old.colors.length != colors.length;
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
