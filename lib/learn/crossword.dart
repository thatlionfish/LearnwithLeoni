import 'dart:math';

import 'answer_check.dart';

enum Dir { across, down }

/// Ein eingetragenes Wort im Gitter.
class PlacedWord {
  const PlacedWord({
    required this.answer,
    required this.clue,
    required this.row,
    required this.col,
    required this.dir,
    required this.number,
    this.payload,
  });

  /// Großbuchstaben, ohne Leerzeichen, ß als SS.
  final String answer;
  final String clue;
  final int row;
  final int col;
  final Dir dir;
  final int number;

  /// Beliebige Zusatzdaten, z. B. die Karte.
  final Object? payload;

  int get length => answer.length;

  (int, int) cell(int i) => dir == Dir.across ? (row, col + i) : (row + i, col);

  bool contains(int r, int c) => dir == Dir.across
      ? r == row && c >= col && c < col + length
      : c == col && r >= row && r < row + length;

  int indexOf(int r, int c) => dir == Dir.across ? c - col : r - row;
}

class Crossword {
  const Crossword({
    required this.rows,
    required this.cols,
    required this.words,
  });

  final int rows;
  final int cols;
  final List<PlacedWord> words;

  /// Lösungsbuchstabe pro Zelle (null = Block).
  List<List<String?>> get solution {
    final g = List.generate(rows, (_) => List<String?>.filled(cols, null));
    for (final w in words) {
      for (var i = 0; i < w.length; i++) {
        final (r, c) = w.cell(i);
        g[r][c] = w.answer[i];
      }
    }
    return g;
  }

  /// Wörter, die durch die Zelle laufen.
  List<PlacedWord> wordsAt(int r, int c) => [
    for (final w in words)
      if (w.contains(r, c)) w,
  ];

  /// Nummer, die in der Zelle angezeigt wird (Wortanfang), sonst null.
  int? numberAt(int r, int c) {
    for (final w in words) {
      if (w.row == r && w.col == c) return w.number;
    }
    return null;
  }
}

/// Eingabe → Gitterbuchstaben: „der Käse“ → „KÄSE“.
String toGridWord(String term) =>
    stripArticle(term)
        .toUpperCase()
        .replaceAll('ß', 'SS')
        .replaceAll(RegExp(r'[^A-ZÄÖÜ]'), '');

/// Baut ein möglichst kompaktes Kreuzworträtsel.
///
/// Probiert mehrere zufällige Reihenfolgen und nimmt das Ergebnis mit den
/// meisten Wörtern (bei Gleichstand das kleinste Gitter).
Crossword buildCrossword(
  List<({String answer, String clue, Object? payload})> entries, {
  int attempts = 40,
  int maxWords = 12,
  Random? random,
}) {
  final rnd = random ?? Random();
  final cleaned = [
    for (final e in entries)
      if (e.answer.length >= 2) e,
  ];
  _Grid? best;
  for (var a = 0; a < attempts; a++) {
    final order = [...cleaned]..shuffle(rnd);
    order.sort((x, y) => y.answer.length.compareTo(x.answer.length));
    // Etwas Zufall auch bei gleicher Länge behalten:
    final grid = _Grid();
    for (final e in order.take(maxWords * 2)) {
      if (grid.placed.length >= maxWords) break;
      grid.tryPlace(e.answer, e.clue, e.payload, rnd);
    }
    if (best == null ||
        grid.placed.length > best.placed.length ||
        (grid.placed.length == best.placed.length && grid.area < best.area)) {
      best = grid;
    }
  }
  return (best ?? _Grid()).finish();
}

class _Raw {
  _Raw(this.answer, this.clue, this.payload, this.row, this.col, this.dir);
  final String answer;
  final String clue;
  final Object? payload;
  int row;
  int col;
  final Dir dir;
}

class _Grid {
  final Map<(int, int), String> cells = {};
  final List<_Raw> placed = [];

  // Grenzen werden beim Eintragen mitgeführt, statt jedes Mal alle Zellen
  // zu durchsuchen (das machte das Rätsel auf Handys spürbar langsam).
  int minR = 1 << 30;
  int maxR = -(1 << 30);
  int minC = 1 << 30;
  int maxC = -(1 << 30);
  int get area => cells.isEmpty ? 0 : (maxR - minR + 1) * (maxC - minC + 1);

  void tryPlace(String word, String clue, Object? payload, Random rnd) {
    if (placed.any((p) => p.answer == word)) return;
    if (placed.isEmpty) {
      _put(_Raw(word, clue, payload, 0, 0, Dir.across));
      return;
    }
    // (Zeile, Spalte, Richtung, Kreuzungen, Fläche danach)
    final options = <(int, int, Dir, int, int)>[];
    for (final p in placed) {
      for (var i = 0; i < p.answer.length; i++) {
        for (var j = 0; j < word.length; j++) {
          if (p.answer[i] != word[j]) continue;
          final dir = p.dir == Dir.across ? Dir.down : Dir.across;
          final (pr, pc) = p.dir == Dir.across
              ? (p.row, p.col + i)
              : (p.row + i, p.col);
          final (r, c) = dir == Dir.across ? (pr, pc - j) : (pr - j, pc);
          final crossings = _fits(word, r, c, dir);
          if (crossings > 0) {
            options.add((r, c, dir, crossings, _areaWith(word, r, c, dir)));
          }
        }
      }
    }
    if (options.isEmpty) return;
    // Mehr Kreuzungen und kleineres Gitter bevorzugen.
    options.sort((a, b) {
      final byCross = b.$4.compareTo(a.$4);
      return byCross != 0 ? byCross : a.$5.compareTo(b.$5);
    });
    final pick = options[rnd.nextInt(min(2, options.length))];
    _put(_Raw(word, clue, payload, pick.$1, pick.$2, pick.$3));
  }

  int _areaWith(String w, int r, int c, Dir d) {
    final r2 = d == Dir.down ? r + w.length - 1 : r;
    final c2 = d == Dir.across ? c + w.length - 1 : c;
    final height = max<int>(maxR, r2) - min<int>(minR, r) + 1;
    final width = max<int>(maxC, c2) - min<int>(minC, c) + 1;
    return height * width;
  }

  /// Anzahl Kreuzungen, oder -1 wenn das Wort nicht passt.
  int _fits(String w, int r, int c, Dir d) {
    final (dr, dc) = d == Dir.across ? (0, 1) : (1, 0);
    // Vor und nach dem Wort muss frei sein.
    if (cells.containsKey((r - dr, c - dc))) return -1;
    if (cells.containsKey((r + dr * w.length, c + dc * w.length))) return -1;
    var crossings = 0;
    for (var i = 0; i < w.length; i++) {
      final rr = r + dr * i, cc = c + dc * i;
      final existing = cells[(rr, cc)];
      if (existing != null) {
        if (existing != w[i]) return -1;
        crossings++;
      } else {
        // Keine Nachbarn quer zur Richtung, sonst entstehen Unsinnswörter.
        if (cells.containsKey((rr + dc, cc + dr)) ||
            cells.containsKey((rr - dc, cc - dr))) {
          return -1;
        }
      }
    }
    // Nicht komplett über einem bestehenden Wort liegen.
    return crossings == w.length ? -1 : crossings;
  }

  void _put(_Raw raw) {
    final (dr, dc) = raw.dir == Dir.across ? (0, 1) : (1, 0);
    for (var i = 0; i < raw.answer.length; i++) {
      cells[(raw.row + dr * i, raw.col + dc * i)] = raw.answer[i];
    }
    final endR = raw.row + dr * (raw.answer.length - 1);
    final endC = raw.col + dc * (raw.answer.length - 1);
    minR = min(minR, raw.row);
    minC = min(minC, raw.col);
    maxR = max(maxR, endR);
    maxC = max(maxC, endC);
    placed.add(raw);
  }

  Crossword finish() {
    if (placed.isEmpty) return const Crossword(rows: 0, cols: 0, words: []);
    final r0 = minR, c0 = minC;
    final sorted = [...placed]
      ..sort((a, b) {
        final byRow = a.row.compareTo(b.row);
        return byRow != 0 ? byRow : a.col.compareTo(b.col);
      });
    final numbers = <(int, int), int>{};
    final words = <PlacedWord>[];
    for (final p in sorted) {
      final key = (p.row - r0, p.col - c0);
      final number = numbers.putIfAbsent(key, () => numbers.length + 1);
      words.add(
        PlacedWord(
          answer: p.answer,
          clue: p.clue,
          row: key.$1,
          col: key.$2,
          dir: p.dir,
          number: number,
          payload: p.payload,
        ),
      );
    }
    return Crossword(rows: maxR - r0 + 1, cols: maxC - c0 + 1, words: words);
  }
}
