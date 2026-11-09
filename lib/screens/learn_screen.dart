import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../audio/speaker.dart';
import '../data/leitner.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../l10n/gloss.dart';
import '../learn/crochet.dart';
import '../learn/session.dart';
import '../ui/colors.dart';
import '../ui/organic.dart';
import '../ui/theme.dart';
import '../widgets/crochet.dart';
import '../widgets/exercise_kit.dart';
import '../widgets/leoni.dart';
import '../widgets/page_frame.dart';
import '../widgets/student_loader.dart';

/// Lernsitzung mit Karteikarten unter `#/s/<code>/lernen` (optional `?set=<id>`).
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key, required this.code, this.setId});

  final String code;
  final String? setId;

  @override
  Widget build(BuildContext context) => StudentLoader(
    code: code,
    builder: (context, data) {
      final sets = setId == null
          ? data.content.sets
          : [?data.content.set(setId!)];
      return _LearnView(code: code, data: data, sets: sets);
    },
  );
}

class _LearnView extends StatefulWidget {
  const _LearnView({
    required this.code,
    required this.data,
    required this.sets,
  });

  final String code;
  final StudentData data;
  final List<VocabSet> sets;

  @override
  State<_LearnView> createState() => _LearnViewState();
}

class _LearnViewState extends State<_LearnView> {
  final FocusNode _focus = FocusNode(debugLabel: 'learn-keys');
  bool _flipped = false;

  /// Nach jeder Antwort: wann die letzte Karte wiederkommt.
  ({String term, String note, bool secure})? _lastNote;

  /// Wörter, die in dieser Sitzung „sicher“ geworden sind.
  int _secured = 0;

  /// Was Kumachan in dieser Runde gehäkelt hat (pro Wort).
  final Map<String, CrochetStep> _crocheted = {};

  /// Quadrate an der Decke vor der Runde – für die Animation am Schluss.
  late final int _attachedBefore;

  @override
  void initState() {
    super.initState();
    _attachedBefore = CrochetWork.of(
      widget.data.content.sets,
      widget.data.progress,
    ).attached.length;
  }

  bool get _germanFront => AppScope.of(context).settings.germanFront;

  /// Kurze Einblendung von Leoni (Pose + Spruch).
  (LeoniPose, LeoniPhrase)? _toast;
  Timer? _toastTimer;
  LeoniPhrase? _donePhrase;

  /// Einmal pro Seite gebaut: Wer zwischendurch die Decke anschaut und
  /// zurückkommt, findet seine Runde (und ihren Abschluss) wieder.
  late final LearnSession _session = LearnSession.build(
    widget.sets,
    widget.data.progress,
  );

  @override
  void dispose() {
    _toastTimer?.cancel();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _grade(Grade grade) async {
    if (!_flipped || _session.isDone) return;
    final t = AppLocalizations.of(context);
    final item = _session.current!;
    final before = widget.data.progress.stateOf(item.set, item.card)?.box ?? 0;
    final moment = _session.answer(grade, (item, g) {
      widget.data.progress.record(item.set, item.card, g);
    });
    unawaited(widget.data.days.markToday());
    final state = widget.data.progress.stateOf(item.set, item.card);
    if (state != null && state.box > before) {
      _crocheted[item.key] = CrochetStep(
        CrochetSquare(
          set: item.set,
          card: item.card,
          rounds: state.box,
          due: state.due,
        ),
        from: before,
        to: state.box,
      );
    }
    final secure = state?.isSecure ?? false;
    if (secure && grade == Grade.knew) _secured++;
    setState(() {
      _flipped = false;
      _lastNote = (
        term: item.card.term,
        secure: secure,
        note: _session.isQueued(item)
            ? t.reviewAgainNow
            : secure
            ? t.reviewSecure
            : t.reviewIn(state == null ? 1 : max(0, Leitner.daysUntil(state))),
      );
    });

    if (_session.isDone) {
      final phrase = await LeoniPhrases.pick('done');
      if (mounted) setState(() => _donePhrase = phrase);
      return;
    }
    if (moment != null) {
      final (pose, mood) = switch (moment) {
        LeoniMoment.streak => (
          Random().nextBool() ? LeoniPose.thumbs : LeoniPose.clap,
          'streak',
        ),
        LeoniMoment.encourage => (LeoniPose.encourage, 'encourage'),
      };
      final phrase = await LeoniPhrases.pick(mood);
      if (!mounted || phrase == null) return;
      _toastTimer?.cancel();
      setState(() => _toast = (pose, phrase));
      _toastTimer = Timer(const Duration(milliseconds: 3200), () {
        if (mounted) setState(() => _toast = null);
      });
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final key = e.logicalKey;
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter) {
      if (!_flipped) setState(() => _flipped = true);
      return KeyEventResult.handled;
    }
    final grade = switch (key) {
      LogicalKeyboardKey.digit1 || LogicalKeyboardKey.numpad1 => Grade.knew,
      LogicalKeyboardKey.digit2 || LogicalKeyboardKey.numpad2 => Grade.almost,
      LogicalKeyboardKey.digit3 ||
      LogicalKeyboardKey.numpad3 => Grade.didNotKnow,
      _ => null,
    };
    if (grade != null && _flipped) {
      _grade(grade);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (_session.total == 0) return _empty(t);
    if (_session.isDone) return _done(t);

    final item = _session.current!;
    final text = Theme.of(context).textTheme;
    final shown = min(_session.answeredCount + 1, _session.total);

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Stack(
        children: [
          PageFrame(
            showBack: true,
            seed: 13,
            title: Text(
              t.progressOf(shown, _session.total),
              style: text.labelLarge,
            ),
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.elliptical(6, 4)),
                child: LinearProgressIndicator(
                  value: _session.answeredCount / _session.total,
                  minHeight: 5,
                  backgroundColor: LeoColors.vanillaIce,
                  color: LeoColors.woodAsh,
                ),
              ),
              const SizedBox(height: 12),
              // Feste Plätze: Schalter rechts, darunter der Hinweis zur
              // letzten Karte – nichts springt, wenn er erscheint.
              Align(
                alignment: Alignment.centerRight,
                child: _DirectionToggle(
                  germanFront: _germanFront,
                  onChanged: (v) async {
                    await AppScope.of(context).settings.setGermanFront(v);
                    if (mounted) setState(() => _flipped = false);
                  },
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _LastNote(_lastNote),
                ),
              ),
              const SizedBox(height: 8),
              _FlipCard(
                key: ValueKey(
                  '${item.key}${_session.answeredCount}$_germanFront',
                ),
                item: item,
                flipped: _flipped,
                germanFront: _germanFront,
                onFlip: () => setState(() => _flipped = true),
              ),
              const SizedBox(height: 10),
              // Wort und (nach dem Umdrehen) Beispielsatz anhören. Steht
              // Deutsch hinten, verrät das Anhören vor dem Umdrehen die Lösung.
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  if (_germanFront || _flipped)
                    TextButton.icon(
                      onPressed: () => Speaker.play(
                        url: audioUrl(widget.code, item.card.audio),
                        text: item.card.term,
                        lang: voiceLang(item.set),
                      ),
                      icon: const Icon(Icons.volume_up_rounded),
                      label: Text(t.listen),
                    ),
                  if (_flipped && item.card.example != null)
                    TextButton.icon(
                      onPressed: () => Speaker.play(
                        url: audioUrl(widget.code, item.card.exampleAudio),
                        text: item.card.example,
                        lang: voiceLang(item.set),
                      ),
                      icon: const Icon(Icons.record_voice_over_outlined),
                      label: Text(t.listenSentence),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: _flipped
                    ? _GradeButtons(onGrade: _grade)
                    : Center(
                        key: const ValueKey('hint'),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Glossed(
                            t.tapToFlip,
                            gloss: glossOf(context)?.tapToFlip,
                            style: text.bodySmall,
                            glossSize: 11.5,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 120),
            ],
          ),
          // Leoni taucht unten links kurz auf.
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.25),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _toast == null
                        ? const SizedBox.shrink()
                        : IgnorePointer(
                            key: ValueKey(_toast),
                            // Material sorgt für den richtigen Textstil
                            // (ausserhalb des Scaffolds).
                            child: Material(
                              type: MaterialType.transparency,
                              child: LeoniSays(
                                pose: _toast!.$1,
                                headline: '',
                                phrase: _toast!.$2,
                                figureHeight: 120,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _done(AppLocalizations t) {
    final text = Theme.of(context).textTheme;
    final s = _session;
    return PageFrame(
      seed: 17,
      children: [
        const SizedBox(height: 12),
        LeoniSays(
          pose: s.notKnown > s.knew ? LeoniPose.heart : LeoniPose.cheer,
          companion: s.notKnown > s.knew ? KumaPose.hug : KumaPose.cheer,
          headline: t.sessionDoneTitle,
          phrase: _donePhrase,
        ),
        const SizedBox(height: 12),
        OrganicCard(
          seed: 5,
          color: LeoColors.vanillaIce,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.sessionDoneStats(s.knew, s.almost, s.notKnown),
                style: text.bodyLarge,
              ),
              if (_secured > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SenchaDot(size: 11),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.securedCount(_secured),
                        style: sans(16, weight: 650),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Text(
                t.streakDays(max(1, widget.data.days.streak())),
                style: text.bodySmall,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go('/s/${widget.code}'),
                child: Text(t.backHome),
              ),
            ],
          ),
        ),
        if (_crocheted.isNotEmpty) ...[
          const SizedBox(height: 16),
          _CrochetedToday(
            code: widget.code,
            steps: _crocheted.values.toList(),
            work: CrochetWork.of(
              widget.data.content.sets,
              widget.data.progress,
            ),
            attachedBefore: _attachedBefore,
          ),
        ],
      ],
    );
  }

  Widget _empty(AppLocalizations t) => PageFrame(
    showBack: true,
    seed: 17,
    children: [
      const SizedBox(height: 12),
      LeoniSays(
        pose: LeoniPose.shrug,
        companion: KumaPose.sleepy,
        headline: t.allDoneToday,
        phrase: null,
        subline: t.nothingToLearn,
      ),
    ],
  );
}

/// Karte, die sich beim Tippen ruhig um die senkrechte Achse dreht.
class _FlipCard extends StatelessWidget {
  const _FlipCard({
    super.key,
    required this.item,
    required this.flipped,
    required this.onFlip,
    this.germanFront = true,
  });

  final SessionItem item;
  final bool flipped;
  final VoidCallback onFlip;

  /// `false`: vorne die Übersetzung, hinten das deutsche Wort.
  final bool germanFront;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: flipped ? 1 : 0),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubic,
      builder: (context, v, _) {
        final showBack = v >= 0.5;
        final angle = v * pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(showBack ? angle - pi : angle),
          child: showBack ? _back(context) : _front(context),
        );
      },
    );
  }

  Widget _shell({
    required Widget child,
    required Color color,
    required String label,
  }) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 280),
    child: OrganicCard(
      seed: item.card.id.hashCode,
      color: color,
      onTap: flipped ? null : onFlip,
      semanticLabel: label,
      padding: const EdgeInsets.fromLTRB(26, 30, 26, 30),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );

  Widget _front(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = item.card;
    return _shell(
      color: LeoColors.brightWhite,
      label: germanFront ? c.term : c.translation,
      child: SizedBox(
        height: 220,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Einzelne Wörter gehören zu keinem Thema.
            if (!item.set.isCollection) ...[
              Text(item.set.title, style: text.labelMedium),
              const SizedBox(height: 22),
            ],
            if (germanFront) ...[
              Text(
                c.term,
                textAlign: TextAlign.center,
                style: serif(36, weight: 420),
              ),
              if (c.plural != null) ...[
                const SizedBox(height: 6),
                Text(c.plural!, style: text.bodyMedium),
              ],
            ] else
              Text(
                c.translation,
                textAlign: TextAlign.center,
                style: serif(32, weight: 420),
              ),
          ],
        ),
      ),
    );
  }

  Widget _back(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = item.card;
    return _shell(
      color: LeoColors.vanillaIce,
      label: '${c.term}: ${c.translation}',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 220),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (germanFront) ...[
              Text(
                c.term,
                style: text.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                c.translation,
                textAlign: TextAlign.center,
                style: serif(30, weight: 420),
              ),
            ] else ...[
              // Deutsch hinten: das deutsche Wort ist die Lösung, also gross.
              Text(c.translation, style: text.titleMedium),
              const SizedBox(height: 10),
              Text(
                c.term,
                textAlign: TextAlign.center,
                style: serif(34, weight: 420),
              ),
              if (c.plural != null) ...[
                const SizedBox(height: 4),
                Text(c.plural!, style: text.bodyMedium),
              ],
            ],
            if (c.alt != null) ...[
              const SizedBox(height: 6),
              Text(c.alt!, style: text.bodyMedium),
            ],
            if (c.example != null) ...[
              const SizedBox(height: 22),
              Text(
                c.example!,
                textAlign: TextAlign.center,
                style: text.bodyLarge,
              ),
              if (c.exampleTranslation != null)
                Text(
                  c.exampleTranslation!,
                  textAlign: TextAlign.center,
                  style: text.bodySmall,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GradeButtons extends StatelessWidget {
  const _GradeButtons({required this.onGrade});

  final void Function(Grade) onGrade;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    Widget button(
      Grade g,
      String label,
      Color bg,
      Color fg,
      int seed,
      String key,
    ) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OrganicCard(
          seed: seed,
          color: bg,
          onTap: () => onGrade(g),
          semanticLabel: '$label ($key)',
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: sans(15, weight: 650, color: fg),
              ),
              Text(key, style: sans(11.5, color: fg.withValues(alpha: 0.75))),
            ],
          ),
        ),
      ),
    );
    return Row(
      key: const ValueKey('grades'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        button(
          Grade.didNotKnow,
          t.gradeNotKnown,
          LeoColors.sand,
          LeoColors.chocolate,
          71,
          '3',
        ),
        button(
          Grade.almost,
          t.gradeAlmost,
          LeoColors.brightWhite,
          LeoColors.chocolate,
          72,
          '2',
        ),
        button(
          Grade.knew,
          t.gradeKnew,
          LeoColors.chocolate,
          LeoColors.brightWhite,
          73,
          '1',
        ),
      ],
    );
  }
}

/// Kurz nach jeder Antwort: wann die letzte Karte wiederkommt.
class _LastNote extends StatelessWidget {
  const _LastNote(this.note);

  final ({String term, String note, bool secure})? note;

  @override
  Widget build(BuildContext context) {
    final n = note;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: n == null
          ? const SizedBox(height: 20)
          : Row(
              key: ValueKey(n),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (n.secure) ...[
                  const SenchaDot(size: 10),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: n.term, style: sans(13.5, weight: 700)),
                        TextSpan(text: ' – ${n.note}'),
                      ],
                    ),
                    style: sans(13.5, color: LeoColors.inkSoft),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Deutsch vorne oder hinten – das Gerät merkt sich die Wahl.
class _DirectionToggle extends StatelessWidget {
  const _DirectionToggle({required this.germanFront, required this.onChanged});

  final bool germanFront;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    Widget option(bool value, String label, int seed) {
      final on = value == germanFront;
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: OrganicCard(
          seed: seed,
          color: on ? LeoColors.chocolate : LeoColors.brightWhite,
          onTap: on ? null : () => onChanged(value),
          semanticLabel: label,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: sans(
              13,
              weight: 650,
              color: on ? LeoColors.brightWhite : LeoColors.chocolate,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        option(true, t.germanFront, 121),
        option(false, t.germanBack, 122),
      ],
    );
  }
}

/// Nach der Lernrunde: Kumachan zeigt, was sie gehäkelt hat. Die Quadrate
/// wachsen nacheinander um ihre neuen Runden, fertige kommen an die Decke.
class _CrochetedToday extends StatelessWidget {
  const _CrochetedToday({
    required this.code,
    required this.steps,
    required this.work,
    required this.attachedBefore,
  });

  final String code;
  final List<CrochetStep> steps;
  final CrochetWork work;
  final int attachedBefore;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final g = glossOf(context);
    final text = Theme.of(context).textTheme;
    final rounds = steps.fold(0, (s, x) => s + x.newRounds);
    // Erst die fertigen (die kommen an die Decke), dann die anderen.
    final ordered = [
      ...steps.where((s) => s.joined),
      ...steps.where((s) => !s.joined),
    ];
    return OrganicCard(
      seed: 18,
      color: LeoColors.brightWhite,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Glossed(
            t.blanketToday,
            gloss: g?.blanketToday,
            style: text.titleLarge,
          ),
          const SizedBox(height: 2),
          Text(t.blanketNewRounds(rounds), style: text.bodyMedium),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              for (final (i, s) in ordered.indexed)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GrannySquare(
                      square: s.square,
                      size: 62,
                      from: s.from,
                      delay: Duration(milliseconds: 260 * min(i, 12)),
                    ),
                    const SizedBox(height: 4),
                    SquareLabel(s.square.card.term, width: 78),
                    if (s.joined)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SenchaDot(size: 8),
                          const SizedBox(width: 4),
                          Text(
                            t.blanketJoined,
                            style: sans(11.5, weight: 700, height: 1.2),
                          ),
                        ],
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              KumaRoll(work: work, height: 120, animateFrom: attachedBefore),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.blanketSummary(
                        work.attached.length,
                        work.onHook.length,
                      ),
                      style: text.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => context.push('/s/$code/decke'),
                      child: Text(t.blanketOpen),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
