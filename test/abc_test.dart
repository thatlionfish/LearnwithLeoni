import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:learnwithleoni/data/models.dart';
import 'package:learnwithleoni/games/abc/abc_game.dart';
import 'package:learnwithleoni/learn/answer_check.dart';

List<AbcHint> sharedHints() {
  final json = jsonDecode(
    File('web/data/abc/hints.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return [
    for (final h in json['hints'] as List)
      AbcHint.fromJson(h as Map<String, dynamic>),
  ];
}

void main() {
  test('Hinweisdatei ist gültig: jede Antwort passt zu ihrem Buchstaben', () {
    final hints = sharedHints();
    expect(hints.length, greaterThan(50));
    for (final h in hints) {
      expect(h.answers, isNotEmpty);
      expect(h.translations['en'], isNotNull, reason: h.clue);
      for (final a in h.answers) {
        expect(abcLetter(a), h.letter, reason: '$a bei „${h.clue}“');
      }
    }
  });

  test('Für die Mischung gibt es mehrere spielbare Buchstaben', () {
    final letters = availableLetters(sharedHints(), {...AbcTopic.values});
    expect(letters, containsAll(['B', 'F', 'G', 'M', 'R', 'S', 'Z']));
  });

  test('abcLetter ohne Artikel und Umlaut', () {
    expect(abcLetter('der Käse'), 'K');
    expect(abcLetter('Österreich'), 'O');
  });

  test('Runde: richtig, fast richtig, falscher Buchstabe, weiter', () {
    final hints = [
      const AbcHint(
        topic: AbcTopic.food,
        clue: 'Käsegericht',
        answers: ['Fondue'],
      ),
      const AbcHint(
        topic: AbcTopic.culture,
        clue: 'Währung',
        answers: ['Franken'],
      ),
      const AbcHint(topic: AbcTopic.culture, clue: 'Wind', answers: ['Föhn']),
      const AbcHint(
        topic: AbcTopic.people,
        clue: 'Tennis',
        answers: ['Federer'],
      ),
      const AbcHint(
        topic: AbcTopic.food,
        clue: 'anderer Buchstabe',
        answers: ['Rösti'],
      ),
    ];
    final round = AbcRound(
      letter: 'F',
      allHints: hints,
      topics: {...AbcTopic.values},
      random: Random(1),
    );
    expect(round.total, 4);
    expect(round.goal, 4);
    final answers = {for (final h in hints) h.clue: h.answers.first};

    // Erste Antwort richtig
    final a = round.answer(answers[round.current!.clue]!);
    expect(a.result, AnswerResult.correct);
    // Zweite mit Tippfehler
    final target = answers[round.current!.clue]!;
    final typo = target.length > 5
        ? '${target.substring(0, target.length - 1)}x'
        : target;
    final b = round.answer(typo);
    expect(b.correct, isTrue);
    // Dritte: falscher Anfangsbuchstabe
    final c = round.answer('Rösti');
    expect(c.correct, isFalse);
    round.skip();
    expect(round.isDone, isTrue);
    expect(round.score, 2);
  });

  test('Eigene Wörter werden zu Hinweisen', () {
    const set = VocabSet(
      id: 's',
      title: 'S',
      titleTranslation: '',
      variety: Variety.de,
      published: true,
      cards: [VocabCard(id: 'k', term: 'der Käse', translation: 'cheese')],
    );
    final h = vocabHints([set]).single;
    expect(h.letter, 'K');
    expect(h.clue, 'cheese');
    expect(h.answers, ['Käse']);
  });
}
