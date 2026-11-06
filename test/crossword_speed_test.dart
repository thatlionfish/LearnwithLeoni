import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:learnwithleoni/data/models.dart';
import 'package:learnwithleoni/learn/crossword.dart';
import 'package:learnwithleoni/learn/exercises.dart';

/// Das Kreuzworträtsel muss auch auf einem langsamen Handy sofort stehen.
void main() {
  test('Irenes Hör-Kreuzworträtsel wird schnell erzeugt', () {
    final set = VocabSet.fromJson(
      jsonDecode(
        File('web/data/students/t7vrtmj4/sets/expressionismus.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>,
    );
    final entries = [
      for (final c in set.cards)
        if (gapInExample(c) case final gap?)
          (answer: toGridWord(gap.found), clue: gap.sentence, payload: c),
    ];
    final sw = Stopwatch()..start();
    for (var i = 0; i < 5; i++) {
      final cw = buildCrossword(entries, maxWords: 10, random: Random(i));
      expect(cw.words.length, greaterThanOrEqualTo(6));
    }
    // Fünf Rätsel in klar unter 0,3 s (Handys sind 5–10× langsamer).
    expect(
      sw.elapsedMilliseconds,
      lessThan(300),
      reason: '${sw.elapsedMilliseconds} ms',
    );
  });
}
