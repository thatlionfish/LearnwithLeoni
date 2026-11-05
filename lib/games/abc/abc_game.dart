import 'dart:math';

import '../../data/models.dart';
import '../../learn/answer_check.dart';

/// Themen im ABC-Radio.
enum AbcTopic {
  vocab,
  culture,
  people,
  food,
  traditions;

  static AbcTopic? parse(Object? s) {
    for (final t in values) {
      if (t.name == s) return t;
    }
    return null;
  }
}

/// Ein Hinweis: Umschreibung → Wort mit dem Buchstaben.
class AbcHint {
  const AbcHint({
    required this.topic,
    required this.clue,
    required this.answers,
    this.translations = const {},
    this.card,
  });

  factory AbcHint.fromJson(Map<String, dynamic> j) => AbcHint(
    topic: AbcTopic.parse(j['topic']) ?? AbcTopic.culture,
    clue: j['clue'] as String,
    answers: [for (final a in j['answers'] as List) a as String],
    translations: {
      for (final MapEntry(:key, :value) in j.entries)
        if (key.length == 2 && value is String) key: value,
    },
  );

  final AbcTopic topic;

  /// Umschreibung auf Deutsch (bei eigenen Wörtern: die Übersetzung).
  final String clue;

  /// Gültige Antworten, die erste ist die Musterlösung.
  final List<String> answers;

  /// Übersetzungen der Umschreibung nach Sprachcode.
  final Map<String, String> translations;

  /// Bei eigenen Wörtern die Karte dazu.
  final VocabCard? card;

  String get letter => abcLetter(answers.first);
}

/// Anfangsbuchstabe ohne Umlaut: „Österreich“ → „O“.
String abcLetter(String word) {
  final w = stripArticle(word.trim());
  if (w.isEmpty) return '';
  final c = w[0].toUpperCase();
  return switch (c) {
    'Ä' => 'A',
    'Ö' => 'O',
    'Ü' => 'U',
    _ => c,
  };
}

/// Hinweise aus den Karten des Schülers: Übersetzung → deutsches Wort.
List<AbcHint> vocabHints(List<VocabSet> sets) => [
  for (final s in sets)
    for (final c in s.cards)
      if (abcLetter(c.term).isNotEmpty)
        AbcHint(
          topic: AbcTopic.vocab,
          clue: c.translation,
          answers: [stripArticle(c.term)],
          card: c,
        ),
];

/// Buchstaben, für die es mindestens [min] Hinweise in den Themen gibt.
List<String> availableLetters(
  List<AbcHint> hints,
  Set<AbcTopic> topics, {
  int min = 6,
}) {
  final counts = <String, int>{};
  for (final h in hints) {
    if (topics.contains(h.topic)) {
      counts[h.letter] = (counts[h.letter] ?? 0) + 1;
    }
  }
  return [
    for (final e in counts.entries)
      if (e.value >= min) e.key,
  ]..sort();
}

/// Was mit einem Hinweis passiert ist.
class AbcResult {
  const AbcResult(this.hint, {this.given, this.result});
  final AbcHint hint;
  final String? given;

  /// null = übersprungen.
  final AnswerResult? result;

  bool get correct =>
      result == AnswerResult.correct || result == AnswerResult.close;
}

/// Eine Runde: ein Buchstabe, eine Sendezeit, Hinweis um Hinweis.
class AbcRound {
  AbcRound({
    required this.letter,
    required List<AbcHint> allHints,
    required Set<AbcTopic> topics,
    Random? random,
  }) : _random = random ?? Random() {
    _queue = [
      for (final h in allHints)
        if (h.letter == letter && topics.contains(h.topic)) h,
    ]..shuffle(_random);
    total = _queue.length;
    _sameLetter = [
      for (final h in allHints)
        if (h.letter == letter) h.answers.first,
    ];
  }

  static const int defaultGoal = 12;

  final String letter;
  final Random _random;
  late final List<AbcHint> _queue;
  late final List<String> _sameLetter;
  late final int total;
  final List<AbcResult> results = [];

  int get goal => min(defaultGoal, total);
  int get score => results.where((r) => r.correct).length;
  bool get isDone => _queue.isEmpty;
  AbcHint? get current => _queue.isEmpty ? null : _queue.first;

  /// Drei Antworten zur Auswahl (für Anfänger).
  List<String> options() {
    final h = current;
    if (h == null) return const [];
    final others = [
      for (final a in _sameLetter)
        if (normalizeAnswer(a) != normalizeAnswer(h.answers.first)) a,
    ]..shuffle(_random);
    return [h.answers.first, ...others.take(2)]..shuffle(_random);
  }

  /// Antwort prüfen: muss passen und mit dem Buchstaben anfangen.
  AbcResult answer(String input) {
    final h = _queue.removeAt(0);
    var r = checkAnswer(input, h.answers);
    if (r != AnswerResult.wrong && abcLetter(input) != letter) {
      r = AnswerResult.wrong;
    }
    final res = AbcResult(h, given: input, result: r);
    results.add(res);
    return res;
  }

  /// „Weiter“: Hinweis überspringen.
  AbcResult skip() {
    final res = AbcResult(_queue.removeAt(0));
    results.add(res);
    return res;
  }

  /// Zeit abgelaufen: der Rest bleibt für die Auswertung unbeantwortet.
  List<AbcHint> get remaining => List.unmodifiable(_queue);
}
