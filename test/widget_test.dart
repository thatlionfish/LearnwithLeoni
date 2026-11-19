import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnwithleoni/app_settings.dart';
import 'package:learnwithleoni/audio/kuma_voice.dart';
import 'package:learnwithleoni/data/leitner.dart';
import 'package:learnwithleoni/data/repository.dart';
import 'package:learnwithleoni/main.dart';
import 'package:learnwithleoni/screens/home_screen.dart';
import 'package:learnwithleoni/widgets/exercise_kit.dart' show audioUrl;
import 'package:learnwithleoni/widgets/leoni.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSource implements ContentSource {
  FakeSource(this.files);
  final Map<String, Map<String, dynamic>> files;
  @override
  Future<Map<String, dynamic>?> load(String path) async => files[path];
}

const fHints = [
  {
    'topic': 'food',
    'clue': 'Käsegericht im Caquelon',
    'answers': ['Fondue'],
    'en': 'x',
  },
  {
    'topic': 'culture',
    'clue': 'Währung',
    'answers': ['Franken'],
    'en': 'x',
  },
  {
    'topic': 'culture',
    'clue': 'Warmer Wind',
    'answers': ['Föhn'],
    'en': 'x',
  },
  {
    'topic': 'people',
    'clue': 'Tennisspieler',
    'answers': ['Federer'],
    'en': 'x',
  },
  {
    'topic': 'traditions',
    'clue': 'Fest mit Masken',
    'answers': ['Fasnacht'],
    'en': 'x',
  },
  {
    'topic': 'culture',
    'clue': 'Fünffrankenstück',
    'answers': ['Fünfliber'],
    'en': 'x',
  },
];

const arztSet = {
  'id': 'arzt',
  'title': 'Beim Arzt',
  'titleTranslation': "At the doctor's",
  'status': 'published',
  'cards': [
    {
      'id': 'termin',
      'term': 'der Termin',
      'translation': 'appointment',
      'example': 'Ich habe morgen einen Termin.',
    },
    {'id': 'fieber', 'term': 'das Fieber', 'translation': 'fever'},
  ],
};

FakeSource demoSource() => FakeSource({
  'students/hoer1/student.json': {
    'name': 'Irene',
    'explainLanguage': 'en',
    'crossword': 'audio',
    'sets': ['arzt'],
  },
  'students/hoer1/sets/arzt.json': arztSet,
  'abc/hints.json': {'hints': fHints},
  'students/samm1/student.json': {
    'name': 'Mia',
    'explainLanguage': 'en',
    'sets': ['arzt', 'lose'],
  },
  'students/samm1/sets/arzt.json': arztSet,
  'students/samm1/sets/lose.json': {
    'id': 'lose',
    'title': 'Wörter ohne Thema',
    'status': 'published',
    'collection': true,
    'cards': [
      {
        'id': 'schuerze',
        'term': 'die Schürze',
        'translation': 'apron',
        'example': 'Beim Kochen trage ich eine Schürze.',
      },
      {'id': 'beachten', 'term': 'beachten', 'translation': 'to observe'},
      {'id': 'ball', 'term': 'einen Ball werfen', 'translation': 'to throw'},
    ],
  },
  'students/anna1/student.json': {
    'name': 'Anna',
    'explainLanguage': 'en',
    'level': 'A2',
    'sets': ['arzt', 'entwurf'],
  },
  'students/anna1/sets/arzt.json': {
    'id': 'arzt',
    'title': 'Beim Arzt',
    'titleTranslation': "At the doctor's",
    'status': 'published',
    'cards': [
      {
        'id': 'termin',
        'term': 'der Termin',
        'translation': 'appointment',
        'example': 'Ich habe morgen einen Termin.',
      },
      {'id': 'fieber', 'term': 'das Fieber', 'translation': 'fever'},
    ],
  },
  'students/fide1/student.json': {
    'name': 'Reika',
    'explainLanguage': 'ja',
    'sets': ['essen'],
  },
  'students/fide1/sets/essen.json': {
    'id': 'essen',
    'title': 'Essen',
    'status': 'published',
    'cards': [
      {'id': 'brot', 'term': 'das Brot', 'translation': 'パン'},
      {'id': 'kaese', 'term': 'der Käse', 'translation': 'チーズ'},
    ],
    'fide': [
      {
        'id': 'markt',
        'level': 'A2',
        'situation': 'Frau Nakamura ist auf dem Markt.',
        'situationTranslation': '中村さんは市場にいます。',
        'items': [
          {
            'id': 'm1',
            'question': 'Was kostet ein Kilo Tomaten?',
            'text': 'Verkäuferin: Heute nur vier Franken fünfzig.',
            'pictures': ['price:6.00', 'price:4.50', 'price:5.40'],
            'answer': 1,
          },
        ],
      },
      {
        'id': 'einladung',
        'level': 'B1',
        'situation': 'Frau Silva ist eingeladen.',
        'items': [
          {
            'id': 'e1',
            'question': 'Was soll Frau Silva mitbringen?',
            'text': 'Nachbarin: Bring doch ein Dessert mit!',
            'keywords': ['Dessert|Kuchen'],
            'model': 'ein Dessert',
          },
        ],
      },
    ],
  },
  'students/anna1/sets/entwurf.json': {
    'id': 'entwurf',
    'title': 'Geheimer Entwurf',
    'status': 'draft',
    'cards': <Object>[],
  },
  // Gemeinsame Bibliothek: Übersetzungen je Sprache, Audio im Themenordner.
  'themen/gesund/thema.json': {
    'id': 'gesund',
    'title': 'Gesundheit',
    'titleTranslation': {'en': 'Health', 'ja': '健康'},
    'status': 'published',
    'cards': [
      {
        'id': 'arzt',
        'term': 'der Arzt',
        'translation': {'en': 'doctor', 'ja': '医者'},
        'audio': 'audio/tts/gesund-arzt.mp3',
      },
      {
        'id': 'fieber',
        'term': 'das Fieber',
        'translation': {'en': 'fever', 'ja': '熱'},
      },
    ],
    'fide': [
      {
        'id': 'praxis',
        'level': 'A2',
        'situation': 'Frau Silva ruft in der Praxis an.',
        'situationTranslation': {'en': 'Ms Silva calls.', 'ja': '電話します。'},
        'items': [
          {
            'id': 'p1',
            'question': 'Wann ist der Termin?',
            'text': 'Assistentin: Am Dienstag um zehn Uhr.',
            'pictures': ['week:Mo', 'week:Di', 'week:Fr'],
            'answer': 1,
          },
        ],
      },
      {
        'id': 'chefin',
        'level': 'B1',
        'situation': 'Herr Keller ist krank.',
        'items': [
          {
            'id': 'c1',
            'question': 'Was braucht die Chefin?',
            'text': 'Chefin: Ab Donnerstag ein Arztzeugnis, bitte.',
            'keywords': ['Zeugnis'],
            'model': 'ein Arztzeugnis',
          },
        ],
      },
    ],
  },
  'students/vane1/student.json': {
    'name': 'Vanessa',
    'explainLanguage': 'en',
    'themen': ['gesund'],
    'sets': ['essen', 'gesund-zh'],
  },
  'students/vane1/sets/essen.json': {
    'id': 'essen',
    'title': 'Essen',
    'status': 'published',
    'cards': [
      {'id': 'brot', 'term': 'das Brot', 'translation': 'bread'},
      {'id': 'kaese', 'term': 'der Käse', 'translation': 'cheese'},
    ],
    'fide': [
      {
        'id': 'markt',
        'level': 'A2',
        'situation': 'Frau Nakamura ist auf dem Markt.',
        'items': [
          {
            'id': 'm1',
            'question': 'Was kostet ein Kilo Tomaten?',
            'text': 'Verkäuferin: Heute nur vier Franken fünfzig.',
            'pictures': ['price:6.00', 'price:4.50', 'price:5.40'],
            'answer': 1,
          },
        ],
      },
      {
        'id': 'einladung',
        'level': 'B1',
        'situation': 'Frau Silva ist eingeladen.',
        'items': [
          {
            'id': 'e1',
            'question': 'Was soll Frau Silva mitbringen?',
            'text': 'Nachbarin: Bring doch ein Dessert mit!',
            'keywords': ['Dessert|Kuchen'],
            'model': 'ein Dessert',
          },
        ],
      },
    ],
  },
  // Zusatz zum Thema: nur auf der Themenseite, nicht bei „Heute“.
  'students/vane1/sets/gesund-zh.json': {
    'id': 'gesund-zh',
    'title': 'Gesundheit auf Züritüütsch',
    'variety': 'gsw',
    'status': 'published',
    'topic': 'gesund',
    'cards': [
      {'id': 'dokter', 'term': 'de Dokter', 'translation': 'doctor'},
    ],
  },
});

Future<void> pumpApp(
  WidgetTester tester,
  String location, {
  double kumaAsk = 0,
}) async {
  SharedPreferences.setMockInitialValues({});
  // Zwischengespeicherte Futures nicht über Tests hinweg teilen.
  LeoniPhrases.resetCache();
  ProgressStore.resetCache();
  KumaVoice.reset();
  LeoniFigure.animate = false;
  // Zufall aus: Kumachan fragt nur, wenn ein Test es will.
  HomeScreen.kumaAskChance = kumaAsk;
  rootBundle.clear();
  svg.cache.clear();
  final settings = await AppSettings.load();
  final router = buildRouter()..go(location);
  await tester.pumpWidget(
    LearnWithLeoniApp(
      settings: settings,
      repository: ContentRepository(demoSource()),
      router: router,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Startseite zeigt Begrüßung, Themen und den Weg zu den Spielen', (
    tester,
  ) async {
    await pumpApp(tester, '/s/anna1');
    expect(
      find.text('Hallo Anna!'),
      findsOneWidget,
    ); // Oberfläche immer Deutsch
    expect(find.text('Topics'), findsOneWidget); // Hilfesprache klein daneben
    expect(find.text('Beim Arzt'), findsOneWidget);
    expect(
      find.text('Geheimer Entwurf'),
      findsNothing,
    ); // Entwürfe nie beim Schüler
    expect(find.text('2 neue Karten'), findsOneWidget);
    // Ohne fide-Aufgaben gibt es keine fide-Karte.
    expect(find.text('fide-Training'), findsNothing);
    // Die Spiele haben eine eigene kleine Seite.
    expect(find.text('Hangman'), findsNothing);
    await tester.ensureVisible(find.text('Spiele'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spiele'));
    await tester.pumpAndSettle();
    expect(find.text('Hangman'), findsOneWidget);
    expect(find.text('Kreuzworträtsel'), findsOneWidget);
  });

  test(
    'Bibliothek: Übersetzung in der Hilfesprache, Audio im Themenordner',
    () async {
      final repo = ContentRepository(demoSource());
      final content = await repo.student('vane1');
      final theme = content.set('gesund')!;
      expect(theme.titleTranslation, 'Health');
      expect(theme.cards.first.translation, 'doctor');
      expect(
        theme.cards.first.audio,
        'themen/gesund/audio/tts/gesund-arzt.mp3',
      );
      expect(
        audioUrl('vane1', theme.cards.first.audio),
        'data/themen/gesund/audio/tts/gesund-arzt.mp3',
      );
      expect(
        audioUrl('vane1', 'audio/tts/essen-brot.mp3'),
        'data/students/vane1/audio/tts/essen-brot.mp3',
      );
      // Der Zusatz ist kein eigenes Thema und zählt nicht für „Heute“.
      expect(content.topics.map((s) => s.id), ['gesund', 'essen']);
      expect(content.mainSets.map((s) => s.id), isNot(contains('gesund-zh')));
      expect(content.extrasOf('gesund').single.id, 'gesund-zh');
    },
  );

  testWidgets('Zusatz auf Züritüütsch steht nur auf der Themenseite', (
    tester,
  ) async {
    await pumpApp(tester, '/s/vane1');
    expect(find.text('Gesundheit'), findsOneWidget);
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('Gesundheit auf Züritüütsch'), findsNothing);
    // 2 Wörter Gesundheit + 2 Wörter Essen, der Zusatz nicht.
    expect(find.text('4 neue Karten'), findsOneWidget);

    await tester.ensureVisible(find.text('Gesundheit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gesundheit'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gesundheit auf Züritüütsch'));
    await tester.pumpAndSettle();
    expect(find.text('Gesundheit auf Züritüütsch'), findsOneWidget);
    expect(find.text('Zusatz'), findsOneWidget);
    expect(find.text('doctor'), findsOneWidget);
    expect(find.text('医者'), findsNothing);
  });

  testWidgets('fide-Training auf der Startseite mischt alle Themen', (
    tester,
  ) async {
    await pumpApp(tester, '/s/vane1');
    expect(find.text('fide-Training'), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Üben'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Üben'));
    await tester.pumpAndSettle();
    // Gleich im Übungsmodus: je zwei Situationen A2 und B1 aus beiden Themen.
    expect(find.textContaining('1 von 4'), findsOneWidget);
    expect(find.text('Wie in der Prüfung'), findsNothing);
  });

  testWidgets('fide-Training nur B1: nur die B1-Aufgaben aus allen Themen', (
    tester,
  ) async {
    await pumpApp(tester, '/s/vane1');
    await tester.ensureVisible(find.text('Nur B1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nur B1'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Üben'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Üben'));
    await tester.pumpAndSettle();
    // Zwei B1-Situationen gibt es (Gesundheit und Essen), keine A2-Bilder.
    expect(find.textContaining('1 von 2'), findsOneWidget);
    expect(find.text('a)'), findsNothing);
  });

  testWidgets('fide in einem Thema: Stufe wählen', (tester) async {
    await pumpApp(tester, '/s/vane1/ueben/fide?set=gesund');
    expect(find.text('1 × A2 · 1 × B1'), findsOneWidget);
    await tester.tap(find.text('Nur A2'));
    await tester.pumpAndSettle();
    expect(find.text('1 × A2'), findsOneWidget);
  });

  testWidgets('Startseite passt auf ein schmales Handy', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester, '/s/anna1');
    expect(tester.takeException(), isNull); // kein Überlauf
    expect(find.text('Hallo Anna!'), findsOneWidget);
  });

  testWidgets('Karte umdrehen, bewerten, Sitzung abschließen', (tester) async {
    await pumpApp(tester, '/s/anna1/lernen?set=arzt');
    expect(find.text('der Termin'), findsOneWidget);
    expect(find.text('appointment'), findsNothing);

    await tester.tap(find.text('der Termin'));
    await tester.pumpAndSettle();
    expect(find.text('appointment'), findsOneWidget);

    await tester.tap(find.text('Wusste ich'));
    await tester.pumpAndSettle();
    expect(find.text('das Fieber'), findsOneWidget);

    // Tastatur: Leertaste dreht um, 1 = gewusst.
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pumpAndSettle();

    expect(find.text('Geschafft!'), findsOneWidget);
    expect(find.textContaining('2 gewusst'), findsOneWidget);
  });

  testWidgets('Kumachan häkelt: Erfolg nach der Runde, Decke über Kumachan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester, '/s/anna1', kumaAsk: 1); // sie fragt bestimmt
    // Keine grosse Kachel mehr; ohne Quadrate fragt Kumachan noch nicht.
    expect(find.text('Kumachans Decke'), findsNothing);
    expect(find.text('Willst du deine Decke sehen?'), findsNothing);

    // Kumachan antippen öffnet ihre Decke.
    await tester.tap(find.byTooltip('Kumachans Decke ansehen'));
    await tester.pumpAndSettle();
    expect(
      find.text('Lern deine ersten Wörter – dann beginnt Kumachan zu häkeln.'),
      findsOneWidget,
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jetzt lernen'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();
    }
    // Zwei neue Wörter gewusst: je zwei Runden.
    expect(find.text('Heute gehäkelt'), findsOneWidget);
    expect(find.text('Kumachan hat 4 Runden gehäkelt.'), findsOneWidget);

    await tester.tap(find.text('Zur Decke'));
    await tester.pumpAndSettle();
    expect(find.text('Am Haken'), findsOneWidget);
    expect(find.text('2 von 5 Runden'), findsNWidgets(2));
    expect(find.text('0 an der Decke · 2 am Haken'), findsOneWidget);

    // Zurück auf der Startseite fragt Kumachan nach ihrer Decke.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zur Startseite'));
    await tester.pumpAndSettle();
    expect(find.text('Willst du deine Decke sehen?'), findsOneWidget);
  });

  testWidgets(
    'Deutsch hinten: vorne die Übersetzung, danach wann sie wiederkommt',
    (tester) async {
      await pumpApp(tester, '/s/anna1/lernen?set=arzt');
      await tester.tap(find.text('Deutsch hinten'));
      await tester.pumpAndSettle();
      expect(find.text('appointment'), findsOneWidget);
      expect(find.text('der Termin'), findsNothing);
      expect(find.text('Anhören'), findsNothing); // würde die Lösung verraten

      await tester.tap(find.text('appointment'));
      await tester.pumpAndSettle();
      expect(find.text('der Termin'), findsOneWidget);
      await tester.tap(find.text('Wusste ich'));
      await tester.pumpAndSettle();
      expect(find.textContaining('kommt in 2 Tagen wieder'), findsOneWidget);

      // Die Wahl bleibt: nächste Karte wieder mit der Übersetzung vorne.
      expect(find.text('fever'), findsOneWidget);
      expect(find.text('das Fieber'), findsNothing);
    },
  );

  testWidgets('Lückentext: tippen, prüfen, Rückmeldung', (tester) async {
    await pumpApp(tester, '/s/anna1/ueben/luecken?set=arzt');
    expect(find.text('Was passt in die Lücke?'), findsOneWidget);
    expect(find.text('What fits in the gap?'), findsOneWidget); // Hilfe
    await tester.tap(find.text('Termin'));
    await tester.pumpAndSettle();
    expect(find.text('Richtig!'), findsOneWidget);
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('Übung geschafft!'), findsOneWidget);
    expect(find.text('1 von 1 richtig'), findsOneWidget);
  });

  testWidgets('Zuordnen: falsches Paar, dann richtige Paare', (tester) async {
    await pumpApp(tester, '/s/anna1/ueben/zuordnen?set=arzt');
    await tester.tap(find.text('der Termin'));
    await tester.pump();
    await tester.tap(find.text('fever'));
    await tester.pump();
    await tester.tap(find.text('appointment'));
    await tester.pump();
    await tester.tap(find.text('das Fieber'));
    await tester.pump();
    await tester.tap(find.text('fever'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Übung geschafft!'), findsOneWidget);
  });

  testWidgets('Kreuzworträtsel lässt sich lösen', (tester) async {
    await pumpApp(tester, '/s/anna1/ueben/kreuzwort?set=arzt');
    expect(find.text('Kreuzworträtsel'), findsOneWidget);
    // Alles aufdecken: jedes Feld antippen und „Buchstabe aufdecken“.
    final cells = find.bySemanticsLabel(RegExp(r'^Feld '));
    final n = cells.evaluate().length;
    expect(n, greaterThan(5));
    for (var i = 0; i < n; i++) {
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Feld ')).at(i));
      await tester.pump();
      await tester.tap(find.text('Buchstabe aufdecken'));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('Übung geschafft!'), findsOneWidget);
  });

  testWidgets('ABC-Radio: ohne Drehknopf starten und Wort eintippen', (
    tester,
  ) async {
    await pumpApp(tester, '/s/anna1/spiel/abc-radio');
    expect(find.text('Spin the letter'), findsNothing);
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auf Sendung!'));
    await tester.pump(const Duration(milliseconds: 200));
    // Nur ein Buchstabe ist spielbar: F. Hinweis lesen und Antwort tippen.
    final answers = {
      for (final h in fHints) h['clue'] as String: (h['answers'] as List).first,
      // Annas eigenes Wort mit F: Hinweis ist die Übersetzung.
      'fever': 'Fieber',
    };
    final clue = answers.keys.firstWhere(
      (c) => find.text(c).evaluate().isNotEmpty,
    );
    await tester.enterText(find.byType(TextField), answers[clue] as String);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 200));
    // 6 gemeinsame Hinweise mit F plus Annas Wort „Fieber“.
    expect(find.text('1 richtig · Ziel: 7 richtige'), findsOneWidget);
    // Sendung beenden, damit keine Timer offen bleiben.
    await tester.pump(const Duration(seconds: 61));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Sendeschluss!'), findsOneWidget);
  });

  testWidgets('Hör-Kreuzworträtsel zeigt keine geschriebenen Hinweise', (
    tester,
  ) async {
    await pumpApp(tester, '/s/hoer1/ueben/kreuzwort?set=arzt');
    expect(find.text('Listen to the word'), findsNothing);
    expect(find.text('Satz anhören'), findsOneWidget);
    expect(find.textContaining('___'), findsNothing); // Satz nur zum Hören
    expect(find.text('appointment'), findsNothing);
    expect(find.text('fever'), findsNothing);
    await tester.tap(find.text('Satz anhören'));
    await tester.pump();
  });

  testWidgets('Kumachan gibt Tipp um Tipp, aber nie die Lösung', (
    tester,
  ) async {
    await pumpApp(tester, '/s/hoer1/ueben/kreuzwort?set=arzt');
    await tester.tap(find.text('Tipp'));
    await tester.pump();
    expect(find.textContaining('Ein Nomen mit'), findsOneWidget);
    await tester.tap(find.text('Tipp').last);
    await tester.pump();
    expect(
      find.textContaining('Es beginnt mit „T“ und hat 6 Buchstaben'),
      findsOneWidget,
    );
    await tester.tap(find.text('Tipp').last);
    await tester.pump();
    expect(find.textContaining('Mehr Tipps habe ich nicht'), findsOneWidget);
    expect(find.text('Termin'), findsNothing); // keine Lösung
  });

  testWidgets('Diktat korrigiert Groß-/Kleinschreibung und zählt sie', (
    tester,
  ) async {
    await pumpApp(tester, '/s/anna1/ueben/diktat?set=arzt');
    await tester.enterText(
      find.byType(TextField),
      'ich habe morgen einen termin',
    );
    await tester.tap(find.text('Prüfen'));
    await tester.pumpAndSettle();
    expect(
      find.text('Achte auf die Groß- und Kleinschreibung:'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Weiter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('0 von 1 richtig'), findsOneWidget);
  });

  testWidgets('fide üben: Bild wählen, frei antworten, Punkte wie im Test', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester, '/s/fide1/ueben/fide?set=essen');
    expect(
      find.text(
        'Wie im fide-Test: Du hörst die Situation und die Frage, '
        'dann den Text – und am Schluss noch einmal die Frage.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Üben'));
    await tester.pumpAndSettle();
    // Beim Üben steht die Situation da; Japanisch nur auf Wunsch.
    expect(find.text('Frau Nakamura ist auf dem Markt.'), findsOneWidget);
    expect(find.text('中村さんは市場にいます。'), findsNothing);
    await tester.tap(find.text('日本語').first);
    await tester.pump();
    expect(find.text('中村さんは市場にいます。'), findsOneWidget);

    await tester.tap(find.text('b)'));
    await tester.pumpAndSettle();
    expect(find.text('Richtig!'), findsOneWidget);
    expect(find.text('Das hast du gehört:'), findsOneWidget);
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'einen Kuchen');
    await tester.tap(find.text('Prüfen'));
    await tester.pumpAndSettle();
    expect(find.text('Richtig!'), findsOneWidget);
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('Übung geschafft!'), findsOneWidget);
    expect(find.textContaining('A2: 1 von 1 Punkten'), findsOneWidget);
    expect(find.textContaining('B1: 2 von 2 Punkten'), findsOneWidget);
  });

  testWidgets('fide wie in der Prüfung: kein Text, höchstens zweimal hören', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester, '/s/fide1/ueben/fide?set=essen');
    await tester.tap(find.text('Wie in der Prüfung'));
    await tester.pumpAndSettle();
    expect(find.text('Frau Nakamura ist auf dem Markt.'), findsNothing);
    expect(find.text('Was kostet ein Kilo Tomaten?'), findsNothing);
    // Die erste Wiedergabe startet von selbst.
    expect(find.text('Du darfst noch einmal hören.'), findsOneWidget);
    await tester.tap(find.text('Anhören'));
    await tester.pump();
    expect(find.text('Du hast zweimal gehört.'), findsOneWidget);
    expect(find.text('Tipp'), findsNothing); // kein Kumachan in der Prüfung
    // Falsches Bild: keine Rückmeldung bis zum Schluss.
    await tester.tap(find.text('a)'));
    await tester.pumpAndSettle();
    expect(find.text('Richtig wäre:'), findsNothing);
  });

  testWidgets('Einzelne Wörter: kein Set, aber unter „Alle Wörter“', (
    tester,
  ) async {
    await pumpApp(tester, '/s/samm1');
    // Unter „Themen“ steht nur das Thema.
    expect(find.text('Beim Arzt'), findsOneWidget);
    expect(find.text('Wörter ohne Thema'), findsNothing);

    await tester.ensureVisible(find.text('Alle Wörter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alle Wörter'));
    await tester.pumpAndSettle();

    // Alle Wörter von A bis Z, der Artikel zählt nicht mit.
    double y(String term) => tester.getTopLeft(find.text(term)).dy;
    expect(y('beachten'), lessThan(y('einen Ball werfen')));
    expect(y('einen Ball werfen'), lessThan(y('das Fieber')));
    expect(y('das Fieber'), lessThan(y('die Schürze')));
    expect(y('die Schürze'), lessThan(y('der Termin')));
    // Die einzelnen Wörter kann man hier üben.
    expect(find.text('Wörter ohne Thema üben'), findsOneWidget);

    // Suche: ü wie u, auch in der Übersetzung.
    await tester.enterText(find.byType(TextField), 'schurz');
    await tester.pumpAndSettle();
    expect(find.text('die Schürze'), findsOneWidget);
    expect(find.text('der Termin'), findsNothing);
    await tester.enterText(find.byType(TextField), 'fever');
    await tester.pumpAndSettle();
    expect(find.text('das Fieber'), findsOneWidget);
    expect(find.text('die Schürze'), findsNothing);
    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pumpAndSettle();
    expect(find.text('Kein Wort gefunden.'), findsOneWidget);

    // Tippen zeigt den Beispielsatz.
    await tester.enterText(find.byType(TextField), 'schurz');
    await tester.pumpAndSettle();
    expect(find.text('Beim Kochen trage ich eine Schürze.'), findsNothing);
    await tester.ensureVisible(find.text('die Schürze'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('die Schürze'));
    await tester.pumpAndSettle();
    expect(find.text('Beim Kochen trage ich eine Schürze.'), findsOneWidget);
  });

  testWidgets('Lernkarte eines einzelnen Worts nennt kein Thema', (
    tester,
  ) async {
    await pumpApp(tester, '/s/samm1/lernen?set=lose');
    expect(find.text('Wörter ohne Thema'), findsNothing);
    expect(find.textContaining('von 3'), findsOneWidget);
  });

  testWidgets('Ohne Sammlung gibt es keine Übungen bei „Alle Wörter“', (
    tester,
  ) async {
    await pumpApp(tester, '/s/anna1/woerter');
    expect(find.text('der Termin'), findsOneWidget);
    expect(find.text('Wörter ohne Thema üben'), findsNothing);
  });

  testWidgets('Wörter ohne Thema üben führt zu den Übungen', (tester) async {
    await pumpApp(tester, '/s/samm1/woerter');
    await tester.tap(find.text('Wörter ohne Thema üben'));
    await tester.pumpAndSettle();
    expect(find.text('Wörter ohne Thema'), findsOneWidget);
    expect(find.text('Zuordnen'), findsOneWidget);
    expect(find.text('Dieses Set lernen'), findsNothing);
  });

  testWidgets('Kumachans Frage drückt Leonis Blase nicht zusammen', (
    tester,
  ) async {
    LeoniFigure.animate = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 335,
              child: LeoniSays(
                headline: 'Reika!',
                companion: KumaPose.wave,
                companionSays: 'Willst du deine Decke sehen?',
                onCompanionTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // Genug Platz für den Text (früher blieben rund 40 Pixel).
    expect(tester.getSize(find.text('Reika!')).width, greaterThan(90));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unbekannter Code zeigt freundliche Meldung', (tester) async {
    await pumpApp(tester, '/s/gibtsnicht');
    expect(find.text('Dieser Link funktioniert nicht'), findsOneWidget);
  });
}
