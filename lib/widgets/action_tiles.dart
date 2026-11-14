import 'dart:math';

import 'package:flutter/material.dart';

import '../ui/organic.dart';

/// Eine Kachel: Beschriftung, Symbol, Ziel.
typedef ActionTile = ({String label, IconData icon, VoidCallback onTap});

/// Kacheln mit Symbol und Beschriftung (Übungen eines Sets, Spiele).
///
/// Alle Kacheln einer Gruppe sind gleich breit, mindestens [minWidth]. Ist ein
/// Wort zu lang, z. B. „Kreuzworträtsel“, werden alle breiter – so wird nie
/// mitten im Wort umgebrochen. Höchstens so breit wie der Platz.
class ActionTiles extends StatelessWidget {
  const ActionTiles({
    super.key,
    required this.tiles,
    this.seed = 80,
    this.minWidth = 176,
    this.spacing = 10,
    this.iconSize = 22,
    this.gap = 10,
    this.padding = const EdgeInsets.all(16),
  });

  final List<ActionTile> tiles;

  /// Form der ersten Kachel, die weiteren zählen hoch.
  final int seed;
  final double minWidth;
  final double spacing;
  final double iconSize;

  /// Abstand zwischen Symbol und Text.
  final double gap;
  final EdgeInsets padding;

  /// Breite des längsten Worts aller Beschriftungen.
  double _widestWord(BuildContext context, TextStyle? style) {
    var widest = 0.0;
    for (final tile in tiles) {
      for (final word in tile.label.split(RegExp(r'\s+'))) {
        if (word.isEmpty) continue;
        final painter = TextPainter(
          text: TextSpan(text: word, style: style),
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

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleSmall;
    // +2: Rundungsreserve, damit das längste Wort sicher auf eine Zeile passt.
    final need =
        padding.horizontal +
        iconSize +
        gap +
        _widestWord(context, style).ceilToDouble() +
        2;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wanted = max(minWidth, need);
        final width = constraints.hasBoundedWidth
            ? min(wanted, constraints.maxWidth)
            : wanted;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final (i, tile) in tiles.indexed)
              SizedBox(
                width: width,
                child: OrganicCard(
                  seed: seed + i,
                  onTap: tile.onTap,
                  padding: padding,
                  child: Row(
                    children: [
                      Icon(tile.icon, size: iconSize),
                      SizedBox(width: gap),
                      Expanded(child: Text(tile.label, style: style)),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
