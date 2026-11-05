// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LearnwithLeoni';

  @override
  String greeting(String name) {
    return 'Hi $name!';
  }

  @override
  String get todayTitle => 'Today';

  @override
  String dueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards to review',
      one: '1 card to review',
      zero: 'No cards to review',
    );
    return '$_temp0';
  }

  @override
  String newCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new cards',
      one: '1 new card',
      zero: 'no new cards',
    );
    return '$_temp0';
  }

  @override
  String get startLearning => 'Start learning';

  @override
  String get allDoneToday => 'You\'re all done for today.';

  @override
  String get yourSets => 'Your sets';

  @override
  String cardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
    );
    return '$_temp0';
  }

  @override
  String get statLearned => 'learned';

  @override
  String get statLearning => 'learning';

  @override
  String get statNew => 'new';

  @override
  String get games => 'Games';

  @override
  String get gameHangman => 'Hangman';

  @override
  String get gameAbcRadio => 'ABC Radio';

  @override
  String get gameCrossword => 'Crossword';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get comingSoonBody =>
      'Leoni is working on this right now. Check back soon!';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get privacy => 'Privacy';

  @override
  String get back => 'Back';

  @override
  String get landingTitle => 'Welcome to LearnwithLeoni';

  @override
  String get landingBody =>
      'Please open the personal link you got from Leoni. That\'s where you\'ll find your cards, exercises and games.';

  @override
  String get notFoundTitle => 'This link doesn\'t work';

  @override
  String get notFoundBody =>
      'It may be incomplete or no longer valid. Ask Leoni for your current link.';

  @override
  String get loadErrorTitle => 'Something went wrong';

  @override
  String get loadErrorBody =>
      'Your content couldn\'t be loaded. Please check your internet connection.';

  @override
  String get retry => 'Try again';

  @override
  String get learnTitle => 'Learn';

  @override
  String get learnThisSet => 'Learn this set';

  @override
  String get tapToFlip => 'Tap the card to flip it';

  @override
  String get flip => 'Flip';

  @override
  String get gradeKnew => 'I knew it';

  @override
  String get gradeAlmost => 'Almost';

  @override
  String get gradeNotKnown => 'Didn\'t know';

  @override
  String progressOf(int current, int total) {
    return '$current of $total';
  }

  @override
  String get sessionDoneTitle => 'Done!';

  @override
  String sessionDoneStats(int knew, int almost, int notKnown) {
    return '$knew known · $almost almost · $notKnown to practise';
  }

  @override
  String get backHome => 'Back to home';

  @override
  String get nothingToLearn =>
      'There\'s nothing to review here right now. Come back tomorrow!';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days in a row',
      one: '1 day in a row',
    );
    return '$_temp0';
  }

  @override
  String get exampleLabel => 'Example';

  @override
  String get close => 'Close';

  @override
  String get allCards => 'All cards';

  @override
  String get practice => 'Practise';

  @override
  String get exChoice => 'Multiple choice';

  @override
  String get exMatch => 'Match';

  @override
  String get exCloze => 'Fill the gap';

  @override
  String get exDictation => 'Dictation';

  @override
  String get exListening => 'Listening';

  @override
  String get exCrossword => 'Crossword';

  @override
  String get check => 'Check';

  @override
  String get next => 'Next';

  @override
  String get correctAnswer => 'Correct!';

  @override
  String get almostCorrect => 'Almost – this is how it\'s spelled:';

  @override
  String get wrongAnswer => 'The answer is:';

  @override
  String get yourAnswer => 'Your answer';

  @override
  String get listen => 'Listen';

  @override
  String get listenSlow => 'Slowly';

  @override
  String get chooseTranslation => 'What does it mean?';

  @override
  String get fillGap => 'What fits in the gap?';

  @override
  String get writeWhatYouHear =>
      'Listen carefully and write down the sentence.';

  @override
  String get matchInstruction => 'Tap a word, then its translation.';

  @override
  String get showText => 'Show text';

  @override
  String get hideText => 'Hide text';

  @override
  String get listenFirst =>
      'Listen to the text first, then answer the questions.';

  @override
  String get exerciseDone => 'Exercise done!';

  @override
  String scoreOf(int correct, int total) {
    return '$correct of $total correct';
  }

  @override
  String get again => 'Again';

  @override
  String get revealLetter => 'Reveal a letter';

  @override
  String get across => 'Across';

  @override
  String get down => 'Down';

  @override
  String get solved => 'Solved!';

  @override
  String get voiceNote => 'Computer voice – Leoni\'s recording is coming.';

  @override
  String get audioMissing => 'There\'s no recording for this text yet.';

  @override
  String get chooseSet => 'Which set?';

  @override
  String get hangmanAll => 'All';

  @override
  String hangmanCategory(String name) {
    return 'Category: $name';
  }

  @override
  String get hangmanHint => 'Hint (costs 1 life)';

  @override
  String get hangmanShowClue => 'Translation as a clue';

  @override
  String get hangmanWon => 'You won!';

  @override
  String get hangmanLost => 'Not this time';

  @override
  String hangmanSolvedWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Solved with $count mistakes.',
      one: 'Solved with 1 mistake.',
      zero: 'Solved without a mistake!',
    );
    return '$_temp0';
  }

  @override
  String get hangmanWordWas => 'The word was:';

  @override
  String get newGame => 'New game';

  @override
  String get orPressEnter => 'or press Enter';

  @override
  String get statWins => 'Wins';

  @override
  String get statLosses => 'Losses';

  @override
  String statStreak(int best) {
    return 'Streak (record: $best)';
  }

  @override
  String livesLeft(int count, int max) {
    return '$count of $max tries left';
  }

  @override
  String letterKey(String letter) {
    return 'Letter $letter';
  }

  @override
  String get abcTitle => 'ABC Radio';

  @override
  String get abcIntro =>
      'One letter, one minute of airtime: find as many words as you can that start with the letter. Don\'t know one? Just say “next”.';

  @override
  String get abcTopics => 'Topics';

  @override
  String get abcTopicMix => 'Mix';

  @override
  String get abcTopicVocab => 'My words';

  @override
  String get abcTopicCulture => 'Switzerland';

  @override
  String get abcTopicPeople => 'Famous people';

  @override
  String get abcTopicFood => 'Food';

  @override
  String get abcTopicTraditions => 'Traditions';

  @override
  String get abcTime => 'Airtime';

  @override
  String abcSeconds(int count) {
    return '$count seconds';
  }

  @override
  String get abcStart => 'On air!';

  @override
  String get abcSkip => 'Next';

  @override
  String get abcOk => 'OK';

  @override
  String get abcLetter => 'Letter';

  @override
  String abcGoal(int count) {
    return 'Goal: $count correct';
  }

  @override
  String abcScore(int count) {
    return '$count correct';
  }

  @override
  String abcRecord(String letter, int count) {
    return 'Your record with $letter: $count';
  }

  @override
  String get abcTimeUp => 'That\'s the end of the show!';

  @override
  String get abcGoalReached => 'Goal reached – brilliant!';

  @override
  String get abcReview => 'All clues';

  @override
  String get abcNotEnough =>
      'There aren\'t enough clues for these topics yet. Choose more topics.';

  @override
  String get privacyBody =>
      'LearnwithLeoni doesn\'t collect any data. There\'s no account, no tracking and no cookies.\n\nYour progress is stored only on your device (in your browser). Leoni can\'t see it. If you clear your browser data or switch devices, your progress starts over – your content stays.\n\nThe only things stored online are your first name or nickname, your language, your level and your learning content.';
}
