// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'LearnwithLeoni';

  @override
  String greeting(String name) {
    return 'こんにちは、$nameさん！';
  }

  @override
  String get todayTitle => '今日';

  @override
  String dueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '復習するカード：$count枚',
      zero: '復習するカードはありません',
    );
    return '$_temp0';
  }

  @override
  String newCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '新しいカード：$count枚',
      zero: '新しいカードはありません',
    );
    return '$_temp0';
  }

  @override
  String get startLearning => '学習を始める';

  @override
  String get allDoneToday => '今日の分はすべて終わりました。';

  @override
  String get yourSets => 'あなたのセット';

  @override
  String cardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'カード$count枚',
    );
    return '$_temp0';
  }

  @override
  String get statLearned => '覚えた';

  @override
  String get statLearning => '学習中';

  @override
  String get statNew => '新しい';

  @override
  String get games => 'ゲーム';

  @override
  String get gameHangman => 'ハングマン';

  @override
  String get gameAbcRadio => 'ABCラジオ';

  @override
  String get gameCrossword => 'クロスワード';

  @override
  String get comingSoon => '近日公開';

  @override
  String get comingSoonBody => 'レオニが今これを準備しています。また見に来てね！';

  @override
  String get settings => '設定';

  @override
  String get privacy => 'プライバシー';

  @override
  String get back => '戻る';

  @override
  String get landingTitle => 'LearnwithLeoniへようこそ';

  @override
  String get landingBody => 'レオニからもらった個人用のリンクを開いてください。そこにカード、練習問題、ゲームがあります。';

  @override
  String get notFoundTitle => 'このリンクは使えません';

  @override
  String get notFoundBody => 'リンクが不完全か、もう有効ではないかもしれません。レオニに今のリンクを聞いてください。';

  @override
  String get loadErrorTitle => 'うまくいきませんでした';

  @override
  String get loadErrorBody => '内容を読み込めませんでした。インターネット接続を確認してください。';

  @override
  String get retry => 'もう一度試す';

  @override
  String get learnTitle => '学習';

  @override
  String get learnThisSet => 'このセットを学習する';

  @override
  String get tapToFlip => 'カードをタップすると裏返ります';

  @override
  String get flip => '裏返す';

  @override
  String get gradeKnew => 'わかった';

  @override
  String get gradeAlmost => 'もう少し';

  @override
  String get gradeNotKnown => 'わからなかった';

  @override
  String progressOf(int current, int total) {
    return '$current / $total';
  }

  @override
  String get sessionDoneTitle => 'できました！';

  @override
  String sessionDoneStats(int knew, int almost, int notKnown) {
    return 'わかった $knew ・ もう少し $almost ・ 要練習 $notKnown';
  }

  @override
  String get backHome => 'ホームへ';

  @override
  String get nothingToLearn => '今は復習するものがありません。また明日来てね！';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日連続',
    );
    return '$_temp0';
  }

  @override
  String get exampleLabel => '例文';

  @override
  String get close => '閉じる';

  @override
  String get allCards => 'すべてのカード';

  @override
  String get allWords => 'すべての単語';

  @override
  String wordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count語',
    );
    return '$_temp0';
  }

  @override
  String get wordSearch => '単語を探す';

  @override
  String get wordsNoMatch => '単語が見つかりません。';

  @override
  String get looseWordsPractice => 'テーマのない単語を練習する';

  @override
  String get practice => '練習';

  @override
  String get exChoice => '選択問題';

  @override
  String get exMatch => '組み合わせ';

  @override
  String get exCloze => '穴埋め';

  @override
  String get exDictation => '書き取り';

  @override
  String get exListening => '聞き取り';

  @override
  String get exCrossword => 'クロスワード';

  @override
  String get check => '確認';

  @override
  String get next => '次へ';

  @override
  String get correctAnswer => '正解！';

  @override
  String get almostCorrect => 'おしい！正しいつづりはこちら：';

  @override
  String get wrongAnswer => '正解は：';

  @override
  String get yourAnswer => 'あなたの答え';

  @override
  String get listen => '聞く';

  @override
  String get listenSlow => 'ゆっくり';

  @override
  String get chooseTranslation => 'どういう意味ですか？';

  @override
  String get fillGap => '空欄に入るのはどれ？';

  @override
  String get writeWhatYouHear => 'よく聞いて、文を書きましょう。';

  @override
  String get matchInstruction => '単語をタップしてから、その訳をタップしてください。';

  @override
  String get showText => 'テキストを表示';

  @override
  String get hideText => 'テキストを隠す';

  @override
  String get listenFirst => 'まずテキストを聞いてから、質問に答えましょう。';

  @override
  String get exerciseDone => '練習完了！';

  @override
  String scoreOf(int correct, int total) {
    return '$total問中$correct問正解';
  }

  @override
  String get again => 'もう一度';

  @override
  String get revealLetter => '1文字見る';

  @override
  String get across => '横';

  @override
  String get down => '縦';

  @override
  String get solved => '解けた！';

  @override
  String get voiceNote => 'コンピューターの音声です。レオニの録音は準備中です。';

  @override
  String get audioMissing => 'このテキストにはまだ録音がありません。';

  @override
  String get chooseSet => 'どのセット？';

  @override
  String get listenSentence => '文を聞く';

  @override
  String get caseHint => '大文字と小文字に注意しましょう：';

  @override
  String get dictationAlmost => 'おしい！印のついた単語を見てください：';

  @override
  String get kumaTip => 'ヒント';

  @override
  String get kumaStrip => '困ったら、くまちゃんをタップしてね。';

  @override
  String get kumaAsk => 'くまちゃんにヒントをもらう';

  @override
  String get crosswordListenHint =>
      '文を聞いてください。間のところで単語が1つ抜けています。文に合う形でパズルに書きましょう。';

  @override
  String get hangmanAll => 'すべて';

  @override
  String hangmanCategory(String name) {
    return 'カテゴリー：$name';
  }

  @override
  String get hangmanHint => 'ヒント（ライフが1つ減ります）';

  @override
  String get hangmanShowClue => '訳をヒントとして表示';

  @override
  String get hangmanWon => '勝ち！';

  @override
  String get hangmanLost => '残念、負けです';

  @override
  String hangmanSolvedWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ミス$count回で解けました。',
      zero: 'ノーミスで解けました！',
    );
    return '$_temp0';
  }

  @override
  String get hangmanWordWas => '答えは：';

  @override
  String get newGame => '新しいゲーム';

  @override
  String get orPressEnter => 'またはEnterキー';

  @override
  String get statWins => '勝ち';

  @override
  String get statLosses => '負け';

  @override
  String statStreak(int best) {
    return '連勝（最高：$best）';
  }

  @override
  String livesLeft(int count, int max) {
    return '残り $count / $max 回';
  }

  @override
  String letterKey(String letter) {
    return '文字 $letter';
  }

  @override
  String get abcTitle => 'ABCラジオ';

  @override
  String get abcIntro =>
      '1つの文字で1分間の放送時間：その文字で始まる単語をできるだけたくさん見つけましょう。わからないときは「次へ」でOK。';

  @override
  String get abcTopics => 'テーマ';

  @override
  String get abcTopicMix => 'ミックス';

  @override
  String get abcTopicVocab => '私の単語';

  @override
  String get abcTopicCulture => 'スイス';

  @override
  String get abcTopicPeople => '有名人';

  @override
  String get abcTopicFood => '食べ物';

  @override
  String get abcTopicTraditions => '伝統';

  @override
  String get abcTime => '放送時間';

  @override
  String abcSeconds(int count) {
    return '$count秒';
  }

  @override
  String get abcStart => '放送開始！';

  @override
  String get abcSkip => '次へ';

  @override
  String get abcOk => 'OK';

  @override
  String get abcLetter => '文字';

  @override
  String abcGoal(int count) {
    return '目標：$count問正解';
  }

  @override
  String abcScore(int count) {
    return '$count問正解';
  }

  @override
  String abcRecord(String letter, int count) {
    return '「$letter」の最高記録：$count';
  }

  @override
  String get abcTimeUp => '放送終了！';

  @override
  String get abcGoalReached => '目標達成、すごい！';

  @override
  String get abcReview => 'すべてのヒント';

  @override
  String get abcNotEnough => 'このテーマにはまだヒントが足りません。テーマをもっと選んでください。';

  @override
  String get statSecure => '習得済み';

  @override
  String get germanFront => 'ドイツ語が表';

  @override
  String get germanBack => 'ドイツ語が裏';

  @override
  String reviewIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日後にまた出ます',
      one: '明日また出ます',
      zero: '今日もう一度出ます',
    );
    return '$_temp0';
  }

  @override
  String get reviewAgainNow => 'すぐにもう一度出ます';

  @override
  String get reviewSecure => '習得済み。もう自動では出ません';

  @override
  String securedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count語を習得しました！',
    );
    return '$_temp0';
  }

  @override
  String cardBox(int box) {
    return '$box / 5 段階目';
  }

  @override
  String get spacedInfo => 'わかった単語は、1日、2日、4日、8日、16日後にまた出ます。そのときも覚えていれば習得済みです。';

  @override
  String get blanketUnroll => 'ブランケットを広げる';

  @override
  String get blanketRollUp => 'また巻く';

  @override
  String get blanketAsk => 'ブランケットを見てみる？';

  @override
  String get blanketTapKuma => 'くまちゃんのブランケットを見る';

  @override
  String blanketSquares(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ブランケットのモチーフ：$count枚',
    );
    return '$_temp0';
  }

  @override
  String get blanketTitle => 'くまちゃんのブランケット';

  @override
  String get blanketIntro =>
      '単語はひとつずつ、かぎ針編みのモチーフになります。単語がわかるたびに、くまちゃんが1段ずつ編み足します。習得した単語のモチーフは大きなブランケットに編みつけられ、くまちゃんはそれにくるまります。覚えた単語が増えるほど、ロールは太くなります。ブランケットを広げると、どれだけ覚えたかが見られます。';

  @override
  String blanketSummary(int attached, int onHook) {
    return 'ブランケットに$attached枚 ・ 編み途中$onHook枚';
  }

  @override
  String get blanketOnHook => '編み途中';

  @override
  String get blanketAttached => 'ブランケットに縫いつけ済み';

  @override
  String blanketWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count語がくまちゃんのかぎ針を待っています。',
    );
    return '$_temp0';
  }

  @override
  String blanketRounds(int count) {
    return '5段中$count段';
  }

  @override
  String get blanketEmpty => '最初の単語を覚えると、くまちゃんが編み始めます。';

  @override
  String get blanketOpen => 'ブランケットを見る';

  @override
  String get blanketToday => '今日編んだもの';

  @override
  String blanketNewRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'くまちゃんが$count段編みました。',
    );
    return '$_temp0';
  }

  @override
  String get blanketJoined => 'ブランケットへ！';

  @override
  String get helpLanguage => 'ヘルプの言語';

  @override
  String get helpLanguageInfo => 'アプリはドイツ語のままです。ヘルプの言語は小さく添えられるだけです。';

  @override
  String get helpNone => 'なし（ドイツ語のみ）';

  @override
  String get exFide => 'fide・聞き取り';

  @override
  String get fideIntro => 'fideテストと同じ流れです：場面と質問を聞いて、テキストを聞き、最後にもう一度質問を聞きます。';

  @override
  String get fideModeExam => '本番と同じ';

  @override
  String get fideModeExamInfo => '聞けるのは2回まで。テキストもヒントもありません。';

  @override
  String get fideModePractice => '練習';

  @override
  String get fideModePracticeInfo => '何回でも、ゆっくりでも聞けます。答えたあとにテキストが見られます。';

  @override
  String get fideStart => 'はじめる';

  @override
  String get fideSituation => '場面';

  @override
  String fideQuestion(int number) {
    return '質問 $number';
  }

  @override
  String get fidePlay => '聞く';

  @override
  String fidePlaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count回聞けます。',
      one: 'あと1回聞けます。',
      zero: '2回聞きました。',
    );
    return '$_temp0';
  }

  @override
  String get fidePictureTask => 'どの絵が合っていますか？a、b、cをタップしてください。';

  @override
  String get fideOpenTask => '短く答えましょう。2〜3語で十分です。';

  @override
  String get fideModelAnswer => '答えの例：';

  @override
  String get fideSelfCheck => '私の答えも同じ意味です';

  @override
  String get fideTranscript => '聞いたテキスト：';

  @override
  String fidePoints(String level, int points, int max) {
    return '$level：$max点中$points点';
  }

  @override
  String get fideResultNote => '本番では「聞き取り」と「会話」の点数を合わせて評価します。';

  @override
  String get privacyBody =>
      'LearnwithLeoniはデータを集めません。アカウントも、トラッキングも、クッキーもありません。\n\n学習の進み具合はあなたの端末（ブラウザ）にだけ保存されます。レオニには見えません。ブラウザのデータを消したり端末を変えたりすると、進み具合は最初からになりますが、学習内容はそのまま残ります。\n\nオンラインに保存されているのは、あなたの名前（またはニックネーム）、言語、レベル、学習内容だけです。';
}
