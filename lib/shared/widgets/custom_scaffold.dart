import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_icons.dart';

import '../../app/providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_durations.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text_styles.dart';
import '../utils/extensions.dart';
import '../utils/platform_adapter.dart';
import 'active_workout_banner.dart';
import '../../features/subscription/presentation/subscription_gate.dart';
import 'offline_banner.dart';

class CustomScaffold extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const CustomScaffold({super.key, required this.navigationShell});

  @override
  ConsumerState<CustomScaffold> createState() => _CustomScaffoldState();
}

class _CustomScaffoldState extends ConsumerState<CustomScaffold> {
  int _prevIndex = 0;

  @override
  void didUpdateWidget(CustomScaffold old) {
    super.didUpdateWidget(old);
    if (old.navigationShell.currentIndex != widget.navigationShell.currentIndex) {
      _prevIndex = old.navigationShell.currentIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeSession = ref.watch(activeWorkoutSessionProvider);
    final currentIndex = widget.navigationShell.currentIndex;
    // Determine slide direction: positive = going right (higher index), negative = left.
    final slideRight = currentIndex > _prevIndex;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const SafeArea(bottom: false, child: OfflineBanner()),
              Expanded(
                child: SubscriptionGate(
                  currentIndex: currentIndex,
                  child: AnimatedSwitcher(
                    duration: AppDurations.fast,
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      // Horizontal slide + fade: slides in from right when going
                      // to a higher tab index, from left when going lower.
                      final offsetBegin = slideRight
                          ? const Offset(0.08, 0)
                          : const Offset(-0.08, 0);
                      final slide = Tween<Offset>(
                        begin: offsetBegin,
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ));
                      return SlideTransition(
                        position: slide,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    // Key must change when the active branch changes so
                    // AnimatedSwitcher knows a new child arrived.
                    child: KeyedSubtree(
                      key: ValueKey<int>(currentIndex),
                      child: widget.navigationShell,
                    ),
                  ),
                ),
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
                    final activeIndex = widget.navigationShell.currentIndex;

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
                                        ? context.navActiveColor
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
                            _expandedNavItem(AppIcons.dumbbell, 'Workout', activeIndex == 0, () => widget.navigationShell.goBranch(0)),
                            _expandedNavItem(AppIcons.calendar, 'Calendar', activeIndex == 1, () => widget.navigationShell.goBranch(1)),
                            _expandedNavItem(AppIcons.home, 'Home', activeIndex == 2, () => widget.navigationShell.goBranch(2)),
                            _expandedNavItem(AppIcons.library, 'Programs', activeIndex == 3, () => widget.navigationShell.goBranch(3)),
                            _expandedNavItem(AppIcons.user, 'Profile', activeIndex == 4, () => widget.navigationShell.goBranch(4)),
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

Widget _expandedNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
  return Expanded(
    child: _NavItem(
      icon: icon,
      label: label,
      isActive: isActive,
      onTap: onTap,
    ),
  );
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
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
      duration: AppDurations.extraFast,
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
    final activeColor = context.navActiveColor;
    final inactiveColor = context.mutedForeground;

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
                size: 20.r,
                color: widget.isActive ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.label,
                style: AppTextStyles.navLabel.copyWith(
                  color: widget.isActive ? activeColor : inactiveColor,
                  fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
