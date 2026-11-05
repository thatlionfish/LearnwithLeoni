import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../audio/speaker.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../learn/answer_check.dart';
import '../../learn/hints.dart';
import '../../widgets/exercise_kit.dart';
import '../../widgets/kuma_helper.dart';
import 'game.dart';
import 'hangman_scene.dart';
import 'palette.dart';
import 'words.dart';

/// Ein Wort im Topf: Kategorie, Wort und – bei Set-Wörtern – die Karte.
typedef HangmanEntry = ({
  String category,
  String word,
  VocabCard? card,
  VocabSet? set,
});

/// Wörter aus den Sets des Schülers, passend für Hangman.
List<HangmanEntry> hangmanEntries(List<VocabSet> sets) => [
  for (final s in sets)
    for (final c in s.cards)
      if (_hangmanWord(c.term) case final w?)
        (category: s.title, word: w, card: c, set: s),
];

String? _hangmanWord(String term) {
  final w = stripArticle(term).toUpperCase().replaceAll('ß', 'SS');
  final letters = w.split('').where(HangmanGame.isGuessable).length;
  if (letters < 3 || !RegExp(r'^[A-ZÄÖÜ \-]+$').hasMatch(w)) return null;
  return w;
}

/// Hangman aus der bestehenden App, mit Wörtern aus den Sets des Schülers.
/// Szene und Farben sind unverändert übernommen.
class HangmanScreen extends StatefulWidget {
  const HangmanScreen({
    super.key,
    required this.code,
    required this.sets,
    this.random,
    this.ambientAnimations = true,
  });

  final String code;
  final List<VocabSet> sets;
  final Random? random;
  final bool ambientAnimations;

  @override
  State<HangmanScreen> createState() => _HangmanScreenState();
}

class _HangmanScreenState extends State<HangmanScreen> {
  late final Random _random = widget.random ?? Random();
  final FocusNode _focusNode = FocusNode(debugLabel: 'hangman-keyboard');

  late final List<HangmanEntry> _mine = hangmanEntries(widget.sets);
  late final List<HangmanEntry> _fixed = [
    for (final e in wordCategories.entries)
      for (final w in e.value)
        (category: e.key, word: w, card: null, set: null),
  ];

  /// null = alle eigenen Wörter (oder alle, falls es keine gibt).
  String? _category;
  bool _showClue = false;
  late HangmanEntry _entry;
  late HangmanGame _game;

  int _wins = 0;
  int _losses = 0;
  int _streak = 0;
  int _bestStreak = 0;
  SharedPreferences? _prefs;

  String get _statsKey => 'hangman/${widget.code}';

  @override
  void initState() {
    super.initState();
    _newEntry();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      final s = p.getStringList(_statsKey);
      setState(() {
        _prefs = p;
        if (s != null && s.length == 4) {
          final v = [for (final x in s) int.tryParse(x) ?? 0];
          _wins = v[0];
          _losses = v[1];
          _streak = v[2];
          _bestStreak = v[3];
        }
      });
    });
  }

  List<String> get _categories => [
    ...{for (final e in _mine) e.category},
    ...wordCategories.keys,
  ];

  List<HangmanEntry> get _pool {
    if (_category == null) return _mine.isNotEmpty ? _mine : _fixed;
    return [
      for (final e in [..._mine, ..._fixed])
        if (e.category == _category) e,
    ];
  }

  String? _lastWord;

  void _newEntry() {
    final pool = _pool;
    var pick = pool[_random.nextInt(pool.length)];
    // Nicht zweimal hintereinander dasselbe Wort.
    for (var i = 0; i < 10 && pool.length > 1 && pick.word == _lastWord; i++) {
      pick = pool[_random.nextInt(pool.length)];
    }
    _lastWord = pick.word;
    _entry = pick;
    _showClue = false;
    _game = HangmanGame(word: pick.word, category: pick.category);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _newGame() {
    setState(_newEntry);
    _focusNode.requestFocus();
  }

  void _selectCategory(String? category) {
    _category = category;
    _newGame();
  }

  void _recordResultIfOver() {
    if (!_game.isOver) return;
    if (_game.isWon) {
      _wins++;
      _streak++;
      _bestStreak = max(_bestStreak, _streak);
    } else {
      _losses++;
      _streak = 0;
    }
    _prefs?.setStringList(_statsKey, [
      '$_wins',
      '$_losses',
      '$_streak',
      '$_bestStreak',
    ]);
    final card = _entry.card;
    if (card != null &&
        _entry.set != null &&
        _entry.set!.variety == Variety.de) {
      // Das gelöste Wort einmal vorlesen.
      Speaker.play(
        url: audioUrl(widget.code, card.audio),
        text: card.term,
        lang: voiceLang(_entry.set!),
      );
    }
  }

  void _guess(String letter) {
    if (_game.isOver) return;
    setState(() {
      final result = _game.guess(letter);
      if (result == GuessResult.correct || result == GuessResult.wrong) {
        _recordResultIfOver();
      }
    });
    _focusNode.requestFocus();
  }

  void _hint() {
    setState(() {
      if (_game.useHint(_random) != null) _recordResultIfOver();
    });
    _focusNode.requestFocus();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_game.isOver &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      _newGame();
      return KeyEventResult.handled;
    }
    final char = event.character;
    if (char == null || char.length != 1) return KeyEventResult.ignored;
    final letter = char.toUpperCase();
    if (!HangmanGame.isGuessable(letter)) return KeyEventResult.ignored;
    _guess(letter);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final card = _entry.card;
    return KumaHelper(
      itemKey: _entry,
      hints: () => [
        ...wordHints(description: card?.hint, term: card?.term, answer: ''),
        'Fang mit häufigen Buchstaben an: E, N, R, S, I.',
      ],
      child: Theme(
        data: buildBeigeTheme(),
        child: Builder(
          builder: (context) => DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Palette.paper, Palette.paperDeep],
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(t.gameHangman),
                actions: [
                  _Stat(Icons.emoji_events_outlined, _wins, t.statWins),
                  _Stat(
                    Icons.sentiment_dissatisfied_outlined,
                    _losses,
                    t.statLosses,
                  ),
                  _Stat(
                    Icons.local_fire_department_outlined,
                    _streak,
                    t.statStreak(_bestStreak),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: Focus(
                focusNode: _focusNode,
                autofocus: true,
                onKeyEvent: _onKey,
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final scene = HangmanScene(
                        game: _game,
                        ambientAnimations: widget.ambientAnimations,
                      );
                      final controls = _buildControls(context, t);

                      if (constraints.maxWidth >= 820) {
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Center(child: scene),
                                  ),
                                  const SizedBox(width: 48),
                                  Expanded(
                                    flex: 6,
                                    child: Center(
                                      child: SingleChildScrollView(
                                        child: controls,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 260,
                                  child: Center(child: scene),
                                ),
                                const SizedBox(height: 20),
                                controls,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, AppLocalizations t) {
    final theme = Theme.of(context);
    final clue = _entry.card?.translation;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(t.hangmanAll),
              selected: _category == null,
              onSelected: (_) => _selectCategory(null),
            ),
            for (final c in _categories)
              ChoiceChip(
                label: Text(c),
                selected: c == _category,
                onSelected: (_) => _selectCategory(c),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            Text(
              t.hangmanCategory(_game.category),
              style: theme.textTheme.titleMedium,
            ),
            _Lives(remaining: _game.remainingAttempts, max: _game.maxMistakes),
            TextButton.icon(
              onPressed: _game.canUseHint ? _hint : null,
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(t.hangmanHint),
            ),
          ],
        ),
        if (clue != null) ...[
          const SizedBox(height: 4),
          FilterChip(
            label: Text(_showClue || _game.isOver ? clue : t.hangmanShowClue),
            selected: _showClue,
            onSelected: (v) => setState(() => _showClue = v),
          ),
        ],
        const SizedBox(height: 24),
        _WordView(game: _game),
        const SizedBox(height: 28),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _game.isOver
              ? _ResultCard(
                  key: const ValueKey('result'),
                  game: _game,
                  entry: _entry,
                  code: widget.code,
                  onNewGame: _newGame,
                )
              : _Keyboard(
                  key: const ValueKey('keyboard'),
                  game: _game,
                  onLetter: _guess,
                ),
        ),
        // Platz für Kumachan unten rechts.
        const SizedBox(height: 130),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.value, this.tooltip);

  final IconData icon;
  final int value;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 4),
            Text('$value', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _Lives extends StatelessWidget {
  const _Lives({required this.remaining, required this.max});

  final int remaining;
  final int max;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Semantics(
      label: AppLocalizations.of(context).livesLeft(remaining, max),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < max; i++)
            Icon(
              i < remaining ? Icons.favorite : Icons.favorite_border,
              size: 20,
              color: color,
            ),
        ],
      ),
    );
  }
}

class _WordView extends StatelessWidget {
  const _WordView({required this.game});

  final HangmanGame game;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chars = game.characters;
    return Semantics(
      label: game.maskedWord,
      excludeSemantics: true,
      child: Wrap(
        key: ObjectKey(game),
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 10,
        children: [
          for (var i = 0; i < chars.length; i++)
            _LetterTile(
              char: chars[i],
              revealed: game.isRevealed(i),
              showMissed: game.isLost && !game.isRevealed(i),
              won: game.isWon,
              theme: theme,
            ),
        ],
      ),
    );
  }
}

class _LetterTile extends StatelessWidget {
  const _LetterTile({
    required this.char,
    required this.revealed,
    required this.showMissed,
    required this.won,
    required this.theme,
  });

  final String char;
  final bool revealed;
  final bool showMissed;
  final bool won;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final visible = revealed || showMissed;
    final color = showMissed
        ? scheme.error
        : (won ? Palette.correct : scheme.onSurface);
    return SizedBox(
      width: 34,
      height: 50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Text(
              visible ? char : ' ',
              key: ValueKey(visible),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: HangmanGame.isGuessable(char)
                  ? scheme.outline
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _Keyboard extends StatelessWidget {
  const _Keyboard({super.key, required this.game, required this.onLetter});

  static const List<String> rows = ['QWERTZUIOPÜ', 'ASDFGHJKLÖÄ', 'YXCVBNM'];

  final HangmanGame game;
  final ValueChanged<String> onLetter;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final keyWidth = min(56.0, constraints.maxWidth / 11);
        return Column(
          children: [
            for (final row in rows)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final letter in row.split(''))
                    SizedBox(
                      width: keyWidth,
                      height: max(40.0, keyWidth * 1.15),
                      child: Padding(
                        padding: const EdgeInsets.all(2.5),
                        child: _KeyButton(
                          letter: letter,
                          guessed: game.guessedLetters.contains(letter),
                          correct: game.isCorrectGuess(letter),
                          onTap: () => onLetter(letter),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.letter,
    required this.guessed,
    required this.correct,
    required this.onTap,
  });

  final String letter;
  final bool guessed;
  final bool correct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final Color bg;
    final Color fg;
    if (!guessed) {
      bg = scheme.secondaryContainer;
      fg = scheme.onSecondaryContainer;
    } else if (correct) {
      bg = Palette.correct;
      fg = Colors.white;
    } else {
      bg = scheme.surfaceContainerHighest;
      fg = scheme.onSurface.withValues(alpha: 0.35);
    }
    final radius = BorderRadius.circular(10);
    return Semantics(
      button: true,
      enabled: !guessed,
      label: AppLocalizations.of(context).letterKey(letter),
      excludeSemantics: true,
      child: Material(
        key: ValueKey('key-$letter'),
        color: bg,
        borderRadius: radius,
        elevation: guessed ? 0 : 1.5,
        shadowColor: Palette.ink.withValues(alpha: 0.4),
        child: InkWell(
          borderRadius: radius,
          canRequestFocus: false,
          onTap: guessed ? null : onTap,
          child: Center(
            child: Text(
              letter,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    super.key,
    required this.game,
    required this.entry,
    required this.code,
    required this.onNewGame,
  });

  final HangmanGame game;
  final HangmanEntry entry;
  final String code;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final won = game.isWon;
    final card = entry.card;
    return Card(
      color: won ? const Color(0xFFDCE8CD) : theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              won ? Icons.celebration : Icons.sentiment_very_dissatisfied,
              size: 48,
              color: won ? Palette.correct : theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              won ? t.hangmanWon : t.hangmanLost,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              won
                  ? t.hangmanSolvedWith(game.mistakes)
                  : '${t.hangmanWordWas} ${game.word}',
              textAlign: TextAlign.center,
            ),
            if (card != null) ...[
              const SizedBox(height: 12),
              Text(card.term, style: theme.textTheme.titleLarge),
              Text(card.translation, style: theme.textTheme.bodyMedium),
              if (card.example != null) ...[
                const SizedBox(height: 6),
                Text(
                  card.example!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (entry.set != null) ...[
                const SizedBox(height: 10),
                ListenButtons(
                  text: card.term,
                  url: audioUrl(code, card.audio),
                  lang: voiceLang(entry.set!),
                  allowVoice: entry.set!.variety == Variety.de,
                ),
              ],
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onNewGame,
              icon: const Icon(Icons.refresh),
              label: Text(t.newGame),
            ),
            const SizedBox(height: 6),
            Text(t.orPressEnter, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
