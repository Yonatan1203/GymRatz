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

class OnboardingUnitsScreen extends ConsumerStatefulWidget {
  const OnboardingUnitsScreen({super.key});

  @override
  ConsumerState<OnboardingUnitsScreen> createState() =>
      _OnboardingUnitsScreenState();
}

class _OnboardingUnitsScreenState
    extends ConsumerState<OnboardingUnitsScreen> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(onboardingProvider).selectedUnits;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OnboardingProgressBar(currentStep: 5, totalSteps: 14),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Choose your units',
                    style: AppTextStyles.h1.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'You can always change this later in settings.',
                    style: AppTextStyles.body.copyWith(
                      color: context.mutedForeground,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxxl),
                  _buildUnitCard(
                    key: 'metric',
                    title: 'Metric',
                    subtitle: 'Kilograms & centimeters',
                    units: 'kg, cm',
                    icon: AppIcons.ruler,
                  ),
                  SizedBox(height: AppSpacing.xl),
                  _buildUnitCard(
                    key: 'imperial',
                    title: 'Imperial',
                    subtitle: 'Pounds & feet/inches',
                    units: 'lbs, ft/in',
                    icon: AppIcons.scale,
                  ),
                ],
              ),
            ),
          ),
          OnboardingBottomButton(
            text: 'Continue',
            enabled: _selected != null,
            onPressed: () {
              if (_selected != null) {
                ref.read(onboardingProvider.notifier).setUnits(_selected!);
                context.push('/onboarding/height');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard({
    required String key,
    required String title,
    required String subtitle,
    required String units,
    required IconData icon,
  }) {
    final isSelected = _selected == key;
    final primary = context.primaryColor;

    return Semantics(
      button: true,
      label: title,
      selected: isSelected,
      child: GestureDetector(
      onTap: () {
        PlatformAdapter.hapticSelection();
        setState(() => _selected = key);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.08)
              : context.cardColor,
          borderRadius: AppRadius.borderXl,
          border: Border.all(
            color: isSelected ? primary : context.borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: AppShadows.md,
        ),
        child: Row(
          children: [
            Container(
              width: 56.r,
              height: 56.r,
              decoration: BoxDecoration(
                color: isSelected
                    ? primary.withValues(alpha: 0.15)
                    : context.mutedColor,
                borderRadius: AppRadius.borderLg,
              ),
              child: Icon(
                icon,
                size: 28.r,
                color: isSelected ? primary : context.mutedForeground,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.h2.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.mutedForeground,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    units,
                    style: AppTextStyles.caption.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w600,
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
