import 'package:flutter_test/flutter_test.dart';
import 'package:learnwithleoni/data/models.dart';
import 'package:learnwithleoni/learn/answer_check.dart';
import 'package:learnwithleoni/learn/hints.dart';
import 'package:learnwithleoni/learn/kuma_phrases.dart';

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

  test('Kumachans Satzsammlung enthält jeden möglichen Tipp', () {
    final set = VocabSet.fromJson({
      'id': 'x',
      'title': 'X',
      'cards': [
        {
          'id': 'k',
          'term': 'der Käse',
          'translation': 'cheese',
          'example': 'Ich esse gern Käse.',
          'hint': 'Man macht ihn aus Milch.',
        },
      ],
      'cloze': [
        {
          'id': 'z',
          'text': 'Das ___ ist frisch.',
          'answers': ['Brot'],
          'hint': 'Man backt es.',
        },
      ],
      'fide': [
        {
          'id': 'f',
          'level': 'B1',
          'situation': 'S',
          'items': [
            {'id': 'f1', 'question': 'Q', 'text': 'T', 'hint': 'Hör gut zu.'},
          ],
        },
      ],
    });
    final all = kumaPhrases([set]);
    for (final h in [
      ...KumaLines.all,
      'Man macht ihn aus Milch.',
      'Ein Nomen mit „der“.',
      'Es beginnt mit „K“ und hat 4 Buchstaben.', // Kreuzworträtsel, ABC
      ...sentenceHints('Ich esse gern Käse.'), // Diktat
      'Man backt es.',
      'Es beginnt mit „B“ und hat 4 Buchstaben.', // Leonis Lückensatz
      'Hör gut zu.', // fide
    ]) {
      expect(all, contains(h));
    }
  });

  test('fide: freie Antwort mit Stichwörtern', () {
    expect(checkKeywords('um 7 Uhr', ['sieben|7|19']), isTrue);
    expect(checkKeywords('Um sieben.', ['sieben|7|19']), isTrue);
    expect(checkKeywords('um 17 Uhr', ['sieben|7|19']), isFalse);
    expect(checkKeywords('keine Nusse', ['Nüsse|Nuss']), isTrue);
    expect(
      checkKeywords('einen Schokoladenkuchen', ['Dessert|Kuchen']),
      isTrue,
    );
    expect(checkKeywords('Wein', ['Dessert|Kuchen']), isFalse);
    expect(checkKeywords('vor dem 20. April', ['20|zwanzig', 'April']), isTrue);
    expect(checkKeywords('am 20. Mai', ['20|zwanzig', 'April']), isFalse);
    expect(checkKeywords('', ['x']), isFalse);
  });
}
