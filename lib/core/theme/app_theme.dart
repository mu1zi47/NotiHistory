import 'package:flutter/material.dart';

import 'system_bars.dart';

const ink = Color(0xFF272339);
const muted = Color(0xFF817C91);
const accent = Color(0xFF7660DB);
const accentSurface = Color(0xFFEEE8FD);
const paper = Color(0xFFF7F6FB);
const actionRadius = 14.0;

/// Exo2 headings; keep the existing Manrope body styles and weights.
const titleFont = 'Exo2';
const bodyFont = 'Manrope';

TextTheme _withFonts(TextTheme base) {
  TextStyle? title(TextStyle? s, FontWeight weight) =>
      s?.copyWith(fontFamily: titleFont, fontWeight: weight);
  TextStyle? body(TextStyle? s, FontWeight weight) =>
      s?.copyWith(fontFamily: bodyFont, fontWeight: weight);
  return base.copyWith(
    displayLarge: title(base.displayLarge, FontWeight.w800),
    displayMedium: title(base.displayMedium, FontWeight.w800),
    displaySmall: title(base.displaySmall, FontWeight.w700),
    headlineLarge: title(base.headlineLarge, FontWeight.w700),
    headlineMedium: title(base.headlineMedium, FontWeight.w700),
    headlineSmall: title(base.headlineSmall, FontWeight.w700),
    titleLarge: title(base.titleLarge, FontWeight.w700),
    titleMedium: title(base.titleMedium, FontWeight.w600),
    titleSmall: title(base.titleSmall, FontWeight.w600),
    bodyLarge: body(base.bodyLarge, FontWeight.w700),
    bodyMedium: body(base.bodyMedium, FontWeight.w700),
    bodySmall: body(base.bodySmall, FontWeight.w600),
    labelLarge: body(base.labelLarge, FontWeight.w800),
    labelMedium: body(base.labelMedium, FontWeight.w800),
    labelSmall: body(base.labelSmall, FontWeight.w700),
  );
}

ThemeData buildAppTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: paper,
  colorScheme: ColorScheme.fromSeed(seedColor: accent, surface: paper),
  appBarTheme: const AppBarTheme(
    systemOverlayStyle: transparentSystemBars,
    backgroundColor: paper,
    foregroundColor: ink,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  textTheme: _withFonts(ThemeData.light().textTheme)
      .apply(bodyColor: ink, displayColor: ink),
  primaryTextTheme: _withFonts(ThemeData.light().primaryTextTheme),
  dialogTheme: const DialogThemeData(
    titleTextStyle: TextStyle(
      fontFamily: titleFont,
      fontSize: 19,
      fontWeight: FontWeight.w700,
      height: 1.3,
      color: ink,
    ),
    contentTextStyle: TextStyle(
      fontFamily: bodyFont,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.5,
      color: muted,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: accentSurface,
      foregroundColor: accent,
      disabledBackgroundColor: accentSurface.withValues(alpha: .55),
      disabledForegroundColor: accent.withValues(alpha: .45),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(actionRadius),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    hintStyle: const TextStyle(
      color: muted,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFECEAF3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: accent),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: const Color(0xFFEDE7FF),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => TextStyle(
        fontSize: 11,
        fontWeight: states.contains(WidgetState.selected)
            ? FontWeight.w800
            : FontWeight.w600,
        color: states.contains(WidgetState.selected) ? accent : muted,
      ),
    ),
  ),
);
