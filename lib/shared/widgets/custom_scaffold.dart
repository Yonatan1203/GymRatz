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
import '../../features/subscription/presentation/subscription_gate.dart';
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
              Expanded(
                child: SubscriptionGate(child: navigationShell),
              ),
            ],
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
                    final activeIndex = navigationShell.currentIndex;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated active indicator pill
                        Row(
                          children: List.generate(tabCount, (index) {
                            return Expanded(
                              child: Center(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                  width: 20,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: index == activeIndex
                                        ? context.primaryColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _expandedNavItem(AppIcons.dumbbell, 'Workout', activeIndex == 0, () => navigationShell.goBranch(0), isDark),
                            _expandedNavItem(AppIcons.calendar, 'Calendar', activeIndex == 1, () => navigationShell.goBranch(1), isDark),
                            _expandedNavItem(AppIcons.home, 'Home', activeIndex == 2, () => navigationShell.goBranch(2), isDark),
                            _expandedNavItem(AppIcons.library, 'Programs', activeIndex == 3, () => navigationShell.goBranch(3), isDark),
                            _expandedNavItem(AppIcons.user, 'Profile', activeIndex == 4, () => navigationShell.goBranch(4), isDark),
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

Widget _expandedNavItem(IconData icon, String label, bool isActive, VoidCallback onTap, bool isDark) {
  return Expanded(
    child: _NavItem(
      icon: icon,
      label: label,
      isActive: isActive,
      onTap: onTap,
      isDark: isDark,
    ),
  );
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
                fontSize: 10,
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
