import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../audio/speaker.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../l10n/gloss.dart';
import '../learn/answer_check.dart';
import '../learn/hints.dart';
import '../ui/colors.dart';
import '../ui/organic.dart';
import '../ui/theme.dart';
import '../widgets/exercise_kit.dart';
import '../widgets/fide_picture.dart';
import '../widgets/kuma_helper.dart';
import '../widgets/leoni.dart';
import '../widgets/page_frame.dart';

/// Hörverstehen im Aufbau des fide-Tests „Verstehen“ (A2–B1):
/// Situation und Frage hören, Hörtext hören, Frage nochmals – dann auf ein
/// Bild zeigen (A2) oder kurz frei antworten (B1).
class FideScreen extends StatefulWidget {
  const FideScreen({super.key, required this.code, required this.set});

  final String code;
  final VocabSet set;

  @override
  State<FideScreen> createState() => _FideScreenState();
}

enum _Mode { exam, practice }

/// Eine Frage in der Reihenfolge des Tests.
class _Step {
  const _Step(
    this.situation,
    this.item, {
    required this.first,
    required this.number,
  });
  final FideSituation situation;
  final FideItem item;

  /// Erste Frage der Situation: Die Prüferin erklärt zuerst die Situation.
  final bool first;
  final int number;
}

class _Answer {
  _Answer(this.step, {this.choice, this.text, required this.correct});
  final _Step step;
  final int? choice;
  final String? text;
  bool correct;

  /// Vom Schüler selbst als richtig bestätigt (freie Antwort).
  bool self = false;

  /// Wie im Test: A2 ein Punkt, B1 zwei Punkte pro Frage.
  int get max => step.item.isPicture ? 1 : 2;
  int get points => correct ? max : 0;
}

class _FideScreenState extends State<FideScreen> {
  /// Im Test darf man jeden Text höchstens zweimal hören.
  static const maxPlays = 2;

  late final List<_Step> _steps = () {
    final out = <_Step>[];
    for (final s in widget.set.fide) {
      for (final (i, item) in s.items.indexed) {
        out.add(_Step(s, item, first: i == 0, number: out.length + 1));
      }
    }
    return out;
  }();

  _Mode? _mode;
  int _index = 0;
  int _plays = 0;
  _Answer? _current;
  final List<_Answer> _answers = [];
  final _input = TextEditingController();
  final _toastKey = GlobalKey<LeoniToastHostState>();
  final _shownTranscripts = <int>{};

  bool get _exam => _mode == _Mode.exam;
  _Step get _step => _steps[_index];

  @override
  void dispose() {
    Speaker.stop();
    _input.dispose();
    super.dispose();
  }

  void _start(_Mode mode) {
    setState(() {
      _mode = mode;
      _index = 0;
      _answers.clear();
      _shownTranscripts.clear();
      _resetStep();
    });
    _play();
  }

  void _resetStep() {
    _plays = 0;
    _current = null;
    _input.clear();
  }

  bool get _canPlay => !_exam || _plays < maxPlays;

  void _play({bool slow = false}) {
    if (!_canPlay) return;
    setState(() => _plays++);
    final step = _step;
    final item = step.item;
    final spoken = item.text.replaceAll(
      RegExp(r'^[^:\n]{1,30}:\s*', multiLine: true),
      '',
    );
    Speaker.play(
      url: audioUrl(widget.code, item.audio),
      text:
          '${step.first ? 'Situation: ${step.situation.situation} ' : ''}'
          'Frage: ${item.question} $spoken '
          'Noch einmal die Frage: ${item.question}',
      rate: slow ? 0.8 : 1,
    );
  }

  void _record(_Answer a) {
    setState(() {
      _current = a;
      _answers.add(a);
    });
    if (!_exam) _toastKey.currentState?.answered(correct: a.correct);
  }

  void _choose(int i) {
    if (_current != null) return;
    _record(_Answer(_step, choice: i, correct: i == _step.item.answer));
  }

  void _submit() {
    if (_current != null) return;
    final item = _step.item;
    final given = _input.text;
    if (given.trim().isEmpty) return;
    final ok =
        checkKeywords(given, item.keywords) ||
        (item.model != null &&
            checkAnswer(given, [item.model!]) != AnswerResult.wrong);
    _record(_Answer(_step, text: given, correct: ok));
  }

  void _next() {
    Speaker.stop();
    setState(() {
      _index++;
      _resetStep();
    });
    if (_index < _steps.length) _play();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (_mode == null) return _startView(t);
    if (_index >= _steps.length) return _doneView(t);
    final page = LeoniToastHost(key: _toastKey, child: _stepView(t));
    // In der Prüfung hilft niemand – beim Üben ist Kumachan da.
    return _exam
        ? page
        : KumaHelper(
            itemKey: _index,
            hints: () => fideHints(_step.item),
            child: page,
          );
  }

  // ---------------------------------------------------------------- Start

  Widget _startView(AppLocalizations t) {
    final g = glossOf(context);
    final text = Theme.of(context).textTheme;
    Widget mode(
      _Mode m,
      String title,
      String? titleG,
      String info,
      String? infoG,
      IconData icon,
      int seed,
    ) => OrganicCard(
      seed: seed,
      color: m == _Mode.exam ? LeoColors.vanillaIce : LeoColors.brightWhite,
      onTap: () => _start(m),
      semanticLabel: title,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Glossed(title, gloss: titleG, style: text.titleMedium),
                const SizedBox(height: 4),
                Glossed(info, gloss: infoG, style: text.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
    final a2 = _steps.where((s) => s.item.isPicture).length;
    final b1 = _steps.length - a2;
    return PageFrame(
      showBack: true,
      seed: 43,
      title: Text(t.exFide, style: text.labelLarge),
      children: [
        LeoniSays(
          pose: LeoniPose.read,
          companion: KumaPose.wave,
          headline: widget.set.title,
          subline: [if (a2 > 0) '$a2 × A2', if (b1 > 0) '$b1 × B1'].join(' · '),
          figureHeight: 140,
        ),
        const SizedBox(height: 8),
        Glossed(t.fideIntro, gloss: g?.fideIntro, style: text.bodyMedium),
        const SizedBox(height: 18),
        mode(
          _Mode.practice,
          t.fideModePractice,
          g?.fideModePractice,
          t.fideModePracticeInfo,
          g?.fideModePracticeInfo,
          Icons.hearing_rounded,
          51,
        ),
        const SizedBox(height: 12),
        mode(
          _Mode.exam,
          t.fideModeExam,
          g?.fideModeExam,
          t.fideModeExamInfo,
          g?.fideModeExamInfo,
          Icons.timer_outlined,
          52,
        ),
        const SizedBox(height: 120),
      ],
    );
  }

  // ---------------------------------------------------------------- Frage

  Widget _stepView(AppLocalizations t) {
    final g = glossOf(context);
    final text = Theme.of(context).textTheme;
    final step = _step;
    final item = step.item;
    final answered = _current != null;

    return PageFrame(
      // Neue Frage = neue Seite: wieder oben beginnen.
      key: ValueKey(_index),
      showBack: true,
      seed: 44,
      title: Text(
        '${t.exFide} · ${t.progressOf(_index + 1, _steps.length)}',
        style: text.labelLarge,
      ),
      children: [
        Row(
          children: [
            _LevelChip(step.situation.level),
            const SizedBox(width: 10),
            Text(t.fideQuestion(step.number), style: text.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        // Beim Üben steht alles da; in der Prüfung gibt es – wie im echten
        // Test – keine geschriebenen Texte, nur Hören.
        if (!_exam)
          OrganicCard(
            seed: 60 + step.situation.id.hashCode % 7,
            color: LeoColors.vanillaIce,
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.fideSituation, style: text.labelMedium),
                const SizedBox(height: 4),
                Text(step.situation.situation, style: sans(16, weight: 480)),
                HelpReveal(step.situation.situationTranslation),
                const SizedBox(height: 12),
                Text(item.question, style: serif(22, weight: 470)),
                HelpReveal(item.questionTranslation),
              ],
            ),
          ),
        if (!_exam) const SizedBox(height: 14),
        _listenRow(t),
        const SizedBox(height: 18),
        Glossed(
          item.isPicture ? t.fidePictureTask : t.fideOpenTask,
          gloss: item.isPicture ? g?.fidePictureTask : g?.fideOpenTask,
          style: text.bodyMedium,
        ),
        const SizedBox(height: 12),
        if (item.isPicture) _pictures(item) else _openAnswer(t, item),
        if (answered && !_exam) ...[
          const SizedBox(height: 16),
          _feedback(t, _current!),
          const SizedBox(height: 12),
          _Transcript(item: item, title: t.fideTranscript),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: answered
              ? FilledButton(
                  autofocus: true,
                  onPressed: _next,
                  child: Text(t.next),
                )
              : item.isPicture
              ? const SizedBox.shrink()
              : FilledButton(onPressed: _submit, child: Text(t.check)),
        ),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _listenRow(AppLocalizations t) {
    final left = maxPlays - _plays;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: _canPlay ? _play : null,
          icon: const Icon(Icons.headphones_rounded),
          label: Text(t.fidePlay),
        ),
        if (!_exam)
          OutlinedButton.icon(
            onPressed: () => _play(slow: true),
            icon: const Icon(Icons.slow_motion_video_rounded),
            label: Text(t.listenSlow),
          ),
        if (_exam)
          Text(
            t.fidePlaysLeft(left < 0 ? 0 : left),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget _pictures(FideItem item) {
    final a = _current;
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 560;
        final cards = [
          for (final (i, p) in item.pictures.indexed)
            _PictureCard(
              picture: p,
              letter: 'abc'[i % 3],
              seed: 300 + i + item.id.hashCode % 11,
              height: wide ? 140 : 118,
              onTap: a == null ? () => _choose(i) : null,
              state: a == null
                  ? OptionState.idle
                  : _exam
                  ? (a.choice == i ? OptionState.selected : OptionState.faded)
                  : i == item.answer
                  ? OptionState.right
                  : a.choice == i
                  ? OptionState.wrong
                  : OptionState.faded,
              showLabel: a != null && !_exam,
            ),
        ];
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, c) in cards.indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: c),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (final c in cards) ...[c, const SizedBox(height: 10)],
          ],
        );
      },
    );
  }

  Widget _openAnswer(AppLocalizations t, FideItem item) => TextField(
    controller: _input,
    enabled: _current == null,
    autocorrect: false,
    enableSuggestions: false,
    textInputAction: TextInputAction.done,
    onSubmitted: (_) => _current == null ? _submit() : _next(),
    style: sans(18, weight: 520),
    decoration: InputDecoration(
      hintText: t.yourAnswer,
      filled: true,
      fillColor: LeoColors.brightWhite,
      border: OutlineInputBorder(
        borderRadius: organicInputRadius(4),
        borderSide: const BorderSide(color: LeoColors.woodAsh),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: organicInputRadius(4),
        borderSide: const BorderSide(color: LeoColors.woodAsh),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: organicInputRadius(4),
        borderSide: const BorderSide(color: LeoColors.chocolate, width: 1.4),
      ),
    ),
  );

  /// Rückmeldung (beim Üben sofort, in der Prüfung erst am Schluss).
  Widget _feedback(AppLocalizations t, _Answer a) {
    final item = a.step.item;
    final text = Theme.of(context).textTheme;
    final String solution;
    final String? translation;
    if (item.isPicture) {
      final p = item.pictures[item.answer];
      solution =
          '${'abc'[item.answer]})${p.label == null ? '' : '  ${p.label}'}';
      translation = null;
    } else {
      solution =
          item.model ?? item.keywords.map((k) => k.split('|').first).join(', ');
      translation = item.modelTranslation;
    }
    return OrganicCard(
      seed: 33 + (a.correct ? 0 : 2),
      color: a.correct ? LeoColors.brightWhite : LeoColors.sand,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (a.correct) ...[
                const SenchaDot(size: 12),
                const SizedBox(width: 10),
              ],
              Text(
                a.correct
                    ? t.correctAnswer
                    : (item.isPicture ? t.wrongAnswer : t.fideModelAnswer),
                style: text.titleMedium,
              ),
            ],
          ),
          if (!a.correct || !item.isPicture) ...[
            const SizedBox(height: 4),
            Text(solution, style: serif(20, weight: 460)),
            HelpReveal(translation),
          ],
          if (!a.correct && !item.isPicture) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() {
                a.correct = true;
                a.self = true;
              }),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(t.fideSelfCheck),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Ende

  Widget _doneView(AppLocalizations t) {
    final g = glossOf(context);
    final text = Theme.of(context).textTheme;
    int sum(bool pictures, int Function(_Answer) f) => _answers
        .where((a) => a.step.item.isPicture == pictures)
        .fold(0, (s, a) => s + f(a));
    final a2Max = sum(true, (a) => a.max);
    final b1Max = sum(false, (a) => a.max);
    final points = sum(true, (a) => a.points) + sum(false, (a) => a.points);
    final good = points >= 0.7 * (a2Max + b1Max);
    return PageFrame(
      showBack: true,
      seed: 45,
      title: Text(t.exFide, style: text.labelLarge),
      children: [
        LeoniSays(
          pose: good ? LeoniPose.kick : LeoniPose.heart,
          companion: good ? KumaPose.dance : KumaPose.hug,
          headline: t.exerciseDone,
          subline: [
            if (a2Max > 0)
              t.fidePoints('A2', sum(true, (a) => a.points), a2Max),
            if (b1Max > 0)
              t.fidePoints('B1', sum(false, (a) => a.points), b1Max),
          ].join('\n'),
        ),
        const SizedBox(height: 4),
        Glossed(
          t.fideResultNote,
          gloss: g?.fideResultNote,
          style: text.bodySmall,
          glossSize: 11.5,
        ),
        const SizedBox(height: 16),
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
            TextButton(
              onPressed: () => setState(() => _mode = null),
              child: Text(t.again),
            ),
          ],
        ),
        const SizedBox(height: 24),
        for (final (i, a) in _answers.indexed) ...[
          _review(t, a, i),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _review(AppLocalizations t, _Answer a, int i) {
    final text = Theme.of(context).textTheme;
    final item = a.step.item;
    final open = _shownTranscripts.contains(i);
    return OrganicCard(
      seed: 400 + i,
      color: a.correct ? LeoColors.brightWhite : LeoColors.vanillaIce,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LevelChip(a.step.situation.level),
              const SizedBox(width: 8),
              Text(t.fideQuestion(a.step.number), style: text.labelLarge),
              const Spacer(),
              if (a.correct) const SenchaDot(size: 11),
            ],
          ),
          const SizedBox(height: 6),
          Text(item.question, style: serif(19, weight: 460)),
          if (item.isPicture) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                for (final (k, p) in item.pictures.indexed)
                  Expanded(
                    child: Opacity(
                      opacity: k == item.answer || k == a.choice ? 1 : 0.4,
                      child: Column(
                        children: [
                          FidePictureView(p, height: 74),
                          Text(
                            '${'abc'[k]})${k == item.answer ? ' ✓' : ''}',
                            style: sans(
                              13,
                              weight: k == item.answer ? 760 : 460,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ] else ...[
            if (a.text != null) Text('„${a.text}“', style: text.bodyMedium),
            if (!a.correct) _feedback(t, a),
          ],
          TextButton.icon(
            onPressed: () => setState(
              () =>
                  open ? _shownTranscripts.remove(i) : _shownTranscripts.add(i),
            ),
            icon: Icon(
              open ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
            ),
            label: Text(open ? t.hideText : t.showText),
          ),
          if (open) _Transcript(item: item),
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip(this.level);

  final String level;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
    decoration: BoxDecoration(
      color: level == 'B1' ? LeoColors.sand : LeoColors.brightWhite,
      borderRadius: organicRadius(level.hashCode, base: 8),
      border: Border.all(color: LeoColors.woodAsh),
    ),
    child: Text(level, style: sans(12.5, weight: 720)),
  );
}

class _PictureCard extends StatelessWidget {
  const _PictureCard({
    required this.picture,
    required this.letter,
    required this.seed,
    required this.height,
    required this.onTap,
    required this.state,
    required this.showLabel,
  });

  final FidePicture picture;
  final String letter;
  final int seed;
  final double height;
  final VoidCallback? onTap;
  final OptionState state;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final bg = switch (state) {
      OptionState.selected => LeoColors.vanillaIce,
      OptionState.wrong => LeoColors.sand,
      OptionState.faded => LeoColors.coconutMilk,
      _ => LeoColors.brightWhite,
    };
    return Opacity(
      opacity: state == OptionState.faded ? 0.55 : 1,
      child: OrganicCard(
        seed: seed,
        color: bg,
        onTap: onTap,
        semanticLabel: '$letter)',
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          children: [
            FidePictureView(picture, height: height),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$letter)', style: sans(16, weight: 720)),
                if (state == OptionState.right) ...[
                  const SizedBox(width: 8),
                  const SenchaDot(size: 11),
                ],
              ],
            ),
            if (showLabel && picture.label != null)
              Text(
                picture.label!,
                textAlign: TextAlign.center,
                style: sans(13.5, color: LeoColors.inkSoft),
              ),
          ],
        ),
      ),
    );
  }
}

/// Der Hörtext zum Nachlesen; „Name: …“ wird als Sprecher gezeigt.
class _Transcript extends StatelessWidget {
  const _Transcript({required this.item, this.title});

  final FideItem item;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return OrganicCard(
      seed: 71,
      color: LeoColors.coconutMilk,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: text.labelMedium),
            const SizedBox(height: 6),
          ],
          for (final line in item.text.split('\n'))
            if (line.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: () {
                  final m = RegExp(r'^([^:]{1,30}):\s*(.*)$').firstMatch(line);
                  return m == null
                      ? Text(line, style: text.bodyMedium)
                      : Text.rich(
                          TextSpan(
                            style: text.bodyMedium,
                            children: [
                              TextSpan(
                                text: '${m[1]}: ',
                                style: sans(15, weight: 700),
                              ),
                              TextSpan(text: m[2]),
                            ],
                          ),
                        );
                }(),
              ),
        ],
      ),
    );
  }
}
