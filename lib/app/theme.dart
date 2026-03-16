import 'package:flutter/material.dart';

ThemeData buildDiaryTheme() {
  const seed = Color(0xFF28666E);

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: seed),
    scaffoldBackgroundColor: const Color(0xFFF6F3EE),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontWeight: FontWeight.w700),
      titleLarge: TextStyle(fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(height: 1.5),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
  );
}
