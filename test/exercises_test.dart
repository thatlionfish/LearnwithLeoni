import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:learnwithleoni/data/models.dart';
import 'package:learnwithleoni/learn/answer_check.dart';
import 'package:learnwithleoni/learn/crossword.dart';
import 'package:learnwithleoni/learn/exercises.dart';

const set = VocabSet(
  id: 'arzt',
  title: 'Beim Arzt',
  titleTranslation: '',
  variety: Variety.de,
  published: true,
  cards: [
    VocabCard(
      id: 'termin',
      term: 'der Termin',
      translation: 'appointment',
      example: 'Ich habe morgen einen Termin.',
      exampleTranslation: 'I have an appointment tomorrow.',
    ),
    VocabCard(id: 'fieber', term: 'das Fieber', translation: 'fever'),
    VocabCard(id: 'rezept', term: 'das Rezept', translation: 'prescription'),
    VocabCard(id: 'apotheke', term: 'die Apotheke', translation: 'pharmacy'),
    VocabCard(id: 'praxis', term: 'die Praxis', translation: 'practice'),
    VocabCard(id: 'kasse', term: 'die Kasse', translation: 'checkout'),
  ],
);

void main() {
  group('checkAnswer', () {
    test('Groß-/Kleinschreibung, Satzzeichen und ß/ss sind egal', () {
      expect(checkAnswer(' termin ', ['Termin']), AnswerResult.correct);
      expect(
        checkAnswer('Ich habe Zeit', ['Ich habe Zeit.']),
        AnswerResult.correct,
      );
      expect(checkAnswer('Strasse', ['Straße']), AnswerResult.correct);
    });

    test('kleine Tippfehler gelten als fast richtig', () {
      expect(checkAnswer('Aphoteke', ['Apotheke']), AnswerResult.close);
      expect(checkAnswer('Kaese', ['Käse']), AnswerResult.close);
    });

    test('kurze Wörter müssen genau stimmen', () {
      expect(checkAnswer('Brod', ['Brot']), AnswerResult.wrong);
      expect(checkAnswer('', ['Brot']), AnswerResult.wrong);
    });

    test('mehrere gültige Schreibweisen', () {
      expect(
        checkAnswer('Grüessech', ['Grüezi', 'Grüessech']),
        AnswerResult.correct,
      );
    });
  });

  test('stripArticle', () {
    expect(stripArticle('der Termin'), 'Termin');
    expect(stripArticle('krank'), 'krank');
  });

  group('Kreuzworträtsel', () {
    final entries = [
      for (final c in set.cards)
        (answer: toGridWord(c.term), clue: c.translation, payload: c),
    ];

    test(
      'Wörter kreuzen sich korrekt und überlappen nicht widersprüchlich',
      () {
        final cw = buildCrossword(entries, random: Random(1));
        expect(cw.words.length, greaterThanOrEqualTo(4));
        final grid = <(int, int), String>{};
        for (final w in cw.words) {
          for (var i = 0; i < w.length; i++) {
            final cell = w.cell(i);
            expect(cell.$1, inInclusiveRange(0, cw.rows - 1));
            expect(cell.$2, inInclusiveRange(0, cw.cols - 1));
            final prev = grid[cell];
            if (prev != null) expect(prev, w.answer[i]);
            grid[cell] = w.answer[i];
          }
        }
        // Jedes Wort (ausser dem ersten) kreuzt mindestens ein anderes.
        for (final w in cw.words.skip(1)) {
          expect(
            cw.words.any(
              (o) =>
                  o != w &&
                  List.generate(
                    w.length,
                    w.cell,
                  ).any((c) => o.contains(c.$1, c.$2)),
            ),
            isTrue,
          );
        }
      },
    );

    test('toGridWord', () {
      expect(toGridWord('der Käse'), 'KÄSE');
      expect(toGridWord('die Straße'), 'STRASSE');
    });
  });

  test('Multiple Choice hat 4 verschiedene Optionen mit der richtigen', () {
    final items = choiceItems(set, random: Random(2));
    expect(items.length, set.cards.length);
    for (final i in items) {
      expect(i.options.toSet().length, 4);
      expect(i.options, contains(i.accepted.first));
    }
  });

  test('Lücke im Beispielsatz – auch bei gebeugten Formen', () {
    const c = VocabCard(
      id: 'l',
      term: 'leuchtend',
      translation: 'bright',
      example: 'Die Expressionisten liebten leuchtende Farben.',
    );
    final gap = gapInExample(c)!;
    expect(gap.sentence, 'Die Expressionisten liebten ___ Farben.');
    expect(gap.found, 'leuchtende');
    expect(toGridWord(gap.found), 'LEUCHTENDE');
    expect(
      gapInExample(
        const VocabCard(
          id: 'x',
          term: 'das Rad',
          translation: 'x',
          example: 'Die Fahrräder.',
        ),
      ),
      isNull, // nur am Wortanfang, nicht mitten im Wort
    );
  });

  test('Lückentext aus Beispielsätzen', () {
    final items = clozeItems(set, random: Random(3));
    expect(items.single.sentence, 'Ich habe morgen einen ___.');
    expect(items.single.accepted, ['Termin']);
  });

  test('Übungsangebot eines Sets', () {
    expect(
      availableExercises(set),
      containsAll([
        ExerciseType.choice,
        ExerciseType.match,
        ExerciseType.cloze,
        ExerciseType.crossword,
      ]),
    );
    expect(availableExercises(set), isNot(contains(ExerciseType.listening)));
  });
}
