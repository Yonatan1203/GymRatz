import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';

import '../../../theme/app_radius.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/utils/platform_adapter.dart';
import '../../../shared/widgets/onboarding_progress_bar.dart';
import '../../../shared/widgets/onboarding_bottom_button.dart';
import '../providers/onboarding_provider.dart';

class OnboardingExperienceScreen extends ConsumerStatefulWidget {
  const OnboardingExperienceScreen({super.key});

  @override
  ConsumerState<OnboardingExperienceScreen> createState() =>
      _OnboardingExperienceScreenState();
}

class _OnboardingExperienceScreenState
    extends ConsumerState<OnboardingExperienceScreen> {
  String? _selected;

  static const _levels = [
    {
      'label': 'Beginner',
      'emoji': '\u{1F331}',
      'desc': 'Less than 6 months of training',
    },
    {
      'label': 'Intermediate',
      'emoji': '\u{1F4AA}',
      'desc': '6 months to 2 years of training',
    },
    {
      'label': 'Advanced',
      'emoji': '\u{1F525}',
      'desc': '2 to 5 years of training',
    },
    {
      'label': 'Elite',
      'emoji': '\u{1F451}',
      'desc': '5+ years of training',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selected = ref.read(onboardingProvider).selectedExperience;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OnboardingProgressBar(currentStep: 2, totalSteps: 14),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Experience level?',
                    style: AppTextStyles.h1.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "We'll adjust intensity based on your level.",
                    style: AppTextStyles.body.copyWith(
                      color: context.mutedForeground,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  ..._levels.map((level) => _buildCard(level)),
                ],
              ),
            ),
          ),
          OnboardingBottomButton(
            text: 'Continue',
            enabled: _selected != null,
            onPressed: () {
              if (_selected != null) {
                ref.read(onboardingProvider.notifier).setExperience(_selected!);
                context.go('/onboarding/style');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, String> level) {
    final isSelected = _selected == level['label'];
    final primary = context.primaryColor;

    return Semantics(
      button: true,
      label: level['label'],
      selected: isSelected,
      child: GestureDetector(
      onTap: () {
        PlatformAdapter.hapticSelection();
        setState(() => _selected = level['label']);
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: AppSpacing.lg),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.08)
              : context.cardColor,
          borderRadius: AppRadius.borderXl,
          border: Border.all(
            color: isSelected ? primary : context.borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 48.r,
              height: 48.r,
              decoration: BoxDecoration(
                color: context.mutedColor,
                borderRadius: AppRadius.borderLg,
              ),
              child: Center(
                child: Text(
                  level['emoji']!,
                  style: TextStyle(fontSize: 24.sp),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level['label']!,
                    style: AppTextStyles.h3.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    level['desc']!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 28.r,
                height: 28.r,
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.check,
                  size: 16.r,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }
}
