import 'package:flutter/material.dart';

/// Modern premium visual palette with a subtle vintage aesthetic.
class AppColors {
  AppColors._();

  // Core Palette
  static const Color background = Color(0xFFF4EBDD); // Warm Cream
  static const Color card = Color(0xFFFFF9F0);       // Warm Ivory Card
  static const Color primary = Color(0xFF6B4F3A);    // Rich Warm Mocha
  static const Color dark = Color(0xFF3A2E27);       // Deep Espresso Typography
  static const Color terracotta = Color(0xFFB86B4B); // Rust / Terracotta (Expenses / Alerts)
  static const Color olive = Color(0xFF657153);      // Sage Olive (Income / Positive Values)
  static const Color mutedGold = Color(0xFFB79B62);  // Muted Antique Gold
  static const Color secondaryBeige = Color(0xFFD8C7AD); // Muted Sand / Borders

  // Modern Semantic & Material Compatibility Aliases
  static const Color secondary = mutedGold;
  static const Color primaryContainer = Color(0xFFEDE4DC);
  static const Color secondaryContainer = secondaryBeige;
  static const Color surface = card;
  static const Color onSurface = dark;
  static const Color onPrimary = card;
  static const Color onSecondary = card;

  // Soft Accents & Background Tints
  static const Color oliveLight = Color(0xFFEBF0E6);
  static const Color terracottaLight = Color(0xFFF7ECE7);
  static const Color goldLight = Color(0xFFF7F2E6);
  static const Color primaryLight = Color(0xFFEDE4DC);

  // Functional Semantic Aliases
  static const Color income = olive;
  static const Color incomeLight = oliveLight;
  static const Color expense = terracotta;
  static const Color expenseLight = terracottaLight;
  static const Color shared = mutedGold;
  static const Color personal = terracotta;

  // Budget Tier Warnings
  static const Color warning75 = mutedGold;
  static const Color warning90 = Color(0xFFC97A4A);
  static const Color warning100 = terracotta;
  static const Color exceeded = Color(0xFF7A2021); // Dark red/brown when exceeded (> 100%)

  // Typography Tones
  static const Color textPrimary = dark;
  static const Color textSecondary = Color(0xFF706053);
  static const Color textMuted = Color(0xFF968779);

  // Borders & Dividers
  static const Color border = Color(0xFFE6D8C4);
  static const Color borderLight = Color(0xFFEFE5D5);

  // Soft vintage shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: dark.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.18),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}
