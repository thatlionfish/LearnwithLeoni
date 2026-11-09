import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/leitner.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../l10n/gloss.dart';
import '../learn/exercises.dart';
import '../widgets/exercise_kit.dart';
import '../ui/colors.dart';
import '../ui/organic.dart';
import '../ui/theme.dart';
import '../widgets/page_frame.dart';
import '../widgets/stats_line.dart';
import '../widgets/student_loader.dart';
import 'message_screen.dart';

/// Ein Set mit allen Karten und dem Einstieg ins Lernen.
class SetScreen extends StatelessWidget {
  const SetScreen({super.key, required this.code, required this.setId});

  final String code;
  final String setId;

  @override
  Widget build(BuildContext context) => StudentLoader(
    code: code,
    builder: (context, data) {
      final t = AppLocalizations.of(context);
      final set = data.content.set(setId);
      if (set == null) {
        return MessageScreen(
          title: t.notFoundTitle,
          body: t.notFoundBody,
          showBack: true,
        );
      }
      return _SetView(code: code, set: set, data: data);
    },
  );
}

class _SetView extends StatefulWidget {
  const _SetView({required this.code, required this.set, required this.data});

  final String code;
  final VocabSet set;
  final StudentData data;

  @override
  State<_SetView> createState() => _SetViewState();
}

class _SetViewState extends State<_SetView> {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final set = widget.set;
    final stats = widget.data.progress.stats(set);

    return PageFrame(
      showBack: true,
      seed: 8,
      children: [
        Text(set.title, style: text.displaySmall),
        if (set.titleTranslation.isNotEmpty)
          Text(set.titleTranslation, style: text.bodyLarge),
        const SizedBox(height: 18),
        StackedProgress(
          secure: stats.secure,
          learned: stats.learned,
          learning: stats.learning,
          total: stats.total,
        ),
        const SizedBox(height: 8),
        Text(statsLine(t, stats), style: text.bodySmall),
        const SizedBox(height: 4),
        Glossed(
          t.spacedInfo,
          gloss: glossOf(context)?.spacedInfo,
          style: text.bodySmall,
          glossSize: 11.5,
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: () async {
              await context.push('/s/${widget.code}/lernen?set=${set.id}');
              if (mounted) setState(() {});
            },
            child: Text(set.isCollection ? t.startLearning : t.learnThisSet),
          ),
        ),
        const SizedBox(height: 30),
        Glossed(
          t.practice,
          gloss: glossOf(context)?.practice,
          style: text.headlineSmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (i, (type, label, query)) in [
              for (final type in availableExercises(set))
                if (type == ExerciseType.listening)
                  for (final l in set.listening)
                    (
                      type,
                      set.listening.length > 1
                          ? l.title
                          : exerciseLabel(t, type),
                      '&text=${l.id}',
                    )
                else
                  (type, exerciseLabel(t, type), ''),
            ].indexed)
              SizedBox(
                width: 176,
                child: OrganicCard(
                  seed: 80 + i,
                  onTap: () async {
                    await context.push(
                      '/s/${widget.code}/ueben/${type.slug}?set=${set.id}$query',
                    );
                    if (mounted) setState(() {});
                  },
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Icon(exerciseIcon(type), size: 22),
                      const SizedBox(width: 10),
                      Expanded(child: Text(label, style: text.titleSmall)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 30),
        Glossed(
          t.allCards,
          gloss: glossOf(context)?.allCards,
          style: text.headlineSmall,
        ),
        const SizedBox(height: 12),
        for (final (i, card) in set.cards.indexed) ...[
          _CardRow(
            card: card,
            seed: 60 + i,
            state: widget.data.progress.stateOf(set, card),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.card, required this.seed, this.state});

  final VocabCard card;
  final int seed;

  /// Lernstand; `null` = noch nicht gelernt.
  final CardState? state;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return OrganicCard(
      seed: seed,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    Text(card.term, style: text.titleLarge),
                    if (card.plural != null)
                      Text(card.plural!, style: text.bodySmall),
                  ],
                ),
              ),
              if (state != null) _BoxDots(state!),
            ],
          ),
          Text(card.translation, style: text.bodyMedium),
          if (card.alt != null) Text(card.alt!, style: text.bodySmall),
          if (card.example != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.only(left: 12),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: LeoColors.woodAsh, width: 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.example!, style: text.bodyMedium),
                  if (card.exampleTranslation != null)
                    Text(card.exampleTranslation!, style: text.bodySmall),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Lernstand einer Karte: fünf Punkte für die Fächer, darunter wann sie
/// wiederkommt – oder „sicher“.
class _BoxDots extends StatelessWidget {
  const _BoxDots(this.state);

  final CardState state;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final small = sans(11.5, color: LeoColors.inkSoft, height: 1.2);
    if (state.isSecure) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SenchaDot(size: 10),
          const SizedBox(width: 6),
          Text(t.statSecure, style: sans(12.5, weight: 700)),
        ],
      );
    }
    final days = Leitner.daysUntil(state);
    return Tooltip(
      message: t.cardBox(state.box),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var b = 1; b <= Leitner.boxes; b++)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: b <= state.box
                        ? LeoColors.chocolate
                        : LeoColors.vanillaIce,
                    border: Border.all(color: LeoColors.woodAsh, width: 0.8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(t.reviewIn(days < 0 ? 0 : days), style: small),
        ],
      ),
    );
  }
}
