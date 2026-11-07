import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Selbsteinschätzung nach einer Karte.
enum Grade { knew, almost, didNotKnow }

/// Lernstand einer Karte: Fach 1–5 (oder [Leitner.secure]) und nächster
/// Fälligkeitstag.
class CardState {
  const CardState({required this.box, required this.due});

  factory CardState.fromJson(Map<String, dynamic> j) =>
      CardState(box: j['b'] as int, due: DateTime.parse(j['d'] as String));

  final int box;

  /// Nur das Datum zählt (lokale Mitternacht).
  final DateTime due;

  /// Ganz sicher gelernt: kommt nicht mehr von selbst.
  bool get isSecure => box >= Leitner.secure;

  Map<String, dynamic> toJson() => {'b': box, 'd': _ymd(due)};
}

/// Leitner-System: 5 Fächer mit wachsenden Abständen, danach „sicher“.
///
/// Gewusst → ein Fach weiter, Abstand 1, 2, 4, 8, 16 Tage. Wer eine Karte nach
/// den 16 Tagen in Fach 5 noch weiss, kann sie sicher: Sie kommt in keiner
/// Lernsitzung mehr. Fast → gleiches Fach, morgen. Nicht gewusst → Fach 1.
abstract final class Leitner {
  static const int boxes = 5;

  /// Stufe nach Fach 5.
  static const int secure = 6;

  /// Abstand in Tagen nach dem Einsortieren in Fach 1–5.
  static const List<int> intervalDays = [1, 2, 4, 8, 16];

  static DateTime today([DateTime? now]) {
    final n = now ?? DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Neuer Lernstand nach einer Antwort. [current] == null: neue Karte (Fach 1).
  static CardState review(CardState? current, Grade grade, {DateTime? now}) {
    final box = (current?.box ?? 1).clamp(1, secure);
    final t = today(now);
    if (grade == Grade.knew && box >= boxes) {
      // Sicher: praktisch nie mehr fällig.
      return CardState(box: secure, due: DateTime(t.year + 10, t.month, t.day));
    }
    final newBox = switch (grade) {
      Grade.knew => box + 1,
      Grade.almost => box.clamp(1, boxes),
      Grade.didNotKnow => 1,
    };
    final days = grade == Grade.knew ? intervalDays[newBox - 1] : 1;
    return CardState(box: newBox, due: DateTime(t.year, t.month, t.day + days));
  }

  /// In wie vielen Tagen die Karte wiederkommt (0 = heute).
  static int daysUntil(CardState s, {DateTime? now}) =>
      // Runden: bei der Zeitumstellung hat ein Tag 23 oder 25 Stunden.
      (s.due.difference(today(now)).inHours / 24).round();
}

/// Zusammenfassung eines Sets für die Startseite.
class SetStats {
  const SetStats({
    required this.total,
    required this.learned,
    required this.learning,
    required this.due,
    this.secure = 0,
  });

  final int total;

  /// Ganz sicher (nach Fach 5).
  final int secure;

  /// Fach 4–5.
  final int learned;

  /// Fach 1–3.
  final int learning;

  /// Heute oder früher fällig.
  final int due;

  int get fresh => total - secure - learned - learning;
}

/// Lernstand eines Schülers, gespeichert nur auf dem Gerät.
class ProgressStore {
  ProgressStore._(this._prefs, this._code, this._states);

  static final Map<String, Future<ProgressStore>> _open = {};

  /// Eine gemeinsame Instanz pro Schüler, damit alle Seiten denselben Stand sehen.
  static Future<ProgressStore> open(String studentCode) =>
      _open.putIfAbsent(studentCode, () => _load(studentCode));

  @visibleForTesting
  static void resetCache() {
    _open.clear();
    PracticeDays._open.clear();
  }

  static Future<ProgressStore> _load(String studentCode) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(studentCode));
    final states = <String, CardState>{};
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        map.forEach(
          (k, v) => states[k] = CardState.fromJson(v as Map<String, dynamic>),
        );
      } on FormatException {
        // Beschädigter Stand: neu beginnen statt abstürzen.
      }
    }
    return ProgressStore._(prefs, studentCode, states);
  }

  final SharedPreferences _prefs;
  final String _code;
  final Map<String, CardState> _states;

  static String _key(String code) => 'progress/$code';
  static String _cardKey(VocabSet set, VocabCard card) =>
      '${set.id}/${card.id}';

  CardState? stateOf(VocabSet set, VocabCard card) =>
      _states[_cardKey(set, card)];

  Future<void> record(
    VocabSet set,
    VocabCard card,
    Grade grade, {
    DateTime? now,
  }) {
    final key = _cardKey(set, card);
    _states[key] = Leitner.review(_states[key], grade, now: now);
    return _prefs.setString(
      _key(_code),
      jsonEncode(_states.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  SetStats stats(VocabSet set, {DateTime? now}) {
    final t = Leitner.today(now);
    var secure = 0, learned = 0, learning = 0, due = 0;
    for (final card in set.cards) {
      final s = stateOf(set, card);
      if (s == null) continue;
      if (s.isSecure) {
        secure++;
        continue;
      }
      if (s.box >= 4) {
        learned++;
      } else {
        learning++;
      }
      if (!s.due.isAfter(t)) due++;
    }
    return SetStats(
      total: set.cards.length,
      secure: secure,
      learned: learned,
      learning: learning,
      due: due,
    );
  }
}

/// Lernserie: an wie vielen Tagen in Folge geübt wurde.
class PracticeDays {
  PracticeDays._(this._prefs, this._code, this._days);

  static final Map<String, Future<PracticeDays>> _open = {};

  static Future<PracticeDays> open(String studentCode) =>
      _open.putIfAbsent(studentCode, () => _load(studentCode));

  static Future<PracticeDays> _load(String studentCode) async {
    final prefs = await SharedPreferences.getInstance();
    final days = prefs.getStringList(_key(studentCode)) ?? const [];
    return PracticeDays._(prefs, studentCode, {...days});
  }

  final SharedPreferences _prefs;
  final String _code;
  final Set<String> _days;

  static String _key(String code) => 'days/$code';

  Future<void> markToday({DateTime? now}) async {
    if (_days.add(_ymd(Leitner.today(now)))) {
      // Nur die letzten 400 Tage behalten.
      final sorted = _days.toList()..sort();
      final keep = sorted.length > 400
          ? sorted.sublist(sorted.length - 400)
          : sorted;
      await _prefs.setStringList(_key(_code), keep);
    }
  }

  /// Serie bis heute; zählt auch, wenn heute noch nicht, aber gestern geübt wurde.
  int streak({DateTime? now}) {
    var day = Leitner.today(now);
    if (!_days.contains(_ymd(day))) {
      day = DateTime(day.year, day.month, day.day - 1);
    }
    var n = 0;
    while (_days.contains(_ymd(day))) {
      n++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return n;
  }
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
