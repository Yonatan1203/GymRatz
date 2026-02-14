import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/app_radius.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/utils/platform_adapter.dart';
import '../../../shared/widgets/onboarding_progress_bar.dart';
import '../../../shared/widgets/onboarding_bottom_button.dart';
import '../providers/onboarding_provider.dart';

class OnboardingStyleScreen extends ConsumerStatefulWidget {
  const OnboardingStyleScreen({super.key});

  @override
  ConsumerState<OnboardingStyleScreen> createState() =>
      _OnboardingStyleScreenState();
}

class _OnboardingStyleScreenState
    extends ConsumerState<OnboardingStyleScreen> {
  String? _selected;

  static const _styles = [
    {
      'label': 'Bodybuilding',
      'emoji': '\u{1F3D7}\u{FE0F}',
      'desc': 'Hypertrophy-focused training',
    },
    {
      'label': 'Powerlifting',
      'emoji': '\u{1F3CB}\u{FE0F}',
      'desc': 'Squat, bench, deadlift focus',
    },
    {
      'label': 'CrossFit',
      'emoji': '\u{26A1}',
      'desc': 'High intensity functional fitness',
    },
    {
      'label': 'Calisthenics',
      'emoji': '\u{1F938}',
      'desc': 'Bodyweight strength training',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selected = ref.read(onboardingProvider).selectedStyle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OnboardingProgressBar(currentStep: 3, totalSteps: 14),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Training style?',
                    style: AppTextStyles.h1.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Pick the training style that suits you best.',
                    style: AppTextStyles.body.copyWith(
                      color: context.mutedForeground,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  ..._styles.map((style) => _buildCard(style)),
                ],
              ),
            ),
          ),
          OnboardingBottomButton(
            text: 'Continue',
            enabled: _selected != null,
            onPressed: () {
              if (_selected != null) {
                ref.read(onboardingProvider.notifier).setStyle(_selected!);
                context.go('/onboarding/injury');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, String> style) {
    final isSelected = _selected == style['label'];
    final primary = context.primaryColor;

    return Semantics(
      button: true,
      label: style['label'],
      selected: isSelected,
      child: GestureDetector(
      onTap: () {
        PlatformAdapter.hapticSelection();
        setState(() => _selected = style['label']);
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
                  style['emoji']!,
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
                    style['label']!,
                    style: AppTextStyles.h3.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    style['desc']!,
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
                  LucideIcons.check,
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
