import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/leitner.dart';
import '../l10n/app_localizations.dart';
import '../learn/session.dart';
import '../ui/colors.dart';
import '../ui/organic.dart';
import '../ui/theme.dart';
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
      return _LearnView(
        code: code,
        data: data,
        session: LearnSession.build(sets, data.progress),
      );
    },
  );
}

class _LearnView extends StatefulWidget {
  const _LearnView({
    required this.code,
    required this.data,
    required this.session,
  });

  final String code;
  final StudentData data;
  final LearnSession session;

  @override
  State<_LearnView> createState() => _LearnViewState();
}

class _LearnViewState extends State<_LearnView> {
  final FocusNode _focus = FocusNode(debugLabel: 'learn-keys');
  bool _flipped = false;

  /// Kurze Einblendung von Leoni (Pose + Spruch).
  (LeoniPose, LeoniPhrase)? _toast;
  Timer? _toastTimer;
  LeoniPhrase? _donePhrase;

  LearnSession get _session => widget.session;

  @override
  void dispose() {
    _toastTimer?.cancel();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _grade(Grade grade) async {
    if (!_flipped || _session.isDone) return;
    final moment = _session.answer(grade, (item, g) {
      widget.data.progress.record(item.set, item.card, g);
    });
    unawaited(widget.data.days.markToday());
    setState(() => _flipped = false);

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
              const SizedBox(height: 22),
              _FlipCard(
                key: ValueKey(item.key + _session.answeredCount.toString()),
                item: item,
                flipped: _flipped,
                onFlip: () => setState(() => _flipped = true),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: _flipped
                    ? _GradeButtons(onGrade: _grade)
                    : Center(
                        key: const ValueKey('hint'),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(t.tapToFlip, style: text.bodySmall),
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
  });

  final SessionItem item;
  final bool flipped;
  final VoidCallback onFlip;

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
      label: c.term,
      child: SizedBox(
        height: 220,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.set.title, style: text.labelMedium),
            const SizedBox(height: 22),
            Text(
              c.term,
              textAlign: TextAlign.center,
              style: serif(36, weight: 420),
            ),
            if (c.plural != null) ...[
              const SizedBox(height: 6),
              Text(c.plural!, style: text.bodyMedium),
            ],
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
            Text(c.term, style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              c.translation,
              textAlign: TextAlign.center,
              style: serif(30, weight: 420),
            ),
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
