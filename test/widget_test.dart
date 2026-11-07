import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnwithleoni/app_settings.dart';
import 'package:learnwithleoni/audio/kuma_voice.dart';
import 'package:learnwithleoni/data/leitner.dart';
import 'package:learnwithleoni/data/repository.dart';
import 'package:learnwithleoni/main.dart';
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
});

Future<void> pumpApp(WidgetTester tester, String location) async {
  SharedPreferences.setMockInitialValues({});
  // Zwischengespeicherte Futures nicht über Tests hinweg teilen.
  LeoniPhrases.resetCache();
  ProgressStore.resetCache();
  KumaVoice.reset();
  LeoniFigure.animate = false;
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
  testWidgets('Startseite zeigt Begrüßung, Sets und Spiele', (tester) async {
    await pumpApp(tester, '/s/anna1');
    expect(
      find.text('Hallo Anna!'),
      findsOneWidget,
    ); // Oberfläche immer Deutsch
    expect(
      find.text('Your sets'),
      findsOneWidget,
    ); // Hilfesprache klein daneben
    expect(find.text('Beim Arzt'), findsOneWidget);
    expect(
      find.text('Geheimer Entwurf'),
      findsNothing,
    ); // Entwürfe nie beim Schüler
    expect(find.text('2 neue Karten'), findsOneWidget);
    expect(find.text('Hangman'), findsOneWidget);
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

  testWidgets('Unbekannter Code zeigt freundliche Meldung', (tester) async {
    await pumpApp(tester, '/s/gibtsnicht');
    expect(find.text('Dieser Link funktioniert nicht'), findsOneWidget);
  });
}
