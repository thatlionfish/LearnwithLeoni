import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnwithleoni/ui/theme.dart';
import 'package:learnwithleoni/widgets/action_tiles.dart';

/// Kacheln in einer Spalte so breit wie ein schmales Handy (375 px minus Rand).
Future<void> pumpTiles(WidgetTester tester, List<String> labels) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLeoTheme(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 335,
            child: ActionTiles(
              tiles: [
                for (final l in labels)
                  (label: l, icon: Icons.hearing_rounded, onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Steht [word] in der Beschriftung [label] ganz auf einer Zeile?
bool onOneLine(WidgetTester tester, String label, String word) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
  final start = label.indexOf(word);
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: start + word.length),
  );
  return boxes.map((b) => b.top.round()).toSet().length == 1;
}

void main() {
  testWidgets('Langes Wort wird nicht mitten im Wort getrennt', (tester) async {
    await pumpTiles(tester, ['Diktat', 'Impressionismus in Deutschland']);
    expect(
      onOneLine(tester, 'Impressionismus in Deutschland', 'Impressionismus'),
      isTrue,
    );
    expect(
      onOneLine(tester, 'Impressionismus in Deutschland', 'Deutschland'),
      isTrue,
    );
  });

  testWidgets('Alle Kacheln einer Gruppe sind gleich breit', (tester) async {
    await pumpTiles(tester, ['Diktat', 'Kreuzworträtsel']);
    expect({
      for (final l in ['Diktat', 'Kreuzworträtsel']) tileWidth(tester, l),
    }, hasLength(1));
    expect(tileWidth(tester, 'Diktat'), greaterThan(176));
    expect(onOneLine(tester, 'Kreuzworträtsel', 'Kreuzworträtsel'), isTrue);
  });

  testWidgets('Kurze Wörter: Kacheln bleiben so schmal wie bisher', (
    tester,
  ) async {
    await pumpTiles(tester, ['Diktat', 'Quiz']);
    expect(tileWidth(tester, 'Diktat'), 176);
  });

  testWidgets('Nie breiter als der Platz', (tester) async {
    await pumpTiles(tester, ['Donaudampfschifffahrtsgesellschaft']);
    expect(tileWidth(tester, 'Donaudampfschifffahrtsgesellschaft'), 335);
  });
}

/// Breite der Kachel, in der [label] steht.
double tileWidth(WidgetTester tester, String label) => tester
    .getSize(
      find
          .ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate(
              (w) => w is SizedBox && w.width != null,
            ),
          )
          .first,
    )
    .width;
