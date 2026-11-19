import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Auswahl der fide-Stufe: beide, nur A2 oder nur B1 (`null` = beide).
class FideLevelChips extends StatelessWidget {
  const FideLevelChips({
    super.key,
    required this.level,
    required this.onChanged,
  });

  final String? level;
  final ValueChanged<String?> onChanged;

  /// Die Stufen, die es gibt.
  static const levels = ['A2', 'B1'];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (value, label) in [
          (null, t.fideLevelAll),
          for (final l in levels) (l, t.fideLevelOnly(l)),
        ])
          // Kompakt, damit alle drei auf dem Handy in eine Zeile passen.
          ChoiceChip(
            label: Text(label),
            selected: level == value,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            onSelected: (_) => onChanged(value),
          ),
      ],
    );
  }
}
