import 'answer_check.dart';

/// Kumachans Tipps zu einem gesuchten Wort – Schritt für Schritt mehr Hilfe,
/// aber nie die Lösung selbst.
///
/// 1. die Umschreibung von Leoni ([description]),
/// 2. die Wortart (aus dem Kartenwort [term], z. B. „die …“ → Nomen),
/// 3. Anfangsbuchstabe und Länge der gesuchten Form [answer].
List<String> wordHints({
  String? description,
  String? term,
  required String answer,
}) {
  final hints = <String>[];
  if (description != null && description.trim().isNotEmpty) {
    hints.add(description.trim());
  }
  final grammar = term == null ? null : _grammarHint(term);
  if (grammar != null) hints.add(grammar);
  final word = answer.trim();
  final letters = word.replaceAll(RegExp(r'[^A-Za-zÄÖÜäöüß]'), '').length;
  if (word.isNotEmpty && letters > 1) {
    hints.add(
      'Es beginnt mit „${word[0].toUpperCase()}“ und hat $letters Buchstaben.',
    );
  }
  return hints;
}

String? _grammarHint(String term) {
  final t = term.trim();
  final m = RegExp(r'^(der|die|das)\s', caseSensitive: false).firstMatch(t);
  if (m != null) {
    final article = m.group(1)!.toLowerCase();
    return 'Ein Nomen mit „$article“.';
  }
  final word = stripArticle(t);
  if (!word.contains(' ') &&
      word == word.toLowerCase() &&
      word.endsWith('en')) {
    return 'Ein Verb – so steht es im Wörterbuch.';
  }
  return null;
}

/// Tipps für einen Diktatsatz.
List<String> sentenceHints(String sentence) {
  final words = sentence
      .split(RegExp(r'\s+'))
      .where((w) => RegExp(r'[A-Za-zÄÖÜäöüß0-9]').hasMatch(w))
      .toList();
  return [
    'Hör ihn dir langsam an – drück auf „Langsam“.',
    'Der Satz hat ${words.length} Wörter.',
    if (words.isNotEmpty)
      'Er beginnt mit „${words.first.replaceAll(RegExp(r'[^\wÄÖÜäöüß]'), '')}“.',
  ];
}
