import 'dart:math';

import 'words.dart';

enum GuessResult { correct, wrong, alreadyGuessed, ignored }

/// Reine Spiellogik, unabhängig von der Oberfläche.
class HangmanGame {
  HangmanGame({
    required String word,
    required this.category,
    this.maxMistakes = 6,
  }) : word = word.toUpperCase();

  /// Startet ein Spiel mit einem zufälligen Wort.
  /// [category] == null wählt aus allen Kategorien.
  /// [avoidWord] wird nach Möglichkeit nicht erneut gezogen.
  factory HangmanGame.random({
    String? category,
    Random? random,
    String? avoidWord,
  }) {
    final rnd = random ?? Random();
    final pool = <(String, String)>[
      for (final entry in wordCategories.entries)
        if (category == null || entry.key == category)
          for (final w in entry.value) (entry.key, w),
    ];
    if (pool.isEmpty) {
      throw ArgumentError.value(category, 'category', 'Unbekannte Kategorie');
    }
    var pick = pool[rnd.nextInt(pool.length)];
    if (pool.length > 1) {
      while (pick.$2 == avoidWord) {
        pick = pool[rnd.nextInt(pool.length)];
      }
    }
    return HangmanGame(word: pick.$2, category: pick.$1);
  }

  final String word;
  final String category;
  final int maxMistakes;

  final Set<String> _guessed = {};
  int _hintsUsed = 0;

  static final RegExp _letter = RegExp(r'^[A-ZÄÖÜ]$');

  /// Nur diese Zeichen kann man raten; alles andere (z. B. Bindestriche)
  /// ist von Anfang an sichtbar.
  static bool isGuessable(String char) => _letter.hasMatch(char);

  Set<String> get guessedLetters => Set.unmodifiable(_guessed);
  int get hintsUsed => _hintsUsed;

  List<String> get characters => word.split('');

  Set<String> get _lettersInWord => characters.where(isGuessable).toSet();

  int get wrongGuesses => _guessed.where((l) => !word.contains(l)).length;

  /// Jeder Tipp kostet einen Versuch.
  int get mistakes => wrongGuesses + _hintsUsed;
  int get remainingAttempts => max(0, maxMistakes - mistakes);

  bool get isWon => _lettersInWord.every(_guessed.contains);
  bool get isLost => !isWon && mistakes >= maxMistakes;
  bool get isOver => isWon || isLost;

  bool isRevealed(int index) {
    final c = word[index];
    return !isGuessable(c) || _guessed.contains(c);
  }

  bool isCorrectGuess(String letter) =>
      _guessed.contains(letter) && word.contains(letter);

  String get maskedWord =>
      [for (var i = 0; i < word.length; i++) isRevealed(i) ? word[i] : '_']
          .join(' ');

  GuessResult guess(String input) {
    if (isOver || input.length != 1) return GuessResult.ignored;
    final letter = input.toUpperCase();
    if (!isGuessable(letter)) return GuessResult.ignored;
    if (_guessed.contains(letter)) return GuessResult.alreadyGuessed;
    _guessed.add(letter);
    return word.contains(letter) ? GuessResult.correct : GuessResult.wrong;
  }

  List<String> get _hiddenLetters =>
      _lettersInWord.where((l) => !_guessed.contains(l)).toList()..sort();

  /// Ein Tipp ist nur erlaubt, wenn er nicht den letzten Versuch kostet.
  bool get canUseHint =>
      !isOver && remainingAttempts > 1 && _hiddenLetters.length > 1;

  /// Deckt einen zufälligen fehlenden Buchstaben auf (kostet einen Versuch).
  String? useHint([Random? random]) {
    if (!canUseHint) return null;
    final hidden = _hiddenLetters;
    final letter = hidden[(random ?? Random()).nextInt(hidden.length)];
    _guessed.add(letter);
    _hintsUsed++;
    return letter;
  }
}
