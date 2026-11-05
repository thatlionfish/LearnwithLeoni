import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'LearnwithLeoni'**
  String get appTitle;

  /// No description provided for @greeting.
  ///
  /// In de, this message translates to:
  /// **'Hallo {name}!'**
  String greeting(String name);

  /// No description provided for @todayTitle.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get todayTitle;

  /// No description provided for @dueCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine Karten zu wiederholen} =1{1 Karte zu wiederholen} other{{count} Karten zu wiederholen}}'**
  String dueCount(int count);

  /// No description provided for @newCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{keine neuen Karten} =1{1 neue Karte} other{{count} neue Karten}}'**
  String newCount(int count);

  /// No description provided for @startLearning.
  ///
  /// In de, this message translates to:
  /// **'Jetzt lernen'**
  String get startLearning;

  /// No description provided for @allDoneToday.
  ///
  /// In de, this message translates to:
  /// **'Für heute ist alles erledigt.'**
  String get allDoneToday;

  /// No description provided for @yourSets.
  ///
  /// In de, this message translates to:
  /// **'Deine Sets'**
  String get yourSets;

  /// No description provided for @cardCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Karte} other{{count} Karten}}'**
  String cardCount(int count);

  /// No description provided for @statLearned.
  ///
  /// In de, this message translates to:
  /// **'gelernt'**
  String get statLearned;

  /// No description provided for @statLearning.
  ///
  /// In de, this message translates to:
  /// **'im Lernen'**
  String get statLearning;

  /// No description provided for @statNew.
  ///
  /// In de, this message translates to:
  /// **'neu'**
  String get statNew;

  /// No description provided for @games.
  ///
  /// In de, this message translates to:
  /// **'Spiele'**
  String get games;

  /// No description provided for @gameHangman.
  ///
  /// In de, this message translates to:
  /// **'Hangman'**
  String get gameHangman;

  /// No description provided for @gameAbcRadio.
  ///
  /// In de, this message translates to:
  /// **'ABC-Radio'**
  String get gameAbcRadio;

  /// No description provided for @gameCrossword.
  ///
  /// In de, this message translates to:
  /// **'Kreuzworträtsel'**
  String get gameCrossword;

  /// No description provided for @comingSoon.
  ///
  /// In de, this message translates to:
  /// **'Bald verfügbar'**
  String get comingSoon;

  /// No description provided for @comingSoonBody.
  ///
  /// In de, this message translates to:
  /// **'Daran arbeitet Leoni gerade. Schau bald wieder vorbei!'**
  String get comingSoonBody;

  /// No description provided for @settings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get language;

  /// No description provided for @privacy.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get privacy;

  /// No description provided for @back.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get back;

  /// No description provided for @landingTitle.
  ///
  /// In de, this message translates to:
  /// **'Willkommen bei LearnwithLeoni'**
  String get landingTitle;

  /// No description provided for @landingBody.
  ///
  /// In de, this message translates to:
  /// **'Öffne bitte den persönlichen Link, den du von Leoni bekommen hast. Dort findest du deine Karten, Übungen und Spiele.'**
  String get landingBody;

  /// No description provided for @notFoundTitle.
  ///
  /// In de, this message translates to:
  /// **'Dieser Link funktioniert nicht'**
  String get notFoundTitle;

  /// No description provided for @notFoundBody.
  ///
  /// In de, this message translates to:
  /// **'Vielleicht ist er unvollständig oder nicht mehr gültig. Frag Leoni nach deinem aktuellen Link.'**
  String get notFoundBody;

  /// No description provided for @loadErrorTitle.
  ///
  /// In de, this message translates to:
  /// **'Etwas hat nicht geklappt'**
  String get loadErrorTitle;

  /// No description provided for @loadErrorBody.
  ///
  /// In de, this message translates to:
  /// **'Die Inhalte konnten nicht geladen werden. Prüfe deine Internetverbindung.'**
  String get loadErrorBody;

  /// No description provided for @retry.
  ///
  /// In de, this message translates to:
  /// **'Nochmal versuchen'**
  String get retry;

  /// No description provided for @learnTitle.
  ///
  /// In de, this message translates to:
  /// **'Lernen'**
  String get learnTitle;

  /// No description provided for @learnThisSet.
  ///
  /// In de, this message translates to:
  /// **'Dieses Set lernen'**
  String get learnThisSet;

  /// No description provided for @tapToFlip.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf die Karte zum Umdrehen'**
  String get tapToFlip;

  /// No description provided for @flip.
  ///
  /// In de, this message translates to:
  /// **'Umdrehen'**
  String get flip;

  /// No description provided for @gradeKnew.
  ///
  /// In de, this message translates to:
  /// **'Wusste ich'**
  String get gradeKnew;

  /// No description provided for @gradeAlmost.
  ///
  /// In de, this message translates to:
  /// **'Fast'**
  String get gradeAlmost;

  /// No description provided for @gradeNotKnown.
  ///
  /// In de, this message translates to:
  /// **'Nicht gewusst'**
  String get gradeNotKnown;

  /// No description provided for @progressOf.
  ///
  /// In de, this message translates to:
  /// **'{current} von {total}'**
  String progressOf(int current, int total);

  /// No description provided for @sessionDoneTitle.
  ///
  /// In de, this message translates to:
  /// **'Geschafft!'**
  String get sessionDoneTitle;

  /// No description provided for @sessionDoneStats.
  ///
  /// In de, this message translates to:
  /// **'{knew} gewusst · {almost} fast · {notKnown} noch üben'**
  String sessionDoneStats(int knew, int almost, int notKnown);

  /// No description provided for @backHome.
  ///
  /// In de, this message translates to:
  /// **'Zur Startseite'**
  String get backHome;

  /// No description provided for @nothingToLearn.
  ///
  /// In de, this message translates to:
  /// **'Gerade gibt es hier nichts zu wiederholen. Komm morgen wieder!'**
  String get nothingToLearn;

  /// No description provided for @streakDays.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Tag in Folge} other{{count} Tage in Folge}}'**
  String streakDays(int count);

  /// No description provided for @exampleLabel.
  ///
  /// In de, this message translates to:
  /// **'Beispiel'**
  String get exampleLabel;

  /// No description provided for @close.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get close;

  /// No description provided for @allCards.
  ///
  /// In de, this message translates to:
  /// **'Alle Karten'**
  String get allCards;

  /// No description provided for @practice.
  ///
  /// In de, this message translates to:
  /// **'Üben'**
  String get practice;

  /// No description provided for @exChoice.
  ///
  /// In de, this message translates to:
  /// **'Multiple Choice'**
  String get exChoice;

  /// No description provided for @exMatch.
  ///
  /// In de, this message translates to:
  /// **'Zuordnen'**
  String get exMatch;

  /// No description provided for @exCloze.
  ///
  /// In de, this message translates to:
  /// **'Lückentext'**
  String get exCloze;

  /// No description provided for @exDictation.
  ///
  /// In de, this message translates to:
  /// **'Diktat'**
  String get exDictation;

  /// No description provided for @exListening.
  ///
  /// In de, this message translates to:
  /// **'Hörverstehen'**
  String get exListening;

  /// No description provided for @exCrossword.
  ///
  /// In de, this message translates to:
  /// **'Kreuzworträtsel'**
  String get exCrossword;

  /// No description provided for @check.
  ///
  /// In de, this message translates to:
  /// **'Prüfen'**
  String get check;

  /// No description provided for @next.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get next;

  /// No description provided for @correctAnswer.
  ///
  /// In de, this message translates to:
  /// **'Richtig!'**
  String get correctAnswer;

  /// No description provided for @almostCorrect.
  ///
  /// In de, this message translates to:
  /// **'Fast richtig – so schreibt man es:'**
  String get almostCorrect;

  /// No description provided for @wrongAnswer.
  ///
  /// In de, this message translates to:
  /// **'Richtig wäre:'**
  String get wrongAnswer;

  /// No description provided for @yourAnswer.
  ///
  /// In de, this message translates to:
  /// **'Deine Antwort'**
  String get yourAnswer;

  /// No description provided for @listen.
  ///
  /// In de, this message translates to:
  /// **'Anhören'**
  String get listen;

  /// No description provided for @listenSlow.
  ///
  /// In de, this message translates to:
  /// **'Langsam'**
  String get listenSlow;

  /// No description provided for @chooseTranslation.
  ///
  /// In de, this message translates to:
  /// **'Was bedeutet das?'**
  String get chooseTranslation;

  /// No description provided for @fillGap.
  ///
  /// In de, this message translates to:
  /// **'Was passt in die Lücke?'**
  String get fillGap;

  /// No description provided for @writeWhatYouHear.
  ///
  /// In de, this message translates to:
  /// **'Hör gut zu und schreib den Satz auf.'**
  String get writeWhatYouHear;

  /// No description provided for @matchInstruction.
  ///
  /// In de, this message translates to:
  /// **'Tippe ein Wort und dann die passende Übersetzung.'**
  String get matchInstruction;

  /// No description provided for @showText.
  ///
  /// In de, this message translates to:
  /// **'Text anzeigen'**
  String get showText;

  /// No description provided for @hideText.
  ///
  /// In de, this message translates to:
  /// **'Text ausblenden'**
  String get hideText;

  /// No description provided for @listenFirst.
  ///
  /// In de, this message translates to:
  /// **'Hör dir zuerst den Text an, dann beantworte die Fragen.'**
  String get listenFirst;

  /// No description provided for @exerciseDone.
  ///
  /// In de, this message translates to:
  /// **'Übung geschafft!'**
  String get exerciseDone;

  /// No description provided for @scoreOf.
  ///
  /// In de, this message translates to:
  /// **'{correct} von {total} richtig'**
  String scoreOf(int correct, int total);

  /// No description provided for @again.
  ///
  /// In de, this message translates to:
  /// **'Nochmal'**
  String get again;

  /// No description provided for @revealLetter.
  ///
  /// In de, this message translates to:
  /// **'Buchstabe aufdecken'**
  String get revealLetter;

  /// No description provided for @across.
  ///
  /// In de, this message translates to:
  /// **'Waagrecht'**
  String get across;

  /// No description provided for @down.
  ///
  /// In de, this message translates to:
  /// **'Senkrecht'**
  String get down;

  /// No description provided for @solved.
  ///
  /// In de, this message translates to:
  /// **'Gelöst!'**
  String get solved;

  /// No description provided for @voiceNote.
  ///
  /// In de, this message translates to:
  /// **'Computerstimme – Leonis Aufnahme folgt.'**
  String get voiceNote;

  /// No description provided for @audioMissing.
  ///
  /// In de, this message translates to:
  /// **'Für diesen Text gibt es noch keine Aufnahme.'**
  String get audioMissing;

  /// No description provided for @chooseSet.
  ///
  /// In de, this message translates to:
  /// **'Welches Set?'**
  String get chooseSet;

  /// No description provided for @listenSentence.
  ///
  /// In de, this message translates to:
  /// **'Satz anhören'**
  String get listenSentence;

  /// No description provided for @kumaTip.
  ///
  /// In de, this message translates to:
  /// **'Tipp'**
  String get kumaTip;

  /// No description provided for @kumaAsk.
  ///
  /// In de, this message translates to:
  /// **'Kumachan um einen Tipp bitten'**
  String get kumaAsk;

  /// No description provided for @kumaNoMore.
  ///
  /// In de, this message translates to:
  /// **'Mehr Tipps habe ich nicht – du schaffst das!'**
  String get kumaNoMore;

  /// No description provided for @crosswordListenHint.
  ///
  /// In de, this message translates to:
  /// **'Hör dir den Satz an. Bei der Pause fehlt ein Wort – schreib es so ins Rätsel, wie es in den Satz passt.'**
  String get crosswordListenHint;

  /// No description provided for @hangmanAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get hangmanAll;

  /// No description provided for @hangmanCategory.
  ///
  /// In de, this message translates to:
  /// **'Kategorie: {name}'**
  String hangmanCategory(String name);

  /// No description provided for @hangmanHint.
  ///
  /// In de, this message translates to:
  /// **'Tipp (kostet 1 Leben)'**
  String get hangmanHint;

  /// No description provided for @hangmanShowClue.
  ///
  /// In de, this message translates to:
  /// **'Übersetzung als Hinweis'**
  String get hangmanShowClue;

  /// No description provided for @hangmanWon.
  ///
  /// In de, this message translates to:
  /// **'Gewonnen!'**
  String get hangmanWon;

  /// No description provided for @hangmanLost.
  ///
  /// In de, this message translates to:
  /// **'Leider verloren'**
  String get hangmanLost;

  /// No description provided for @hangmanSolvedWith.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Ohne Fehler gelöst!} =1{Mit 1 Fehler gelöst.} other{Mit {count} Fehlern gelöst.}}'**
  String hangmanSolvedWith(int count);

  /// No description provided for @hangmanWordWas.
  ///
  /// In de, this message translates to:
  /// **'Das Wort war:'**
  String get hangmanWordWas;

  /// No description provided for @newGame.
  ///
  /// In de, this message translates to:
  /// **'Neues Spiel'**
  String get newGame;

  /// No description provided for @orPressEnter.
  ///
  /// In de, this message translates to:
  /// **'oder Enter drücken'**
  String get orPressEnter;

  /// No description provided for @statWins.
  ///
  /// In de, this message translates to:
  /// **'Siege'**
  String get statWins;

  /// No description provided for @statLosses.
  ///
  /// In de, this message translates to:
  /// **'Niederlagen'**
  String get statLosses;

  /// No description provided for @statStreak.
  ///
  /// In de, this message translates to:
  /// **'Serie (Rekord: {best})'**
  String statStreak(int best);

  /// No description provided for @livesLeft.
  ///
  /// In de, this message translates to:
  /// **'Noch {count} von {max} Versuchen'**
  String livesLeft(int count, int max);

  /// No description provided for @letterKey.
  ///
  /// In de, this message translates to:
  /// **'Buchstabe {letter}'**
  String letterKey(String letter);

  /// No description provided for @abcTitle.
  ///
  /// In de, this message translates to:
  /// **'ABC-Radio'**
  String get abcTitle;

  /// No description provided for @abcIntro.
  ///
  /// In de, this message translates to:
  /// **'Ein Buchstabe, eine Minute Sendezeit: Finde so viele Wörter wie möglich, die mit dem Buchstaben anfangen. Weisst du eines nicht, sag einfach „weiter“.'**
  String get abcIntro;

  /// No description provided for @abcTopics.
  ///
  /// In de, this message translates to:
  /// **'Themen'**
  String get abcTopics;

  /// No description provided for @abcTopicMix.
  ///
  /// In de, this message translates to:
  /// **'Mischung'**
  String get abcTopicMix;

  /// No description provided for @abcTopicVocab.
  ///
  /// In de, this message translates to:
  /// **'Meine Wörter'**
  String get abcTopicVocab;

  /// No description provided for @abcTopicCulture.
  ///
  /// In de, this message translates to:
  /// **'Schweiz'**
  String get abcTopicCulture;

  /// No description provided for @abcTopicPeople.
  ///
  /// In de, this message translates to:
  /// **'Prominente'**
  String get abcTopicPeople;

  /// No description provided for @abcTopicFood.
  ///
  /// In de, this message translates to:
  /// **'Essen'**
  String get abcTopicFood;

  /// No description provided for @abcTopicTraditions.
  ///
  /// In de, this message translates to:
  /// **'Traditionen'**
  String get abcTopicTraditions;

  /// No description provided for @abcTime.
  ///
  /// In de, this message translates to:
  /// **'Sendezeit'**
  String get abcTime;

  /// No description provided for @abcSeconds.
  ///
  /// In de, this message translates to:
  /// **'{count} Sekunden'**
  String abcSeconds(int count);

  /// No description provided for @abcStart.
  ///
  /// In de, this message translates to:
  /// **'Auf Sendung!'**
  String get abcStart;

  /// No description provided for @abcSkip.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get abcSkip;

  /// No description provided for @abcOk.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get abcOk;

  /// No description provided for @abcLetter.
  ///
  /// In de, this message translates to:
  /// **'Buchstabe'**
  String get abcLetter;

  /// No description provided for @abcGoal.
  ///
  /// In de, this message translates to:
  /// **'Ziel: {count} richtige'**
  String abcGoal(int count);

  /// No description provided for @abcScore.
  ///
  /// In de, this message translates to:
  /// **'{count} richtig'**
  String abcScore(int count);

  /// No description provided for @abcRecord.
  ///
  /// In de, this message translates to:
  /// **'Dein Rekord mit {letter}: {count}'**
  String abcRecord(String letter, int count);

  /// No description provided for @abcTimeUp.
  ///
  /// In de, this message translates to:
  /// **'Sendeschluss!'**
  String get abcTimeUp;

  /// No description provided for @abcGoalReached.
  ///
  /// In de, this message translates to:
  /// **'Ziel erreicht – stark!'**
  String get abcGoalReached;

  /// No description provided for @abcReview.
  ///
  /// In de, this message translates to:
  /// **'Alle Hinweise'**
  String get abcReview;

  /// No description provided for @abcNotEnough.
  ///
  /// In de, this message translates to:
  /// **'Für diese Themen gibt es noch nicht genug Hinweise. Wähle mehr Themen aus.'**
  String get abcNotEnough;

  /// No description provided for @privacyBody.
  ///
  /// In de, this message translates to:
  /// **'LearnwithLeoni sammelt keine Daten. Es gibt kein Konto, kein Tracking und keine Cookies.\n\nDein Lernstand wird nur auf deinem Gerät gespeichert (im Browser). Leoni sieht ihn nicht. Wenn du die Browserdaten löschst oder das Gerät wechselst, beginnt dein Lernstand neu – deine Inhalte bleiben erhalten.\n\nOnline gespeichert sind nur dein Vorname oder Spitzname, deine Sprache, dein Niveau und deine Lerninhalte.'**
  String get privacyBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
