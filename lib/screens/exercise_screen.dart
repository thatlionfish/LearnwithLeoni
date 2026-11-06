import 'package:flutter/material.dart';

import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../learn/answer_check.dart';
import '../learn/exercises.dart';
import '../ui/colors.dart';
import '../ui/organic.dart';
import '../ui/theme.dart';
import '../widgets/exercise_kit.dart';
import '../widgets/kuma_helper.dart';
import '../widgets/page_frame.dart';
import '../widgets/student_loader.dart';
import 'crossword_screen.dart';
import 'match_screen.dart';
import 'message_screen.dart';

/// Einstieg für alle Übungen: `#/s/<code>/ueben/<typ>?set=<id>`.
class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({
    super.key,
    required this.code,
    required this.typeSlug,
    this.setId,
    this.textId,
  });

  /// Hörverstehen: welcher Hörtext (sonst der erste).
  final String? textId;

  final String code;
  final String typeSlug;
  final String? setId;

  @override
  Widget build(BuildContext context) => StudentLoader(
    code: code,
    builder: (context, data) {
      final t = AppLocalizations.of(context);
      final type = ExerciseType.fromSlug(typeSlug);
      final sets = data.content.sets;
      final set = setId == null ? null : data.content.set(setId!);
      if (type == null || (setId != null && set == null) || sets.isEmpty) {
        return MessageScreen(
          title: t.notFoundTitle,
          body: t.notFoundBody,
          showBack: true,
        );
      }
      // Kreuzworträtsel geht auch über alle Sets (Spiele-Kachel auf der Startseite).
      if (type == ExerciseType.crossword) {
        return CrosswordScreen(
          code: code,
          sets: set == null ? sets : [set],
          audioClues: data.content.student.crosswordAudio,
        );
      }
      final s = set ?? sets.first;
      return switch (type) {
        ExerciseType.match => MatchScreen(code: code, set: s),
        ExerciseType.listening => _ListeningScreen(
          code: code,
          set: s,
          textId: textId,
        ),
        _ => QuizScreen(code: code, set: s, type: type, others: sets),
      };
    },
  );
}

/// Auswahl- und Eingabefragen: Multiple Choice, Lückentext, Diktat.
class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.code,
    required this.set,
    required this.type,
    this.others = const [],
    this.items,
    this.header,
  });

  final String code;
  final VocabSet set;
  final ExerciseType type;
  final List<VocabSet> others;

  /// Fertige Fragen (z. B. beim Hörverstehen); sonst aus dem Set erzeugt.
  final List<QuizItem>? items;

  /// Zusätzlicher Inhalt über der Frage (z. B. der Hörtext).
  final Widget? header;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<QuizItem> _items;
  int _index = 0;
  int _correct = 0;
  String? _chosen;

  /// null = noch nicht beantwortet, sonst 0 richtig / 1 fast / 2 falsch.
  int? _result;
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  final _toastKey = GlobalKey<LeoniToastHostState>();

  @override
  void initState() {
    super.initState();
    _build();
  }

  void _build() {
    _items =
        widget.items ??
        switch (widget.type) {
          ExerciseType.choice => choiceItems(
            widget.set,
            extraDistractors: [
              for (final s in widget.others)
                if (s.id != widget.set.id) ...s.cards,
            ],
          ),
          ExerciseType.cloze => clozeItems(widget.set),
          ExerciseType.dictation => dictationItems(widget.set),
          _ => const [],
        };
    _index = 0;
    _correct = 0;
    _reset();
  }

  void _reset() {
    _chosen = null;
    _result = null;
    _input.clear();
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  QuizItem get _item => _items[_index];

  void _answer(String value) {
    if (_result != null) return;
    final r = _item.isChoice
        ? (value == _item.accepted.first
              ? AnswerResult.correct
              : AnswerResult.wrong)
        : checkAnswer(value, _item.accepted, caseSensitive: _strict);
    final kind = switch (r) {
      AnswerResult.correct => 0,
      AnswerResult.close => 1,
      AnswerResult.wrong => 2,
      AnswerResult.caseError => 3,
    };
    // Im Diktat zählt nur ein fehlerfreier Satz – auch Groß-/Kleinschreibung.
    final counts = _strict ? kind == 0 : kind < 2;
    setState(() {
      _chosen = value;
      _result = kind;
      if (counts) _correct++;
    });
    _toastKey.currentState?.answered(correct: counts);
  }

  /// Diktat: streng prüfen (Groß-/Kleinschreibung, Tippfehler zählen).
  bool get _strict => widget.type == ExerciseType.dictation;

  void _next() {
    setState(() {
      _index++;
      _reset();
    });
    if (_index < _items.length && !_item.isChoice) _inputFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (_items.isEmpty) {
      return MessageScreen(
        title: t.comingSoon,
        body: t.comingSoonBody,
        showBack: true,
      );
    }
    if (_index >= _items.length) {
      return ExerciseDone(
        code: widget.code,
        correct: _correct,
        total: _items.length,
        onAgain: () => setState(_build),
      );
    }
    return KumaHelper(
      itemKey: _index,
      hints: () => _item.hints,
      audioFor: (h) => _item.hints.isNotEmpty && h == _item.hints.first
          ? audioUrl(widget.code, _item.hintAudio)
          : null,
      child: LeoniToastHost(key: _toastKey, child: _question(context, t)),
    );
  }

  Widget _question(BuildContext context, AppLocalizations t) {
    final text = Theme.of(context).textTheme;
    final item = _item;
    final answered = _result != null;
    final instruction = switch (widget.type) {
      ExerciseType.choice => t.chooseTranslation,
      ExerciseType.cloze => t.fillGap,
      ExerciseType.dictation => t.writeWhatYouHear,
      _ => null,
    };

    return PageFrame(
      showBack: true,
      seed: 21,
      title: Text(
        '${exerciseLabel(t, widget.type)} · ${t.progressOf(_index + 1, _items.length)}',
        style: text.labelLarge,
      ),
      children: [
        ?widget.header,
        if (instruction != null) ...[
          Text(instruction, style: text.bodyMedium),
          const SizedBox(height: 14),
        ],
        OrganicCard(
          key: ValueKey(item.id),
          seed: item.id.hashCode,
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.prompt != null)
                Text(
                  item.prompt!,
                  style: serif(widget.type == ExerciseType.choice ? 32 : 22),
                ),
              if (item.sentence != null)
                _Sentence(item: item, filled: answered ? _chosen : null),
              if (item.speak != null)
                ListenButtons(
                  text: item.speak!,
                  url: audioUrl(widget.code, item.audio),
                  lang: voiceLang(widget.set),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (item.isChoice)
          for (final (i, o) in item.options.indexed) ...[
            OptionButton(
              label: o,
              seed: 100 + i,
              onTap: answered ? null : () => _answer(o),
              state: !answered
                  ? OptionState.idle
                  : o == item.accepted.first
                  ? OptionState.right
                  : o == _chosen
                  ? OptionState.wrong
                  : OptionState.faded,
            ),
            const SizedBox(height: 10),
          ]
        else
          TextField(
            controller: _input,
            focusNode: _inputFocus,
            autofocus: true,
            enabled: !answered,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (v) => answered ? _next() : _answer(v),
            style: sans(18, weight: 520),
            decoration: InputDecoration(
              hintText: t.yourAnswer,
              filled: true,
              fillColor: LeoColors.brightWhite,
              border: OutlineInputBorder(
                borderRadius: organicInputRadius(3),
                borderSide: const BorderSide(color: LeoColors.woodAsh),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: organicInputRadius(3),
                borderSide: const BorderSide(color: LeoColors.woodAsh),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: organicInputRadius(3),
                borderSide: const BorderSide(
                  color: LeoColors.chocolate,
                  width: 1.4,
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (answered) ...[
          FeedbackBox(
            kind: _result!,
            solution: item.accepted.first,
            translation: item.translation,
            // Diktat: falsche Wörter in der Lösung markieren.
            marked: _strict && _result != 0
                ? markWords(_chosen ?? '', item.accepted.first)
                : null,
          ),
          const SizedBox(height: 16),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: answered
              ? FilledButton(
                  autofocus: true,
                  onPressed: _next,
                  child: Text(t.next),
                )
              : item.isChoice
              ? const SizedBox.shrink()
              : FilledButton(
                  onPressed: () => _answer(_input.text),
                  child: Text(t.check),
                ),
        ),
        const SizedBox(height: 120),
      ],
    );
  }
}

/// Satz mit Lücke; nach der Antwort steht die Lösung in der Lücke.
class _Sentence extends StatelessWidget {
  const _Sentence({required this.item, required this.filled});

  final QuizItem item;
  final String? filled;

  @override
  Widget build(BuildContext context) {
    final parts = item.sentence!.split('___');
    final style = serif(23, weight: 400, height: 1.5);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (final (i, p) in parts.indexed) ...[
            TextSpan(text: p),
            if (i < parts.length - 1)
              TextSpan(
                text: filled == null ? '  ______  ' : item.accepted.first,
                style: filled == null
                    ? style.copyWith(color: LeoColors.woodAsh)
                    : style.copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: LeoColors.lemonGrass,
                        decorationThickness: 3,
                      ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Hörtext oben, Fragen darunter.
class _ListeningScreen extends StatefulWidget {
  const _ListeningScreen({required this.code, required this.set, this.textId});

  final String? textId;

  final String code;
  final VocabSet set;

  @override
  State<_ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<_ListeningScreen> {
  bool _showText = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final listening = widget.set.listening.firstWhere(
      (l) => l.id == widget.textId,
      orElse: () => widget.set.listening.first,
    );
    final header = OrganicCard(
      seed: 77,
      color: LeoColors.vanillaIce,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(listening.title, style: text.titleLarge),
          if (listening.titleTranslation != null)
            Text(listening.titleTranslation!, style: text.bodySmall),
          const SizedBox(height: 6),
          Text(t.listenFirst, style: text.bodyMedium),
          const SizedBox(height: 14),
          ListenButtons(
            // Sprecherwechsel als kurze Pause vorlesen.
            text: listening.text.replaceAll(
              RegExp(r'^[^:\n]{1,20}:\s*', multiLine: true),
              '',
            ),
            url: audioUrl(widget.code, listening.audio),
            lang: voiceLang(widget.set),
            allowVoice: widget.set.variety == Variety.de,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _showText = !_showText),
            icon: Icon(
              _showText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            label: Text(_showText ? t.hideText : t.showText),
          ),
          if (_showText)
            for (final line in listening.text.split('\n'))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(line, style: text.bodyMedium),
              ),
        ],
      ),
    );
    return QuizScreen(
      code: widget.code,
      set: widget.set,
      type: ExerciseType.listening,
      items: listeningItems(listening),
      header: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: header,
      ),
    );
  }
}
