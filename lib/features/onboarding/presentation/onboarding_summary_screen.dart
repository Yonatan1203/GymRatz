import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';

import '../../../theme/app_gradients.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/onboarding_progress_bar.dart';
import '../../../shared/widgets/onboarding_bottom_button.dart';
import '../providers/onboarding_provider.dart';

class OnboardingSummaryScreen extends ConsumerWidget {
  const OnboardingSummaryScreen({super.key});

  static String _cmToFeetInches(double cm) {
    final totalInches = (cm / 2.54).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return "$feet'$inches\"";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final isDark = context.isDark;
    final isMetric = state.selectedUnits != 'imperial';
    final heightDisplay = isMetric
        ? '${state.height.round()} cm'
        : _cmToFeetInches(state.height);
    final weightDisplay = isMetric
        ? '${state.weight.round()} kg'
        : '${(state.weight * 2.20462).round()} lbs';

    return Scaffold(
      body: Column(
        children: [
          const OnboardingProgressBar(currentStep: 8, totalSteps: 14),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Your Profile',
                    style: AppTextStyles.h1.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Here's what we know so far",
                    style: AppTextStyles.body.copyWith(color: context.mutedForeground),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  _buildSummaryCard(
                    context,
                    isDark: isDark,
                    icon: AppIcons.target,
                    title: 'Goal',
                    value: state.selectedGoal ?? 'Not set',
                  ),
                  SizedBox(height: AppSpacing.lg),
                  _buildSummaryCard(
                    context,
                    isDark: isDark,
                    icon: AppIcons.award,
                    title: 'Experience',
                    value: state.selectedExperience ?? 'Not set',
                  ),
                  SizedBox(height: AppSpacing.lg),
                  _buildSummaryCard(
                    context,
                    isDark: isDark,
                    icon: AppIcons.ruler,
                    title: 'Body Stats',
                    value: '$heightDisplay • $weightDisplay',
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: AppRadius.borderXxl,
                      border: Border.all(
                        color: context.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(AppIcons.info, size: 20.r, color: context.primaryColor),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            "Based on your profile, we'll create a personalized program.",
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          OnboardingBottomButton(
            text: 'Create Account',
            onPressed: () => context.push('/onboarding/email'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: context.borderColor),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              gradient: AppGradients.primary(isDark: isDark),
              borderRadius: AppRadius.borderLg,
            ),
            child: Icon(icon, size: 24.r, color: Colors.white),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: AppTextStyles.h4.copyWith(
                    color: context.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
