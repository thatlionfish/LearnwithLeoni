import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../ui/colors.dart';
import '../ui/theme.dart';
import 'app_localizations.dart';

/// Hilfesprache des Schülers (`en`, `ja` …) oder `null` = nur Deutsch.
String? helpLanguageOf(BuildContext context) => HelpScope.languageOf(context);

/// Dieselben Oberflächentexte in der Hilfesprache – für die kleine Zeile
/// unter dem deutschen Text. `null`, wenn es keine Hilfesprache gibt.
AppLocalizations? glossOf(BuildContext context) {
  final code = helpLanguageOf(context);
  return code == null ? null : lookupAppLocalizations(Locale(code));
}

/// Stil der Hilfezeile: klein, leise, am Rand.
TextStyle glossStyle([double size = 12.5]) =>
    sans(size, weight: 430, color: LeoColors.inkSoft, height: 1.35);

/// Deutscher Text, darunter klein die Hilfesprache.
class Glossed extends StatelessWidget {
  const Glossed(
    this.text, {
    super.key,
    required this.gloss,
    this.style,
    this.glossSize = 12.5,
  });

  final String text;

  /// Übersetzung in die Hilfesprache; ohne Hilfesprache `null`.
  final String? gloss;
  final TextStyle? style;
  final double glossSize;

  @override
  Widget build(BuildContext context) {
    final g = gloss;
    if (g == null || g.trim().isEmpty || g == text) {
      return Text(text, style: style);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: style),
        const SizedBox(height: 2),
        Text(g, style: glossStyle(glossSize)),
      ],
    );
  }
}

/// Übersetzung eines Inhalts, die erst auf Wunsch erscheint – so bleibt der
/// Blick auf dem Deutschen. Ohne Hilfesprache oder Übersetzung: nichts.
class HelpReveal extends StatefulWidget {
  const HelpReveal(this.translation, {super.key});

  final String? translation;

  @override
  State<HelpReveal> createState() => _HelpRevealState();
}

class _HelpRevealState extends State<HelpReveal> {
  bool _open = false;

  @override
  void didUpdateWidget(HelpReveal old) {
    super.didUpdateWidget(old);
    if (old.translation != widget.translation) _open = false;
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.translation;
    final code = helpLanguageOf(context);
    if (tr == null || tr.trim().isEmpty || code == null) {
      return const SizedBox.shrink();
    }
    if (_open) {
      return GestureDetector(
        onTap: () => setState(() => _open = false),
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(tr, style: glossStyle(13.5)),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => setState(() => _open = true),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          minimumSize: const Size(0, 30),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: LeoColors.inkSoft,
        ),
        icon: const Icon(Icons.translate_rounded, size: 15),
        label: Text(
          helpLanguageNames[code] ?? code,
          style: sans(12.5, weight: 520, color: LeoColors.inkSoft),
        ),
      ),
    );
  }
}

/// Sprachnamen in der jeweiligen Sprache selbst.
const Map<String, String> helpLanguageNames = {
  'de': 'Deutsch',
  'en': 'English',
  'es': 'Español',
  'fr': 'Français',
  'it': 'Italiano',
  'ja': '日本語',
  'pt': 'Português',
};
