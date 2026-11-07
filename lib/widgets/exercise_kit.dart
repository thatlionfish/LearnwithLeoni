import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../audio/speaker.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../learn/exercises.dart';
import '../ui/colors.dart';
import '../ui/organic.dart';
import '../ui/theme.dart';
import 'leoni.dart';
import 'page_frame.dart';

String exerciseLabel(AppLocalizations t, ExerciseType type) => switch (type) {
  ExerciseType.choice => t.exChoice,
  ExerciseType.match => t.exMatch,
  ExerciseType.cloze => t.exCloze,
  ExerciseType.dictation => t.exDictation,
  ExerciseType.listening => t.exListening,
  ExerciseType.crossword => t.exCrossword,
  ExerciseType.fide => t.exFide,
};

IconData exerciseIcon(ExerciseType type) => switch (type) {
  ExerciseType.choice => Icons.checklist_rounded,
  ExerciseType.match => Icons.compare_arrows_rounded,
  ExerciseType.cloze => Icons.short_text_rounded,
  ExerciseType.dictation => Icons.edit_note_rounded,
  ExerciseType.listening => Icons.hearing_rounded,
  ExerciseType.crossword => Icons.grid_view_rounded,
  ExerciseType.fide => Icons.headphones_rounded,
};

/// Adresse einer Audiodatei im Ordner des Schülers.
String? audioUrl(String code, String? file) =>
    file == null ? null : 'data/students/$code/$file';

/// Sprachcode für die Computerstimme.
String voiceLang(VocabSet set) =>
    set.variety == Variety.gsw ? 'de-CH' : 'de-DE';

/// Zwei Knöpfe: Anhören und langsam anhören.
class ListenButtons extends StatelessWidget {
  const ListenButtons({
    super.key,
    required this.text,
    this.url,
    this.lang = 'de-DE',
    this.allowVoice = true,
  });

  final String text;
  final String? url;
  final String lang;

  /// Computerstimme erlaubt (für Bündnerdütsch nicht).
  final bool allowVoice;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final canPlay = url != null || allowVoice;
    if (!canPlay) {
      return Text(t.audioMissing, style: Theme.of(context).textTheme.bodySmall);
    }
    Widget button(String label, IconData icon, double rate, int seed) =>
        OrganicCard(
          seed: seed,
          color: LeoColors.brightWhite,
          onTap: () =>
              Speaker.play(url: url, text: text, lang: lang, rate: rate),
          semanticLabel: label,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            button(t.listen, Icons.volume_up_rounded, 1, 91),
            button(t.listenSlow, Icons.slow_motion_video_rounded, 0.75, 92),
          ],
        ),
        if (url == null) ...[
          const SizedBox(height: 6),
          Text(t.voiceNote, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

/// Rückmeldung nach einer Antwort.
class FeedbackBox extends StatelessWidget {
  const FeedbackBox({
    super.key,
    required this.kind,
    required this.solution,
    this.translation,
    this.marked,
  });

  /// 0 = richtig, 1 = fast, 2 = falsch, 3 = nur Groß-/Kleinschreibung falsch.
  final int kind;
  final String solution;
  final String? translation;

  /// Diktat: Lösung Wort für Wort, falsch geschriebene Wörter markiert.
  final List<(String, bool)>? marked;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return OrganicCard(
      seed: 33 + kind,
      color: kind == 0 ? LeoColors.brightWhite : LeoColors.sand,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3, right: 12),
            child: kind == 0
                ? Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: LeoColors.lemonGrass,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: LeoColors.chocolate,
                    ),
                  )
                : const Icon(Icons.lightbulb_outline_rounded, size: 22),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(switch (kind) {
                  0 => t.correctAnswer,
                  1 => marked != null ? t.dictationAlmost : t.almostCorrect,
                  3 => t.caseHint,
                  _ => t.wrongAnswer,
                }, style: text.titleMedium),
                if (kind != 0)
                  marked == null
                      ? Text(solution, style: serif(20, weight: 460))
                      : Text.rich(
                          TextSpan(
                            style: serif(20, weight: 400),
                            children: [
                              for (final (i, (word, wrong)) in marked!.indexed)
                                TextSpan(
                                  text: i == 0 ? word : ' $word',
                                  style: wrong
                                      ? serif(20, weight: 640).copyWith(
                                          decoration: TextDecoration.underline,
                                          decorationColor: LeoColors.chocolate,
                                          decorationThickness: 2,
                                        )
                                      : null,
                                ),
                            ],
                          ),
                        ),
                if (translation != null) ...[
                  const SizedBox(height: 4),
                  Text(translation!, style: text.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Leoni-Einblendung unten links, wie in der Lernsitzung.
class LeoniToastHost extends StatefulWidget {
  const LeoniToastHost({super.key, required this.child});

  final Widget child;

  @override
  State<LeoniToastHost> createState() => LeoniToastHostState();
}

class LeoniToastHostState extends State<LeoniToastHost> {
  (LeoniPose, LeoniPhrase)? _toast;
  Timer? _timer;
  int _correctRun = 0;
  int _wrongRun = 0;

  /// Nach jeder Antwort aufrufen; Leoni lobt Serien und muntert auf.
  Future<void> answered({required bool correct}) async {
    if (correct) {
      _correctRun++;
      _wrongRun = 0;
      if (_correctRun % 3 != 0) return;
      await show(
        Random().nextBool() ? LeoniPose.thumbs : LeoniPose.clap,
        'streak',
      );
    } else {
      _wrongRun++;
      _correctRun = 0;
      if (_wrongRun != 2) return;
      await show(LeoniPose.encourage, 'encourage');
    }
  }

  Future<void> show(LeoniPose pose, String mood) async {
    final phrase = await LeoniPhrases.pick(mood);
    if (!mounted || phrase == null) return;
    _timer?.cancel();
    setState(() => _toast = (pose, phrase));
    _timer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    Speaker.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 12,
          right: 110, // rechts sitzt Kumachan
          bottom: 12,
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
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
    );
  }
}

/// Abschlussseite einer Übung.
class ExerciseDone extends StatefulWidget {
  const ExerciseDone({
    super.key,
    required this.code,
    required this.correct,
    required this.total,
    required this.onAgain,
  });

  final String code;
  final int correct;
  final int total;
  final VoidCallback onAgain;

  @override
  State<ExerciseDone> createState() => _ExerciseDoneState();
}

class _ExerciseDoneState extends State<ExerciseDone> {
  late final Future<LeoniPhrase?> _phrase = LeoniPhrases.pick('done');

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final good = widget.total == 0 || widget.correct / widget.total >= 0.7;
    return PageFrame(
      seed: 19,
      children: [
        const SizedBox(height: 12),
        FutureBuilder(
          future: _phrase,
          builder: (context, snap) => LeoniSays(
            pose: good ? LeoniPose.kick : LeoniPose.heart,
            companion: good ? KumaPose.dance : KumaPose.hug,
            headline: t.exerciseDone,
            phrase: snap.data,
          ),
        ),
        const SizedBox(height: 12),
        OrganicCard(
          seed: 6,
          color: LeoColors.vanillaIce,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.scoreOf(widget.correct, widget.total),
                style: text.bodyLarge,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/s/${widget.code}'),
                    child: Text(t.back),
                  ),
                  TextButton(onPressed: widget.onAgain, child: Text(t.again)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Auswahlknopf in Quiz-Übungen.
class OptionButton extends StatelessWidget {
  const OptionButton({
    super.key,
    required this.label,
    required this.seed,
    required this.onTap,
    this.state = OptionState.idle,
  });

  final String label;
  final int seed;
  final VoidCallback? onTap;
  final OptionState state;

  @override
  Widget build(BuildContext context) {
    final (bg, border) = switch (state) {
      OptionState.idle => (LeoColors.brightWhite, false),
      OptionState.selected => (LeoColors.vanillaIce, true),
      OptionState.right => (LeoColors.brightWhite, true),
      OptionState.wrong => (LeoColors.sand, false),
      OptionState.faded => (LeoColors.coconutMilk, false),
    };
    return OrganicCard(
      seed: seed,
      color: bg,
      onTap: onTap,
      semanticLabel: label,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: sans(
                16,
                weight: 560,
                color: state == OptionState.faded
                    ? LeoColors.inkSoft
                    : LeoColors.chocolate,
              ),
            ),
          ),
          if (state == OptionState.right) const SenchaDot(size: 12),
          if (border && state == OptionState.selected)
            const Icon(Icons.radio_button_checked_rounded, size: 18),
        ],
      ),
    );
  }
}

enum OptionState { idle, selected, right, wrong, faded }
