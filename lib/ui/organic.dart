import 'dart:math';

import 'package:flutter/material.dart';

import 'colors.dart';

/// Leicht ungleichmäßige Rundungen – jede Karte bekommt per [seed]
/// ihre eigene, aber stabile Form.
BorderRadius organicRadius(int seed, {double base = 26}) {
  final r = Random(seed * 7919 + 17);
  Radius corner() => Radius.elliptical(
    base * (0.72 + r.nextDouble() * 0.56),
    base * (0.72 + r.nextDouble() * 0.56),
  );
  return BorderRadius.only(
    topLeft: corner(),
    topRight: corner(),
    bottomLeft: corner(),
    bottomRight: corner(),
  );
}

/// Ungleichmäßige, aber kreisrunde Ecken – für Eingabefelder, die keine
/// ovalen Ecken erlauben.
BorderRadius organicInputRadius(int seed, {double base = 18}) {
  final r = Random(seed * 7919 + 17);
  Radius corner() => Radius.circular(base * (0.72 + r.nextDouble() * 0.56));
  return BorderRadius.only(
    topLeft: corner(),
    topRight: corner(),
    bottomLeft: corner(),
    bottomRight: corner(),
  );
}

/// Karte mit organischer Form, feinem Rand und ohne harte Schatten.
class OrganicCard extends StatelessWidget {
  const OrganicCard({
    super.key,
    required this.child,
    this.seed = 1,
    this.color = LeoColors.brightWhite,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final int seed;
  final Color color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = organicRadius(seed);
    final shape = RoundedRectangleBorder(
      borderRadius: radius,
      side: const BorderSide(color: LeoColors.woodAsh, width: 1),
    );
    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = InkWell(
        customBorder: shape,
        onTap: onTap,
        hoverColor: LeoColors.vanillaIce.withValues(alpha: 0.5),
        splashColor: LeoColors.woodAsh.withValues(alpha: 0.3),
        child: content,
      );
    }
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      container: true,
      child: Material(
        color: color,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }
}

/// Weiche, kieselartige Flächen im Hintergrund (Wood Ash, wenig Deckkraft).
class PebbleBackground extends StatelessWidget {
  const PebbleBackground({super.key, required this.child, this.seed = 3});

  final Widget child;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PebblePainter(seed), child: child);
  }
}

class _PebblePainter extends CustomPainter {
  _PebblePainter(this.seed);

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(seed);
    final specs = <(Offset, double, Color)>[
      (
        Offset(size.width * 0.92, size.height * 0.08),
        170,
        LeoColors.woodAsh.withValues(alpha: 0.22),
      ),
      (
        Offset(size.width * 0.04, size.height * 0.46),
        130,
        LeoColors.sand.withValues(alpha: 0.45),
      ),
      (
        Offset(size.width * 0.86, size.height * 0.92),
        150,
        LeoColors.vanillaIce.withValues(alpha: 0.9),
      ),
    ];
    for (final (center, radius, color) in specs) {
      canvas.drawPath(pebblePath(center, radius, r), Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_PebblePainter old) => old.seed != seed;
}

/// Geschlossene, weiche Form durch leicht verschobene Punkte auf einem Kreis
/// (Catmull-Rom-Kurve als kubische Bézier-Segmente).
Path pebblePath(Offset center, double radius, Random r, {int points = 7}) {
  final pts = <Offset>[
    for (var i = 0; i < points; i++)
      () {
        final a = 2 * pi * i / points + r.nextDouble() * 0.35;
        final d = radius * (0.78 + r.nextDouble() * 0.3);
        return center + Offset(cos(a) * d, sin(a) * d * 0.86);
      }(),
  ];
  final path = Path()..moveTo(pts[0].dx, pts[0].dy);
  for (var i = 0; i < points; i++) {
    final p0 = pts[(i - 1 + points) % points];
    final p1 = pts[i];
    final p2 = pts[(i + 1) % points];
    final p3 = pts[(i + 2) % points];
    final c1 = p1 + (p2 - p0) / 6;
    final c2 = p2 - (p3 - p1) / 6;
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  return path..close();
}

/// Fortschrittsbalken: sicher · gelernt · im Lernen · neu.
class StackedProgress extends StatelessWidget {
  const StackedProgress({
    super.key,
    required this.learned,
    required this.learning,
    required this.total,
    this.secure = 0,
  });

  final int secure;
  final int learned;
  final int learning;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox(height: 8);
    const radius = BorderRadius.all(Radius.elliptical(8, 6));
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: LeoColors.woodAsh),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: 8,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (secure > 0)
                Expanded(
                  flex: secure,
                  child: const ColoredBox(color: LeoColors.chocolate),
                ),
              if (learned > 0)
                Expanded(
                  flex: learned,
                  child: const ColoredBox(color: LeoColors.inkSoft),
                ),
              if (learning > 0)
                Expanded(
                  flex: learning,
                  child: const ColoredBox(color: LeoColors.woodAsh),
                ),
              if (total - secure - learned - learning > 0)
                Expanded(
                  flex: total - secure - learned - learning,
                  child: const ColoredBox(color: LeoColors.vanillaIce),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kleiner Lemon-Grass-Punkt als Detail.
class SenchaDot extends StatelessWidget {
  const SenchaDot({super.key, this.size = 8});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: LeoColors.lemonGrass,
      shape: BoxShape.circle,
      border: Border.all(
        color: LeoColors.chocolate.withValues(alpha: 0.35),
        width: 0.8,
      ),
    ),
  );
}
