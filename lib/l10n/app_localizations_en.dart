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
  String get listenSentence => 'Listen to the sentence';

  @override
  String get caseHint => 'Watch the capital and small letters:';

  @override
  String get dictationAlmost => 'Almost – look at the marked words:';

  @override
  String get kumaTip => 'Hint';

  @override
  String get kumaStrip => 'Stuck? Tap Kumachan for a hint.';

  @override
  String get kumaAsk => 'Ask Kumachan for a hint';

  @override
  String get crosswordListenHint =>
      'Listen to the sentence. A word is missing at the pause – write it in the puzzle the way it fits the sentence.';

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
  String get statSecure => 'mastered';

  @override
  String get germanFront => 'German on the front';

  @override
  String get germanBack => 'German on the back';

  @override
  String reviewIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'comes back in $count days',
      one: 'comes back tomorrow',
      zero: 'comes back today',
    );
    return '$_temp0';
  }

  @override
  String get reviewAgainNow => 'comes back in a moment';

  @override
  String get reviewSecure => 'mastered – it won\'t come back on its own';

  @override
  String securedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You\'ve mastered $count words!',
      one: 'You\'ve mastered 1 word!',
    );
    return '$_temp0';
  }

  @override
  String cardBox(int box) {
    return 'Box $box of 5';
  }

  @override
  String get spacedInfo =>
      'What you know comes back after 1, 2, 4, 8 and 16 days. If you still know it then, you\'ve mastered it.';

  @override
  String get blanketTitle => 'Kumachan\'s blanket';

  @override
  String get blanketIntro =>
      'Every word is a crochet square. Each time you know a word, Kumachan crochets another round. Once you\'ve mastered the word, he sews the square onto the big blanket – and can snuggle in a little more.';

  @override
  String blanketSummary(int attached, int onHook) {
    return '$attached on the blanket · $onHook on the hook';
  }

  @override
  String blanketDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count blankets are already finished!',
      one: '1 blanket is already finished!',
    );
    return '$_temp0';
  }

  @override
  String get blanketOnHook => 'On the hook';

  @override
  String get blanketAttached => 'On the blanket';

  @override
  String blanketWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words are still waiting for Kumachan\'s hook.',
      one: '1 word is still waiting for Kumachan\'s hook.',
    );
    return '$_temp0';
  }

  @override
  String blanketRounds(int count) {
    return '$count of 5 rounds';
  }

  @override
  String get blanketEmpty =>
      'Learn your first words – then Kumachan starts crocheting.';

  @override
  String get blanketOpen => 'To the blanket';

  @override
  String get blanketToday => 'Crocheted today';

  @override
  String blanketNewRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kumachan crocheted $count rounds.',
      one: 'Kumachan crocheted 1 round.',
    );
    return '$_temp0';
  }

  @override
  String get blanketJoined => 'onto the blanket!';

  @override
  String get helpLanguage => 'Help language';

  @override
  String get helpLanguageInfo =>
      'The app stays in German. The help language is only shown in small print.';

  @override
  String get helpNone => 'None – German only';

  @override
  String get exFide => 'fide · Listening';

  @override
  String get fideIntro =>
      'Just like the fide test: you hear the situation and the question, then the text – and at the end the question once more.';

  @override
  String get fideModeExam => 'Like the exam';

  @override
  String get fideModeExamInfo => 'Listen twice at most, no text, no hints.';

  @override
  String get fideModePractice => 'Practise';

  @override
  String get fideModePracticeInfo =>
      'Listen as often as you like – slowly too. After answering you see the text.';

  @override
  String get fideStart => 'Let\'s go';

  @override
  String get fideSituation => 'Situation';

  @override
  String fideQuestion(int number) {
    return 'Question $number';
  }

  @override
  String get fidePlay => 'Listen';

  @override
  String fidePlaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You can listen $count times.',
      one: 'You can listen once more.',
      zero: 'You\'ve listened twice.',
    );
    return '$_temp0';
  }

  @override
  String get fidePictureTask => 'Which picture fits? Tap a, b or c.';

  @override
  String get fideOpenTask =>
      'Answer the question briefly – two or three words are enough.';

  @override
  String get fideModelAnswer => 'Possible answer:';

  @override
  String get fideSelfCheck => 'My answer means the same';

  @override
  String get fideTranscript => 'This is what you heard:';

  @override
  String fidePoints(String level, int points, int max) {
    return '$level: $points of $max points';
  }

  @override
  String get fideResultNote =>
      'In the real test, the points from “Listening” and “Speaking” are combined.';

  @override
  String get privacyBody =>
      'LearnwithLeoni doesn\'t collect any data. There\'s no account, no tracking and no cookies.\n\nYour progress is stored only on your device (in your browser). Leoni can\'t see it. If you clear your browser data or switch devices, your progress starts over – your content stays.\n\nThe only things stored online are your first name or nickname, your language, your level and your learning content.';
}
