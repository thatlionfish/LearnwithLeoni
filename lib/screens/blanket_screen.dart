import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../l10n/gloss.dart';
import '../learn/crochet.dart';
import '../ui/colors.dart';
import '../ui/organic.dart';
import '../ui/theme.dart';
import '../widgets/crochet.dart';
import '../widgets/page_frame.dart';
import '../widgets/student_loader.dart';

/// Kumachans Häkelecke unter `#/s/<code>/decke`: alle Wörter als
/// Häkelquadrate, die fertigen an der grossen Decke.
class BlanketScreen extends StatelessWidget {
  const BlanketScreen({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) => StudentLoader(
    code: code,
    builder: (context, data) => _BlanketView(
      code: code,
      work: CrochetWork.of(data.content.sets, data.progress),
    ),
  );
}

class _BlanketView extends StatelessWidget {
  const _BlanketView({required this.code, required this.work});

  final String code;
  final CrochetWork work;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final g = glossOf(context);
    final text = Theme.of(context).textTheme;
    return PageFrame(
      showBack: true,
      seed: 47,
      title: Text(t.blanketTitle, style: text.labelLarge),
      children: [
        OrganicCard(
          seed: 48,
          color: LeoColors.vanillaIce,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
            children: [
              Center(child: KumaBlanket(work: work, height: 250)),
              const SizedBox(height: 12),
              Text(
                t.blanketSummary(work.attached.length, work.onHook.length),
                style: serif(20, weight: 460),
                textAlign: TextAlign.center,
              ),
              if (work.blankets > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SenchaDot(size: 10),
                    const SizedBox(width: 6),
                    Text(t.blanketDone(work.blankets), style: text.bodyMedium),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Glossed(t.blanketIntro, gloss: g?.blanketIntro, style: text.bodyMedium),
        if (work.isEmpty) ...[
          const SizedBox(height: 18),
          Glossed(
            t.blanketEmpty,
            gloss: g?.blanketEmpty,
            style: text.bodyLarge,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: () => context.push('/s/$code/lernen'),
              child: Text(t.startLearning),
            ),
          ),
        ],
        if (work.onHook.isNotEmpty) ...[
          const SizedBox(height: 26),
          Glossed(
            t.blanketOnHook,
            gloss: g?.blanketOnHook,
            style: text.headlineSmall,
          ),
          const SizedBox(height: 12),
          _SquareGrid(
            squares: work.onHook,
            caption: (s) => t.blanketRounds(s.rounds),
          ),
        ],
        if (work.attached.isNotEmpty) ...[
          const SizedBox(height: 26),
          Glossed(
            t.blanketAttached,
            gloss: g?.blanketAttached,
            style: text.headlineSmall,
          ),
          const SizedBox(height: 12),
          _SquareGrid(squares: work.attached.reversed.toList()),
        ],
        if (work.waiting > 0) ...[
          const SizedBox(height: 22),
          Text(t.blanketWaiting(work.waiting), style: text.bodySmall),
        ],
        const SizedBox(height: 60),
      ],
    );
  }
}

class _SquareGrid extends StatelessWidget {
  const _SquareGrid({required this.squares, this.caption});

  final List<CrochetSquare> squares;
  final String Function(CrochetSquare)? caption;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 14,
      children: [
        for (final s in squares)
          Tooltip(
            message: '${s.card.term} – ${s.card.translation}',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GrannySquare(square: s, size: 70),
                const SizedBox(height: 4),
                SquareLabel(s.card.term),
                if (caption != null)
                  Text(
                    caption!(s),
                    style: sans(11, color: LeoColors.inkSoft, height: 1.2),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
