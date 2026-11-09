import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/speaker.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../l10n/gloss.dart';
import '../learn/answer_check.dart';
import '../learn/crossword.dart';
import '../learn/exercises.dart';
import '../learn/hints.dart';
import '../widgets/kuma_helper.dart';
import '../ui/colors.dart';
import '../ui/organic.dart';
import '../ui/theme.dart';
import '../widgets/exercise_kit.dart';
import '../widgets/page_frame.dart';

/// Kreuzworträtsel aus den Wörtern eines oder mehrerer Sets.
/// Hinweis = Übersetzung in der Erklärsprache – oder im Hör-Modus das
/// gesprochene deutsche Wort (für Schüler, die Zuhören üben sollen).
class CrosswordScreen extends StatefulWidget {
  const CrosswordScreen({
    super.key,
    required this.code,
    required this.sets,
    this.random,
    this.audioClues = false,
  });

  /// Hör-Modus: Hinweise werden vorgelesen statt angezeigt.
  final bool audioClues;

  final String code;
  final List<VocabSet> sets;
  final Random? random;

  @override
  State<CrosswordScreen> createState() => _CrosswordScreenState();
}

class _CrosswordScreenState extends State<CrosswordScreen> {
  static const _sentinel = '​';

  late Crossword _cw;
  late List<List<String?>> _solution;
  late List<List<String>> _entries;
  final Set<(int, int)> _revealed = {};
  final Set<(int, int)> _marked = {};
  PlacedWord? _word;
  (int, int)? _cell;
  bool _solved = false;
  final _toastKey = GlobalKey<LeoniToastHostState>();
  final _input = TextEditingController(text: _sentinel);
  final _focus = FocusNode();

  /// Tastatur am Computer (das Rätsel liest die Tasten direkt).
  final _keys = FocusNode(debugLabel: 'crossword-keys');

  /// Handy/Tablet: unsichtbares Textfeld öffnet die Bildschirmtastatur.
  bool get _touch =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  void _requestInput() => _touch ? _focus.requestFocus() : _keys.requestFocus();

  @override
  void initState() {
    super.initState();
    _build();
  }

  void _build() {
    final entries = [
      for (final s in widget.sets)
        for (final c in s.cards.where((c) => isSingleWord(c.term)))
          if (!widget.audioClues)
            (answer: toGridWord(c.term), clue: c.translation, payload: c)
          // Hör-Modus: nur Wörter mit Lückensatz; gesucht ist die Form im Satz.
          else if (gapInExample(c) case final gap?)
            (answer: toGridWord(gap.found), clue: gap.sentence, payload: c),
    ];
    _cw = buildCrossword(entries, maxWords: 10, random: widget.random);
    _solution = _cw.solution;
    _entries = List.generate(_cw.rows, (_) => List.filled(_cw.cols, ''));
    _revealed.clear();
    _marked.clear();
    _solved = false;
    _word = _cw.words.isEmpty ? null : _cw.words.first;
    _cell = _word == null ? null : (_word!.row, _word!.col);
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    _keys.dispose();
    super.dispose();
  }

  /// Hör-Modus: den Satz vorlesen – an der Lücke sagt die Stimme „Hm hm hm“.
  /// Gibt es eine fertige Aufnahme (Microsoft-Stimme), wird diese gespielt.
  void _speak(PlacedWord? w) {
    if (!widget.audioClues || w == null) return;
    final card = w.payload;
    final gapAudio = card is VocabCard ? card.gapAudio : null;
    Speaker.play(
      url: audioUrl(widget.code, gapAudio),
      text: w.clue,
      rate: gapAudio == null ? 0.9 : 1,
    );
  }

  void _select(int r, int c) {
    if (_solution[r][c] == null) return;
    final words = _cw.wordsAt(r, c);
    final before = _word;
    setState(() {
      // Zweimal auf dieselbe Zelle: Richtung wechseln.
      if (_cell == (r, c) && words.length > 1) {
        _word = words.firstWhere((w) => w != _word, orElse: () => words.first);
      } else if (_word == null || !_word!.contains(r, c)) {
        _word = words.first;
      }
      _cell = (r, c);
    });
    if (_word != before) _speak(_word);
    _requestInput();
  }

  void _selectWord(PlacedWord w) {
    setState(() {
      _word = w;
      _cell = (w.row, w.col);
    });
    _speak(w);
    _requestInput();
  }

  void _type(String ch) {
    final cell = _cell, word = _word;
    if (cell == null || word == null || _solved) return;
    final letter = ch.toUpperCase();
    if (!RegExp(r'^[A-ZÄÖÜ]$').hasMatch(letter)) return;
    setState(() {
      if (!_revealed.contains(cell)) _entries[cell.$1][cell.$2] = letter;
      _marked.remove(cell);
      final i = word.indexOf(cell.$1, cell.$2);
      if (i < word.length - 1) _cell = word.cell(i + 1);
    });
    _checkSolved();
  }

  void _backspace() {
    final cell = _cell, word = _word;
    if (cell == null || word == null || _solved) return;
    setState(() {
      if (_entries[cell.$1][cell.$2].isNotEmpty && !_revealed.contains(cell)) {
        _entries[cell.$1][cell.$2] = '';
      } else {
        final i = word.indexOf(cell.$1, cell.$2);
        if (i > 0) {
          _cell = word.cell(i - 1);
          final prev = _cell!;
          if (!_revealed.contains(prev)) _entries[prev.$1][prev.$2] = '';
        }
      }
    });
  }

  void _onInput(String value) {
    // Unsichtbares Feld für die Handy-Tastatur: Sentinel weg = Löschen.
    if (!value.startsWith(_sentinel)) {
      _backspace();
    } else {
      for (final ch in value.substring(_sentinel.length).split('')) {
        _type(ch == 'ß' ? 'S' : ch);
      }
    }
    _input.value = const TextEditingValue(
      text: _sentinel,
      selection: TextSelection.collapsed(offset: 1),
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final word = _word, cell = _cell;
    if (word == null || cell == null) return KeyEventResult.ignored;
    final k = e.logicalKey;
    (int, int)? move;
    if (k == LogicalKeyboardKey.arrowRight) move = (0, 1);
    if (k == LogicalKeyboardKey.arrowLeft) move = (0, -1);
    if (k == LogicalKeyboardKey.arrowDown) move = (1, 0);
    if (k == LogicalKeyboardKey.arrowUp) move = (-1, 0);
    if (k == LogicalKeyboardKey.backspace) {
      _backspace();
      return KeyEventResult.handled;
    }
    final ch = e.character;
    if (ch != null &&
        ch.length == 1 &&
        RegExp(r'[a-zA-ZäöüÄÖÜß]').hasMatch(ch)) {
      _type(ch == 'ß' ? 'S' : ch);
      return KeyEventResult.handled;
    }
    if (move != null) {
      final r = cell.$1 + move.$1, c = cell.$2 + move.$2;
      if (r >= 0 &&
          c >= 0 &&
          r < _cw.rows &&
          c < _cw.cols &&
          _solution[r][c] != null) {
        final dir = move.$1 == 0 ? Dir.across : Dir.down;
        setState(() {
          _cell = (r, c);
          final ws = _cw.wordsAt(r, c);
          _word = ws.firstWhere((w) => w.dir == dir, orElse: () => ws.first);
        });
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _check() {
    setState(() {
      for (var r = 0; r < _cw.rows; r++) {
        for (var c = 0; c < _cw.cols; c++) {
          final want = _solution[r][c];
          final got = _entries[r][c];
          if (want != null && got.isNotEmpty && got != want) {
            _marked.add((r, c));
          }
        }
      }
    });
    _toastKey.currentState?.answered(correct: _marked.isEmpty);
  }

  void _reveal() {
    final cell = _cell;
    if (cell == null) return;
    setState(() {
      _entries[cell.$1][cell.$2] = _solution[cell.$1][cell.$2]!;
      _revealed.add(cell);
      _marked.remove(cell);
    });
    _checkSolved();
  }

  void _checkSolved() {
    for (var r = 0; r < _cw.rows; r++) {
      for (var c = 0; c < _cw.cols; c++) {
        if (_solution[r][c] != null && _entries[r][c] != _solution[r][c]) {
          return;
        }
      }
    }
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _solved = true);
    });
  }

  int get _cleanWords => _cw.words.where((w) {
    for (var i = 0; i < w.length; i++) {
      if (_revealed.contains(w.cell(i))) return false;
    }
    return true;
  }).length;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (_solved) {
      return ExerciseDone(
        code: widget.code,
        correct: _cleanWords,
        total: _cw.words.length,
        onAgain: () => setState(_build),
      );
    }
    final text = Theme.of(context).textTheme;
    final word = _word;
    return Focus(
      focusNode: _keys,
      autofocus: !_touch,
      onKeyEvent: _onKey,
      child: KumaHelper(
        itemKey: word,
        hints: () {
          final card = word?.payload;
          if (word == null) return const <String>[];
          return wordHints(
            description: card is VocabCard ? card.hint : null,
            term: card is VocabCard ? card.term : null,
            answer: crosswordHintAnswer(word.answer),
          );
        },
        audioFor: (h) {
          final card = word?.payload;
          return card is VocabCard && h == card.hint
              ? audioUrl(widget.code, card.hintAudio)
              : null;
        },
        child: LeoniToastHost(
          key: _toastKey,
          child: PageFrame(
            showBack: true,
            seed: 29,
            title: Text(t.exCrossword, style: text.labelLarge),
            children: [
              if (word != null)
                OrganicCard(
                  seed: 41,
                  color: LeoColors.vanillaIce,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  child: Row(
                    children: [
                      Text(
                        '${word.number} ${word.dir == Dir.across ? t.across : t.down}',
                        style: text.labelMedium,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: widget.audioClues
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: FilledButton.icon(
                                  onPressed: () => _speak(word),
                                  icon: const Icon(Icons.volume_up_rounded),
                                  label: Text(t.listenSentence),
                                ),
                              )
                            : Text(word.clue, style: serif(19, weight: 440)),
                      ),
                      Text('${word.length}', style: text.labelMedium),
                    ],
                  ),
                ),
              if (widget.audioClues) ...[
                const SizedBox(height: 8),
                Glossed(
                  t.crosswordListenHint,
                  gloss: glossOf(context)?.crosswordListenHint,
                  style: text.bodySmall,
                  glossSize: 11.5,
                ),
              ],
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, box) {
                  // Ganze Pixel, sonst wirken Linien ungleich dick.
                  final size = min(
                    42.0,
                    (box.maxWidth - 4) / max(1, _cw.cols),
                  ).floorToDouble();
                  return Center(child: _grid(size));
                },
              ),
              // Unsichtbares Eingabefeld, öffnet die Handy-Tastatur.
              SizedBox(
                height: 1,
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: _input,
                    focusNode: _focus,
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: _onInput,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton(onPressed: _check, child: Text(t.check)),
                  TextButton.icon(
                    onPressed: _reveal,
                    icon: const Icon(Icons.lightbulb_outline_rounded),
                    label: Text(t.revealLetter),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              for (final dir in Dir.values) ...[
                Text(
                  dir == Dir.across ? t.across : t.down,
                  style: text.titleMedium,
                ),
                const SizedBox(height: 6),
                for (final w in _cw.words.where((w) => w.dir == dir))
                  InkWell(
                    onTap: () => _selectWord(w),
                    borderRadius: organicRadius(w.number, base: 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 7,
                        horizontal: 6,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text('${w.number}', style: text.labelMedium),
                          ),
                          Expanded(
                            child: widget.audioClues
                                ? Row(
                                    children: [
                                      const Icon(
                                        Icons.volume_up_rounded,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${w.length}',
                                        style: sans(
                                          15,
                                          weight: w == word ? 650 : 420,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    w.clue,
                                    style: sans(
                                      15,
                                      weight: w == word ? 650 : 420,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grid(double size) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < _cw.rows; r++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var c = 0; c < _cw.cols; c++) _cellWidget(r, c, size),
            ],
          ),
      ],
    );
  }

  Widget _cellWidget(int r, int c, double size) {
    if (_solution[r][c] == null) return SizedBox(width: size, height: size);
    final inWord = _word?.contains(r, c) ?? false;
    final current = _cell == (r, c);
    final wrong = _marked.contains((r, c));
    final color = current
        ? LeoColors.sand
        : wrong
        ? LeoColors.woodAsh.withValues(alpha: 0.55)
        : inWord
        ? LeoColors.vanillaIce
        : LeoColors.brightWhite;
    final number = _cw.numberAt(r, c);
    final letter = _entries[r][c];
    return GestureDetector(
      onTap: () => _select(r, c),
      child: Semantics(
        button: true,
        label: 'Feld ${r + 1}/${c + 1}${letter.isEmpty ? '' : ': $letter'}',
        // Jedes Feld – leer oder nicht – ist genau size × size gross,
        // damit Zeilen und Spalten sauber untereinander stehen.
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size * 0.18),
            border: Border.all(
              color: current ? LeoColors.chocolate : LeoColors.woodAsh,
              width: current ? 1.4 : 1,
            ),
          ),
          child: Stack(
            children: [
              if (number != null)
                Positioned(
                  left: 3,
                  top: 1,
                  child: Text('$number', style: sans(size * 0.24, weight: 600)),
                ),
              Center(
                child: Text(
                  letter,
                  style:
                      serif(
                        size * 0.52,
                        weight: _revealed.contains((r, c)) ? 380 : 480,
                      ).copyWith(
                        color: _revealed.contains((r, c))
                            ? LeoColors.inkSoft
                            : LeoColors.chocolate,
                      ),
                ),
              ),
              if (wrong)
                Positioned(
                  right: 3,
                  bottom: 3,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: LeoColors.chocolate,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
