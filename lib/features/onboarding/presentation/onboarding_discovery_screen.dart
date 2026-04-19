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
import '../providers/onboarding_provider.dart';

class OnboardingDiscoveryScreen extends ConsumerStatefulWidget {
  const OnboardingDiscoveryScreen({super.key});

  @override
  ConsumerState<OnboardingDiscoveryScreen> createState() =>
      _OnboardingDiscoveryScreenState();
}

class _OnboardingDiscoveryScreenState
    extends ConsumerState<OnboardingDiscoveryScreen> {
  String? _selected;

  static const _options = [
    'App Store',
    'Instagram',
    'Friend',
    'YouTube',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OnboardingProgressBar(currentStep: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.xxl),
                  Text(
                    'How did you find us?',
                    style: AppTextStyles.h1.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'This helps us grow our community',
                    style: AppTextStyles.body.copyWith(color: context.mutedForeground),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  ..._options.map((option) {
                    final isSelected = _selected == option;
                    return Semantics(
                      button: true,
                      label: option,
                      selected: isSelected,
                      child: ScaleTap(
                      onTap: () {
                        PlatformAdapter.hapticSelection();
                        setState(() => _selected = option);
                      },
                      child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: AppSpacing.lg),
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.primaryColor.withValues(alpha: 0.08)
                              : context.cardColor,
                          borderRadius: AppRadius.borderXl,
                          border: Border.all(
                            color: isSelected
                                ? context.primaryColor
                                : context.borderColor,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: AppShadows.sm,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option,
                                style: AppTextStyles.h4.copyWith(
                                  color: context.foreground,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 28.r,
                                height: 28.r,
                                decoration: BoxDecoration(
                                  color: context.primaryColor,
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
                  }),
                ],
              ),
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final onboarding = ref.watch(onboardingProvider);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onboarding.error != null)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: 8.h),
                      child: Text(
                        onboarding.error!,
                        style: AppTextStyles.caption.copyWith(color: context.destructiveColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  OnboardingBottomButton(
                    text: onboarding.isSubmitting ? 'Creating Account...' : 'Get Started',
                    enabled: _selected != null && !onboarding.isSubmitting,
                    onPressed: () async {
                      if (_selected != null) {
                        ref.read(onboardingProvider.notifier).setDiscovery(_selected!);
                        final success = await ref.read(onboardingProvider.notifier).completeOnboarding();
                        if (success && context.mounted) {
                          context.go('/home');
                        }
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
