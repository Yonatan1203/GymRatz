import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../utils/platform_adapter.dart';

class CustomScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const CustomScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          navigationShell,
          // Theme toggle button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: _ThemeToggle(isDark: isDark, ref: ref),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          boxShadow: AppShadows.xxl,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: LucideIcons.dumbbell,
                  label: 'Workout',
                  isActive: navigationShell.currentIndex == 0,
                  onTap: () => navigationShell.goBranch(0),
                  isDark: isDark,
                ),
                _NavItem(
                  icon: LucideIcons.calendar,
                  label: 'Calendar',
                  isActive: navigationShell.currentIndex == 1,
                  onTap: () => navigationShell.goBranch(1),
                  isDark: isDark,
                ),
                _NavItem(
                  icon: LucideIcons.home,
                  label: 'Home',
                  isActive: navigationShell.currentIndex == 2,
                  onTap: () => navigationShell.goBranch(2),
                  isDark: isDark,
                ),
                _NavItem(
                  icon: LucideIcons.library,
                  label: 'Programs',
                  isActive: navigationShell.currentIndex == 3,
                  onTap: () => navigationShell.goBranch(3),
                  isDark: isDark,
                ),
                _NavItem(
                  icon: LucideIcons.user,
                  label: 'Profile',
                  isActive: navigationShell.currentIndex == 4,
                  onTap: () => navigationShell.goBranch(4),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final bool isDark;
  final WidgetRef ref;

  const _ThemeToggle({required this.isDark, required this.ref});

  @override
  Widget build(BuildContext context) {
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final inactiveColor =
        isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;

    return Semantics(
      button: true,
      label: label,
      selected: isActive,
      child: GestureDetector(
      onTap: () {
        PlatformAdapter.hapticLight();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
