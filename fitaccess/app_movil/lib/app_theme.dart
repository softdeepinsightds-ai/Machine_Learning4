import 'package:flutter/material.dart';

/// Identidad visual premium: negro carbón + dorado suave + acentos semánticos.
abstract final class GymColors {
  static const background = Color(0xFF090B0E);
  static const surface = Color(0xFF171A20);
  static const surfaceHigh = Color(0xFF232730);
  static const gold = Color(0xFFD9B86C);
  static const lightGold = Color(0xFFF4DEAB);
  static const muted = Color(0xFFA7ABB5);
  static const white = Color(0xFFF7F5EF);
  static const green = Color(0xFF67D8A4);
  static const orange = Color(0xFFEFC17A);
  static const red = Color(0xFFFF7C80);
}

ThemeData buildGymTheme() {
  final colors = ColorScheme.fromSeed(
    seedColor: GymColors.gold,
    brightness: Brightness.dark,
    surface: GymColors.background,
    primary: GymColors.gold,
    onPrimary: GymColors.background,
    onSurface: GymColors.white,
    error: GymColors.red,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: GymColors.background,
    colorScheme: colors,
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: GymColors.white, letterSpacing: -.5),
      titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: GymColors.white),
      titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: GymColors.white),
      bodyLarge: TextStyle(fontSize: 15, color: GymColors.white, height: 1.45),
      bodyMedium: TextStyle(fontSize: 14, color: GymColors.muted, height: 1.45),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: GymColors.background,
      foregroundColor: GymColors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: GymColors.white, letterSpacing: .3),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: GymColors.surface,
      floatingLabelStyle: const TextStyle(color: GymColors.gold),
      labelStyle: const TextStyle(color: GymColors.muted),
      hintStyle: const TextStyle(color: GymColors.muted),
      helperStyle: const TextStyle(color: GymColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: GymColors.surfaceHigh)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: GymColors.surfaceHigh)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: GymColors.gold, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: GymColors.red)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: GymColors.gold,
        foregroundColor: GymColors.background,
        disabledBackgroundColor: GymColors.surfaceHigh,
        disabledForegroundColor: GymColors.muted,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: .1),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: GymColors.gold,
        minimumSize: const Size(0, 48),
        side: const BorderSide(color: Color(0xFF625438)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: GymColors.lightGold)),
    dividerTheme: const DividerThemeData(color: GymColors.surfaceHigh),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: GymColors.gold),
    snackBarTheme: SnackBarThemeData(backgroundColor: GymColors.surfaceHigh, contentTextStyle: const TextStyle(color: GymColors.white), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
  );
}
