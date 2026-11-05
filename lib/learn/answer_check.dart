/// Ergebnis einer getippten Antwort.
enum AnswerResult {
  /// Genau richtig (Groß-/Kleinschreibung, ß/ss, Satzzeichen egal).
  correct,

  /// Ein kleiner Tippfehler – zählt als richtig, wird aber markiert.
  close,
  wrong,
}

/// Vereinheitlicht eine Eingabe für den Vergleich.
String normalizeAnswer(String s) {
  var t = s.toLowerCase().trim();
  t = t.replaceAll('ß', 'ss').replaceAll('ẞ', 'ss');
  t = t.replaceAll(RegExp(r'''[.,!?;:"'«»„“”‚‘’()\-–—]'''), ' ');
  t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t;
}

/// Prüft [input] gegen alle gültigen Schreibweisen in [accepted].
///
/// Umlaute sind Pflicht (ä ≠ a), aber „ae“ statt „ä“ gilt als kleiner Fehler.
AnswerResult checkAnswer(String input, List<String> accepted) {
  final given = normalizeAnswer(input);
  if (given.isEmpty) return AnswerResult.wrong;
  var best = AnswerResult.wrong;
  for (final a in accepted) {
    final want = normalizeAnswer(a);
    if (given == want) return AnswerResult.correct;
    if (_umlautFallback(given) == _umlautFallback(want)) {
      best = AnswerResult.close;
      continue;
    }
    // Erlaubte Tippfehler: keine bis 4 Zeichen, 1 bis 7, sonst 2.
    final allowed = want.length <= 4 ? 0 : (want.length <= 7 ? 1 : 2);
    if (allowed > 0 && levenshtein(given, want, max: allowed) <= allowed) {
      best = AnswerResult.close;
    }
  }
  return best;
}

String _umlautFallback(String s) =>
    s.replaceAll('ä', 'ae').replaceAll('ö', 'oe').replaceAll('ü', 'ue');

/// Editierdistanz, bei der auch ein Buchstabendreher („ie“/„ei“) nur 1 zählt.
/// Bricht ab, sobald sie [max] sicher übersteigt.
int levenshtein(String a, String b, {int max = 1 << 30}) {
  if ((a.length - b.length).abs() > max) return max + 1;
  List<int>? prev2;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    var rowMin = cur[0];
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      var v = [
        prev[j] + 1,
        cur[j - 1] + 1,
        prev[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
      if (prev2 != null &&
          j > 1 &&
          a.codeUnitAt(i - 1) == b.codeUnitAt(j - 2) &&
          a.codeUnitAt(i - 2) == b.codeUnitAt(j - 1) &&
          prev2[j - 2] + 1 < v) {
        v = prev2[j - 2] + 1;
      }
      cur[j] = v;
      if (v < rowMin) rowMin = v;
    }
    if (rowMin > max) return max + 1;
    prev2 = prev;
    prev = cur;
  }
  return prev[b.length];
}

/// Nomen ohne Artikel, z. B. „der Termin“ → „Termin“.
String stripArticle(String term) {
  final m = RegExp(
    r'^(der|die|das|dr|d|s|ds|en|e|es|ein|eine)\s+',
    caseSensitive: false,
  ).firstMatch(term);
  return m == null ? term : term.substring(m.end);
}
