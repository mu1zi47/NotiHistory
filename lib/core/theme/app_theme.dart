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

class AppPalette {
  const AppPalette(this.dark);
  final bool dark;
  Color get ink => dark ? const Color(0xFFECE8F5) : const Color(0xFF272339);
  Color get muted => dark ? const Color(0xFFB3AABD) : const Color(0xFF817C91);
  Color get accent => dark ? const Color(0xFFB6A3FF) : const Color(0xFF7660DB);
  Color get accentSurface =>
      dark ? const Color(0xFF342A4B) : const Color(0xFFEEE8FD);
  Color get paper => dark ? const Color(0xFF15121C) : const Color(0xFFF7F6FB);
  Color get surface => dark ? const Color(0xFF211C2B) : Colors.white;
  Color get divider => dark ? const Color(0xFF383140) : const Color(0xFFEEECF4);
  Color get deleteSurface =>
      dark ? const Color(0xFF40242D) : const Color(0xFFFBEAEC);
  Color get deleteInk =>
      dark ? const Color(0xFFF09AA8) : const Color(0xFFC76370);
}

AppPalette ui(BuildContext context) =>
    AppPalette(Theme.of(context).brightness == Brightness.dark);

ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final palette = AppPalette(brightness == Brightness.dark);
  final ink = palette.ink, muted = palette.muted, accent = palette.accent;
  final accentSurface = palette.accentSurface, paper = palette.paper;
  final base = ThemeData(brightness: brightness);
  return ThemeData(
    brightness: brightness,
    useMaterial3: true,
    scaffoldBackgroundColor: paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      surface: palette.surface,
      brightness: brightness,
    ),
    appBarTheme: AppBarTheme(
      systemOverlayStyle: brightness == Brightness.dark
          ? transparentDarkSystemBars
          : transparentSystemBars,
      backgroundColor: paper,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    textTheme: _withFonts(base.textTheme)
        .apply(bodyColor: ink, displayColor: ink),
    primaryTextTheme: _withFonts(base.primaryTextTheme),
    dialogTheme: DialogThemeData(
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
      fillColor: palette.surface,
      hintStyle: TextStyle(
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
        borderSide: BorderSide(color: palette.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: accent),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      indicatorColor: accentSurface,
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
}
