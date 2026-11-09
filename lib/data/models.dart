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
    this.fide = const [],
    this.isCollection = false,
  });

  factory VocabSet.fromJson(Map<String, dynamic> j) => VocabSet(
    id: j['id'] as String,
    title: j['title'] as String,
    titleTranslation: (j['titleTranslation'] as String?) ?? '',
    variety: Variety.parse(j['variety']),
    published: j['status'] == 'published',
    isCollection: j['collection'] == true,
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
    fide: [
      for (final f in (j['fide'] as List?) ?? const [])
        FideSituation.fromJson(f as Map<String, dynamic>),
    ],
  );

  final String id;
  final String title;
  final String titleTranslation;
  final Variety variety;

  /// Entwürfe sieht nur die Werkstatt, nie ein Schüler.
  final bool published;

  /// Sammlung einzelner Wörter ohne Thema: kein eigenes Set auf der
  /// Startseite, die Wörter stehen unter „Alle Wörter“ und kommen beim Lernen.
  final bool isCollection;
  final List<VocabCard> cards;

  /// Von Leoni geschriebene Lückensätze.
  final List<ClozeItem> cloze;

  /// Hörtexte mit Fragen.
  final List<ListeningText> listening;

  /// Hörverstehen im Aufbau des fide-Tests.
  final List<FideSituation> fide;
}

/// fide-Test „Verstehen“: Die Prüferin erklärt eine Situation, dann folgen
/// Fragen mit je einem kurzen Hörtext.
class FideSituation {
  const FideSituation({
    required this.id,
    required this.situation,
    required this.level,
    required this.items,
    this.situationTranslation,
  });

  factory FideSituation.fromJson(Map<String, dynamic> j) => FideSituation(
    id: j['id'] as String,
    situation: j['situation'] as String,
    situationTranslation: j['situationTranslation'] as String?,
    level: (j['level'] as String?) ?? 'A2',
    items: [
      for (final i in (j['items'] as List?) ?? const [])
        FideItem.fromJson(i as Map<String, dynamic>),
    ],
  );

  final String id;
  final String situation;
  final String? situationTranslation;

  /// `A2` (Bild auswählen) oder `B1` (frei antworten).
  final String level;
  final List<FideItem> items;
}

class FideItem {
  const FideItem({
    required this.id,
    required this.question,
    required this.text,
    this.questionTranslation,
    this.audio,
    this.pictures = const [],
    this.answer = 0,
    this.keywords = const [],
    this.model,
    this.modelTranslation,
    this.hint,
  });

  factory FideItem.fromJson(Map<String, dynamic> j) => FideItem(
    id: j['id'] as String,
    question: j['question'] as String,
    questionTranslation: j['questionTranslation'] as String?,
    text: j['text'] as String,
    audio: j['audio'] as String?,
    pictures: [
      for (final p in (j['pictures'] as List?) ?? const [])
        FidePicture.fromJson(p),
    ],
    answer: (j['answer'] as int?) ?? 0,
    keywords: [
      for (final k in (j['keywords'] as List?) ?? const []) k as String,
    ],
    model: j['model'] as String?,
    modelTranslation: j['modelTranslation'] as String?,
    hint: j['hint'] as String?,
  );

  final String id;
  final String question;
  final String? questionTranslation;

  /// Der Hörtext; Zeilen mit „Name: …“ bekommen je eine eigene Stimme.
  final String text;

  /// Fertige Aufnahme: (Situation,) Frage, Hörtext, Frage nochmals.
  final String? audio;

  /// A2: genau drei Bilder a), b), c); [answer] ist der Index des richtigen.
  final List<FidePicture> pictures;
  final int answer;

  /// B1: Stichwörter, die in der Antwort vorkommen müssen. Jeder Eintrag ist
  /// eine Gruppe mit Alternativen, getrennt mit „|“ – alle Gruppen müssen passen.
  final List<String> keywords;

  /// B1: Musterantwort.
  final String? model;
  final String? modelTranslation;

  /// Kumachans erster Tipp (auf Deutsch, nie die Lösung).
  final String? hint;

  bool get isPicture => pictures.isNotEmpty;
}

/// Ein Antwortbild, z. B. `clock:18:30`, `price:4.50`, `cal:5,19`,
/// `week:Di,Sa`, `icon:cake`, `icons:cake,coffee`, `count:4:person`.
class FidePicture {
  const FidePicture(this.spec, {this.label});

  factory FidePicture.fromJson(Object? j) => j is Map
      ? FidePicture(j['pic'] as String, label: j['label'] as String?)
      : FidePicture(j as String);

  final String spec;

  /// Was das Bild zeigt (auf Deutsch); erscheint nach dem Antworten.
  final String? label;

  String get kind => spec.split(':').first;
  String get value => spec.substring(spec.indexOf(':') + 1);
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
    this.exampleAudio,
    this.gapAudio,
    this.hintAudio,
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
    exampleAudio: j['exampleAudio'] as String?,
    gapAudio: j['gapAudio'] as String?,
    hintAudio: j['hintAudio'] as String?,
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

  /// Fertiges Audio (relativ zum Schülerordner): Beispielsatz, Lückensatz
  /// mit „Hm hm hm“ und Umschreibung. Erzeugt von `tool/tts.dart`.
  final String? exampleAudio;
  final String? gapAudio;
  final String? hintAudio;
}
