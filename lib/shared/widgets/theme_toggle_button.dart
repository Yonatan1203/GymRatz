import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../utils/platform_adapter.dart';

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: 'Switch to ${isDark ? 'light' : 'dark'} mode',
      child: GestureDetector(
      onTap: () {
        PlatformAdapter.hapticMedium();
        ref.read(themeProvider.notifier).toggleTheme();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: AppShadows.lg,
        ),
        child: Icon(
          isDark ? LucideIcons.sun : LucideIcons.moon,
          size: 20,
          color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
        ),
      ),
    ),
    );
  }
}
