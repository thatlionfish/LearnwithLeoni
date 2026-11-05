import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../learn/exercises.dart';
import '../widgets/exercise_kit.dart';
import '../ui/colors.dart';
import '../ui/organic.dart';
import '../widgets/page_frame.dart';
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
          learned: stats.learned,
          learning: stats.learning,
          total: stats.total,
        ),
        const SizedBox(height: 8),
        Text(
          '${t.cardCount(stats.total)} · ${stats.learned} ${t.statLearned} · '
          '${stats.learning} ${t.statLearning} · ${stats.fresh} ${t.statNew}',
          style: text.bodySmall,
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: () async {
              await context.push('/s/${widget.code}/lernen?set=${set.id}');
              if (mounted) setState(() {});
            },
            child: Text(t.learnThisSet),
          ),
        ),
        const SizedBox(height: 30),
        Text(t.practice, style: text.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (i, type) in availableExercises(set).indexed)
              SizedBox(
                width: 176,
                child: OrganicCard(
                  seed: 80 + i,
                  onTap: () async {
                    await context.push(
                      '/s/${widget.code}/ueben/${type.slug}?set=${set.id}',
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
                      Expanded(
                        child: Text(
                          exerciseLabel(t, type),
                          style: text.titleSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 30),
        Text(t.allCards, style: text.headlineSmall),
        const SizedBox(height: 12),
        for (final (i, card) in set.cards.indexed) ...[
          _CardRow(card: card, seed: 60 + i),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.card, required this.seed});

  final VocabCard card;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return OrganicCard(
      seed: seed,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text(card.term, style: text.titleLarge),
              if (card.plural != null)
                Text(card.plural!, style: text.bodySmall),
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
