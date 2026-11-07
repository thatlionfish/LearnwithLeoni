import 'dart:math';

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

/// Kumachans Häkelecke unter `#/s/<code>/decke`: Kumachan in ihrer
/// Decke eingerollt; ausgerollt sieht man alle gelernten Wörter.
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

class _BlanketView extends StatefulWidget {
  const _BlanketView({required this.code, required this.work});

  final String code;
  final CrochetWork work;

  @override
  State<_BlanketView> createState() => _BlanketViewState();
}

class _BlanketViewState extends State<_BlanketView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _unroll = AnimationController(
    vsync: this,
    // Je länger die Decke, desto länger dauert das Ausrollen.
    duration: Duration(
      milliseconds:
          900 +
          min(
            2600,
            140 * (widget.work.attached.length / CrochetWork.columns).ceil(),
          ),
    ),
  );

  @override
  void dispose() {
    _unroll.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_unroll.value > 0.5) {
      _unroll.reverse();
    } else {
      _unroll.forward();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final g = glossOf(context);
    final text = Theme.of(context).textTheme;
    final work = widget.work;
    final open =
        _unroll.status == AnimationStatus.forward ||
        _unroll.status == AnimationStatus.completed;

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
              AnimatedBuilder(
                animation: _unroll,
                builder: (context, _) => Center(
                  child: KumaRoll(
                    work: work,
                    height: 230,
                    unrolled: Curves.easeInOut.transform(_unroll.value),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t.blanketSquares(work.attached.length),
                style: serif(20, weight: 460),
                textAlign: TextAlign.center,
              ),
              Text(
                t.blanketSummary(work.attached.length, work.onHook.length),
                style: text.bodySmall,
                textAlign: TextAlign.center,
              ),
              if (work.attached.isNotEmpty) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _toggle,
                  icon: Icon(
                    open
                        ? Icons.unfold_less_rounded
                        : Icons.unfold_more_rounded,
                  ),
                  label: Text(open ? t.blanketRollUp : t.blanketUnroll),
                ),
              ],
            ],
          ),
        ),
        // Die ausgerollte Decke wächst nach unten, vorne läuft die Rolle mit.
        AnimatedBuilder(
          animation: _unroll,
          builder: (context, _) {
            final v = Curves.easeInOut.transform(_unroll.value);
            if (v <= 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                children: [
                  ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: v,
                      child: UnrolledBlanket(squares: work.attached),
                    ),
                  ),
                  if (v < 1) RollEdge(thickness: 8 + 26 * (1 - v)),
                ],
              ),
            );
          },
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
              onPressed: () => context.push('/s/${widget.code}/lernen'),
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
          Wrap(
            spacing: 10,
            runSpacing: 14,
            children: [
              for (final s in work.onHook)
                Tooltip(
                  message: '${s.card.term} – ${s.card.translation}',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GrannySquare(square: s, size: 70),
                      const SizedBox(height: 4),
                      SquareLabel(s.card.term),
                      Text(
                        t.blanketRounds(s.rounds),
                        style: sans(11, color: LeoColors.inkSoft, height: 1.2),
                      ),
                    ],
                  ),
                ),
            ],
          ),
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
