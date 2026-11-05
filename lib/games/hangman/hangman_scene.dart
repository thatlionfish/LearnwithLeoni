import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'game.dart';
import 'palette.dart';

/// Animierte Galgen-Szene.
///
/// - Der Himmel wird mit jedem Fehler abendlicher, bei einer Niederlage Nacht.
/// - Wolken ziehen, die Figur pendelt, blinzelt und zeigt ihre Stimmung.
/// - Neue Körperteile werden mit einer glühenden Federspitze gezeichnet,
///   ein Fehler lässt den Galgen wackeln.
/// - Gewinnen: Das Seil reißt, die Figur landet, jubelt, Konfetti fliegt.
/// - Verlieren: Blitz, Nachthimmel mit Sternen und Mond.
class HangmanScene extends StatefulWidget {
  const HangmanScene({
    super.key,
    required this.game,
    this.ambientAnimations = true,
  });

  final HangmanGame game;

  /// Dauerhafte Animationen (Wolken, Pendeln, Blinzeln). In Tests aus.
  final bool ambientAnimations;

  @override
  State<HangmanScene> createState() => _HangmanSceneState();
}

class _HangmanSceneState extends State<HangmanScene>
    with TickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    lowerBound: 0,
    upperBound: 6,
    value: widget.game.mistakes.toDouble(),
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final AnimationController _ending = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: (HangmanScenePainter.endingSeconds * 1000).round(),
    ),
    value: widget.game.isOver ? 1 : 0,
  );
  final ValueNotifier<double> _time = ValueNotifier(0);
  late final _ticker = createTicker(
    (elapsed) => _time.value = elapsed.inMicroseconds / 1e6,
  );

  // Letzter bekannter Spielstand. Bewusst in initState gesetzt und nicht
  // als `late`-Initialisierer: der würde erst beim ersten Zug ausgewertet,
  // wenn der neue Fehler schon gezählt ist.
  late HangmanGame _game;
  late int _mistakes;
  late bool _over;

  @override
  void initState() {
    super.initState();
    _game = widget.game;
    _mistakes = widget.game.mistakes;
    _over = widget.game.isOver;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTicker();
  }

  void _updateTicker() {
    final run =
        widget.ambientAnimations && !MediaQuery.disableAnimationsOf(context);
    if (run && !_ticker.isActive) {
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void didUpdateWidget(HangmanScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateTicker();
    final g = widget.game;

    if (!identical(g, _game)) {
      // Neues Spiel: Figur wieder "wegradieren".
      _game = g;
      _mistakes = g.mistakes;
      _over = g.isOver;
      _shake.value = 0;
      _ending.value = 0;
      _progress.animateTo(
        g.mistakes.toDouble(),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeIn,
      );
      return;
    }

    if (g.mistakes > _mistakes) {
      _progress.animateTo(
        g.mistakes.toDouble(),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
      );
      _shake.forward(from: 0);
    }
    _mistakes = g.mistakes;

    if (g.isOver && !_over) _ending.forward(from: 0);
    _over = g.isOver;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _progress.dispose();
    _shake.dispose();
    _ending.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final label = g.isWon
        ? 'Gewonnen, die Figur ist frei'
        : 'Galgen: ${g.mistakes} von ${g.maxMistakes} Teilen gezeichnet';
    return Semantics(
      label: label,
      image: true,
      child: AspectRatio(
        aspectRatio:
            HangmanScenePainter.designWidth / HangmanScenePainter.designHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final radius =
                HangmanScenePainter.cornerRadius *
                constraints.maxWidth /
                HangmanScenePainter.designWidth;
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  BoxShadow(
                    color: Palette.ink.withValues(alpha: 0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: HangmanScenePainter(
                    progress: _progress,
                    time: _time,
                    shake: _shake,
                    ending: _ending,
                    won: g.isWon,
                    lost: g.isLost,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _Mood { calm, worried, scared, dead, cheering }

class HangmanScenePainter extends CustomPainter {
  HangmanScenePainter({
    required this.progress,
    required this.time,
    required this.shake,
    required this.ending,
    required this.won,
    required this.lost,
  }) : super(repaint: Listenable.merge([progress, time, shake, ending]));

  /// 0 bis 6: wie viele Körperteile gezeichnet sind (auch Zwischenwerte).
  final Animation<double> progress;

  /// Laufende Zeit in Sekunden für Daueranimationen.
  final ValueListenable<double> time;

  /// 0 bis 1 nach einem Fehler.
  final Animation<double> shake;

  /// 0 bis 1 nach Spielende (Sieg- bzw. Niederlage-Sequenz).
  final Animation<double> ending;

  final bool won;
  final bool lost;

  static const double designWidth = 200;
  static const double designHeight = 250;
  static const double cornerRadius = 18;
  static const double endingSeconds = 2.8;

  static const Rect _full = Rect.fromLTWH(0, 0, designWidth, designHeight);
  static const Offset _hinge = Offset(145, 19);
  static const Offset _head = Offset(145, 64);
  static const double _headRadius = 22;

  static const Color _dayTop = Color(0xFFF6E4C4);
  static const Color _dayBottom = Color(0xFFFBF5EA);
  static const Color _duskTop = Color(0xFFD98C5A);
  static const Color _duskBottom = Color(0xFFF3CDA2);
  static const Color _nightTop = Color(0xFF261E33);
  static const Color _nightBottom = Color(0xFF574152);

  static final List<(Offset, double)> _stars = _makeStars();
  static final List<_Confetto> _confetti = _makeConfetti();

  static double _smooth(double a, double b, double x) {
    final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = min(size.width / designWidth, size.height / designHeight);
    canvas.save();
    canvas.translate(
      (size.width - designWidth * scale) / 2,
      (size.height - designHeight * scale) / 2,
    );
    canvas.scale(scale);
    canvas.clipRRect(
      RRect.fromRectAndRadius(_full, const Radius.circular(cornerRadius)),
    );

    final t = time.value;
    final p = progress.value;
    final e = ending.value;
    final danger = (p / 6).clamp(0.0, 1.0);
    final dusk = won ? danger * (1 - _smooth(0, 0.5, e)) : danger;
    final night = lost ? _smooth(0, 0.6, e) : 0.0;

    _paintSky(canvas, dusk, night, t);
    _paintHills(canvas, dusk, night);

    final s = shake.value;
    final dx = (s > 0 && s < 1) ? sin(s * pi * 7) * (1 - s) * 5 : 0.0;
    canvas.save();
    canvas.translate(dx, 0);
    _paintGallows(canvas);
    if (dusk > 0) {
      canvas.drawRect(
        _full,
        Paint()..color = Palette.sunset.withValues(alpha: 0.07 * dusk),
      );
    }
    if (night > 0) {
      canvas.drawRect(
        _full,
        Paint()..color = Palette.nightTint.withValues(alpha: 0.38 * night),
      );
    }
    _paintFigure(canvas, p, e, t, night);
    canvas.restore();

    if (won) _paintConfetti(canvas, e);
    if (lost) _paintLightning(canvas, e);

    canvas.restore();
  }

  // ---------------------------------------------------------------- Himmel

  void _paintSky(Canvas canvas, double dusk, double night, double t) {
    final top = Color.lerp(
      Color.lerp(_dayTop, _duskTop, dusk),
      _nightTop,
      night,
    )!;
    final bottom = Color.lerp(
      Color.lerp(_dayBottom, _duskBottom, dusk),
      _nightBottom,
      night,
    )!;
    canvas.drawRect(
      _full,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(_full),
    );

    if (night > 0) {
      for (var i = 0; i < _stars.length; i++) {
        final (pos, r) = _stars[i];
        final a = night * (0.55 + 0.45 * sin(t * 2.3 + i * 1.7));
        canvas.drawCircle(
          pos,
          r,
          Paint()..color = const Color(0xFFFFF6DD).withValues(alpha: a),
        );
      }
      // Mondsichel
      const moon = Offset(178, 54);
      canvas.drawCircle(
        moon,
        16,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFF3D1).withValues(alpha: 0.35 * night),
              const Color(0x00FFF3D1),
            ],
          ).createShader(Rect.fromCircle(center: moon, radius: 16)),
      );
      canvas.drawCircle(
        moon,
        9,
        Paint()..color = const Color(0xFFFFF0C9).withValues(alpha: night),
      );
      final skyAtMoon = Color.lerp(top, bottom, moon.dy / designHeight)!;
      canvas.drawCircle(
        moon + const Offset(4.5, -3),
        8,
        Paint()..color = skyAtMoon.withValues(alpha: night),
      );
    }

    // Sonne: geht mit jedem Fehler unter.
    final sunCenter = Offset(28, 44 + dusk * 120 + night * 90);
    final sunColor = Color.lerp(Palette.sun, Palette.sunset, dusk)!;
    final sunAlpha = 1 - night;
    if (sunAlpha > 0) {
      canvas.drawCircle(
        sunCenter,
        32,
        Paint()
          ..shader = RadialGradient(
            colors: [
              sunColor.withValues(alpha: 0.5 * sunAlpha),
              sunColor.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: sunCenter, radius: 32)),
      );
      final rays = Paint()
        ..color = sunColor.withValues(alpha: 0.55 * sunAlpha * (1 - dusk))
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 8; i++) {
        final a = t * 0.35 + i * pi / 4;
        final dir = Offset(cos(a), sin(a));
        canvas.drawLine(sunCenter + dir * 18, sunCenter + dir * 24, rays);
      }
      canvas.drawCircle(
        sunCenter,
        13,
        Paint()..color = sunColor.withValues(alpha: sunAlpha),
      );
    }

    // Wolken
    final cloudColor = Color.lerp(
      const Color(0xFFFFFBF3),
      const Color(0xFF8C7686),
      night,
    )!.withValues(alpha: 0.88 - 0.35 * night);
    for (final (x0, y, speed, s) in const [
      (10.0, 30.0, 4.0, 1.0),
      (120.0, 62.0, 6.5, 0.8),
      (230.0, 100.0, 3.0, 0.65),
    ]) {
      final x = ((x0 + t * speed) % 280) - 45;
      _cloud(canvas, Offset(x, y), s, cloudColor);
    }
  }

  void _cloud(Canvas canvas, Offset o, double s, Color color) {
    final paint = Paint()..color = color;
    canvas.drawCircle(o + Offset(0, 2) * s, 8 * s, paint);
    canvas.drawCircle(o + Offset(11, -4) * s, 11 * s, paint);
    canvas.drawCircle(o + Offset(24, 1) * s, 8.5 * s, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(o.dx - 7 * s, o.dy, o.dx + 32 * s, o.dy + 9 * s),
        Radius.circular(5 * s),
      ),
      paint,
    );
  }

  void _paintHills(Canvas canvas, double dusk, double night) {
    final back = Color.lerp(
      Color.lerp(const Color(0xFFE3D2B0), const Color(0xFFD4A77A), dusk * 0.6),
      const Color(0xFF3E3140),
      night,
    )!;
    final front = Color.lerp(
      Color.lerp(const Color(0xFFCDB68C), const Color(0xFFB98A5E), dusk * 0.6),
      const Color(0xFF2F2532),
      night,
    )!;
    final backPath = Path()
      ..moveTo(0, 214)
      ..quadraticBezierTo(55, 192, 115, 210)
      ..quadraticBezierTo(165, 224, 200, 204)
      ..lineTo(200, 250)
      ..lineTo(0, 250)
      ..close();
    canvas.drawPath(backPath, Paint()..color = back);
    final frontPath = Path()
      ..moveTo(0, 232)
      ..cubicTo(60, 220, 140, 230, 200, 222)
      ..lineTo(200, 250)
      ..lineTo(0, 250)
      ..close();
    canvas.drawPath(frontPath, Paint()..color = front);

    final grass = Paint()
      ..color = Color.lerp(
        const Color(0xFF8C7A4E),
        const Color(0xFF1E1822),
        night,
      )!
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (final x in const [8.0, 30.0, 96.0, 128.0, 190.0]) {
      const y = 246.0;
      canvas.drawLine(Offset(x, y), Offset(x - 2, y - 5), grass);
      canvas.drawLine(Offset(x, y), Offset(x + 1, y - 6), grass);
      canvas.drawLine(Offset(x, y), Offset(x + 3, y - 4), grass);
    }
  }

  // ---------------------------------------------------------------- Galgen

  void _paintGallows(Canvas canvas) {
    // Stützen und Plattform
    _beam(canvas, const Rect.fromLTWH(24, 236, 8, 14), horizontal: false);
    _beam(canvas, const Rect.fromLTWH(168, 236, 8, 14), horizontal: false);
    _beam(canvas, const Rect.fromLTWH(12, 228, 176, 10), horizontal: true);

    // Strebe
    canvas.save();
    canvas.translate(78, 38);
    canvas.rotate(-0.775);
    _beam(
      canvas,
      Rect.fromCenter(center: Offset.zero, width: 58, height: 8),
      horizontal: true,
    );
    canvas.restore();

    _beam(canvas, const Rect.fromLTWH(46, 14, 12, 216), horizontal: false);
    _beam(canvas, const Rect.fromLTWH(40, 8, 116, 11), horizontal: true);

    final bolt = Paint()..color = const Color(0xFF3A2614);
    final shine = Paint()..color = const Color(0x66FFFFFF);
    for (final o in const [
      Offset(52, 13.5),
      Offset(150, 13.5),
      Offset(52, 223),
      Offset(20, 233),
      Offset(180, 233),
    ]) {
      canvas.drawCircle(o, 1.9, bolt);
      canvas.drawCircle(o + const Offset(-0.6, -0.6), 0.6, shine);
    }
  }

  void _beam(Canvas canvas, Rect rect, {required bool horizontal}) {
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(2.5));
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: horizontal ? Alignment.topCenter : Alignment.centerLeft,
          end: horizontal ? Alignment.bottomCenter : Alignment.centerRight,
          colors: const [Palette.woodLight, Palette.wood, Palette.woodDark],
          stops: const [0, 0.45, 1],
        ).createShader(rect),
    );

    final grain = Paint()
      ..color = Palette.woodDark.withValues(alpha: 0.35)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    for (final f in const [0.3, 0.68]) {
      final path = Path();
      if (horizontal) {
        final y = rect.top + rect.height * f;
        path.moveTo(rect.left + 3, y);
        for (var x = rect.left + 3; x < rect.right - 3; x += 4) {
          path.lineTo(x, y + sin(x * 0.35 + f * 10) * 0.5);
        }
      } else {
        final x = rect.left + rect.width * f;
        path.moveTo(x, rect.top + 3);
        for (var y = rect.top + 3; y < rect.bottom - 3; y += 4) {
          path.lineTo(x + sin(y * 0.3 + f * 10) * 0.5, y);
        }
      }
      canvas.drawPath(path, grain);
    }

    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Palette.woodDark.withValues(alpha: 0.9),
    );
  }

  void _rope(Canvas canvas, Offset from, Offset to, [double alpha = 1]) {
    if (alpha <= 0) return;
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = Palette.rope.withValues(alpha: alpha)
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round,
    );
    final twist = Paint()
      ..color = Palette.ropeDark.withValues(alpha: 0.8 * alpha)
      ..strokeWidth = 1;
    for (var y = from.dy + 2; y < to.dy - 1; y += 3) {
      canvas.drawLine(
        Offset(from.dx - 1.6, y),
        Offset(from.dx + 1.6, y + 1.6),
        twist,
      );
    }
  }

  // ---------------------------------------------------------------- Figur

  void _paintFigure(Canvas canvas, double p, double e, double t, double night) {
    final ink = Color.lerp(Palette.ink, const Color(0xFFF3E6D0), night)!;
    final reveal = won ? _smooth(0, 0.3, e) : 0.0;
    double part(int i) => max((p - i).clamp(0.0, 1.0), reveal);

    var amp = 0.018 + 0.011 * p;
    if (lost) amp = 0.07 + 0.16 * (1 - _smooth(0, 1, e));
    final angle = amp * sin(t * 1.7);

    if (!won) {
      canvas.save();
      _rotateAround(canvas, _hinge, angle);
      _rope(canvas, _hinge, const Offset(145, 42));
      _paintBody(
        canvas,
        part,
        ink,
        t,
        mood: lost
            ? _Mood.dead
            : p < 2
            ? _Mood.calm
            : p < 4
            ? _Mood.worried
            : _Mood.scared,
      );
      canvas.restore();
      return;
    }

    // Sieg: Seil reißt, Figur fällt, landet federnd und jubelt.
    final fall = Curves.bounceOut.transform((e / 0.5).clamp(0.0, 1.0)) * 23;
    final after = ((e - 0.5) / 0.5).clamp(0.0, 1.0);
    final jump = after > 0
        ? -sin(after * pi * 3).abs() * 9 * (1 - after * 0.5)
        : 0.0;
    final armLift = _smooth(0.45, 0.62, e);

    canvas.save();
    _rotateAround(canvas, _hinge, sin(t * 6) * 0.35 * (1 - _smooth(0, 1, e)));
    _rope(canvas, _hinge, const Offset(145, 31));
    canvas.restore();
    _rope(
      canvas,
      Offset(145, 33 + fall * 1.4),
      Offset(145, 42 + fall * 1.4),
      1 - _smooth(0, 0.25, e),
    );

    final lift = -jump;
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(145, 229),
        width: max(10.0, 40 - lift * 1.4),
        height: 4,
      ),
      Paint()..color = Palette.ink.withValues(alpha: 0.22 * reveal),
    );

    canvas.save();
    canvas.translate(0, fall + jump);
    _paintBody(
      canvas,
      part,
      ink,
      t,
      mood: e > 0.3 ? _Mood.cheering : _Mood.calm,
      armLift: armLift,
    );
    canvas.restore();
  }

  void _rotateAround(Canvas canvas, Offset pivot, double angle) {
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    canvas.translate(-pivot.dx, -pivot.dy);
  }

  void _paintBody(
    Canvas canvas,
    double Function(int) part,
    Color ink,
    double t, {
    required _Mood mood,
    double armLift = 0,
  }) {
    final stroke = Paint()
      ..color = ink
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final h = part(0);
    if (h > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: _head, radius: _headRadius),
        -pi / 2,
        2 * pi * h,
        false,
        stroke,
      );
      if (h < 1) {
        final a = -pi / 2 + 2 * pi * h;
        _penTip(canvas, _head + Offset(cos(a), sin(a)) * _headRadius);
      }
    }

    const shoulders = Offset(145, 105);
    const hip = Offset(145, 155);
    final lines = <(Offset, Offset)>[
      (const Offset(145, 86), hip),
      (
        shoulders,
        Offset.lerp(const Offset(115, 135), const Offset(117, 76), armLift)!,
      ),
      (
        shoulders,
        Offset.lerp(const Offset(175, 135), const Offset(173, 76), armLift)!,
      ),
      (hip, const Offset(118, 205)),
      (hip, const Offset(172, 205)),
    ];
    for (var i = 0; i < lines.length; i++) {
      final f = part(i + 1);
      if (f <= 0) continue;
      final (a, b) = lines[i];
      final end = Offset.lerp(a, b, f)!;
      canvas.drawLine(a, end, stroke);
      if (f < 1) _penTip(canvas, end);
    }

    if (h >= 1) _paintFace(canvas, ink, t, mood);
  }

  void _penTip(Canvas canvas, Offset o) {
    canvas.drawCircle(
      o,
      8,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Palette.sunset.withValues(alpha: 0.55),
            Palette.sunset.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: o, radius: 8)),
    );
    canvas.drawCircle(o, 2.6, Paint()..color = Palette.sun);
  }

  void _paintFace(Canvas canvas, Color ink, double t, _Mood mood) {
    final line = Paint()
      ..color = ink
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = ink;
    const le = Offset(137, 60);
    const re = Offset(153, 60);

    if (mood == _Mood.dead) {
      for (final c in const [le, re]) {
        canvas.drawLine(
          c - const Offset(3.5, 3.5),
          c + const Offset(3.5, 3.5),
          line,
        );
        canvas.drawLine(
          c + const Offset(-3.5, 3.5),
          c + const Offset(3.5, -3.5),
          line,
        );
      }
      canvas.drawArc(
        Rect.fromCenter(center: const Offset(145, 80), width: 14, height: 9),
        1.15 * pi,
        0.7 * pi,
        false,
        line,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(148.5, 78.5),
          width: 5,
          height: 6.5,
        ),
        Paint()..color = const Color(0xFFD9675A),
      );
      return;
    }

    // Augen
    final blink = mood != _Mood.cheering && (t % 3.6) < 0.13;
    if (mood == _Mood.cheering) {
      for (final c in const [le, re]) {
        canvas.drawArc(
          Rect.fromCircle(center: c + const Offset(0, 1.5), radius: 3.2),
          pi,
          pi,
          false,
          line,
        );
      }
    } else if (blink) {
      for (final c in const [le, re]) {
        canvas.drawLine(c - const Offset(3, 0), c + const Offset(3, 0), line);
      }
    } else {
      final r = mood == _Mood.scared ? 3.1 : 2.6;
      canvas.drawCircle(le, r, fill);
      canvas.drawCircle(re, r, fill);
    }

    // Augenbrauen
    if (mood == _Mood.worried || mood == _Mood.scared) {
      final lift = mood == _Mood.scared ? 2.0 : 0.0;
      canvas.drawLine(
        Offset(131, 53 - lift),
        Offset(140, 50 - lift * 1.5),
        line,
      );
      canvas.drawLine(
        Offset(150, 50 - lift * 1.5),
        Offset(159, 53 - lift),
        line,
      );
    }

    // Mund
    switch (mood) {
      case _Mood.calm:
        canvas.drawArc(
          Rect.fromCenter(center: const Offset(145, 70), width: 14, height: 10),
          0.15 * pi,
          0.7 * pi,
          false,
          line,
        );
      case _Mood.worried:
        canvas.drawLine(const Offset(139, 75), const Offset(151, 74), line);
      case _Mood.scared:
        canvas.drawArc(
          Rect.fromCenter(center: const Offset(145, 80), width: 14, height: 10),
          1.15 * pi,
          0.7 * pi,
          false,
          line,
        );
        final phase = (t * 18) % 16;
        final drop = Offset(167, 48 + phase);
        final dropPaint = Paint()
          ..color = const Color(0xFF7FB2D6).withValues(alpha: 1 - phase / 16);
        canvas.drawCircle(drop, 2.2, dropPaint);
        canvas.drawPath(
          Path()
            ..moveTo(drop.dx - 2, drop.dy - 0.6)
            ..lineTo(drop.dx, drop.dy - 5)
            ..lineTo(drop.dx + 2, drop.dy - 0.6)
            ..close(),
          dropPaint,
        );
      case _Mood.cheering:
        canvas.drawArc(
          Rect.fromCenter(center: const Offset(145, 70), width: 16, height: 13),
          0,
          pi,
          true,
          fill,
        );
      case _Mood.dead:
        break;
    }
  }

  // ---------------------------------------------------------------- Effekte

  void _paintConfetti(Canvas canvas, double e) {
    final seconds = e * endingSeconds;
    final alpha = 1 - _smooth(0.78, 1, e);
    if (alpha <= 0) return;
    for (final c in _confetti) {
      final tt = seconds - c.delay;
      if (tt <= 0) continue;
      final pos = Offset(
        c.start.dx + c.velocity.dx * tt,
        c.start.dy + c.velocity.dy * tt + 0.5 * 210 * tt * tt,
      );
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(c.phase + c.spin * tt);
      canvas.scale(1, 0.25 + 0.75 * cos(tt * c.flip).abs());
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: c.width, height: c.height),
        Paint()..color = c.color.withValues(alpha: alpha),
      );
      canvas.restore();
    }
  }

  void _paintLightning(Canvas canvas, double e) {
    final first = 1 - _smooth(0, 0.16, e);
    final second = (e > 0.22 && e < 0.3) ? (1 - (e - 0.22) / 0.08) * 0.7 : 0.0;
    final f = max(first, second);
    if (f <= 0) return;

    final bolt = Path()
      ..moveTo(182, 0)
      ..lineTo(168, 36)
      ..lineTo(178, 38)
      ..lineTo(160, 82)
      ..lineTo(171, 84)
      ..lineTo(156, 118);
    canvas.drawPath(
      bolt,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFFFF2B8).withValues(alpha: 0.3 * f),
    );
    canvas.drawPath(
      bolt,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFFFF8DA).withValues(alpha: f),
    );
    canvas.drawRect(
      _full,
      Paint()..color = Colors.white.withValues(alpha: 0.5 * f),
    );
  }

  static List<(Offset, double)> _makeStars() {
    final rnd = Random(5);
    return [
      for (var i = 0; i < 24; i++)
        (
          Offset(rnd.nextDouble() * designWidth, rnd.nextDouble() * 140),
          0.6 + rnd.nextDouble() * 1.1,
        ),
    ];
  }

  static List<_Confetto> _makeConfetti() {
    const colors = [
      Palette.sunset,
      Palette.correct,
      Palette.sun,
      Palette.accent,
      Color(0xFFC0504D),
      Color(0xFF7FB2D6),
    ];
    final rnd = Random(11);
    return [
      for (var i = 0; i < 80; i++)
        _Confetto(
          start: Offset(145 + (rnd.nextDouble() - 0.5) * 24, 70),
          velocity: Offset(
            (rnd.nextDouble() - 0.5) * 180,
            -(90 + rnd.nextDouble() * 120),
          ),
          delay: 0.3 + rnd.nextDouble() * 0.25,
          width: 3 + rnd.nextDouble() * 2.5,
          height: 2 + rnd.nextDouble() * 1.8,
          spin: (rnd.nextDouble() - 0.5) * 14,
          flip: 4 + rnd.nextDouble() * 8,
          phase: rnd.nextDouble() * pi,
          color: colors[i % colors.length],
        ),
    ];
  }

  @override
  bool shouldRepaint(HangmanScenePainter old) =>
      old.won != won ||
      old.lost != lost ||
      old.progress != progress ||
      old.time != time ||
      old.shake != shake ||
      old.ending != ending;
}

class _Confetto {
  const _Confetto({
    required this.start,
    required this.velocity,
    required this.delay,
    required this.width,
    required this.height,
    required this.spin,
    required this.flip,
    required this.phase,
    required this.color,
  });

  final Offset start;
  final Offset velocity;
  final double delay;
  final double width;
  final double height;
  final double spin;
  final double flip;
  final double phase;
  final Color color;
}
