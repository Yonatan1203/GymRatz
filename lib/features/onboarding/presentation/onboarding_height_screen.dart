import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/onboarding_progress_bar.dart';
import '../../../shared/widgets/onboarding_bottom_button.dart';
import '../providers/onboarding_provider.dart';

class OnboardingHeightScreen extends ConsumerStatefulWidget {
  const OnboardingHeightScreen({super.key});

  @override
  ConsumerState<OnboardingHeightScreen> createState() =>
      _OnboardingHeightScreenState();
}

class _OnboardingHeightScreenState
    extends ConsumerState<OnboardingHeightScreen> {
  late FixedExtentScrollController _scrollController;
  late int _selectedIndex;
  bool _isMetric = true;

  // Metric: 140-210 cm
  static const _metricMin = 140;
  static const _metricMax = 210;

  // Imperial heights: 4'8" to 6'10" (56 inches to 82 inches)
  static const _imperialMinInches = 56;
  static const _imperialMaxInches = 82;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProvider);
    _isMetric = state.selectedUnits != 'imperial';
    final currentHeight = state.height;

    if (_isMetric) {
      _selectedIndex = (currentHeight - _metricMin).round().clamp(0, _metricMax - _metricMin);
    } else {
      // Convert cm to inches
      final inches = (currentHeight / 2.54).round();
      _selectedIndex = (inches - _imperialMinInches).clamp(0, _imperialMaxInches - _imperialMinInches);
    }

    _scrollController = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int get _itemCount => _isMetric
      ? (_metricMax - _metricMin + 1)
      : (_imperialMaxInches - _imperialMinInches + 1);

  String _labelForIndex(int index) {
    if (_isMetric) {
      return '${_metricMin + index} cm';
    } else {
      final totalInches = _imperialMinInches + index;
      final feet = totalInches ~/ 12;
      final inches = totalInches % 12;
      return "$feet'$inches\"";
    }
  }

  double _heightCmForIndex(int index) {
    if (_isMetric) {
      return (_metricMin + index).toDouble();
    } else {
      return (_imperialMinInches + index) * 2.54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.primaryColor;

    return Scaffold(
      body: Column(
        children: [
          const OnboardingProgressBar(currentStep: 6, totalSteps: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Your height',
                    style: AppTextStyles.h1.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Scroll to select your height.',
                    style: AppTextStyles.body.copyWith(
                      color: context.mutedForeground,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxxl),

                  // Large display of selected value
                  Center(
                    child: Text(
                      _labelForIndex(_selectedIndex),
                      style: AppTextStyles.display.copyWith(
                        color: primary,
                        fontSize: 56.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxl),

                  // Scroll picker
                  Expanded(
                    child: Stack(
                      children: [
                        // Selection highlight
                        Center(
                          child: Container(
                            height: 56.h,
                            margin: EdgeInsets.symmetric(horizontal: 24.w),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.1),
                              borderRadius: AppRadius.borderLg,
                              border: Border.all(
                                color: primary.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                        // Wheel
                        ListWheelScrollView.useDelegate(
                          controller: _scrollController,
                          itemExtent: 56.h,
                          physics: const FixedExtentScrollPhysics(),
                          perspective: 0.003,
                          diameterRatio: 1.5,
                          onSelectedItemChanged: (index) {
                            setState(() => _selectedIndex = index);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: _itemCount,
                            builder: (context, index) {
                              final isSelected = index == _selectedIndex;
                              return Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: AppTextStyles.h2.copyWith(
                                    color: isSelected
                                        ? context.foreground
                                        : context.mutedForeground.withOpacity(0.6),
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    fontSize: isSelected ? 22.sp : 18.sp,
                                  ),
                                  child: Text(_labelForIndex(index)),
                                ),
                              );
                            },
                          ),
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
              ref
                  .read(onboardingProvider.notifier)
                  .setHeight(_heightCmForIndex(_selectedIndex));
              context.push('/onboarding/weight');
            },
          ),
        ],
      ),
    );
  }
}
