import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../ui/theme.dart';

/// Logo (Leoni und Kumachan auf dem Kiesel) mit Schriftzug.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 34, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final image = SvgPicture.asset(
      'assets/logo/logo.svg',
      width: size,
      height: size,
      semanticsLabel: 'LearnwithLeoni',
    );
    if (!showName) return image;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        image,
        const SizedBox(width: 10),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('LearnwithLeoni', style: serif(20, weight: 440)),
          ),
        ),
      ],
    );
  }
}
