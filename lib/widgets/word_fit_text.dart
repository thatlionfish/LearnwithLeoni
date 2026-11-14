import 'dart:math';

import 'package:flutter/material.dart';

/// Wörter in lateinischer Schrift, die nicht umgebrochen werden dürfen.
/// Japanisch, Chinesisch usw. darf zwischen allen Zeichen umbrechen und
/// zählt deshalb nicht; ein Bindestrich ist eine erlaubte Trennstelle.
final _unbreakable = RegExp(r'''[0-9A-Za-zÀ-ÖØ-öø-ɏ'’]+''');

/// Breite des längsten Worts aus [texts] in [style] (ohne Umbruch).
double widestWord(
  BuildContext context,
  Iterable<String> texts,
  TextStyle? style,
) {
  // Wie beim Anzeigen: Der Grundstil liefert z. B. den Buchstabenabstand.
  final shown = DefaultTextStyle.of(context).style.merge(style);
  var widest = 0.0;
  for (final text in texts) {
    for (final m in _unbreakable.allMatches(text)) {
      final painter = TextPainter(
        text: TextSpan(text: m.group(0), style: shown),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      widest = max(widest, painter.width);
      painter.dispose();
    }
  }
  return widest;
}

/// Text, der lange Wörter nicht mitten im Wort trennt.
///
/// Passt das längste Wort nicht in die Breite, z. B. „Widerstandsfähigkeit“
/// auf einer Lernkarte am Handy, wird die Schrift so weit kleiner, dass es
/// auf eine Zeile passt – höchstens bis auf [minScale] der Grösse.
class WordFitText extends StatelessWidget {
  const WordFitText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign,
    this.minScale = 0.6,
  });

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final double minScale;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      var fitted = style;
      if (constraints.hasBoundedWidth) {
        // −1: Rundungsreserve, damit das Wort sicher auf eine Zeile passt.
        final room = constraints.maxWidth - 1;
        final size =
            style.fontSize ?? DefaultTextStyle.of(context).style.fontSize ?? 14;
        var scale = 1.0;
        var widest = widestWord(context, [text], style);
        // Der Buchstabenabstand schrumpft nicht mit: nachmessen.
        for (var i = 0; i < 4 && widest > room && scale > minScale; i++) {
          scale = max(minScale, scale * room / widest);
          fitted = style.copyWith(fontSize: size * scale);
          widest = widestWord(context, [text], fitted);
        }
      }
      return Text(text, style: fitted, textAlign: textAlign);
    },
  );
}
