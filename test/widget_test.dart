import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnwithleoni/app_settings.dart';
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
    expect(find.text('Hi Anna!'), findsOneWidget); // Erklärsprache Englisch
    expect(find.text('Beim Arzt'), findsOneWidget);
    expect(
      find.text('Geheimer Entwurf'),
      findsNothing,
    ); // Entwürfe nie beim Schüler
    expect(find.text('2 new cards'), findsOneWidget);
    expect(find.text('Hangman'), findsOneWidget);
  });

  testWidgets('Startseite passt auf ein schmales Handy', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester, '/s/anna1');
    expect(tester.takeException(), isNull); // kein Überlauf
    expect(find.text('Hi Anna!'), findsOneWidget);
  });

  testWidgets('Karte umdrehen, bewerten, Sitzung abschließen', (tester) async {
    await pumpApp(tester, '/s/anna1/lernen?set=arzt');
    expect(find.text('der Termin'), findsOneWidget);
    expect(find.text('appointment'), findsNothing);

    await tester.tap(find.text('der Termin'));
    await tester.pumpAndSettle();
    expect(find.text('appointment'), findsOneWidget);

    await tester.tap(find.text('I knew it'));
    await tester.pumpAndSettle();
    expect(find.text('das Fieber'), findsOneWidget);

    // Tastatur: Leertaste dreht um, 1 = gewusst.
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pumpAndSettle();

    expect(find.text('Done!'), findsOneWidget);
    expect(find.textContaining('2 known'), findsOneWidget);
  });

  testWidgets('Lückentext: tippen, prüfen, Rückmeldung', (tester) async {
    await pumpApp(tester, '/s/anna1/ueben/luecken?set=arzt');
    expect(find.text('What fits in the gap?'), findsOneWidget);
    await tester.tap(find.text('Termin'));
    await tester.pumpAndSettle();
    expect(find.text('Correct!'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Exercise done!'), findsOneWidget);
    expect(find.text('1 of 1 correct'), findsOneWidget);
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
    expect(find.text('Exercise done!'), findsOneWidget);
  });

  testWidgets('Kreuzworträtsel lässt sich lösen', (tester) async {
    await pumpApp(tester, '/s/anna1/ueben/kreuzwort?set=arzt');
    expect(find.text('Crossword'), findsOneWidget);
    // Alles aufdecken: jedes Feld antippen und „Buchstabe aufdecken“.
    final cells = find.bySemanticsLabel(RegExp(r'^Feld '));
    final n = cells.evaluate().length;
    expect(n, greaterThan(5));
    for (var i = 0; i < n; i++) {
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Feld ')).at(i));
      await tester.pump();
      await tester.tap(find.text('Reveal a letter'));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('Exercise done!'), findsOneWidget);
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
    await tester.tap(find.text('On air!'));
    await tester.pump(const Duration(milliseconds: 200));
    // Nur ein Buchstabe ist spielbar: F. Hinweis lesen und Antwort tippen.
    final answers = {
      for (final h in fHints) h['clue'] as String: (h['answers'] as List).first,
    };
    final clue = answers.keys.firstWhere(
      (c) => find.text(c).evaluate().isNotEmpty,
    );
    await tester.enterText(find.byType(TextField), answers[clue] as String);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 200));
    // 6 gemeinsame Hinweise mit F plus Annas Wort „Fieber“.
    expect(find.text('1 correct · Goal: 7 correct'), findsOneWidget);
    // Sendung beenden, damit keine Timer offen bleiben.
    await tester.pump(const Duration(seconds: 61));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text("That's the end of the show!"), findsOneWidget);
  });

  testWidgets('Hör-Kreuzworträtsel zeigt keine geschriebenen Hinweise', (
    tester,
  ) async {
    await pumpApp(tester, '/s/hoer1/ueben/kreuzwort?set=arzt');
    expect(find.text('Listen to the word'), findsNothing);
    expect(find.text('Listen to the sentence'), findsOneWidget);
    expect(find.textContaining('___'), findsNothing); // Satz nur zum Hören
    expect(find.text('appointment'), findsNothing);
    expect(find.text('fever'), findsNothing);
    await tester.tap(find.text('Listen to the sentence'));
    await tester.pump();
  });

  testWidgets('Kumachan gibt Tipp um Tipp, aber nie die Lösung', (
    tester,
  ) async {
    await pumpApp(tester, '/s/hoer1/ueben/kreuzwort?set=arzt');
    await tester.tap(find.text('Hint'));
    await tester.pump();
    expect(find.textContaining('Ein Nomen mit'), findsOneWidget);
    await tester.tap(find.text('Hint').last);
    await tester.pump();
    expect(
      find.textContaining('Es beginnt mit „T“ und hat 6 Buchstaben'),
      findsOneWidget,
    );
    await tester.tap(find.text('Hint').last);
    await tester.pump();
    expect(find.textContaining("That's all my hints"), findsOneWidget);
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
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.text('Watch the capital and small letters:'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 1 correct'), findsOneWidget);
  });

  testWidgets('Unbekannter Code zeigt freundliche Meldung', (tester) async {
    await pumpApp(tester, '/s/gibtsnicht');
    expect(find.text("This link doesn't work"), findsOneWidget);
  });
}
