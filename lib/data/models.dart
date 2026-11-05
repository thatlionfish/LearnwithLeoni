/// Sprachvarietät eines Inhalts.
enum Variety {
  /// Hochdeutsch
  de,

  /// Bündnerdütsch
  gsw;

  static Variety parse(Object? v) => v == 'gsw' ? Variety.gsw : Variety.de;
}

/// Ein Schüler, wie er in `data/students/<code>/student.json` steht.
class Student {
  const Student({
    required this.code,
    required this.name,
    required this.explainLanguage,
    required this.level,
    required this.targets,
    required this.setIds,
    this.crosswordAudio = false,
  });

  factory Student.fromJson(String code, Map<String, dynamic> j) => Student(
    code: code,
    name: j['name'] as String,
    explainLanguage: (j['explainLanguage'] as String?) ?? 'en',
    level: (j['level'] as String?) ?? 'A1',
    targets: [
      for (final t in (j['targets'] as List?) ?? const ['de']) Variety.parse(t),
    ],
    setIds: [for (final s in (j['sets'] as List?) ?? const []) s as String],
    crosswordAudio: j['crossword'] == 'audio',
  );

  final String code;
  final String name;

  /// ISO-Sprachcode, z. B. `en`, `es`, `ja`.
  final String explainLanguage;
  final String level;
  final List<Variety> targets;
  final List<String> setIds;

  /// Kreuzworträtsel mit gesprochenen statt geschriebenen Hinweisen
  /// ("crossword": "audio" in student.json).
  final bool crosswordAudio;
}

/// Ein Vokabelset, wie es in `data/students/<code>/sets/<id>.json` steht.
class VocabSet {
  const VocabSet({
    required this.id,
    required this.title,
    required this.titleTranslation,
    required this.variety,
    required this.published,
    required this.cards,
    this.cloze = const [],
    this.listening = const [],
  });

  factory VocabSet.fromJson(Map<String, dynamic> j) => VocabSet(
    id: j['id'] as String,
    title: j['title'] as String,
    titleTranslation: (j['titleTranslation'] as String?) ?? '',
    variety: Variety.parse(j['variety']),
    published: j['status'] == 'published',
    cards: [
      for (final c in (j['cards'] as List?) ?? const [])
        VocabCard.fromJson(c as Map<String, dynamic>),
    ],
    cloze: [
      for (final c in (j['cloze'] as List?) ?? const [])
        ClozeItem.fromJson(c as Map<String, dynamic>),
    ],
    listening: [
      for (final l in (j['listening'] as List?) ?? const [])
        ListeningText.fromJson(l as Map<String, dynamic>),
    ],
  );

  final String id;
  final String title;
  final String titleTranslation;
  final Variety variety;

  /// Entwürfe sieht nur die Werkstatt, nie ein Schüler.
  final bool published;
  final List<VocabCard> cards;

  /// Von Leoni geschriebene Lückensätze.
  final List<ClozeItem> cloze;

  /// Hörtexte mit Fragen.
  final List<ListeningText> listening;
}

/// Lückensatz: `___` markiert die Lücke.
class ClozeItem {
  const ClozeItem({
    required this.id,
    required this.text,
    required this.answers,
    this.options = const [],
    this.translation,
    this.hint,
  });

  factory ClozeItem.fromJson(Map<String, dynamic> j) => ClozeItem(
    id: j['id'] as String,
    text: j['text'] as String,
    answers: [for (final a in j['answers'] as List) a as String],
    options: [for (final o in (j['options'] as List?) ?? const []) o as String],
    translation: j['translation'] as String?,
    hint: j['hint'] as String?,
  );

  final String id;
  final String text;

  /// Umschreibung des gesuchten Worts (Kumachans Tipp).
  final String? hint;

  /// Alle gültigen Antworten; die erste ist die Musterlösung.
  final List<String> answers;

  /// Leer = frei tippen, sonst Auswahl.
  final List<String> options;
  final String? translation;
}

/// Hörtext (Dialog, Durchsage …) mit Verständnisfragen.
class ListeningText {
  const ListeningText({
    required this.id,
    required this.title,
    required this.text,
    required this.questions,
    this.audio,
    this.titleTranslation,
  });

  factory ListeningText.fromJson(Map<String, dynamic> j) => ListeningText(
    id: j['id'] as String,
    title: j['title'] as String,
    titleTranslation: j['titleTranslation'] as String?,
    text: j['text'] as String,
    audio: j['audio'] as String?,
    questions: [
      for (final q in (j['questions'] as List?) ?? const [])
        ListeningQuestion.fromJson(q as Map<String, dynamic>),
    ],
  );

  final String id;
  final String title;
  final String? titleTranslation;

  /// Der gesprochene Text; Zeilen mit „Name: …“ werden als Dialog gezeigt.
  final String text;
  final String? audio;
  final List<ListeningQuestion> questions;
}

class ListeningQuestion {
  const ListeningQuestion({
    required this.question,
    required this.options,
    required this.answer,
    this.translation,
  });

  factory ListeningQuestion.fromJson(Map<String, dynamic> j) =>
      ListeningQuestion(
        question: j['q'] as String,
        options: [for (final o in j['options'] as List) o as String],
        answer: j['answer'] as int,
        translation: j['translation'] as String?,
      );

  final String question;
  final List<String> options;

  /// Index der richtigen Antwort in [options].
  final int answer;
  final String? translation;
}

class VocabCard {
  const VocabCard({
    required this.id,
    required this.term,
    required this.translation,
    this.plural,
    this.alt,
    this.example,
    this.exampleTranslation,
    this.audio,
    this.verified = true,
    this.hint,
  });

  factory VocabCard.fromJson(Map<String, dynamic> j) => VocabCard(
    id: j['id'] as String,
    term: j['term'] as String,
    translation: j['translation'] as String,
    plural: j['plural'] as String?,
    alt: j['alt'] as String?,
    example: j['example'] as String?,
    exampleTranslation: j['exampleTranslation'] as String?,
    audio: j['audio'] as String?,
    verified: (j['verified'] as bool?) ?? true,
    hint: j['hint'] as String?,
  );

  final String id;

  /// Wort oder Ausdruck, bei Nomen mit Artikel.
  final String term;
  final String translation;
  final String? plural;

  /// Dieselbe Bedeutung in der anderen Varietät.
  final String? alt;
  final String? example;
  final String? exampleTranslation;

  /// Relativer Pfad zur Audiodatei im Ordner des Schülers.
  final String? audio;

  /// `false` = Bündnerdütsch-Schreibweise von Leoni noch nicht bestätigt.
  final bool verified;

  /// Umschreibung auf Deutsch – Kumachans erster Tipp, nie die Lösung.
  final String? hint;
}
