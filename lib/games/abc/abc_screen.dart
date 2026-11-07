import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_scope.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/gloss.dart';
import '../../learn/answer_check.dart';
import '../../ui/colors.dart';
import '../../ui/organic.dart';
import '../../ui/theme.dart';
import '../../widgets/leoni.dart';
import '../../widgets/page_frame.dart';
import '../../learn/hints.dart';
import '../../widgets/kuma_helper.dart';
import 'abc_game.dart';

enum _Phase { setup, onAir, done }

/// ABC-Radio – nach dem Vorbild des Schweizer Kult-Radiospiels.
class AbcRadioScreen extends StatefulWidget {
  const AbcRadioScreen({
    super.key,
    required this.code,
    required this.student,
    required this.sets,
    this.random,
  });

  final String code;
  final Student student;
  final List<VocabSet> sets;
  final Random? random;

  @override
  State<AbcRadioScreen> createState() => _AbcRadioScreenState();
}

class _AbcRadioScreenState extends State<AbcRadioScreen> {
  late final Random _random = widget.random ?? Random();
  List<AbcHint>? _hints;
  Set<AbcTopic> _topics = {...AbcTopic.values};
  int _seconds = 60;

  _Phase _phase = _Phase.setup;
  String _letter = '?';
  AbcRound? _round;
  Timer? _timer;
  double _left = 1; // Anteil der verbleibenden Sendezeit
  /// Abgelaufene Sendezeit in Millisekunden (gezählt in 100-ms-Schritten).
  int _elapsedMs = 0;
  AbcResult? _last;
  int? _record;
  bool _newRecord = false;
  final _input = TextEditingController();
  final _focus = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hints == null) _load();
  }

  Future<void> _load() async {
    final json = await AppScope.of(context).repository.shared('abc/hints.json');
    final shared = [
      for (final h in (json?['hints'] as List?) ?? const [])
        AbcHint.fromJson(h as Map<String, dynamic>),
    ];
    if (!mounted) return;
    setState(() => _hints = [...shared, ...vocabHints(widget.sets)]);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<String> get _letters => availableLetters(_hints ?? const [], _topics);

  /// Zufälliger Buchstabe, dann sofort auf Sendung – ohne Drehknopf.
  void _go() {
    final letters = _letters;
    if (letters.isEmpty) return;
    _letter = letters[_random.nextInt(letters.length)];
    _start();
  }

  Future<void> _start() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _round = AbcRound(
        letter: _letter,
        allHints: _hints!,
        topics: _topics,
        random: _random,
      );
      _record = prefs.getInt(_recordKey);
      _newRecord = false;
      _last = null;
      _phase = _Phase.onAir;
      _left = 1;
      _elapsedMs = 0;
    });
    _input.clear();
    _focus.requestFocus();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _elapsedMs += 100;
      final ms = _seconds * 1000 - _elapsedMs;
      if (ms <= 0) {
        _finish();
      } else {
        setState(() => _left = ms / (_seconds * 1000));
      }
    });
  }

  String get _recordKey => 'abc/${widget.code}/$_letter';

  Future<void> _finish() async {
    _timer?.cancel();
    final round = _round!;
    final prefs = await SharedPreferences.getInstance();
    final best = prefs.getInt(_recordKey) ?? 0;
    if (round.score > best) {
      await prefs.setInt(_recordKey, round.score);
      _newRecord = round.score > 0;
    }
    if (mounted) setState(() => _phase = _Phase.done);
  }

  void _submit(String value) {
    final round = _round;
    if (round == null || round.isDone || _phase != _Phase.onAir) return;
    setState(() {
      _last = value.trim().isEmpty ? round.skip() : round.answer(value);
    });
    _input.clear();
    _focus.requestFocus();
    if (round.isDone) _finish();
  }

  void _skip() {
    final round = _round;
    if (round == null || round.isDone) return;
    setState(() => _last = round.skip());
    _input.clear();
    _focus.requestFocus();
    if (round.isDone) _finish();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return switch (_phase) {
      _Phase.done => _doneView(t),
      _ => KumaHelper(
        itemKey: _round?.current,
        hints: () {
          final h = _round?.current;
          if (h == null || _phase != _Phase.onAir) {
            return const [KumaLines.abcStart];
          }
          return wordHints(
            description: h.card?.hint,
            term: h.card?.term,
            answer: h.answers.first,
          );
        },
        child: PageFrame(
          showBack: true,
          seed: 31,
          title: Text(
            t.abcTitle,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          children: [
            _Radio(
              letter: _letter,
              onAir: _phase == _Phase.onAir,
              timeLeft: _left,
              seconds: _seconds,
              score: _round?.score,
              goal: _round?.goal,
            ),
            const SizedBox(height: 18),
            if (_phase == _Phase.onAir) _playView(t) else _setupView(t),
            const SizedBox(height: 120),
          ],
        ),
      ),
    };
  }

  Widget _setupView(AppLocalizations t) {
    final text = Theme.of(context).textTheme;
    if (_hints == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    final topicLabels = {
      AbcTopic.vocab: t.abcTopicVocab,
      AbcTopic.culture: t.abcTopicCulture,
      AbcTopic.people: t.abcTopicPeople,
      AbcTopic.food: t.abcTopicFood,
      AbcTopic.traditions: t.abcTopicTraditions,
    };
    final letters = _letters;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Glossed(
          t.abcIntro,
          gloss: glossOf(context)?.abcIntro,
          style: text.bodyMedium,
        ),
        const SizedBox(height: 18),
        Text(t.abcTopics, style: text.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: Text(t.abcTopicMix),
              selected: _topics.length == AbcTopic.values.length,
              onSelected: (_) => setState(() => _topics = {...AbcTopic.values}),
            ),
            for (final topic in AbcTopic.values)
              FilterChip(
                label: Text(topicLabels[topic]!),
                selected:
                    _topics.contains(topic) &&
                    _topics.length < AbcTopic.values.length,
                onSelected: (_) => setState(() {
                  final allOn = _topics.length == AbcTopic.values.length;
                  if (allOn) {
                    _topics = {topic};
                  } else if (_topics.contains(topic) && _topics.length > 1) {
                    _topics = {..._topics}..remove(topic);
                  } else {
                    _topics = {..._topics, topic};
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(t.abcTime, style: text.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final s in const [45, 60, 90])
              ChoiceChip(
                label: Text(t.abcSeconds(s)),
                selected: _seconds == s,
                onSelected: (_) => setState(() => _seconds = s),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const SizedBox(height: 12),
        if (letters.isEmpty)
          Text(t.abcNotEnough, style: text.bodyMedium)
        else
          FilledButton.icon(
            onPressed: _go,
            icon: const Icon(Icons.radio_rounded),
            label: Text(t.abcStart),
          ),
      ],
    );
  }

  Widget _playView(AppLocalizations t) {
    final text = Theme.of(context).textTheme;
    final round = _round!;
    final hint = round.current;
    if (hint == null) return const SizedBox.shrink();
    final lang = helpLanguageOf(context);
    final translation = hint.topic == AbcTopic.vocab || lang == null
        ? null
        : hint.translations[lang];
    final last = _last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OrganicCard(
          key: ValueKey(hint.answers.first),
          seed: hint.clue.hashCode,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${t.abcLetter} $_letter …', style: text.labelMedium),
              const SizedBox(height: 6),
              Text(hint.clue, style: serif(22, weight: 440)),
              HelpReveal(translation),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _input,
          focusNode: _focus,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          onSubmitted: _submit,
          style: serif(22, weight: 440),
          decoration: InputDecoration(
            hintText: '$_letter…',
            filled: true,
            fillColor: LeoColors.brightWhite,
            border: OutlineInputBorder(borderRadius: organicInputRadius(5)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton(
              onPressed: () => _submit(_input.text),
              child: Text(t.abcOk),
            ),
            const SizedBox(width: 10),
            TextButton(onPressed: _skip, child: Text(t.abcSkip)),
            const Spacer(),
            if (last != null)
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (last.correct) const SenchaDot(size: 10),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        last.hint.answers.first,
                        overflow: TextOverflow.ellipsis,
                        style: sans(
                          15,
                          weight: last.correct ? 650 : 450,
                          color: last.correct
                              ? LeoColors.chocolate
                              : LeoColors.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _doneView(AppLocalizations t) {
    final text = Theme.of(context).textTheme;
    final round = _round!;
    final reached = round.score >= round.goal;
    final lang = helpLanguageOf(context);
    return PageFrame(
      showBack: true,
      seed: 37,
      children: [
        LeoniSays(
          companion: reached ? KumaPose.cheer : KumaPose.hug,
          pose: reached
              ? LeoniPose.kick
              : (round.score > 0 ? LeoniPose.clap : LeoniPose.encourage),
          headline: reached ? t.abcGoalReached : t.abcTimeUp,
          subline:
              '${t.abcScore(round.score)} · ${t.abcGoal(round.goal)}\n'
              '${t.abcRecord(_letter, max(round.score, _record ?? 0))}',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => setState(() => _phase = _Phase.setup),
              icon: const Icon(Icons.radio_rounded),
              label: Text(t.again),
            ),
            TextButton(
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go('/s/${widget.code}'),
              child: Text(t.back),
            ),
          ],
        ),
        if (_newRecord) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const SenchaDot(),
              const SizedBox(width: 8),
              Text(t.abcRecord(_letter, round.score), style: text.labelMedium),
            ],
          ),
        ],
        const SizedBox(height: 24),
        Text(t.abcReview, style: text.headlineSmall),
        const SizedBox(height: 10),
        for (final (i, r) in [
          ...round.results,
          for (final h in round.remaining) AbcResult(h),
        ].indexed) ...[
          OrganicCard(
            seed: 500 + i,
            color: r.correct ? LeoColors.brightWhite : LeoColors.vanillaIce,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 10),
                  child: r.correct
                      ? const SenchaDot(size: 10)
                      : const SizedBox(width: 10, height: 10),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.hint.answers.first, style: serif(19, weight: 460)),
                      Text(r.hint.clue, style: text.bodyMedium),
                      if (r.hint.translations[lang] case final tr?
                          when r.hint.topic != AbcTopic.vocab)
                        Text(tr, style: glossStyle()),
                      if (r.given != null &&
                          !r.correct &&
                          r.given!.trim().isNotEmpty)
                        Text('„${r.given}“', style: text.bodySmall),
                      if (r.result == AnswerResult.close)
                        Text(t.almostCorrect, style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Das Radio: Skala mit Nadel, grosser Buchstabe, Sendezeit, On-Air-Lämpchen.
class _Radio extends StatelessWidget {
  const _Radio({
    required this.letter,
    required this.onAir,
    required this.timeLeft,
    required this.seconds,
    this.score,
    this.goal,
  });

  final String letter;
  final bool onAir;
  final double timeLeft;
  final int seconds;
  final int? score;
  final int? goal;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final index = (letter.codeUnitAt(0) - 65).clamp(0, 25);
    return OrganicCard(
      seed: 2,
      color: LeoColors.vanillaIce,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
      child: Column(
        children: [
          Row(
            children: [
              _OnAirLamp(on: onAir),
              const SizedBox(width: 8),
              Text(
                'ON AIR',
                style: sans(
                  12.5,
                  weight: 750,
                  color: onAir ? LeoColors.chocolate : LeoColors.inkSoft,
                ),
              ),
              const Spacer(),
              if (score != null)
                Text(
                  '${t.abcScore(score!)} · ${t.abcGoal(goal ?? 12)}',
                  style: text.labelMedium,
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Frequenzskala A–Z mit Nadel
          SizedBox(
            height: 34,
            child: LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: LeoColors.sand,
                          borderRadius: organicRadius(9, base: 12),
                          border: Border.all(color: LeoColors.woodAsh),
                        ),
                      ),
                    ),
                    for (var i = 0; i < 26; i++)
                      Positioned(
                        left: 8 + (w - 16) * i / 25 - 4,
                        top: 4,
                        child: SizedBox(
                          width: 8,
                          child: Column(
                            children: [
                              Container(
                                width: 1,
                                height: i % 5 == 0 ? 10 : 6,
                                color: LeoColors.chocolate.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              if (i % 5 == 0)
                                Text(
                                  String.fromCharCode(65 + i),
                                  style: sans(
                                    9,
                                    weight: 600,
                                    color: LeoColors.inkSoft,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 120),
                      left: 8 + (w - 16) * index / 25 - 1.5,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 3, color: LeoColors.chocolate),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 132,
                height: 132,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: onAir ? timeLeft : 1,
                        strokeWidth: 6,
                        backgroundColor: LeoColors.sand,
                        color: onAir && timeLeft < 0.2
                            ? LeoColors.inkSoft
                            : LeoColors.chocolate,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(letter, style: serif(72, weight: 420, height: 1)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            onAir
                ? t.abcSeconds((timeLeft * seconds).ceil())
                : t.abcSeconds(seconds),
            style: text.labelMedium,
          ),
        ],
      ),
    );
  }
}

/// Lemon-Grass-Lämpchen, pulsiert während der Sendung.
class _OnAirLamp extends StatefulWidget {
  const _OnAirLamp({required this.on});
  final bool on;

  @override
  State<_OnAirLamp> createState() => _OnAirLampState();
}

class _OnAirLampState extends State<_OnAirLamp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didUpdateWidget(_OnAirLamp old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync() {
    final animate =
        widget.on &&
        LeoniFigure.animate &&
        !MediaQuery.disableAnimationsOf(context);
    if (animate && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!animate && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.on
              ? Color.lerp(
                  LeoColors.lemonGrass,
                  LeoColors.lemonGrass.withValues(alpha: 0.45),
                  _c.value,
                )
              : LeoColors.woodAsh,
          border: Border.all(color: LeoColors.chocolate.withValues(alpha: 0.5)),
          boxShadow: widget.on
              ? [
                  BoxShadow(
                    color: LeoColors.lemonGrass.withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
