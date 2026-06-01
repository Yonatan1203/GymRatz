import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../utils/platform_adapter.dart';

class OnboardingProgressBar extends StatelessWidget {
  final int currentStep; // 1-based
  final int totalSteps;
  /// Whether to show the "Skip" button. Defaults to true.
  final bool showSkip;

  const OnboardingProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 9,
    this.showSkip = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, MediaQuery.of(context).padding.top + 8, 16.w, 12.h),
      color: bg.withValues(alpha: 0.95),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Go back',
            child: GestureDetector(
            onTap: () {
              PlatformAdapter.hapticLight();
              context.pop();
            },
            child: SizedBox(
              width: 40.r,
              height: 40.r,
              child: Center(
                child: Icon(
                  AppIcons.arrowLeft,
                  size: 20.r,
                  color: isDark
                      ? AppColors.darkForeground
                      : AppColors.lightForeground,
                ),
              ),
            ),
          ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Row(
              children: List.generate(totalSteps, (index) {
                final isCurrent = index == currentStep;
                final isCompleted = index < currentStep;
                final coral = isDark ? AppColors.darkCoral : AppColors.lightCoral;

                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    height: 4.h,
                    margin: EdgeInsets.symmetric(horizontal: 1.5.w),
                    decoration: BoxDecoration(
                      color: isCompleted ? primary : isCurrent ? coral : muted,
                      borderRadius: AppRadius.borderFull,
                    ),
                  ),
                );
              }),
            ),
          ),
          if (showSkip) ...[
            SizedBox(width: 16.w),
            Semantics(
              button: true,
              label: 'Skip onboarding',
              child: GestureDetector(
                onTap: () {
                  PlatformAdapter.hapticLight();
                  context.go('/home');
                },
                child: Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
