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
import '../../../shared/widgets/scale_tap.dart';
import '../../../shared/widgets/staggered_list.dart';
import '../providers/onboarding_provider.dart';

class OnboardingGoalScreen extends ConsumerStatefulWidget {
  const OnboardingGoalScreen({super.key});

  @override
  ConsumerState<OnboardingGoalScreen> createState() =>
      _OnboardingGoalScreenState();
}

class _OnboardingGoalScreenState extends ConsumerState<OnboardingGoalScreen> {
  String? _selectedGoal;
  String? _selectedExperience;

  static const _goals = [
    {'label': 'Build Muscle', 'emoji': '\u{1F4AA}', 'desc': 'Gain size and definition'},
    {'label': 'Lose Fat', 'emoji': '\u{1F525}', 'desc': 'Burn calories and lean out'},
    {'label': 'Get Stronger', 'emoji': '\u{1F3CB}\u{FE0F}', 'desc': 'Increase your max lifts'},
    {'label': 'Improve Endurance', 'emoji': '\u{1F3C3}', 'desc': 'Build stamina and conditioning'},
  ];

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
    final state = ref.read(onboardingProvider);
    _selectedGoal = state.selectedGoal;
    _selectedExperience = state.selectedExperience;
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
              child: StaggeredList(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Tell us about yourself',
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
                  ..._goals.map((goal) => _buildCard(
                    item: goal,
                    isSelected: _selectedGoal == goal['label'],
                    onTap: () {
                      PlatformAdapter.hapticSelection();
                      setState(() => _selectedGoal = goal['label']);
                    },
                  )),
                  SizedBox(height: AppSpacing.sectionGap),
                  Text(
                    'Experience Level',
                    style: AppTextStyles.h2.copyWith(
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
                  ..._levels.map((level) => _buildCard(
                    item: level,
                    isSelected: _selectedExperience == level['label'],
                    onTap: () {
                      PlatformAdapter.hapticSelection();
                      setState(() => _selectedExperience = level['label']);
                    },
                  )),
                  SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
          OnboardingBottomButton(
            text: 'Continue',
            enabled: _selectedGoal != null && _selectedExperience != null,
            onPressed: () {
              if (_selectedGoal != null && _selectedExperience != null) {
                final notifier = ref.read(onboardingProvider.notifier);
                notifier.setGoal(_selectedGoal!);
                notifier.setExperience(_selectedExperience!);
                context.push('/onboarding/style');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required Map<String, String> item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primary = context.primaryColor;

    return Semantics(
      button: true,
      label: item['label'],
      selected: isSelected,
      child: ScaleTap(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: AppSpacing.lg),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: isSelected
                ? primary.withOpacity(0.1)
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
                    item['emoji']!,
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
                      item['label']!,
                      style: AppTextStyles.h3.copyWith(
                        color: context.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      item['desc']!,
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
