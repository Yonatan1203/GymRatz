import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  AppGradients._();

  // Primary gradient: bg-gradient-to-br from-primary to-accent (headers, CTAs, workout cards)
  static LinearGradient primary({bool isDark = false}) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [AppColors.darkPrimary, AppColors.darkAccent]
            : [AppColors.lightPrimary, AppColors.lightAccent],
      );

  // Horizontal primary→accent: bg-gradient-to-r (progress bars, action buttons)
  static LinearGradient primaryHorizontal({bool isDark = false}) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: isDark
            ? [AppColors.darkPrimary, AppColors.darkAccent]
            : [AppColors.lightPrimary, AppColors.lightAccent],
      );

  // Subtle 10% opacity: bg-gradient-to-r from-primary/10 to-accent/10 (exercise headers)
  static LinearGradient primarySubtle({bool isDark = false}) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: isDark
            ? [AppColors.darkPrimary.withValues(alpha: 0.1), AppColors.darkAccent.withValues(alpha: 0.1)]
            : [AppColors.lightPrimary.withValues(alpha: 0.1), AppColors.lightAccent.withValues(alpha: 0.1)],
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
    colors: [AppColors.showcaseGreenStart, AppColors.showcaseGreenEnd],
  );

  static const LinearGradient showcasePurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.showcasePurpleStart, AppColors.showcasePurpleEnd],
  );

  static const LinearGradient showcaseYellow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.lightSecondary, AppColors.showcaseYellowEnd],
  );

  // Health screen: bg-gradient-to-br from-red-500 to-pink-500
  static const LinearGradient health = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.healthStart, AppColors.healthEnd],
  );
}
