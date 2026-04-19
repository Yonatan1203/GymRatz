import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/onboarding_progress_bar.dart';
import '../../../shared/widgets/onboarding_bottom_button.dart';
import '../providers/onboarding_provider.dart';

class OnboardingWeightScreen extends ConsumerStatefulWidget {
  const OnboardingWeightScreen({super.key});

  @override
  ConsumerState<OnboardingWeightScreen> createState() => _OnboardingWeightScreenState();
}

class _OnboardingWeightScreenState extends ConsumerState<OnboardingWeightScreen> {
  late FixedExtentScrollController _scrollController;
  late double _selectedWeight;

  @override
  void initState() {
    super.initState();
    _selectedWeight = ref.read(onboardingProvider).weight;
    final index = (_selectedWeight - 40).round();
    _scrollController = FixedExtentScrollController(initialItem: index.clamp(0, 160));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OnboardingProgressBar(currentStep: 7, totalSteps: 14),
          Expanded(
            child: Column(
              children: [
                SizedBox(height: AppSpacing.xxl),
                Text(
                  'Your weight',
                  style: AppTextStyles.h1.copyWith(
                    color: context.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'This helps us calculate your metrics',
                  style: AppTextStyles.body.copyWith(color: context.mutedForeground),
                ),
                SizedBox(height: 32.h),
                Text(
                  '${_selectedWeight.round()} kg',
                  style: AppTextStyles.display.copyWith(
                    color: context.primaryColor,
                  ),
                ),
                SizedBox(height: 24.h),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: _scrollController,
                    itemExtent: 50.h,
                    physics: const FixedExtentScrollPhysics(),
                    diameterRatio: 1.5,
                    onSelectedItemChanged: (index) {
                      setState(() => _selectedWeight = (40 + index).toDouble());
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 161,
                      builder: (context, index) {
                        final weight = 40 + index;
                        final isSelected = weight == _selectedWeight.round();
                        return Center(
                          child: Text(
                            '$weight',
                            style: TextStyle(
                              fontSize: isSelected ? 28.sp : 20.sp,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                              color: isSelected
                                  ? context.foreground
                                  : context.mutedForeground.withOpacity(0.6),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          OnboardingBottomButton(
            text: 'Continue',
            onPressed: () {
              ref.read(onboardingProvider.notifier).setWeight(_selectedWeight);
              context.push('/onboarding/summary');
            },
          ),
        ],
      ),
    );
  }
}
