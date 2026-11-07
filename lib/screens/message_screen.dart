import 'package:flutter/material.dart';

import '../l10n/gloss.dart';
import '../ui/organic.dart';
import '../widgets/leoni.dart';
import '../widgets/page_frame.dart';

/// Einfache Seite mit Leoni und einer Nachricht (Willkommen, Fehler, bald …).
class MessageScreen extends StatelessWidget {
  const MessageScreen({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.showBack = false,
    this.pose = LeoniPose.wave,
    this.titleGloss,
    this.bodyGloss,
  });

  final LeoniPose pose;

  final String title;
  final String body;

  /// Dieselben Texte klein in der Hilfesprache.
  final String? titleGloss;
  final String? bodyGloss;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PageFrame(
      showBack: showBack,
      seed: 5,
      children: [
        const SizedBox(height: 24),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              KumaFigure(
                pose: pose == LeoniPose.shrug ? KumaPose.sleepy : KumaPose.idle,
                height: 104,
              ),
              const SizedBox(width: 6),
              LeoniFigure(pose: pose, height: 200),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OrganicCard(
          seed: 9,
          padding: const EdgeInsets.all(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Glossed(title, gloss: titleGloss, style: text.headlineSmall),
              const SizedBox(height: 10),
              Glossed(body, gloss: bodyGloss, style: text.bodyLarge),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
