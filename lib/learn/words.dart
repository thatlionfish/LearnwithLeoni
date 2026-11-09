import '../data/models.dart';
import 'answer_check.dart';

/// Ein Wort mit seinem Set (Lernstand und Stimme hängen am Set).
typedef WordEntry = ({VocabSet set, VocabCard card});

/// Kleinbuchstaben, ä wie a, ß wie ss – zum Sortieren und Suchen.
String _fold(String s) => s
    .toLowerCase()
    .replaceAll('ä', 'a')
    .replaceAll('ö', 'o')
    .replaceAll('ü', 'u')
    .replaceAll('ß', 'ss');

/// Alle Wörter aus [sets] von A bis Z, der Artikel zählt nicht mit.
List<WordEntry> allWords(Iterable<VocabSet> sets) {
  final words = <WordEntry>[
    for (final set in sets)
      for (final card in set.cards) (set: set, card: card),
  ];
  String key(WordEntry w) => _fold(stripArticle(w.card.term));
  words.sort((a, b) => key(a).compareTo(key(b)));
  return words;
}

/// Passt das Wort zur Suche? Sucht auch in der Übersetzung.
bool wordMatches(WordEntry w, String query) {
  final q = _fold(query.trim());
  if (q.isEmpty) return true;
  final c = w.card;
  return [
    c.term,
    c.translation,
    ?c.plural,
    ?c.alt,
  ].any((s) => _fold(s).contains(q));
}
