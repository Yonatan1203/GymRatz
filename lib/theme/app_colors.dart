import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Light Mode (from globals.css :root) ───
  static const lightBackground = Color(0xFFF5F5F7);
  static const lightForeground = Color(0xFF2C2C2E);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightPrimary = Color(0xFF8FC4C4);
  static const lightPrimaryForeground = Color(0xFFFFFFFF);
  static const lightSecondary = Color(0xFFA8B8C8);
  static const lightSecondaryForeground = Color(0xFF2C2C2E);
  static const lightAccent = Color(0xFFB8D8D8);
  static const lightAccentForeground = Color(0xFF2C2C2E);
  static const lightMuted = Color(0xFFE8E8EA);
  static const lightMutedForeground = Color(0xFF6E6E73);
  static const lightDestructive = Color(0xFFD4183D);
  static const lightDestructiveForeground = Color(0xFFFFFFFF);
  static const lightBorder = Color(0x268FC4C4); // 15% primary teal
  static const lightInputBackground = Color(0xFFF5F5F7);
  static const lightSwitchBackground = Color(0xFFC7C7CC);
  static const lightRing = Color(0xFF8FC4C4);

  // ─── Dark Mode (from globals.css .dark) ───
  static const darkBackground = Color(0xFF0D0F11);
  static const darkForeground = Color(0xFFE5E7E9);
  static const darkCard = Color(0xFF1A1D1F);
  static const darkPrimary = Color(0xFF2A5A5A);
  static const darkPrimaryForeground = Color(0xFFFFFFFF);
  static const darkSecondary = Color(0xFF3A4A5A);
  static const darkSecondaryForeground = Color(0xFFFFFFFF);
  static const darkAccent = Color(0xFF3A6A6A);
  static const darkAccentForeground = Color(0xFFFFFFFF);
  static const darkMuted = Color(0xFF252830);
  static const darkMutedForeground = Color(0xFFB0B2B5);
  static const darkDestructive = Color(0xFF8B2F39);
  static const darkDestructiveForeground = Color(0xFFD4808F);
  static const darkBorder = Color(0xFF2A2D32);
  static const darkInput = Color(0xFF252830);
  static const darkRing = Color(0xFF2A5A5A);

  // Coral accent — warm energy color
  static const lightCoral = Color(0xFFEF6B4A);
  static const darkCoral = Color(0xFFC4553B);
  static const lightCoralForeground = Colors.white;
  static const darkCoralForeground = Colors.white;

  // ─── Chart Colors ───
  static const chart1Light = Color(0xFF8FC4C4);
  static const chart2Light = Color(0xFFA8B8C8);
  static const chart3Light = Color(0xFFB8D8D8);
  static const chart4Light = Color(0xFFC8E8E8);
  static const chart5Light = Color(0xFF6E6E73);

  static const chart1Dark = Color(0xFF2A5A5A);
  static const chart2Dark = Color(0xFF3A4A5A);
  static const chart3Dark = Color(0xFF3A6A6A);
  static const chart4Dark = Color(0xFF4A7A7A);
  static const chart5Dark = Color(0xFF8E9093);

  // ─── Shared / Semantic ───
  static const white = Colors.white;
  static const black = Colors.black;
  static const transparent = Colors.transparent;

  // Achievement rarity gradients
  static const rarityCommonStart = Color(0xFF8FC4C4);
  static const rarityCommonEnd = Color(0xFFB8D8D8);
  static const rarityRareStart = Color(0xFF60A5FA);
  static const rarityRareEnd = Color(0xFF818CF8);
  static const rarityEpicStart = Color(0xFFA855F7);
  static const rarityEpicEnd = Color(0xFFEC4899);
  static const rarityLegendaryStart = Color(0xFFF59E0B);
  static const rarityLegendaryEnd = Color(0xFFEF4444);

  // Dark mode missed day (orange)
  static const darkMissedDay = Color(0xFFF97316);
}
