import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/leitner.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../ui/colors.dart';
import '../ui/organic.dart';
import '../widgets/app_logo.dart';
import '../widgets/leoni.dart';
import '../widgets/page_frame.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/student_loader.dart';

/// Persönliche Startseite unter `#/s/<code>`.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) => StudentLoader(
    code: code,
    builder: (context, data) => _HomeView(code: code, data: data),
  );
}

class _HomeView extends StatefulWidget {
  const _HomeView({required this.code, required this.data});

  final String code;
  final StudentData data;

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  late final int _streak = widget.data.days.streak();
  late final Future<LeoniPhrase?> _phrase = LeoniPhrases.pick(
    _streak >= 2 ? 'dayStreak' : 'greeting',
  );

  /// Nach dem Zurückkommen (z. B. vom Lernen) Zahlen neu berechnen.
  Future<void> _open(String location) async {
    await context.push(location);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final code = widget.code;
    final data = widget.data;
    final sets = data.content.sets;
    final stats = {for (final s in sets) s.id: data.progress.stats(s)};
    final due = stats.values.fold(0, (a, s) => a + s.due);
    final fresh = stats.values.fold(0, (a, s) => a + s.fresh);
    final streak = data.days.streak();

    return PageFrame(
      title: const AppLogo(),
      actions: [
        IconButton(
          tooltip: t.settings,
          icon: const Icon(Icons.tune_rounded),
          onPressed: () => showSettingsSheet(context),
        ),
        const SizedBox(width: 8),
      ],
      children: [
        FutureBuilder<LeoniPhrase?>(
          future: _phrase,
          builder: (context, snap) => LeoniSays(
            companion: _streak >= 2 ? KumaPose.hug : KumaPose.wave,
            headline: t.greeting(data.content.student.name),
            phrase: snap.data,
            pose: _streak >= 2 ? LeoniPose.heart : LeoniPose.wave,
          ),
        ),
        const SizedBox(height: 8),

        // Heute
        OrganicCard(
          seed: 11,
          color: LeoColors.vanillaIce,
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SenchaDot(),
                  const SizedBox(width: 10),
                  Text(t.todayTitle, style: text.titleLarge),
                  const Spacer(),
                  if (streak > 0)
                    Text(t.streakDays(streak), style: text.labelMedium),
                ],
              ),
              const SizedBox(height: 8),
              Text(t.dueCount(due), style: text.bodyLarge),
              Text(t.newCount(fresh.clamp(0, 999)), style: text.bodySmall),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: due + fresh == 0
                    ? Text(t.allDoneToday, style: text.bodyMedium)
                    : FilledButton(
                        onPressed: () => _open('/s/$code/lernen'),
                        child: Text(t.startLearning),
                      ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        Text(t.yourSets, style: text.headlineSmall),
        const SizedBox(height: 12),
        for (final (i, set) in sets.indexed) ...[
          _SetTile(
            set: set,
            stats: stats[set.id]!,
            seed: 20 + i,
            onTap: () => _open('/s/$code/set/${set.id}'),
          ),
          const SizedBox(height: 12),
        ],

        const SizedBox(height: 20),
        Text(t.games, style: text.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (i, (label, icon, slug)) in [
              (t.gameHangman, Icons.gesture_rounded, 'hangman'),
              (t.gameAbcRadio, Icons.radio_outlined, 'abc-radio'),
              (t.gameCrossword, Icons.grid_view_rounded, 'kreuzwort'),
            ].indexed)
              _GameTile(
                label: label,
                icon: icon,
                seed: 40 + i,
                onTap: () => _open(switch (slug) {
                  'kreuzwort' => '/s/$code/ueben/kreuzwort',
                  _ => '/s/$code/spiel/$slug',
                }),
              ),
          ],
        ),
      ],
    );
  }
}

class _SetTile extends StatelessWidget {
  const _SetTile({
    required this.set,
    required this.stats,
    required this.seed,
    required this.onTap,
  });

  final VocabSet set;
  final SetStats stats;
  final int seed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return OrganicCard(
      seed: seed,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(set.title, style: text.titleLarge),
                    if (set.titleTranslation.isNotEmpty)
                      Text(set.titleTranslation, style: text.bodySmall),
                  ],
                ),
              ),
              if (set.variety == Variety.gsw)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text('Bündnerdütsch', style: text.labelMedium),
                ),
            ],
          ),
          const SizedBox(height: 14),
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
        ],
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.label,
    required this.icon,
    required this.seed,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int seed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 172,
      child: OrganicCard(
        seed: seed,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.titleSmall),
            ),
          ],
        ),
      ),
    );
  }
}
