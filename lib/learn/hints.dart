import '../data/models.dart';
import 'answer_check.dart';

/// Kumachans feste Sätze. Alles, was sie sagt, wird vorab mit ihrer Stimme
/// aufgenommen (`tool/tts.dart`) – neue Sätze deshalb hier eintragen.
abstract final class KumaLines {
  static const noMore = 'Mehr Tipps habe ich nicht – du schaffst das!';
  static const listening = [
    'Hör dir den Text nochmal an – auch langsam.',
    'Du kannst den Text einblenden und nachlesen.',
  ];
  static const matchStart = 'Tippe zuerst links ein deutsches Wort an.';
  static const abcStart = 'Drück auf „Auf Sendung!“ – dann helfe ich dir.';
  static const hangmanLetters =
      'Fang mit häufigen Buchstaben an: E, N, R, S, I.';
  static const fideAgain =
      'Hör dir alles noch einmal an – in der Prüfung darfst du zweimal hören.';
  static const fidePicture = [
    fideAgain,
    'Achte auf Zahlen, Uhrzeiten und Tage.',
    'Vorsicht: Im Text kommen oft auch die falschen Bilder vor. Hör bis zum Schluss zu!',
  ];
  static const fideOpen = [
    fideAgain,
    'Die Frage hilft dir: Wann? – eine Zeit. Wo? – ein Ort. Was? – eine Sache.',
    'Eine kurze Antwort genügt, zwei oder drei Wörter.',
  ];

  static const all = [
    noMore,
    ...listening,
    matchStart,
    abcStart,
    hangmanLetters,
    ...fidePicture,
    ...fideOpen,
  ];
}

/// Tipps zu einer fide-Frage.
List<String> fideHints(FideItem item) => [
  if (item.hint != null && item.hint!.trim().isNotEmpty) item.hint!.trim(),
  ...(item.isPicture ? KumaLines.fidePicture : KumaLines.fideOpen),
];

/// Kreuzworträtsel: Gitterwort („KÄSE“) → Form für den Buchstaben-Tipp.
String crosswordHintAnswer(String gridWord) => gridWord.isEmpty
    ? gridWord
    : gridWord[0] + gridWord.substring(1).toLowerCase();

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
