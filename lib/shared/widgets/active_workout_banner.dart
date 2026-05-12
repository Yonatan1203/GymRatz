import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_icons.dart';

import '../../app/providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text_styles.dart';
import '../utils/extensions.dart';
import '../utils/platform_adapter.dart';
import 'package:flutter/services.dart';

class ActiveWorkoutBanner extends ConsumerStatefulWidget {
  const ActiveWorkoutBanner({super.key});

  @override
  ConsumerState<ActiveWorkoutBanner> createState() => _ActiveWorkoutBannerState();
}

class _ActiveWorkoutBannerState extends ConsumerState<ActiveWorkoutBanner> {
  bool _hasVibrated = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activeWorkoutSessionProvider);
    if (session == null) return const SizedBox.shrink();

    final isDark = context.isDark;
    final restTimerValue = ref.watch(restTimerSecondsProvider).valueOrNull;
    final restActive = session.restActive && session.timerRunning && restTimerValue != null;
    final restSeconds = restTimerValue ?? 0;
    final timerDone = restActive && restSeconds == 0;

    // Vibrate once when timer reaches zero
    if (timerDone && !_hasVibrated) {
      _hasVibrated = true;
      HapticFeedback.heavyImpact();
    } else if (!timerDone) {
      _hasVibrated = false;
    }

    return GestureDetector(
      onTap: () {
        PlatformAdapter.hapticLight();
        context.push('/workout/${session.dayId}');
      },
      child: Container(
        margin: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 4.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkCard : AppColors.lightCard).withValues(alpha: 0.85),
          borderRadius: AppRadius.borderXl,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: AppShadows.md,
        ),
        child: Row(
          children: [
            _CircleButton(
              icon: AppIcons.chevronUp,
              isDark: isDark,
              onTap: () {
                PlatformAdapter.hapticLight();
                context.push('/workout/${session.dayId}');
              },
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const _PulsingDot(),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          session.workoutName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.foreground,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      if (restActive)
                        timerDone
                            ? Icon(AppIcons.bell, size: 22.r, color: context.coralColor)
                            : Text(
                                _formatTimer(restSeconds),
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: context.foreground,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                    ],
                  ),
                  if (session.currentExerciseName.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(left: 14.w),
                      child: Text(
                        session.currentExerciseName,
                        style: AppTextStyles.caption.copyWith(
                          color: context.mutedForeground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            _CircleButton(
              icon: AppIcons.trash2,
              isDark: isDark,
              isDestructive: true,
              onTap: () => _showDiscardDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimer(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showDiscardDialog(BuildContext context, WidgetRef ref) {
    PlatformAdapter.hapticMedium();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Workout?'),
        content: const Text('All progress for this workout will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(activeWorkoutSessionProvider.notifier).endSession();
              Navigator.of(ctx).pop();
            },
            child: Text(
              'Discard',
              style: TextStyle(color: context.destructiveColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final bool isDestructive;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.isDark,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? context.destructiveColor
        : context.mutedForeground;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32.r,
        height: 32.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (isDark ? AppColors.darkMuted : AppColors.lightMuted),
        ),
        child: Icon(icon, size: 16.r, color: color),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: 8.r,
        height: 8.r,
        decoration: const BoxDecoration(
          color: Color(0xFF22C55E), // green-500
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
