import 'package:flutter/material.dart';

/// Warme Beige-Palette für die ganze App.
abstract final class Palette {
  static const Color paper = Color(0xFFF4ECDF);
  static const Color paperDeep = Color(0xFFEADFCB);
  static const Color card = Color(0xFFFAF5EC);
  static const Color key = Color(0xFFE6D8C1);
  static const Color keyUsed = Color(0xFFDCCDB5);
  static const Color ink = Color(0xFF3B2E22);
  static const Color inkSoft = Color(0xFF6B5A48);
  static const Color line = Color(0xFFA08A6E);
  static const Color accent = Color(0xFF8B5E3C);
  static const Color correct = Color(0xFF5E8C4A);
  static const Color wrong = Color(0xFFB4442F);

  // Szene
  static const Color wood = Color(0xFF8B5A2B);
  static const Color woodLight = Color(0xFFAD7A45);
  static const Color woodDark = Color(0xFF5A381A);
  static const Color rope = Color(0xFFCBA56C);
  static const Color ropeDark = Color(0xFF9A7641);
  static const Color sun = Color(0xFFF4C152);
  static const Color sunset = Color(0xFFE2703A);
  static const Color nightTint = Color(0xFF1B1530);
}

ThemeData buildBeigeTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Palette.accent,
        brightness: Brightness.light,
      ).copyWith(
        primary: Palette.accent,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFE9D3BC),
        onPrimaryContainer: const Color(0xFF3E2716),
        secondaryContainer: Palette.key,
        onSecondaryContainer: Palette.ink,
        surface: Palette.paper,
        onSurface: Palette.ink,
        onSurfaceVariant: Palette.inkSoft,
        surfaceContainerLow: const Color(0xFFF0E6D6),
        surfaceContainerHighest: Palette.keyUsed,
        outline: Palette.line,
        outlineVariant: const Color(0xFFD3C3AA),
        error: Palette.wrong,
        errorContainer: const Color(0xFFF2D5C8),
        onErrorContainer: const Color(0xFF5A1D10),
      );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.paper,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Palette.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: Palette.ink,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Palette.card,
      selectedColor: const Color(0xFFE9D3BC),
      side: const BorderSide(color: Color(0xFFD3C3AA)),
      labelStyle: const TextStyle(color: Palette.ink),
      checkmarkColor: Palette.accent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
