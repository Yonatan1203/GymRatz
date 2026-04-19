import 'package:flutter/material.dart';
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

class OnboardingShowcaseScreen extends StatelessWidget {
  const OnboardingShowcaseScreen({super.key});

  static const _features = [
    {
      'title': 'Workout Tracker',
      'desc': 'Log sets, reps, and weights with ease',
      'icon': AppIcons.dumbbell,
      'gradient': 'primary',
    },
    {
      'title': 'Smart Challenges',
      'desc': 'Progressive overload built right in',
      'icon': AppIcons.target,
      'gradient': 'yellow',
    },
    {
      'title': 'Progress Charts',
      'desc': 'Visualize your gains over time',
      'icon': AppIcons.trendingUp,
      'gradient': 'green',
    },
    {
      'title': 'Community',
      'desc': 'Connect with fellow gym rats',
      'icon': AppIcons.users,
      'gradient': 'purple',
    },
  ];

  LinearGradient _getGradient(String name, bool isDark) {
    switch (name) {
      case 'primary':
        return AppGradients.primary(isDark: isDark);
      case 'yellow':
        return AppGradients.showcaseYellow;
      case 'green':
        return AppGradients.showcaseGreen;
      case 'purple':
        return AppGradients.showcasePurple;
      default:
        return AppGradients.primary(isDark: isDark);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      body: Column(
        children: [
          const OnboardingProgressBar(currentStep: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.xxl),
                  Text(
                    "What you'll get",
                    style: AppTextStyles.h1.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Everything you need to reach your goals',
                    style: AppTextStyles.body.copyWith(color: context.mutedForeground),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  ..._features.map((f) {
                    return Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: AppSpacing.lg),
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: AppRadius.borderXxl,
                        border: Border.all(color: context.borderColor, width: 2),
                        boxShadow: AppShadows.md,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56.r,
                            height: 56.r,
                            decoration: BoxDecoration(
                              gradient: _getGradient(f['gradient'] as String, isDark),
                              borderRadius: AppRadius.borderXl,
                              boxShadow: AppShadows.sm,
                            ),
                            child: Icon(
                              f['icon'] as IconData,
                              size: 28.r,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f['title'] as String,
                                  style: AppTextStyles.h3.copyWith(
                                    color: context.foreground,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  f['desc'] as String,
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: context.mutedForeground),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
          OnboardingBottomButton(
            text: 'Continue',
            onPressed: () => context.push('/onboarding/goal'),
          ),
        ],
      ),
    );
  }
}
