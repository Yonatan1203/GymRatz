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

class OnboardingGoalScreen extends ConsumerStatefulWidget {
  const OnboardingGoalScreen({super.key});

  @override
  ConsumerState<OnboardingGoalScreen> createState() =>
      _OnboardingGoalScreenState();
}

class _OnboardingGoalScreenState extends ConsumerState<OnboardingGoalScreen> {
  String? _selected;

  static const _goals = [
    {'label': 'Build Muscle', 'emoji': '\u{1F4AA}', 'desc': 'Gain size and definition'},
    {'label': 'Lose Fat', 'emoji': '\u{1F525}', 'desc': 'Burn calories and lean out'},
    {'label': 'Get Stronger', 'emoji': '\u{1F3CB}\u{FE0F}', 'desc': 'Increase your max lifts'},
    {'label': 'Improve Endurance', 'emoji': '\u{1F3C3}', 'desc': 'Build stamina and conditioning'},
  ];

  @override
  void initState() {
    super.initState();
    _selected = ref.read(onboardingProvider).selectedGoal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OnboardingProgressBar(currentStep: 1, totalSteps: 14),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.xxl),
                  Text(
                    "What's your goal?",
                    style: AppTextStyles.h1.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'This helps us tailor your workout plan.',
                    style: AppTextStyles.body.copyWith(
                      color: context.mutedForeground,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  ..._goals.map((goal) => _buildGoalCard(goal)),
                ],
              ),
            ),
          ),
          OnboardingBottomButton(
            text: 'Continue',
            enabled: _selected != null,
            onPressed: () {
              if (_selected != null) {
                ref.read(onboardingProvider.notifier).setGoal(_selected!);
                context.push('/onboarding/experience');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Map<String, String> goal) {
    final isSelected = _selected == goal['label'];
    final primary = context.primaryColor;

    return Semantics(
      button: true,
      label: goal['label'],
      selected: isSelected,
      child: GestureDetector(
      onTap: () {
        PlatformAdapter.hapticSelection();
        setState(() => _selected = goal['label']);
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
            // Emoji
            Container(
              width: 48.r,
              height: 48.r,
              decoration: BoxDecoration(
                color: context.mutedColor,
                borderRadius: AppRadius.borderLg,
              ),
              child: Center(
                child: Text(
                  goal['emoji']!,
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
                    goal['label']!,
                    style: AppTextStyles.h3.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    goal['desc']!,
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
