import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_radius.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBackground,
        fontFamily: GoogleFonts.montserrat().fontFamily,
        colorScheme: const ColorScheme.light(
          primary: AppColors.lightPrimary,
          onPrimary: AppColors.lightPrimaryForeground,
          secondary: AppColors.lightSecondary,
          onSecondary: AppColors.lightSecondaryForeground,
          tertiary: AppColors.lightAccent,
          onTertiary: AppColors.lightAccentForeground,
          surface: AppColors.lightCard,
          onSurface: AppColors.lightForeground,
          error: AppColors.lightDestructive,
          onError: AppColors.lightDestructiveForeground,
          outline: AppColors.lightBorder,
          surfaceContainerHighest: AppColors.lightMuted,
          onSurfaceVariant: AppColors.lightMutedForeground,
        ),
        cardTheme: CardThemeData(
          color: AppColors.lightCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderXl,
            side: const BorderSide(color: AppColors.lightBorder),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          foregroundColor: AppColors.lightForeground,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightMuted,
          hintStyle: TextStyle(
            color: AppColors.lightMutedForeground,
            fontFamily: GoogleFonts.montserrat().fontFamily,
          ),
          border: OutlineInputBorder(
            borderRadius: AppRadius.borderLg,
            borderSide: const BorderSide(color: AppColors.lightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderLg,
            borderSide: const BorderSide(color: AppColors.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderLg,
            borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderLg,
            borderSide: const BorderSide(color: AppColors.lightDestructive),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.lightPrimary,
            foregroundColor: AppColors.lightPrimaryForeground,
            elevation: 1,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.lightCard,
          selectedItemColor: AppColors.lightPrimary,
          unselectedItemColor: AppColors.lightMutedForeground,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.lightBorder,
          thickness: 1,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        fontFamily: GoogleFonts.montserrat().fontFamily,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.darkPrimary,
          onPrimary: AppColors.darkPrimaryForeground,
          secondary: AppColors.darkSecondary,
          onSecondary: AppColors.darkSecondaryForeground,
          tertiary: AppColors.darkAccent,
          onTertiary: AppColors.darkAccentForeground,
          surface: AppColors.darkCard,
          onSurface: AppColors.darkForeground,
          error: AppColors.darkDestructive,
          onError: AppColors.darkDestructiveForeground,
          outline: AppColors.darkBorder,
          surfaceContainerHighest: AppColors.darkMuted,
          onSurfaceVariant: AppColors.darkMutedForeground,
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderXl,
            side: const BorderSide(color: AppColors.darkBorder),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          foregroundColor: AppColors.darkForeground,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkMuted,
          hintStyle: TextStyle(
            color: AppColors.darkMutedForeground,
            fontFamily: GoogleFonts.montserrat().fontFamily,
          ),
          border: OutlineInputBorder(
            borderRadius: AppRadius.borderLg,
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderLg,
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderLg,
            borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderLg,
            borderSide: const BorderSide(color: AppColors.darkDestructive),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkPrimary,
            foregroundColor: AppColors.darkPrimaryForeground,
            elevation: 1,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.darkCard,
          selectedItemColor: AppColors.darkPrimary,
          unselectedItemColor: AppColors.darkMutedForeground,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.darkBorder,
          thickness: 1,
        ),
      );
}
