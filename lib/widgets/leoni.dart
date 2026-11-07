import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/gloss.dart';
import '../ui/colors.dart';
import '../ui/theme.dart';
import 'figure.dart';
import 'kuma_poses.g.dart';
import 'leoni_poses.g.dart';

export 'figure.dart';
export 'kuma_poses.g.dart';
export 'leoni_poses.g.dart';

/// Leoni als animierte Comic-Figur.
class LeoniFigure extends StatelessWidget {
  const LeoniFigure({super.key, this.pose = LeoniPose.wave, this.height = 160});

  final LeoniPose pose;
  final double height;

  /// In Widget-Tests ausschalten (gilt für alle Figuren).
  static bool get animate => AnimatedFigure.animate;
  static set animate(bool v) => AnimatedFigure.animate = v;

  @override
  Widget build(BuildContext context) =>
      AnimatedFigure(pose: pose, height: height);
}

/// Kumachan, Leonis gehäkelter Bär.
class KumaFigure extends StatelessWidget {
  const KumaFigure({super.key, this.pose = KumaPose.idle, this.height = 110});

  final KumaPose pose;
  final double height;

  @override
  Widget build(BuildContext context) =>
      AnimatedFigure(pose: pose, height: height);
}

/// Ein Spruch: Original (Deutsch oder Bündnerdütsch) plus Übersetzungen.
class LeoniPhrase {
  const LeoniPhrase(this.original, this.translations);

  final String original;
  final Map<String, String> translations;

  /// Übersetzung in die Hilfesprache (`null` = nur Deutsch).
  String? translationFor(String? languageCode) =>
      languageCode == null || languageCode == 'de'
      ? null
      : translations[languageCode];
}

/// Lädt `assets/leoni/phrases.json` einmal.
abstract final class LeoniPhrases {
  static Future<Map<String, List<LeoniPhrase>>>? _cache;

  @visibleForTesting
  static void resetCache() => _cache = null;

  static Future<Map<String, List<LeoniPhrase>>> load() => _cache ??= () async {
    final raw = jsonDecode(
      await rootBundle.loadString('assets/leoni/phrases.json'),
    ) as Map<String, dynamic>;
    return {
      for (final MapEntry(:key, :value) in raw.entries)
        key: [
          for (final p in value as List)
            LeoniPhrase((p as Map<String, dynamic>)['text'] as String, {
              for (final MapEntry(:key, :value) in p.entries)
                if (key != 'text') key: value as String,
            }),
        ],
    };
  }();

  static Future<LeoniPhrase?> pick(String mood, {Random? random}) async {
    final list = (await load())[mood];
    if (list == null || list.isEmpty) return null;
    return list[(random ?? Random()).nextInt(list.length)];
  }
}

/// Figur mit Sprechblase.
class LeoniSays extends StatelessWidget {
  const LeoniSays({
    super.key,
    required this.headline,
    this.phrase,
    this.pose = LeoniPose.wave,
    this.subline,
    this.figureHeight = 168,
    this.companion,
  });

  /// Kumachan steht klein neben Leoni (optional).
  final KumaPose? companion;

  /// Fett über dem Spruch, z. B. „Hallo Anna!“. Leer = keine Überschrift.
  final String headline;
  final LeoniPhrase? phrase;
  final LeoniPose pose;

  /// Zusätzlicher Satz unter der Überschrift (ohne Übersetzung).
  final String? subline;
  final double figureHeight;

  @override
  Widget build(BuildContext context) {
    final translation = phrase?.translationFor(helpLanguageOf(context));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (companion != null)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: KumaFigure(pose: companion!, height: figureHeight * 0.52),
          ),
        LeoniFigure(pose: pose, height: figureHeight),
        const SizedBox(width: 4),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: figureHeight / 3),
            child: CustomPaint(
              painter: _BubblePainter(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (headline.isNotEmpty)
                      Text(headline, style: serif(24, weight: 460)),
                    if (subline != null) ...[
                      const SizedBox(height: 4),
                      Text(subline!, style: sans(15.5)),
                    ],
                    if (phrase != null) ...[
                      const SizedBox(height: 4),
                      Text(phrase!.original, style: sans(16, weight: 520)),
                      if (translation != null)
                        Text(translation, style: glossStyle(13.5)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Sprechblase mit leicht unregelmäßiger Form und Zipfel nach links unten.
class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const l = 10.0; // Platz für den Zipfel
    final path = Path()
      ..moveTo(l + 22, 2)
      ..cubicTo(w * 0.45, -2, w * 0.75, 3, w - 20, 1)
      ..quadraticBezierTo(w + 1, 2, w, 24)
      ..cubicTo(w + 2, h * 0.45, w - 1, h * 0.75, w - 2, h - 22)
      ..quadraticBezierTo(w - 3, h + 1, w - 26, h - 1)
      ..cubicTo(w * 0.6, h + 2, w * 0.3, h - 2, l + 30, h)
      ..quadraticBezierTo(l + 16, h, l + 10, h - 6)
      // Zipfel
      ..quadraticBezierTo(l - 2, h + 6, -2, h + 4)
      ..quadraticBezierTo(l + 2, h - 6, l + 2, h - 22)
      ..cubicTo(l + 1, h * 0.6, l - 1, h * 0.3, l + 1, 22)
      ..quadraticBezierTo(l + 2, 1, l + 22, 2)
      ..close();
    canvas.drawPath(path, Paint()..color = LeoColors.brightWhite);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = LeoColors.woodAsh,
    );
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) => false;
}
