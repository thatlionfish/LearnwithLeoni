import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../audio/speaker.dart';
import '../data/leitner.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../l10n/gloss.dart';
import '../learn/crochet.dart';
import '../learn/words.dart';
import '../ui/colors.dart';
import '../ui/organic.dart';
import '../widgets/crochet.dart';
import '../widgets/exercise_kit.dart';
import '../widgets/page_frame.dart';
import '../widgets/stats_line.dart';
import '../widgets/student_loader.dart';

/// Alle Wörter eines Schülers an einem Ort: `#/s/<code>/woerter`.
class WordsScreen extends StatelessWidget {
  const WordsScreen({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) => StudentLoader(
    code: code,
    builder: (context, data) => _WordsView(code: code, data: data),
  );
}

class _WordsView extends StatefulWidget {
  const _WordsView({required this.code, required this.data});

  final String code;
  final StudentData data;

  @override
  State<_WordsView> createState() => _WordsViewState();
}

class _WordsViewState extends State<_WordsView> {
  String _query = '';

  SetStats _sum() {
    var total = 0, secure = 0, learned = 0, learning = 0, due = 0;
    for (final set in widget.data.content.sets) {
      final s = widget.data.progress.stats(set);
      total += s.total;
      secure += s.secure;
      learned += s.learned;
      learning += s.learning;
      due += s.due;
    }
    return SetStats(
      total: total,
      secure: secure,
      learned: learned,
      learning: learning,
      due: due,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final g = glossOf(context);
    final text = Theme.of(context).textTheme;
    final content = widget.data.content;
    final progress = widget.data.progress;
    final stats = _sum();
    final loose = content.collection;
    final shown = [
      for (final w in allWords(content.sets))
        if (wordMatches(w, _query)) w,
    ];

    return PageFrame(
      showBack: true,
      seed: 12,
      children: [
        Glossed(t.allWords, gloss: g?.allWords, style: text.displaySmall),
        const SizedBox(height: 18),
        StackedProgress(
          secure: stats.secure,
          learned: stats.learned,
          learning: stats.learning,
          total: stats.total,
        ),
        const SizedBox(height: 8),
        Text(statsLine(t, stats), style: text.bodySmall),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: () async {
              await context.push('/s/${widget.code}/lernen');
              if (mounted) setState(() {});
            },
            child: Text(t.startLearning),
          ),
        ),
        // Wörter aus den Themen übt man im Set, die einzelnen von hier aus.
        if (loose != null) ...[
          const SizedBox(height: 16),
          OrganicCard(
            seed: 17,
            onTap: () async {
              await context.push('/s/${widget.code}/set/${loose.id}');
              if (mounted) setState(() {});
            },
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.edit_note_rounded, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Glossed(
                    t.looseWordsPractice,
                    gloss: g?.looseWordsPractice,
                    style: text.titleSmall,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 22),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: t.wordSearch,
            prefixIcon: const Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 14),
        if (shown.isEmpty) Text(t.wordsNoMatch, style: text.bodyMedium),
        for (final (i, w) in shown.indexed) ...[
          _WordRow(
            key: ValueKey('${w.set.id}/${w.card.id}'),
            code: widget.code,
            word: w,
            state: progress.stateOf(w.set, w.card),
            seed: 60 + i,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Eine Zeile: das Häkelquadrat zeigt den Lernstand, Tippen zeigt den Satz.
class _WordRow extends StatefulWidget {
  const _WordRow({
    super.key,
    required this.code,
    required this.word,
    required this.state,
    required this.seed,
  });

  final String code;
  final WordEntry word;

  /// Lernstand; `null` = noch nicht gelernt.
  final CardState? state;
  final int seed;

  @override
  State<_WordRow> createState() => _WordRowState();
}

class _WordRowState extends State<_WordRow> {
  bool _open = false;

  /// Bündnerdütsch nur mit Leonis Aufnahme, nie mit der Computerstimme.
  Widget? _listen(BuildContext context, String words, String? file) {
    final set = widget.word.set;
    if (file == null && set.variety != Variety.de) return null;
    final t = AppLocalizations.of(context);
    return IconButton(
      tooltip: t.listen,
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.volume_up_rounded, size: 22),
      onPressed: () => Speaker.play(
        url: audioUrl(widget.code, file),
        text: words,
        lang: voiceLang(set),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final card = widget.word.card;
    final state = widget.state;
    final example = card.example;
    return OrganicCard(
      seed: widget.seed,
      onTap: () => setState(() => _open = !_open),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GrannySquare(
                square: CrochetSquare(
                  set: widget.word.set,
                  card: card,
                  rounds: state?.box ?? 0,
                  due: state?.due ?? DateTime(2000),
                ),
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        Text(card.term, style: text.titleMedium),
                        if (card.plural != null)
                          Text(card.plural!, style: text.bodySmall),
                      ],
                    ),
                    Text(card.translation, style: glossStyle()),
                  ],
                ),
              ),
              ?_listen(context, card.term, card.audio),
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                child: const Icon(
                  Icons.expand_more_rounded,
                  size: 22,
                  color: LeoColors.inkSoft,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(48, 8, 6, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (card.alt != null)
                          Text(card.alt!, style: text.bodySmall),
                        if (example != null)
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(example, style: text.bodyMedium),
                                    if (card.exampleTranslation != null)
                                      Text(
                                        card.exampleTranslation!,
                                        style: glossStyle(),
                                      ),
                                  ],
                                ),
                              ),
                              ?_listen(context, example, card.exampleAudio),
                            ],
                          ),
                        if (state != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            state.isSecure
                                ? t.statSecure
                                : t.reviewIn(
                                    Leitner.daysUntil(state) < 0
                                        ? 0
                                        : Leitner.daysUntil(state),
                                  ),
                            style: text.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
