import 'package:flutter_test/flutter_test.dart';
import 'package:learnwithleoni/learn/hints.dart';

void main() {
  test('Tipps: Umschreibung, Wortart, Anfangsbuchstabe – nie das Wort', () {
    final hints = wordHints(
      description: 'Ein Papier von der Ärztin.',
      term: 'das Rezept',
      answer: 'Rezept',
    );
    expect(hints, [
      'Ein Papier von der Ärztin.',
      'Ein Nomen mit „das“.',
      'Es beginnt mit „R“ und hat 6 Buchstaben.',
    ]);
    expect(hints.join(' '), isNot(contains('Rezept')));
  });

  test('Verb und ohne Umschreibung', () {
    expect(wordHints(term: 'gründen', answer: 'gründen'), [
      'Ein Verb – so steht es im Wörterbuch.',
      'Es beginnt mit „G“ und hat 7 Buchstaben.',
    ]);
  });

  test('Diktat-Tipps', () {
    final h = sentenceHints('Ich habe morgen einen Termin.');
    expect(h, contains('Der Satz hat 5 Wörter.'));
    expect(h.last, 'Er beginnt mit „Ich“.');
  });
}
