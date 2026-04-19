import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_icons.dart';

import '../../app/providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../utils/extensions.dart';
import '../utils/platform_adapter.dart';
import 'active_workout_banner.dart';
import 'offline_banner.dart';

class CustomScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const CustomScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeSession = ref.watch(activeWorkoutSessionProvider);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const OfflineBanner(),
              Expanded(child: navigationShell),
            ],
          ),
          // Theme toggle button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: _ThemeToggle(isDark: isDark, ref: ref),
          ),
          // Floating active workout banner
          if (activeSession != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: const ActiveWorkoutBanner(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              boxShadow: AppShadows.sm,
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tabCount = 5;
                    final tabWidth = constraints.maxWidth / tabCount;
                    final activeIndex = navigationShell.currentIndex;

                    return Stack(
                      children: [
                        // Animated active indicator pill
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          top: 0,
                          left: activeIndex * tabWidth +
                              (tabWidth - 20) / 2,
                          child: Container(
                            width: 20,
                            height: 3,
                            decoration: BoxDecoration(
                              color: context.primaryColor,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _NavItem(
                              icon: AppIcons.dumbbell,
                              label: 'Workout',
                              isActive: activeIndex == 0,
                              onTap: () => navigationShell.goBranch(0),
                              isDark: isDark,
                            ),
                            _NavItem(
                              icon: AppIcons.calendar,
                              label: 'Calendar',
                              isActive: activeIndex == 1,
                              onTap: () => navigationShell.goBranch(1),
                              isDark: isDark,
                            ),
                            _NavItem(
                              icon: AppIcons.home,
                              label: 'Home',
                              isActive: activeIndex == 2,
                              onTap: () => navigationShell.goBranch(2),
                              isDark: isDark,
                            ),
                            _NavItem(
                              icon: AppIcons.library,
                              label: 'Programs',
                              isActive: activeIndex == 3,
                              onTap: () => navigationShell.goBranch(3),
                              isDark: isDark,
                            ),
                            _NavItem(
                              icon: AppIcons.user,
                              label: 'Profile',
                              isActive: activeIndex == 4,
                              onTap: () => navigationShell.goBranch(4),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
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
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: AnimatedRotation(
            turns: isDark ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isDark ? AppIcons.sun : AppIcons.moon,
              size: 20,
              color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _NavItem extends StatefulWidget {
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
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.15),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _pulseController.forward(from: 0);
    PlatformAdapter.hapticLight();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor =
        widget.isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final inactiveColor = widget.isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    return Semantics(
      button: true,
      label: widget.label,
      selected: widget.isActive,
      child: GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final baseScale = widget.isActive ? 1.1 : 1.0;
                final pulseScale = _pulseController.isAnimating
                    ? _pulseAnimation.value
                    : baseScale;
                return Transform.scale(
                  scale: pulseScale,
                  child: child,
                );
              },
              child: Icon(
                widget.icon,
                size: 20,
                color: widget.isActive ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 11,
                color: widget.isActive ? activeColor : inactiveColor,
                fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
