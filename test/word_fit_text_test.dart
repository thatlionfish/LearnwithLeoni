import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnwithleoni/ui/theme.dart';
import 'package:learnwithleoni/widgets/word_fit_text.dart';

/// Wie eine Kachel in „Zuordnen“ auf einem schmalen Handy: etwa 130 px Platz.
Future<void> pumpFit(WidgetTester tester, String text, {double width = 130}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: buildLeoTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: WordFitText(text, style: serif(18, weight: 440)),
            ),
          ),
        ),
      ),
    );

double fontSize(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!.fontSize!;

/// Steht [word] in [text] ganz auf einer Zeile?
bool onOneLine(WidgetTester tester, String text, String word) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  final start = text.indexOf(word);
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: start + word.length),
  );
  return boxes.map((b) => b.top.round()).toSet().length == 1;
}

void main() {
  testWidgets('Langes Wort wird kleiner statt mitten im Wort getrennt', (
    tester,
  ) async {
    // Die Testschrift ist etwa doppelt so breit wie die echte, darum 220 px
    // statt der 130 px einer Kachel auf dem Handy.
    await pumpFit(tester, 'der Immobilienmakler', width: 220);
    expect(fontSize(tester, 'der Immobilienmakler'), lessThan(18));
    expect(
      onOneLine(tester, 'der Immobilienmakler', 'Immobilienmakler'),
      isTrue,
    );
  });

  testWidgets('Kurze Wörter behalten ihre Grösse', (tester) async {
    await pumpFit(tester, 'die Heizung', width: 300);
    expect(fontSize(tester, 'die Heizung'), 18);
  });

  testWidgets('Japanisch darf umbrechen und wird nicht verkleinert', (
    tester,
  ) async {
    await pumpFit(tester, '引っ越していく、よそへ移る');
    expect(fontSize(tester, '引っ越していく、よそへ移る'), 18);
  });

  testWidgets('Nie kleiner als 60 Prozent', (tester) async {
    await pumpFit(
      tester,
      'Donaudampfschifffahrtsgesellschaftskapitän',
      width: 60,
    );
    expect(
      fontSize(tester, 'Donaudampfschifffahrtsgesellschaftskapitän'),
      closeTo(18 * 0.6, 0.01),
    );
  });
}
