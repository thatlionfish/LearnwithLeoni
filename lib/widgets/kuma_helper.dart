import 'package:flutter/material.dart';

import '../audio/speaker.dart';
import '../l10n/app_localizations.dart';
import '../ui/colors.dart';
import '../ui/organic.dart';
import '../ui/theme.dart';
import 'leoni.dart';

/// Kumachan sitzt unten rechts und hilft auf Knopfdruck: jeder Tipp verrät
/// etwas mehr (Umschreibung → Wortart → Anfangsbuchstabe), nie die Lösung.
class KumaHelper extends StatefulWidget {
  const KumaHelper({
    super.key,
    required this.child,
    required this.hints,
    required this.itemKey,
    this.audioFor,
  });

  final Widget child;

  /// Fertiges Audio zu einem Tipp (z. B. die Umschreibung), sonst Browser-Stimme.
  final String? Function(String hint)? audioFor;

  /// Tipps zur aktuellen Aufgabe, vom leichtesten zum stärksten.
  final List<String> Function() hints;

  /// Wechselt die Aufgabe, beginnen die Tipps wieder von vorn.
  final Object? itemKey;

  @override
  State<KumaHelper> createState() => _KumaHelperState();
}

class _KumaHelperState extends State<KumaHelper> {
  int _level = 0;
  String? _shown;

  @override
  void didUpdateWidget(KumaHelper old) {
    super.didUpdateWidget(old);
    if (old.itemKey != widget.itemKey) {
      _level = 0;
      _shown = null;
    }
  }

  void _tap() {
    final t = AppLocalizations.of(context);
    final hints = widget.hints();
    setState(() {
      if (_level < hints.length) {
        _shown = hints[_level];
        _level++;
      } else {
        _shown = t.kumaNoMore;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final shown = _shown;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final bubble = shown == null ? null : _bubble(t, shown);

    if (wide) {
      // Breiter Bildschirm: Kumachan sitzt rechts neben der Inhaltsspalte.
      return Stack(
        children: [
          widget.child,
          Positioned(
            right: 16,
            bottom: 12,
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (bubble != null)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: bubble,
                      ),
                    ),
                  const SizedBox(width: 6),
                  _kuma(t, shown, height: 100),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Handy: eigener Streifen unten – Kumachan verdeckt nie einen Knopf.
    // Der Tipp schiebt den Inhalt nach oben, statt ihn zu verdecken.
    return Column(
      children: [
        Expanded(child: widget.child),
        if (bubble != null)
          Material(
            color: LeoColors.coconutMilk,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: bubble,
                ),
              ),
            ),
          ),
        Material(
          color: LeoColors.coconutMilk,
          child: SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: LeoColors.woodAsh)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 6, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.kumaStrip,
                      style: sans(13.5, color: LeoColors.inkSoft),
                    ),
                  ),
                  _kuma(t, shown, height: 58),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bubble(AppLocalizations t, String shown) => Material(
    type: MaterialType.transparency,
    child: OrganicCard(
      key: ValueKey(shown),
      seed: 88,
      color: LeoColors.vanillaIce,
      padding: const EdgeInsets.fromLTRB(16, 12, 6, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${t.kumaTip} $_level',
                  style: sans(12, weight: 650, color: LeoColors.inkSoft),
                ),
                const SizedBox(height: 2),
                Text(shown, style: sans(15.5, weight: 500)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: t.listen,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.volume_up_rounded, size: 20),
                onPressed: () => Speaker.play(
                  url: widget.audioFor?.call(shown),
                  text: shown,
                  // Kumachans Stimme: hoch und ein bisschen quietschig.
                  pitch: 1.8,
                  rate: 1.05,
                ),
              ),
              IconButton(
                tooltip: t.close,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => setState(() => _shown = null),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _kuma(AppLocalizations t, String? shown, {required double height}) =>
      Semantics(
        button: true,
        label: t.kumaAsk,
        child: Tooltip(
          message: t.kumaAsk,
          child: GestureDetector(
            onTap: _tap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                KumaFigure(
                  pose: shown == null ? KumaPose.idle : KumaPose.wave,
                  height: height,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: LeoColors.brightWhite,
                    borderRadius: organicRadius(7, base: 10),
                    border: Border.all(color: LeoColors.woodAsh),
                  ),
                  child: Text(t.kumaTip, style: sans(12.5, weight: 650)),
                ),
              ],
            ),
          ),
        ),
      );
}
