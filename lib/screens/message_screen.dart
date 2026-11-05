import 'package:flutter/material.dart';

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
  });

  final LeoniPose pose;

  final String title;
  final String body;
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
              Text(title, style: text.headlineSmall),
              const SizedBox(height: 10),
              Text(body, style: text.bodyLarge),
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
