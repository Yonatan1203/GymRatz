import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_icons.dart';

import '../../app/providers.dart';
import '../../theme/app_colors.dart';
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
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Icon(
            isDark ? AppIcons.sun : AppIcons.moon,
            size: 20,
            color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
          ),
        ),
      ),
    ),
    );
  }
}
