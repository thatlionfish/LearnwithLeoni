import '../data/leitner.dart';
import '../data/models.dart';

/// Eine Karte in einer Lernsitzung.
class SessionItem {
  const SessionItem(this.set, this.card);
  final VocabSet set;
  final VocabCard card;

  String get key => '${set.id}/${card.id}';
}

/// Moment, in dem Leoni kurz auftaucht.
enum LeoniMoment { streak, encourage }

/// Reine Ablauflogik einer Lernsitzung, ohne Oberfläche.
///
/// - Zuerst fällige Karten (die ältesten zuerst), dann bis zu [maxNew] neue.
/// - Nur die erste Antwort pro Karte zählt fürs Leitner-System.
/// - „Nicht gewusst“ kommt in derselben Sitzung noch einmal (höchstens 2×).
class LearnSession {
  LearnSession._(this._queue, this.total);

  static const int maxNew = 10;
  static const int maxRepeats = 2;

  factory LearnSession.build(
    List<VocabSet> sets,
    ProgressStore progress, {
    DateTime? now,
    int newLimit = maxNew,
  }) {
    final today = Leitner.today(now);
    final due = <(SessionItem, DateTime)>[];
    final fresh = <SessionItem>[];
    for (final set in sets) {
      for (final card in set.cards) {
        final state = progress.stateOf(set, card);
        if (state == null) {
          fresh.add(SessionItem(set, card));
        } else if (!state.isSecure && !state.due.isAfter(today)) {
          due.add((SessionItem(set, card), state.due));
        }
      }
    }
    due.sort((a, b) => a.$2.compareTo(b.$2));
    final queue = [for (final (item, _) in due) item, ...fresh.take(newLimit)];
    return LearnSession._(queue, queue.length);
  }

  final List<SessionItem> _queue;

  /// Anzahl verschiedener Karten zu Beginn.
  final int total;

  final Set<String> _answered = {};
  final Map<String, int> _repeats = {};
  int _correctRun = 0;
  int _wrongRun = 0;

  int knew = 0;
  int almost = 0;
  int notKnown = 0;

  bool get isDone => _queue.isEmpty;
  SessionItem? get current => _queue.isEmpty ? null : _queue.first;

  /// Wie viele verschiedene Karten schon beantwortet sind.
  int get answeredCount => _answered.length;

  /// Kommt die Karte in dieser Sitzung noch einmal?
  bool isQueued(SessionItem item) => _queue.any((i) => i.key == item.key);

  /// Verarbeitet eine Antwort. Gibt zurück, ob Leoni etwas sagen soll.
  /// [record] wird nur bei der ersten Antwort pro Karte aufgerufen.
  LeoniMoment? answer(
    Grade grade,
    void Function(SessionItem item, Grade grade) record,
  ) {
    final item = _queue.removeAt(0);
    if (_answered.add(item.key)) {
      record(item, grade);
      switch (grade) {
        case Grade.knew:
          knew++;
        case Grade.almost:
          almost++;
        case Grade.didNotKnow:
          notKnown++;
      }
    }
    if (grade == Grade.didNotKnow) {
      final n = _repeats[item.key] ?? 0;
      if (n < maxRepeats) {
        _repeats[item.key] = n + 1;
        // Nicht direkt wieder, sondern ein paar Karten später.
        _queue.insert(_queue.length.clamp(0, 3), item);
      }
    }

    if (grade == Grade.knew) {
      _correctRun++;
      _wrongRun = 0;
      if (_correctRun % 3 == 0) return LeoniMoment.streak;
    } else if (grade == Grade.didNotKnow) {
      _wrongRun++;
      _correctRun = 0;
      if (_wrongRun == 2) return LeoniMoment.encourage;
    } else {
      _correctRun = 0;
    }
    return null;
  }
}
