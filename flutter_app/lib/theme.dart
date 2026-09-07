import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'brand.dart';

const ink = StudiaryBrand.ink;
const coral = StudiaryBrand.coral;
const coralDeep = StudiaryBrand.error;
const mint = StudiaryBrand.mint;
const canvas = StudiaryBrand.background;
const night = StudiaryBrand.darkSurface;

const defaultThemeBackground = '#FFF4DE';
const defaultThemePrimary = '#8A9BFF';
const defaultThemeText = '#27345E';
const defaultThemeSurface = '#FFFFFF';

ThemeData buildTheme({
  required bool dark,
  String backgroundHex = defaultThemeBackground,
  String primaryHex = defaultThemePrimary,
  String textHex = defaultThemeText,
  String surfaceHex = defaultThemeSurface,
}) {
  final requestedBackground = _parseHex(backgroundHex, canvas);
  final requestedPrimary = _parseHex(primaryHex, coral);
  final requestedText = _parseHex(textHex, ink);
  final requestedSurface = _parseHex(surfaceHex, StudiaryBrand.surface);
  final background = dark
      ? _darken(requestedBackground, .72)
      : requestedBackground;
  final surface = dark ? _darken(requestedSurface, .62) : requestedSurface;
  final primary = dark ? _lighten(requestedPrimary, .12) : requestedPrimary;
  final onSurface = _readable(requestedText, background);
  final onSurfaceVariant = _readable(
    Color.lerp(requestedText, background, .38)!,
    background,
    minimumContrast: 3,
  );
  final primaryContainer = Color.lerp(primary, background, .84)!;
  final onPrimaryContainer = _readable(requestedText, primaryContainer);
  final onPrimary = _readable(Colors.white, primary);
  final secondary = Color.lerp(primary, mint, .62)!;
  final onSecondary = _readable(ink, secondary);
  final outline = Color.lerp(onSurface, background, .58)!;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: primary,
        brightness: dark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        surfaceContainer: Color.lerp(surface, background, .28)!,
        surfaceContainerHighest: Color.lerp(surface, background, .1)!,
        outline: outline,
        outlineVariant: Color.lerp(outline, background, .58)!,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    fontFamily: 'sans',
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? surface : background,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StudiaryBrand.cardRadius),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 74,
      elevation: 0,
      backgroundColor: surface,
      indicatorColor: primary.withValues(alpha: dark ? .25 : .2),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color.lerp(surface, background, .34),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StudiaryBrand.controlRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StudiaryBrand.controlRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StudiaryBrand.controlRadius),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StudiaryBrand.controlRadius),
      ),
      side: BorderSide.none,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StudiaryBrand.controlRadius),
      ),
    ),
  );
}

Color _parseHex(String value, Color fallback) {
  final clean = value.replaceAll('#', '');
  final normalized = clean.length == 6 ? 'FF$clean' : clean;
  final parsed = int.tryParse(normalized, radix: 16);
  return parsed == null ? fallback : Color(parsed);
}

Color _darken(Color color, double amount) => Color.lerp(color, night, amount)!;

Color _lighten(Color color, double amount) =>
    Color.lerp(color, Colors.white, amount)!;

Color _readable(
  Color preferred,
  Color background, {
  double minimumContrast = 4.5,
}) {
  if (_contrast(preferred, background) >= minimumContrast) return preferred;
  final light = _contrast(Colors.white, background);
  final dark = _contrast(ink, background);
  return light >= dark ? Colors.white : ink;
}

double _contrast(Color first, Color second) {
  final firstLuminance = _luminance(first);
  final secondLuminance = _luminance(second);
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + .05) / (darker + .05);
}

double _luminance(Color color) {
  final argb = color.toARGB32();

  double channel(int value) {
    final normalized = value / 255;
    return normalized <= .03928
        ? normalized / 12.92
        : math.pow((normalized + .055) / 1.055, 2.4).toDouble();
  }

  return .2126 * channel((argb >> 16) & 0xFF) +
      .7152 * channel((argb >> 8) & 0xFF) +
      .0722 * channel(argb & 0xFF);
}
