import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/app_gradients.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_toggle.dart';
import '../../../shared/widgets/onboarding_progress_bar.dart';
import '../../../shared/widgets/onboarding_bottom_button.dart';
import '../providers/onboarding_provider.dart';

class OnboardingNotificationsScreen extends ConsumerStatefulWidget {
  const OnboardingNotificationsScreen({super.key});

  @override
  ConsumerState<OnboardingNotificationsScreen> createState() =>
      _OnboardingNotificationsScreenState();
}

class _OnboardingNotificationsScreenState
    extends ConsumerState<OnboardingNotificationsScreen> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      body: Column(
        children: [
          const OnboardingProgressBar(currentStep: 10, totalSteps: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Column(
                children: [
                  SizedBox(height: 48.h),
                  Container(
                    width: 80.r,
                    height: 80.r,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary(isDark: isDark),
                      borderRadius: AppRadius.borderXxl,
                      boxShadow: AppShadows.lg,
                    ),
                    child: Icon(LucideIcons.bell, size: 40.r, color: Colors.white),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Stay on track',
                    style: AppTextStyles.h1.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Get reminders to keep your streak going',
                    style: AppTextStyles.body.copyWith(color: context.mutedForeground),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 48.h),
                  Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: AppRadius.borderXl,
                      border: Border.all(color: context.borderColor),
                      boxShadow: AppShadows.md,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Push Notifications',
                                style: AppTextStyles.h4.copyWith(
                                  color: context.foreground,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Workout reminders & streak alerts',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: context.mutedForeground),
                              ),
                            ],
                          ),
                        ),
                        CustomToggle(
                          value: _enabled,
                          onChanged: (val) => setState(() => _enabled = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          OnboardingBottomButton(
            text: 'Continue',
            onPressed: () {
              ref.read(onboardingProvider.notifier).setNotificationsEnabled(_enabled);
              context.go('/onboarding/health');
            },
          ),
        ],
      ),
    );
  }
}
