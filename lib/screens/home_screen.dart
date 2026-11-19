import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/leitner.dart';
import '../data/models.dart';
import '../learn/crochet.dart';
import '../l10n/app_localizations.dart';
import '../l10n/gloss.dart';
import '../ui/colors.dart';
import '../ui/organic.dart';
import '../widgets/app_logo.dart';
import '../widgets/leoni.dart';
import '../widgets/page_frame.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/student_loader.dart';
import '../widgets/word_fit_text.dart';

/// Persönliche Startseite unter `#/s/<code>`.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.code});

  final String code;

  /// Wie oft Kumachan von sich aus nach ihrer Decke fragt (Tests: 0 oder 1).
  static double kumaAskChance = 1 / 3;

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

  /// Fragt Kumachan diesmal „Willst du deine Decke sehen?“ – nicht jedes Mal.
  late final bool _kumaAsks = Random().nextDouble() < HomeScreen.kumaAskChance;

  CrochetWork get _work =>
      CrochetWork.of(widget.data.content.sets, widget.data.progress);

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
    final sets = data.content.mainSets;
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
            // Kumachan antippen öffnet ihre Decke; ab und zu fragt sie selbst.
            onCompanionTap: () => _open('/s/$code/decke'),
            companionLabel: t.blanketTapKuma,
            companionSays: _kumaAsks && !_work.isEmpty ? t.blanketAsk : null,
            companionSaysGloss: _kumaAsks && !_work.isEmpty
                ? glossOf(context)?.blanketAsk
                : null,
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
                  Glossed(
                    t.todayTitle,
                    gloss: glossOf(context)?.todayTitle,
                    style: text.titleLarge,
                  ),
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

        // fide-Training: alle Themen gemischt, direkt von hier.
        if (sets.any((s) => s.fide.isNotEmpty)) ...[
          const SizedBox(height: 12),
          _FideCard(
            onPractice: () => _open('/s/$code/ueben/fide?mode=practice'),
            onExam: () => _open('/s/$code/ueben/fide?mode=exam'),
          ),
        ],

        // Themen: schlank, ein Tipp führt zu allem, was dazugehört.
        if (data.content.topics.isNotEmpty) ...[
          const SizedBox(height: 28),
          Glossed(
            t.topics,
            gloss: glossOf(context)?.topics,
            style: text.headlineSmall,
          ),
          const SizedBox(height: 10),
          for (final (i, set) in data.content.topics.indexed) ...[
            _TopicRow(
              set: set,
              stats: stats[set.id]!,
              seed: 20 + i,
              onTap: () => _open('/s/$code/set/${set.id}'),
            ),
            const SizedBox(height: 8),
          ],
        ],

        const SizedBox(height: 24),
        Row(
          children: [
            for (final (i, (label, gloss, icon, location)) in [
              (
                t.allWords,
                glossOf(context)?.allWords,
                Icons.menu_book_rounded,
                '/s/$code/woerter',
              ),
              (
                t.games,
                glossOf(context)?.games,
                Icons.extension_rounded,
                '/s/$code/spiele',
              ),
              (
                t.blanketShort,
                glossOf(context)?.blanketShort,
                Icons.bed_rounded,
                '/s/$code/decke',
              ),
            ].indexed) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _SmallTile(
                  label: label,
                  gloss: gloss,
                  icon: icon,
                  seed: 16 + i,
                  onTap: () => _open(location),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// fide-Hörverstehen über alle Themen: gleich üben oder wie in der Prüfung.
class _FideCard extends StatelessWidget {
  const _FideCard({required this.onPractice, required this.onExam});

  final VoidCallback onPractice;
  final VoidCallback onExam;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final g = glossOf(context);
    final text = Theme.of(context).textTheme;
    return OrganicCard(
      seed: 13,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.headphones_rounded, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Glossed(
                  t.fideTraining,
                  gloss: g?.fideTraining,
                  style: text.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Glossed(
            t.fideTrainingInfo,
            gloss: g?.fideTrainingInfo,
            style: text.bodyMedium,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: onPractice,
                child: Text(t.fideModePractice),
              ),
              OutlinedButton(onPressed: onExam, child: Text(t.fideModeExam)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Eine Zeile pro Thema: Titel, Fortschritt, Pfeil.
class _TopicRow extends StatelessWidget {
  const _TopicRow({
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
    final text = Theme.of(context).textTheme;
    return OrganicCard(
      seed: seed,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 12, 10, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(set.title, style: text.titleMedium),
                if (set.titleTranslation.isNotEmpty)
                  Text(set.titleTranslation, style: text.bodySmall),
                const SizedBox(height: 8),
                StackedProgress(
                  secure: stats.secure,
                  learned: stats.learned,
                  learning: stats.learning,
                  total: stats.total,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${stats.secure + stats.learned}/${stats.total}',
            style: text.labelMedium,
          ),
          const Icon(Icons.chevron_right_rounded, size: 22),
        ],
      ),
    );
  }
}

/// Kleine Kachel unten: Alle Wörter, Spiele, Decke.
class _SmallTile extends StatelessWidget {
  const _SmallTile({
    required this.label,
    required this.gloss,
    required this.icon,
    required this.seed,
    required this.onTap,
  });

  final String label;
  final String? gloss;
  final IconData icon;
  final int seed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return OrganicCard(
      seed: seed,
      onTap: onTap,
      semanticLabel: label,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 6),
          WordFitText(
            label,
            textAlign: TextAlign.center,
            style: text.titleSmall ?? const TextStyle(),
          ),
          if (gloss != null && gloss != label)
            Text(gloss!, textAlign: TextAlign.center, style: glossStyle(11)),
        ],
      ),
    );
  }
}
