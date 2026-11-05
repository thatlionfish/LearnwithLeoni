import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:learnwithleoni/games/hangman/game.dart';
import 'package:learnwithleoni/games/hangman/words.dart';

void main() {
  group('HangmanGame', () {
    test('richtige und falsche Buchstaben', () {
      final g = HangmanGame(word: 'Igel', category: 'Tiere');
      expect(g.maskedWord, '_ _ _ _');
      expect(g.guess('e'), GuessResult.correct);
      expect(g.guess('E'), GuessResult.alreadyGuessed);
      expect(g.guess('X'), GuessResult.wrong);
      expect(g.guess('1'), GuessResult.ignored);
      expect(g.maskedWord, '_ _ E _');
      expect(g.mistakes, 1);
      expect(g.remainingAttempts, 5);
    });

    test('Gewinnen', () {
      final g = HangmanGame(word: 'KÄSE', category: 'x');
      for (final l in ['K', 'ä', 'S', 'E']) {
        g.guess(l);
      }
      expect(g.isWon, isTrue);
      expect(g.isOver, isTrue);
      expect(g.guess('Z'), GuessResult.ignored);
    });

    test('Verlieren nach 6 Fehlern', () {
      final g = HangmanGame(word: 'JUDO', category: 'Sport');
      for (final l in ['A', 'B', 'C', 'E', 'F']) {
        g.guess(l);
      }
      expect(g.isLost, isFalse);
      g.guess('G');
      expect(g.isLost, isTrue);
      expect(g.remainingAttempts, 0);
    });

    test('Tipp deckt Buchstaben auf und kostet ein Leben', () {
      final g = HangmanGame(word: 'ZEBRA', category: 'Tiere');
      final letter = g.useHint(Random(1));
      expect(letter, isNotNull);
      expect('ZEBRA'.contains(letter!), isTrue);
      expect(g.mistakes, 1);
      expect(g.hintsUsed, 1);
    });

    test('Tipp nicht möglich beim letzten Leben', () {
      final g = HangmanGame(word: 'ZEBRA', category: 'Tiere');
      for (final l in ['Q', 'W', 'T', 'U', 'I']) {
        g.guess(l);
      }
      expect(g.remainingAttempts, 1);
      expect(g.canUseHint, isFalse);
      expect(g.useHint(), isNull);
    });

    test('Zufallswort aus gewählter Kategorie, ohne Wiederholung', () {
      final rnd = Random(42);
      var last = '';
      for (var i = 0; i < 50; i++) {
        final g = HangmanGame.random(
          category: 'Länder',
          random: rnd,
          avoidWord: last,
        );
        expect(g.category, 'Länder');
        expect(wordCategories['Länder'], contains(g.word));
        expect(g.word, isNot(last));
        last = g.word;
      }
    });

    test('alle Wörter bestehen nur aus ratbaren Buchstaben', () {
      for (final words in wordCategories.values) {
        for (final w in words) {
          expect(w.split('').every(HangmanGame.isGuessable), isTrue, reason: w);
        }
      }
    });
  });
}
