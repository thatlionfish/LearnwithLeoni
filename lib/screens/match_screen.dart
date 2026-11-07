import 'dart:math';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../l10n/gloss.dart';
import '../learn/exercises.dart';
import '../ui/colors.dart';
import '../ui/organic.dart';
import '../ui/theme.dart';
import '../learn/hints.dart';
import '../widgets/exercise_kit.dart';
import '../widgets/kuma_helper.dart';
import '../widgets/page_frame.dart';

/// Zuordnen: links deutsche Wörter, rechts Übersetzungen (gemischt).
class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key, required this.code, required this.set});

  final String code;
  final VocabSet set;

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  late List<List<VocabCard>> _rounds;
  int _round = 0;
  late List<VocabCard> _right;
  final Set<String> _done = {};
  String? _selectedLeft;
  String? _wrongRight;
  int _mistakes = 0;
  int _pairs = 0;
  final _toastKey = GlobalKey<LeoniToastHostState>();

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _rounds = matchRounds(widget.set);
    _round = 0;
    _mistakes = 0;
    _pairs = 0;
    _startRound();
  }

  void _startRound() {
    _done.clear();
    _selectedLeft = null;
    _wrongRight = null;
    if (_round < _rounds.length) {
      _right = [..._rounds[_round]]..shuffle(Random());
    }
  }

  void _tapLeft(VocabCard c) => setState(() {
    _selectedLeft = c.id;
    _wrongRight = null;
  });

  void _tapRight(VocabCard c) {
    final left = _selectedLeft;
    if (left == null) return;
    final toast = _toastKey.currentState;
    if (left == c.id) {
      setState(() {
        _done.add(c.id);
        _pairs++;
        _selectedLeft = null;
        _wrongRight = null;
      });
      toast?.answered(correct: true);
      if (_done.length == _rounds[_round].length) {
        Future.delayed(const Duration(milliseconds: 450), () {
          if (!mounted) return;
          setState(() {
            _round++;
            _startRound();
          });
        });
      }
    } else {
      setState(() {
        _mistakes++;
        _wrongRight = c.id;
      });
      toast?.answered(correct: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (_round >= _rounds.length) {
      return ExerciseDone(
        code: widget.code,
        correct: max(0, _pairs - _mistakes),
        total: _pairs,
        onAgain: () => setState(_start),
      );
    }
    final text = Theme.of(context).textTheme;
    final left = _rounds[_round];
    VocabCard? selected;
    for (final c in left) {
      if (c.id == _selectedLeft) selected = c;
    }
    return KumaHelper(
      itemKey: _selectedLeft,
      hints: () => selected == null
          ? const [KumaLines.matchStart]
          : wordHints(
              description: selected.hint,
              term: selected.term,
              answer: '',
            ),
      child: LeoniToastHost(
        key: _toastKey,
        child: PageFrame(
          showBack: true,
          seed: 23,
          title: Text(
            '${t.exMatch} · ${t.progressOf(_round + 1, _rounds.length)}',
            style: text.labelLarge,
          ),
          children: [
            Glossed(
              t.matchInstruction,
              gloss: glossOf(context)?.matchInstruction,
              style: text.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      for (final (i, c) in left.indexed) ...[
                        _Tile(
                          label: c.term,
                          seed: 200 + i,
                          done: _done.contains(c.id),
                          selected: _selectedLeft == c.id,
                          onTap: _done.contains(c.id)
                              ? null
                              : () => _tapLeft(c),
                          serifFont: true,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      for (final (i, c) in _right.indexed) ...[
                        _Tile(
                          label: c.translation,
                          seed: 300 + i,
                          done: _done.contains(c.id),
                          wrong: _wrongRight == c.id,
                          onTap: _done.contains(c.id) || _selectedLeft == null
                              ? null
                              : () => _tapRight(c),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.seed,
    required this.onTap,
    this.done = false,
    this.selected = false,
    this.wrong = false,
    this.serifFont = false,
  });

  final String label;
  final int seed;
  final VoidCallback? onTap;
  final bool done;
  final bool selected;
  final bool wrong;
  final bool serifFont;

  @override
  Widget build(BuildContext context) {
    final color = done
        ? LeoColors.coconutMilk
        : selected
        ? LeoColors.vanillaIce
        : wrong
        ? LeoColors.sand
        : LeoColors.brightWhite;
    final style = serifFont ? serif(18, weight: 440) : sans(15.5, weight: 540);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: done ? 0.55 : 1,
      child: OrganicCard(
        seed: seed,
        color: color,
        onTap: onTap,
        semanticLabel: label,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: style.copyWith(
                  color: done ? LeoColors.inkSoft : LeoColors.chocolate,
                ),
              ),
            ),
            if (done) const SenchaDot(size: 10),
            if (selected) const Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}
