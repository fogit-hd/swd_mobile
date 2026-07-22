import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_spacing.dart';

/// Light Mode giáo dục — Primary #0284C7, Accent #F59E0B, nền Off-white.
class AppTheme {
  // ── Brand ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1E40AF); // Deep professional blue
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color accent = Color(0xFF2563EB); // Vibrant blue accent
  static const Color accentDark = Color(0xFF1D4ED8);

  // ── Neutrals (Minimalist enterprise SaaS palette) ──────────────────────
  static const Color black = Color(0xFF0F172A);
  static const Color darkGray = Color(0xFF334155);
  static const Color mediumGray = Color(0xFF64748B);
  static const Color lightGray = Color(0xFFE2E8F0);
  static const Color background = Color(0xFFEEF2F6); // Rich slate-indigo tinted background
  static const Color white = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color success = Color(0xFF10B981);

  // ── Status pastel ────────────────────────────────────────────────────
  static const Color statusPendingBg = Color(0xFFF1F5F9);
  static const Color statusPendingFg = Color(0xFF64748B);
  static const Color statusActiveBg = Color(0xFFDBEAFE);
  static const Color statusActiveFg = Color(0xFF1E40AF);
  static const Color statusDoneBg = Color(0xFFD1FAE5);
  static const Color statusDoneFg = Color(0xFF059669);

  /// Ultra-soft, elevated drop shadow for white cards (border-0 floating aesthetic).
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.08),
          blurRadius: 40,
          offset: const Offset(0, 20),
          spreadRadius: -10,
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.03),
          blurRadius: 16,
          offset: const Offset(0, 8),
          spreadRadius: -6,
        ),
      ];

  /// Deep, prominent soft shadow for floating containers like Login card.
  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.14),
          blurRadius: 60,
          offset: const Offset(0, 30),
          spreadRadius: -12,
        ),
        BoxShadow(
          color: const Color(0xFF2563EB).withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      surface: white,
      error: error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        foregroundColor: black,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: black,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: black),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primary,
        unselectedItemColor: mediumGray,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFF2563EB).withValues(alpha: 0.14),
            width: 1.2,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          minimumSize: const Size(double.infinity, AppSpacing.minTouchTarget),
          animationDuration: Duration.zero,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            inherit: false,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: white,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, AppSpacing.minTouchTarget),
          side: const BorderSide(color: lightGray),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        labelStyle: const TextStyle(color: mediumGray),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
