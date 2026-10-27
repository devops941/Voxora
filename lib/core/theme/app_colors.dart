import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary brand colors
  static const Color primary = Color(0xFF3B5BDB);       // Deep indigo-blue
  static const Color primaryLight = Color(0xFF748FFC);   // Light indigo
  static const Color primaryDark = Color(0xFF2444C5);    // Darker indigo

  // Accent colors
  static const Color accent = Color(0xFFFF6B6B);         // Vibrant coral
  static const Color accentLight = Color(0xFFFF9A9A);    // Light coral
  static const Color accentDark = Color(0xFFE84343);     // Dark coral

  // Secondary colors
  static const Color secondary = Color(0xFF20C997);      // Teal green
  static const Color secondaryLight = Color(0xFF63E6BE); // Light teal
  static const Color secondaryDark = Color(0xFF12A37A);  // Dark teal

  // Warning / success / error
  static const Color success = Color(0xFF2FCC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // ── Light theme ──────────────────────────────────
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  static const Color textPrimaryLight = Color(0xFF1A1D2E);
  static const Color textSecondaryLight = Color(0xFF6C757D);
  static const Color textHintLight = Color(0xFFADB5BD);
  static const Color textDisabledLight = Color(0xFFCED4DA);

  static const Color dividerLight = Color(0xFFE9ECEF);
  static const Color borderLight = Color(0xFFDEE2E6);
  static const Color shadowLight = Color(0x1A000000);

  // ── Dark theme ───────────────────────────────────
  static const Color backgroundDark = Color(0xFF0F1117);
  static const Color surfaceDark = Color(0xFF1A1D2E);
  static const Color cardDark = Color(0xFF242840);

  static const Color textPrimaryDark = Color(0xFFF1F3F5);
  static const Color textSecondaryDark = Color(0xFFADB5BD);
  static const Color textHintDark = Color(0xFF6C757D);
  static const Color textDisabledDark = Color(0xFF495057);

  static const Color dividerDark = Color(0xFF2C2F45);
  static const Color borderDark = Color(0xFF343A54);
  static const Color shadowDark = Color(0x33000000);

  // ── Gradient presets ─────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF1A1D2E), Color(0xFF2A3060), Color(0xFF3B5BDB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF3B5BDB), Color(0xFF5270E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Transparent helpers ──────────────────────────
  static const Color transparent = Colors.transparent;
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // ── Score / level colors ─────────────────────────
  static const Color scoreExcellent = Color(0xFF2FCC71);
  static const Color scoreGood = Color(0xFF3B5BDB);
  static const Color scoreFair = Color(0xFFF39C12);
  static const Color scorePoor = Color(0xFFE74C3C);

  // ── Skill / level badge colors ───────────────────
  static const Color levelBeginner = Color(0xFF74B9FF);
  static const Color levelElementary = Color(0xFF55EFC4);
  static const Color levelIntermediate = Color(0xFFFDCB6E);
  static const Color levelUpperIntermediate = Color(0xFFE17055);
  static const Color levelAdvanced = Color(0xFFD63031);
}
