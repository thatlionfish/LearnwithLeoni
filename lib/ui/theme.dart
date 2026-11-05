import 'package:flutter/material.dart';

import 'colors.dart';

/// Überschriften: Fraunces (variable, weich gestellt).
TextStyle serif(double size, {double weight = 420, double height = 1.2}) =>
    TextStyle(
      fontFamily: 'Fraunces',
      fontSize: size,
      height: height,
      color: LeoColors.chocolate,
      fontWeight: _weight(weight),
      fontVariations: [
        FontVariation('wght', weight),
        const FontVariation('SOFT', 100),
        FontVariation('opsz', size.clamp(9, 144).toDouble()),
      ],
    );

/// Fließtext: Nunito (variable).
TextStyle sans(
  double size, {
  double weight = 420,
  Color? color,
  double height = 1.45,
}) => TextStyle(
  fontFamily: 'Nunito',
  fontSize: size,
  height: height,
  color: color ?? LeoColors.chocolate,
  fontWeight: _weight(weight),
  fontVariations: [FontVariation('wght', weight)],
);

FontWeight _weight(double w) =>
    FontWeight.values[((w / 100).round() - 1).clamp(0, 8)];

ThemeData buildLeoTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: LeoColors.chocolate,
    onPrimary: LeoColors.brightWhite,
    secondary: LeoColors.woodAsh,
    onSecondary: LeoColors.chocolate,
    tertiary: LeoColors.lemonGrass,
    onTertiary: LeoColors.chocolate,
    error: LeoColors.chocolate,
    onError: LeoColors.brightWhite,
    surface: LeoColors.coconutMilk,
    onSurface: LeoColors.chocolate,
    onSurfaceVariant: LeoColors.inkSoft,
    surfaceContainerLowest: LeoColors.brightWhite,
    surfaceContainerLow: LeoColors.brightWhite,
    surfaceContainer: LeoColors.vanillaIce,
    surfaceContainerHigh: LeoColors.vanillaIce,
    surfaceContainerHighest: LeoColors.sand,
    outline: LeoColors.woodAsh,
    outlineVariant: LeoColors.sand,
  );

  final text = TextTheme(
    displaySmall: serif(34, weight: 380),
    headlineMedium: serif(28, weight: 400),
    headlineSmall: serif(24, weight: 420),
    titleLarge: serif(21, weight: 460),
    titleMedium: sans(16.5, weight: 650),
    titleSmall: sans(14.5, weight: 650),
    bodyLarge: sans(16.5),
    bodyMedium: sans(15),
    bodySmall: sans(13.5, color: LeoColors.inkSoft),
    labelLarge: sans(15.5, weight: 650),
    labelMedium: sans(13.5, weight: 600, color: LeoColors.inkSoft),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: LeoColors.coconutMilk,
    textTheme: text,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: LeoColors.chocolate,
      titleTextStyle: serif(22, weight: 440),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LeoColors.chocolate,
        foregroundColor: LeoColors.brightWhite,
        disabledBackgroundColor: LeoColors.sand,
        disabledForegroundColor: LeoColors.inkSoft,
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
        textStyle: sans(16, weight: 650),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.elliptical(26, 22),
            topRight: Radius.elliptical(22, 26),
            bottomLeft: Radius.elliptical(24, 28),
            bottomRight: Radius.elliptical(28, 22),
          ),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: LeoColors.chocolate,
        minimumSize: const Size(48, 48),
        textStyle: sans(15, weight: 650),
      ),
    ),
    iconTheme: const IconThemeData(color: LeoColors.chocolate),
    dividerTheme: const DividerThemeData(
      color: LeoColors.woodAsh,
      thickness: 1,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: LeoColors.coconutMilk,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: LeoColors.woodAsh,
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.all(LeoColors.chocolate),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}
