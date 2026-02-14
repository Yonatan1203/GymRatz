import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  AppGradients._();

  // Primary gradient: from-primary to-accent (headers, CTAs, workout cards)
  static LinearGradient primary({bool isDark = false}) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [AppColors.darkPrimary, AppColors.darkAccent]
            : [AppColors.lightPrimary, AppColors.lightAccent],
      );

  // Secondary gradient: from-secondary to-accent
  static LinearGradient secondary({bool isDark = false}) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [AppColors.darkSecondary, AppColors.darkAccent]
            : [AppColors.lightSecondary, AppColors.lightAccent],
      );

  // Welcome screen overlay
  static const LinearGradient welcomeOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x99000000), // black/60
      Color(0x66000000), // black/40
      Color(0xCC000000), // black/80
    ],
  );

  // Achievement rarity gradients
  static const LinearGradient rarityCommon = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.rarityCommonStart, AppColors.rarityCommonEnd],
  );

  static const LinearGradient rarityRare = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.rarityRareStart, AppColors.rarityRareEnd],
  );

  static const LinearGradient rarityEpic = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.rarityEpicStart, AppColors.rarityEpicEnd],
  );

  static const LinearGradient rarityLegendary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.rarityLegendaryStart, AppColors.rarityLegendaryEnd],
  );

  // Showcase screen gradients
  static const LinearGradient showcaseGreen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C55E), Color(0xFF10B981)],
  );

  static const LinearGradient showcasePurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
  );

  static const LinearGradient showcaseYellow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA8B8C8), Color(0xFFEAB308)],
  );
}
