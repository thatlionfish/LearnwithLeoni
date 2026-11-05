import 'dart:math';

import '../data/models.dart';
import 'answer_check.dart';

/// Übungsarten, wie sie in der Adresse stehen: `#/s/<code>/ueben/<typ>`.
enum ExerciseType {
  choice('auswahl'),
  match('zuordnen'),
  cloze('luecken'),
  dictation('diktat'),
  listening('hoeren'),
  crossword('kreuzwort');

  const ExerciseType(this.slug);
  final String slug;

  static ExerciseType? fromSlug(String s) {
    for (final t in values) {
      if (t.slug == s) return t;
    }
    return null;
  }
}

/// Eine Frage in einer Quiz-Übung: entweder Auswahl oder freie Eingabe.
class QuizItem {
  const QuizItem({
    required this.id,
    required this.accepted,
    this.prompt,
    this.sentence,
    this.speak,
    this.audio,
    this.options = const [],
    this.translation,
    this.explanation,
  });

  final String id;

  /// Großes Wort oben (z. B. bei Multiple Choice).
  final String? prompt;

  /// Satz mit `___` als Lücke.
  final String? sentence;

  /// Text, der vorgelesen wird (Diktat).
  final String? speak;

  /// Audiodatei relativ zum Schülerordner.
  final String? audio;

  /// Leer = freie Eingabe.
  final List<String> options;

  /// Gültige Antworten, die erste ist die Musterlösung.
  final List<String> accepted;

  /// Übersetzung des Satzes oder Wortes, nach dem Antworten gezeigt.
  final String? translation;
  final String? explanation;

  bool get isChoice => options.isNotEmpty;
}

/// Multiple Choice: deutsches Wort → richtige Übersetzung aus vier.
List<QuizItem> choiceItems(
  VocabSet set, {
  List<VocabCard> extraDistractors = const [],
  Random? random,
  int max = 10,
}) {
  final rnd = random ?? Random();
  final pool = [...set.cards, ...extraDistractors];
  final cards = [...set.cards]..shuffle(rnd);
  return [
    for (final c in cards.take(max))
      () {
        final others = [
          ...{
            for (final o in pool)
              if (o.translation != c.translation) o.translation,
          },
        ]..shuffle(rnd);
        final options = [c.translation, ...others.take(3)]..shuffle(rnd);
        return QuizItem(
          id: c.id,
          prompt: c.term,
          options: options,
          accepted: [c.translation],
          translation: c.example,
        );
      }(),
  ];
}

/// Beispielsatz mit Lücke (`___`) an der Stelle des Kartenworts – auch
/// gebeugt, z. B. „leuchtende“ bei „leuchtend“. `null`, wenn das Wort im Satz
/// nicht vorkommt. [found] ist die Form, die im Satz steht.
({String sentence, String found})? gapInExample(VocabCard c) {
  final ex = c.example;
  if (ex == null) return null;
  final word = stripArticle(c.term);
  final m = RegExp(
    '(?<![A-Za-zÄÖÜäöüß])${RegExp.escape(word)}[A-Za-zÄÖÜäöüß]*',
    caseSensitive: false,
  ).firstMatch(ex);
  if (m == null) return null;
  return (
    sentence: ex.replaceRange(m.start, m.end, '___'),
    found: ex.substring(m.start, m.end),
  );
}

/// Lückentext: Leonis Lückensätze plus automatisch aus den Beispielsätzen.
List<QuizItem> clozeItems(VocabSet set, {Random? random, int max = 10}) {
  final rnd = random ?? Random();
  final items = <QuizItem>[
    for (final c in set.cloze)
      QuizItem(
        id: c.id,
        sentence: c.text,
        options: [...c.options]..shuffle(rnd),
        accepted: c.answers,
        translation: c.translation,
      ),
  ];
  final words = [for (final c in set.cards) stripArticle(c.term)];
  for (final c in set.cards) {
    final gap = gapInExample(c);
    if (gap == null) continue;
    final word = stripArticle(c.term);
    final found = gap.found;
    final distractors = [
      for (final w in words)
        if (w.toLowerCase() != word.toLowerCase()) w,
    ]..shuffle(rnd);
    items.add(
      QuizItem(
        id: 'auto-${c.id}',
        sentence: gap.sentence,
        options: [found, ...distractors.take(2)]..shuffle(rnd),
        accepted: [found],
        translation: c.exampleTranslation,
      ),
    );
  }
  items.shuffle(rnd);
  return items.take(max).toList();
}

/// Diktat: Beispielsatz anhören und aufschreiben.
List<QuizItem> dictationItems(VocabSet set, {Random? random, int max = 6}) {
  final rnd = random ?? Random();
  final items = [
    for (final c in set.cards)
      if (c.example != null)
        QuizItem(
          id: c.id,
          speak: c.example,
          accepted: [c.example!],
          translation: c.exampleTranslation,
        ),
  ]..shuffle(rnd);
  return items.take(max).toList();
}

/// Fragen zu einem Hörtext.
List<QuizItem> listeningItems(ListeningText text) => [
  for (final (i, q) in text.questions.indexed)
    QuizItem(
      id: '${text.id}-$i',
      prompt: q.question,
      options: q.options,
      accepted: [q.options[q.answer]],
      translation: q.translation,
    ),
];

/// Runden für „Zuordnen“: je bis zu 5 Paare Wort ↔ Übersetzung.
List<List<VocabCard>> matchRounds(
  VocabSet set, {
  Random? random,
  int size = 5,
}) {
  final cards = [...set.cards]..shuffle(random ?? Random());
  return [
    for (var i = 0; i < cards.length; i += size)
      cards.sublist(i, min(i + size, cards.length)),
  ].where((r) => r.length >= 2).toList();
}

/// Welche Übungen ein Set anbieten kann.
List<ExerciseType> availableExercises(VocabSet set) => [
  if (set.cards.length >= 2) ExerciseType.choice,
  if (set.cards.length >= 2) ExerciseType.match,
  if (set.cloze.isNotEmpty || set.cards.any((c) => c.example != null))
    ExerciseType.cloze,
  if (set.cards.any((c) => c.example != null) && set.variety == Variety.de)
    ExerciseType.dictation,
  if (set.listening.isNotEmpty) ExerciseType.listening,
  if (set.cards.length >= 3) ExerciseType.crossword,
];
