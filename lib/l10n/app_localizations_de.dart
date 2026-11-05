// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'LearnwithLeoni';

  @override
  String greeting(String name) {
    return 'Hallo $name!';
  }

  @override
  String get todayTitle => 'Heute';

  @override
  String dueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Karten zu wiederholen',
      one: '1 Karte zu wiederholen',
      zero: 'Keine Karten zu wiederholen',
    );
    return '$_temp0';
  }

  @override
  String newCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Karten',
      one: '1 neue Karte',
      zero: 'keine neuen Karten',
    );
    return '$_temp0';
  }

  @override
  String get startLearning => 'Jetzt lernen';

  @override
  String get allDoneToday => 'Für heute ist alles erledigt.';

  @override
  String get yourSets => 'Deine Sets';

  @override
  String cardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Karten',
      one: '1 Karte',
    );
    return '$_temp0';
  }

  @override
  String get statLearned => 'gelernt';

  @override
  String get statLearning => 'im Lernen';

  @override
  String get statNew => 'neu';

  @override
  String get games => 'Spiele';

  @override
  String get gameHangman => 'Hangman';

  @override
  String get gameAbcRadio => 'ABC-Radio';

  @override
  String get gameCrossword => 'Kreuzworträtsel';

  @override
  String get comingSoon => 'Bald verfügbar';

  @override
  String get comingSoonBody =>
      'Daran arbeitet Leoni gerade. Schau bald wieder vorbei!';

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get privacy => 'Datenschutz';

  @override
  String get back => 'Zurück';

  @override
  String get landingTitle => 'Willkommen bei LearnwithLeoni';

  @override
  String get landingBody =>
      'Öffne bitte den persönlichen Link, den du von Leoni bekommen hast. Dort findest du deine Karten, Übungen und Spiele.';

  @override
  String get notFoundTitle => 'Dieser Link funktioniert nicht';

  @override
  String get notFoundBody =>
      'Vielleicht ist er unvollständig oder nicht mehr gültig. Frag Leoni nach deinem aktuellen Link.';

  @override
  String get loadErrorTitle => 'Etwas hat nicht geklappt';

  @override
  String get loadErrorBody =>
      'Die Inhalte konnten nicht geladen werden. Prüfe deine Internetverbindung.';

  @override
  String get retry => 'Nochmal versuchen';

  @override
  String get learnTitle => 'Lernen';

  @override
  String get learnThisSet => 'Dieses Set lernen';

  @override
  String get tapToFlip => 'Tippe auf die Karte zum Umdrehen';

  @override
  String get flip => 'Umdrehen';

  @override
  String get gradeKnew => 'Wusste ich';

  @override
  String get gradeAlmost => 'Fast';

  @override
  String get gradeNotKnown => 'Nicht gewusst';

  @override
  String progressOf(int current, int total) {
    return '$current von $total';
  }

  @override
  String get sessionDoneTitle => 'Geschafft!';

  @override
  String sessionDoneStats(int knew, int almost, int notKnown) {
    return '$knew gewusst · $almost fast · $notKnown noch üben';
  }

  @override
  String get backHome => 'Zur Startseite';

  @override
  String get nothingToLearn =>
      'Gerade gibt es hier nichts zu wiederholen. Komm morgen wieder!';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage in Folge',
      one: '1 Tag in Folge',
    );
    return '$_temp0';
  }

  @override
  String get exampleLabel => 'Beispiel';

  @override
  String get close => 'Schließen';

  @override
  String get allCards => 'Alle Karten';

  @override
  String get practice => 'Üben';

  @override
  String get exChoice => 'Multiple Choice';

  @override
  String get exMatch => 'Zuordnen';

  @override
  String get exCloze => 'Lückentext';

  @override
  String get exDictation => 'Diktat';

  @override
  String get exListening => 'Hörverstehen';

  @override
  String get exCrossword => 'Kreuzworträtsel';

  @override
  String get check => 'Prüfen';

  @override
  String get next => 'Weiter';

  @override
  String get correctAnswer => 'Richtig!';

  @override
  String get almostCorrect => 'Fast richtig – so schreibt man es:';

  @override
  String get wrongAnswer => 'Richtig wäre:';

  @override
  String get yourAnswer => 'Deine Antwort';

  @override
  String get listen => 'Anhören';

  @override
  String get listenSlow => 'Langsam';

  @override
  String get chooseTranslation => 'Was bedeutet das?';

  @override
  String get fillGap => 'Was passt in die Lücke?';

  @override
  String get writeWhatYouHear => 'Hör gut zu und schreib den Satz auf.';

  @override
  String get matchInstruction =>
      'Tippe ein Wort und dann die passende Übersetzung.';

  @override
  String get showText => 'Text anzeigen';

  @override
  String get hideText => 'Text ausblenden';

  @override
  String get listenFirst =>
      'Hör dir zuerst den Text an, dann beantworte die Fragen.';

  @override
  String get exerciseDone => 'Übung geschafft!';

  @override
  String scoreOf(int correct, int total) {
    return '$correct von $total richtig';
  }

  @override
  String get again => 'Nochmal';

  @override
  String get revealLetter => 'Buchstabe aufdecken';

  @override
  String get across => 'Waagrecht';

  @override
  String get down => 'Senkrecht';

  @override
  String get solved => 'Gelöst!';

  @override
  String get voiceNote => 'Computerstimme – Leonis Aufnahme folgt.';

  @override
  String get audioMissing => 'Für diesen Text gibt es noch keine Aufnahme.';

  @override
  String get chooseSet => 'Welches Set?';

  @override
  String get listenWord => 'Wort anhören';

  @override
  String get listenSentence => 'Satz anhören';

  @override
  String get crosswordListenHint =>
      'Hör dir das Wort an und schreib es ohne Artikel ins Rätsel.';

  @override
  String get hangmanAll => 'Alle';

  @override
  String hangmanCategory(String name) {
    return 'Kategorie: $name';
  }

  @override
  String get hangmanHint => 'Tipp (kostet 1 Leben)';

  @override
  String get hangmanShowClue => 'Übersetzung als Hinweis';

  @override
  String get hangmanWon => 'Gewonnen!';

  @override
  String get hangmanLost => 'Leider verloren';

  @override
  String hangmanSolvedWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mit $count Fehlern gelöst.',
      one: 'Mit 1 Fehler gelöst.',
      zero: 'Ohne Fehler gelöst!',
    );
    return '$_temp0';
  }

  @override
  String get hangmanWordWas => 'Das Wort war:';

  @override
  String get newGame => 'Neues Spiel';

  @override
  String get orPressEnter => 'oder Enter drücken';

  @override
  String get statWins => 'Siege';

  @override
  String get statLosses => 'Niederlagen';

  @override
  String statStreak(int best) {
    return 'Serie (Rekord: $best)';
  }

  @override
  String livesLeft(int count, int max) {
    return 'Noch $count von $max Versuchen';
  }

  @override
  String letterKey(String letter) {
    return 'Buchstabe $letter';
  }

  @override
  String get abcTitle => 'ABC-Radio';

  @override
  String get abcIntro =>
      'Ein Buchstabe, eine Minute Sendezeit: Finde so viele Wörter wie möglich, die mit dem Buchstaben anfangen. Weisst du eines nicht, sag einfach „weiter“.';

  @override
  String get abcTopics => 'Themen';

  @override
  String get abcTopicMix => 'Mischung';

  @override
  String get abcTopicVocab => 'Meine Wörter';

  @override
  String get abcTopicCulture => 'Schweiz';

  @override
  String get abcTopicPeople => 'Prominente';

  @override
  String get abcTopicFood => 'Essen';

  @override
  String get abcTopicTraditions => 'Traditionen';

  @override
  String get abcTime => 'Sendezeit';

  @override
  String abcSeconds(int count) {
    return '$count Sekunden';
  }

  @override
  String get abcStart => 'Auf Sendung!';

  @override
  String get abcSkip => 'Weiter';

  @override
  String get abcOk => 'OK';

  @override
  String get abcLetter => 'Buchstabe';

  @override
  String abcGoal(int count) {
    return 'Ziel: $count richtige';
  }

  @override
  String abcScore(int count) {
    return '$count richtig';
  }

  @override
  String abcRecord(String letter, int count) {
    return 'Dein Rekord mit $letter: $count';
  }

  @override
  String get abcTimeUp => 'Sendeschluss!';

  @override
  String get abcGoalReached => 'Ziel erreicht – stark!';

  @override
  String get abcReview => 'Alle Hinweise';

  @override
  String get abcNotEnough =>
      'Für diese Themen gibt es noch nicht genug Hinweise. Wähle mehr Themen aus.';

  @override
  String get privacyBody =>
      'LearnwithLeoni sammelt keine Daten. Es gibt kein Konto, kein Tracking und keine Cookies.\n\nDein Lernstand wird nur auf deinem Gerät gespeichert (im Browser). Leoni sieht ihn nicht. Wenn du die Browserdaten löschst oder das Gerät wechselst, beginnt dein Lernstand neu – deine Inhalte bleiben erhalten.\n\nOnline gespeichert sind nur dein Vorname oder Spitzname, deine Sprache, dein Niveau und deine Lerninhalte.';
}
