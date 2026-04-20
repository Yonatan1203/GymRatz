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

class OnboardingStyleScreen extends ConsumerStatefulWidget {
  const OnboardingStyleScreen({super.key});

  @override
  ConsumerState<OnboardingStyleScreen> createState() =>
      _OnboardingStyleScreenState();
}

class _OnboardingStyleScreenState
    extends ConsumerState<OnboardingStyleScreen> {
  String? _selectedStyle;
  late Set<String> _selectedInjuries;

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

  static const _injuries = [
    {'label': 'Shoulder', 'emoji': '\u{1F9BE}'},
    {'label': 'Back', 'emoji': '\u{1F9B4}'},
    {'label': 'Knee', 'emoji': '\u{1F9B5}'},
    {'label': 'Wrist', 'emoji': '\u{270B}'},
    {'label': 'Hip', 'emoji': '\u{1F9CD}'},
    {'label': 'None', 'emoji': '\u{2705}'},
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProvider);
    _selectedStyle = state.selectedStyle;
    _selectedInjuries = Set<String>.from(state.selectedInjuries);
  }

  void _toggleInjury(String injury) {
    setState(() {
      if (injury == 'None') {
        _selectedInjuries = {'None'};
        return;
      }
      _selectedInjuries.remove('None');
      if (_selectedInjuries.contains(injury)) {
        _selectedInjuries.remove(injury);
      } else {
        _selectedInjuries.add(injury);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OnboardingProgressBar(currentStep: 3),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: StaggeredList(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Your training',
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
                  ..._styles.map((style) => _buildStyleCard(style)),
                  SizedBox(height: AppSpacing.sectionGap),
                  Text(
                    'Any injuries or limitations?',
                    style: AppTextStyles.h2.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "We'll work around them. Select all that apply.",
                    style: AppTextStyles.body.copyWith(
                      color: context.mutedForeground,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.lg,
                    crossAxisSpacing: AppSpacing.lg,
                    childAspectRatio: 1.6,
                    children: _injuries
                        .map((injury) => _buildInjuryCard(injury))
                        .toList(),
                  ),
                  SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
          OnboardingBottomButton(
            text: 'Continue',
            enabled: _selectedStyle != null && _selectedInjuries.isNotEmpty,
            onPressed: () {
              if (_selectedStyle != null && _selectedInjuries.isNotEmpty) {
                final notifier = ref.read(onboardingProvider.notifier);
                notifier.setStyle(_selectedStyle!);
                // Sync injuries with provider
                // First set to 'None' to clear, then toggle each selected
                notifier.toggleInjury('None'); // clears to {'None'}
                if (!_selectedInjuries.contains('None')) {
                  for (final injury in _selectedInjuries) {
                    notifier.toggleInjury(injury);
                  }
                }
                context.push('/onboarding/height');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStyleCard(Map<String, String> style) {
    final isSelected = _selectedStyle == style['label'];
    final primary = context.primaryColor;

    return Semantics(
      button: true,
      label: style['label'],
      selected: isSelected,
      child: ScaleTap(
        onTap: () {
          PlatformAdapter.hapticSelection();
          setState(() => _selectedStyle = style['label']);
        },
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: AppSpacing.lg),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: isSelected
                ? primary.withValues(alpha:0.1)
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

  Widget _buildInjuryCard(Map<String, String> injury) {
    final isSelected = _selectedInjuries.contains(injury['label']);
    final primary = context.primaryColor;

    return Semantics(
      button: true,
      label: injury['label'],
      selected: isSelected,
      child: ScaleTap(
        onTap: () {
          PlatformAdapter.hapticSelection();
          _toggleInjury(injury['label']!);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? primary.withValues(alpha:0.1)
                : context.cardColor,
            borderRadius: AppRadius.borderXl,
            border: Border.all(
              color: isSelected ? primary : context.borderColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                injury['emoji']!,
                style: TextStyle(fontSize: 28.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                injury['label']!,
                style: AppTextStyles.buttonText.copyWith(
                  color: context.foreground,
                ),
              ),
              if (isSelected)
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Icon(
                    AppIcons.check,
                    size: 16.r,
                    color: primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
