import 'package:flutter/widgets.dart';

/// Vergrössert die ganze App gleichmässig, wenn der Bildschirm breit ist.
///
/// Die App ist fürs Handy gestaltet (Inhaltsspalte bis 600 px). Auf einem
/// Computer würde sie sonst klein in der Mitte stehen. Darum wird ab etwa
/// 1000 px Breite alles – Schrift, Figuren, Karten, Kreuzworträtsel – im
/// gleichen Verhältnis grösser gezeichnet (höchstens 1,45-fach).
class ProportionalScale extends StatelessWidget {
  const ProportionalScale({super.key, required this.child});

  final Widget child;

  /// Vergrösserung für eine logische Breite [width].
  static double factorFor(Size size) {
    final w = size.width;
    if (w < 1000) return 1;
    // Linear von 1,0 bei 1000 px auf 1,45 bei 1900 px – und nie so gross,
    // dass weniger als 640 px Höhe übrig bleiben.
    final byWidth = 1 + (w - 1000) / 900 * 0.45;
    final byHeight = size.height / 640;
    return byWidth.clamp(1.0, 1.45).clamp(1.0, byHeight < 1 ? 1.0 : byHeight);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final s = factorFor(mq.size);
    if (s == 1) return child;
    final scaled = mq.size / s;
    return MediaQuery(
      data: mq.copyWith(
        size: scaled,
        padding: mq.padding / s,
        viewPadding: mq.viewPadding / s,
        viewInsets: mq.viewInsets / s,
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0,
          minHeight: 0,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: Transform.scale(
            scale: s,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: scaled.width,
              height: scaled.height,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
