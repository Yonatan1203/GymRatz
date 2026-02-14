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

class OnboardingInjuryScreen extends ConsumerStatefulWidget {
  const OnboardingInjuryScreen({super.key});

  @override
  ConsumerState<OnboardingInjuryScreen> createState() =>
      _OnboardingInjuryScreenState();
}

class _OnboardingInjuryScreenState
    extends ConsumerState<OnboardingInjuryScreen> {
  late Set<String> _selected;

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
    _selected = Set<String>.from(ref.read(onboardingProvider).selectedInjuries);
  }

  void _toggle(String injury) {
    setState(() {
      if (injury == 'None') {
        _selected = {'None'};
        return;
      }
      _selected.remove('None');
      if (_selected.contains(injury)) {
        _selected.remove(injury);
      } else {
        _selected.add(injury);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OnboardingProgressBar(currentStep: 4, totalSteps: 14),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Any injuries?',
                    style: AppTextStyles.h1.copyWith(
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
                  SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
          OnboardingBottomButton(
            text: 'Continue',
            enabled: _selected.isNotEmpty,
            onPressed: () {
              if (_selected.isNotEmpty) {
                // Sync each selection with provider
                final notifier = ref.read(onboardingProvider.notifier);
                // Clear and rebuild
                for (final injury in _selected) {
                  notifier.toggleInjury(injury);
                }
                context.go('/onboarding/units');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInjuryCard(Map<String, String> injury) {
    final isSelected = _selected.contains(injury['label']);
    final primary = context.primaryColor;

    return Semantics(
      button: true,
      label: injury['label'],
      selected: isSelected,
      child: GestureDetector(
      onTap: () {
        PlatformAdapter.hapticSelection();
        _toggle(injury['label']!);
      },
      child: Container(
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
                  LucideIcons.check,
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
