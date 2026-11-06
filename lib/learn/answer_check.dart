/// Ergebnis einer getippten Antwort.
enum AnswerResult {
  /// Genau richtig (ß/ss und Satzzeichen egal; Groß-/Kleinschreibung nur
  /// egal, wenn nicht streng geprüft wird).
  correct,

  /// Ein kleiner Tippfehler – wird markiert.
  close,

  /// Nur die Groß-/Kleinschreibung stimmt nicht (nur bei strenger Prüfung).
  caseError,
  wrong,
}

/// Vereinheitlicht eine Eingabe für den Vergleich.
String normalizeAnswer(String s, {bool keepCase = false}) {
  var t = keepCase ? s.trim() : s.toLowerCase().trim();
  t = t.replaceAll('ß', 'ss').replaceAll('ẞ', 'SS');
  t = t.replaceAll(RegExp(r'''[.,!?;:"'«»„“”‚‘’()\-–—]'''), ' ');
  t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t;
}

/// Prüft [input] gegen alle gültigen Schreibweisen in [accepted].
///
/// Umlaute sind Pflicht (ä ≠ a), aber „ae“ statt „ä“ gilt als kleiner Fehler.
/// Mit [caseSensitive] (Diktat) muss auch die Groß-/Kleinschreibung stimmen.
AnswerResult checkAnswer(
  String input,
  List<String> accepted, {
  bool caseSensitive = false,
}) {
  final given = normalizeAnswer(input);
  if (given.isEmpty) return AnswerResult.wrong;
  var best = AnswerResult.wrong;
  for (final a in accepted) {
    final want = normalizeAnswer(a);
    if (given == want) {
      if (!caseSensitive ||
          normalizeAnswer(input, keepCase: true) ==
              normalizeAnswer(a, keepCase: true)) {
        return AnswerResult.correct;
      }
      best = AnswerResult.caseError;
      continue;
    }
    if (best == AnswerResult.caseError) continue;
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

/// Vergleicht zwei Sätze Wort für Wort und markiert in [expected] jedes Wort,
/// das in [given] anders geschrieben ist (auch nur in der Groß-/Kleinschreibung).
/// `null`, wenn die Wortzahl nicht übereinstimmt.
List<(String word, bool wrong)>? markWords(String given, String expected) {
  List<String> words(String s) =>
      s.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty).toList();
  String core(String w) => normalizeAnswer(w, keepCase: true);
  final g = words(given), e = words(expected);
  if (g.length != e.length) return null;
  return [for (var i = 0; i < e.length; i++) (e[i], core(g[i]) != core(e[i]))];
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
