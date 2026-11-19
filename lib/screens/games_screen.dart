import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../l10n/gloss.dart';
import '../widgets/action_tiles.dart';
import '../widgets/page_frame.dart';

/// Die Spiele an einem Ort: `#/s/<code>/spiele` (von der Startseite aus).
class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return PageFrame(
      showBack: true,
      seed: 14,
      children: [
        Glossed(
          t.games,
          gloss: glossOf(context)?.games,
          style: text.displaySmall,
        ),
        const SizedBox(height: 20),
        ActionTiles(
          seed: 40,
          minWidth: 172,
          spacing: 12,
          iconSize: 24,
          gap: 12,
          padding: const EdgeInsets.all(18),
          tiles: [
            for (final (label, icon, location) in [
              (t.gameHangman, Icons.gesture_rounded, '/s/$code/spiel/hangman'),
              (
                t.gameAbcRadio,
                Icons.radio_outlined,
                '/s/$code/spiel/abc-radio',
              ),
              (
                t.gameCrossword,
                Icons.grid_view_rounded,
                '/s/$code/ueben/kreuzwort',
              ),
            ])
              (label: label, icon: icon, onTap: () => context.push(location)),
          ],
        ),
      ],
    );
  }
}
