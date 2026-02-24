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

  const OnboardingProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 14,
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
            child: Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: muted,
                shape: BoxShape.circle,
              ),
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
          SizedBox(width: 16.w),
          Expanded(
            child: Row(
              children: List.generate(totalSteps, (index) {
                final isCompleted = index < currentStep;
                return Expanded(
                  child: Container(
                    height: 4.h,
                    margin: EdgeInsets.symmetric(horizontal: 1.5.w),
                    decoration: BoxDecoration(
                      color: isCompleted ? primary : muted,
                      borderRadius: AppRadius.borderFull,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
