import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

extension BuildContextX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get foreground =>
      isDark ? AppColors.darkForeground : AppColors.lightForeground;
  Color get mutedForeground =>
      isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;
  Color get cardColor => isDark ? AppColors.darkCard : AppColors.lightCard;
  Color get borderColor =>
      isDark ? AppColors.darkBorder : AppColors.lightBorder;
  Color get mutedColor => isDark ? AppColors.darkMuted : AppColors.lightMuted;
  Color get primaryColor =>
      isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
  Color get secondaryColor =>
      isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  Color get accentColor =>
      isDark ? AppColors.darkAccent : AppColors.lightAccent;
  Color get destructiveColor =>
      isDark ? AppColors.darkDestructive : AppColors.lightDestructive;
  Color get backgroundColor =>
      isDark ? AppColors.darkBackground : AppColors.lightBackground;
  Color get coralColor => isDark ? AppColors.darkCoral : AppColors.lightCoral;
  Color get coralForeground => isDark ? AppColors.darkCoralForeground : AppColors.lightCoralForeground;
  Color get missedDayColor => isDark ? AppColors.darkMissedDay : AppColors.lightMissedDay;
}
