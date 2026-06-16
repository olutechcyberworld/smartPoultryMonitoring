import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color primary = Color(0xFF4CAF92);     // teal-green — poultry/eco association
  static const Color warning = Color(0xFFE0A800);     // amber — ELEVATED ammonia, warmup
  static const Color alert = Color(0xFFE05656);       // red — ALERT ammonia, offline, errors
  static const Color success = Color(0xFF4CAF92);     // ON state, NORMAL ammonia
  static const Color textPrimary = Color(0xFFEAEAEA);
  static const Color textSecondary = Color(0xFFA0A0A0);

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: surface,
        error: alert,
        onSurface: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: textPrimary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ── Semantic colors for sensor/relay states ──────────────────────────────
  // Centralized here so screens don't hardcode color logic per widget.

  static Color ammoniaColor(String? tier, {required bool warmupActive}) {
    if (warmupActive) return warning;
    switch (tier) {
      case 'NORMAL':
        return success;
      case 'ELEVATED':
        return warning;
      case 'ALERT':
        return alert;
      default:
        return textSecondary; // sensor error / null
    }
  }

  static Color relayModeColor(bool isOn) => isOn ? success : textSecondary;
}