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

class OnboardingHeightScreen extends ConsumerStatefulWidget {
  const OnboardingHeightScreen({super.key});

  @override
  ConsumerState<OnboardingHeightScreen> createState() =>
      _OnboardingHeightScreenState();
}

class _OnboardingHeightScreenState
    extends ConsumerState<OnboardingHeightScreen> {
  late FixedExtentScrollController _heightScrollController;
  late FixedExtentScrollController _weightScrollController;
  late int _selectedHeightIndex;
  late double _selectedWeight;
  bool _isMetric = true;

  // Height: Metric 140-210 cm
  static const _metricMin = 140;
  static const _metricMax = 210;

  // Height: Imperial 4'8" to 6'10" (56 to 82 inches)
  static const _imperialMinInches = 56;
  static const _imperialMaxInches = 82;

  // Weight: 40-200 kg (stored internally in kg)
  static const _weightMinKg = 40;
  static const _weightMaxKg = 200;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProvider);
    _isMetric = state.selectedUnits != 'imperial';
    final currentHeight = state.height;
    _selectedWeight = state.weight;

    if (_isMetric) {
      _selectedHeightIndex =
          (currentHeight - _metricMin).round().clamp(0, _metricMax - _metricMin);
    } else {
      final inches = (currentHeight / 2.54).round();
      _selectedHeightIndex =
          (inches - _imperialMinInches).clamp(0, _imperialMaxInches - _imperialMinInches);
    }

    _heightScrollController =
        FixedExtentScrollController(initialItem: _selectedHeightIndex);

    final weightIndex = (_selectedWeight - _weightMinKg).round();
    _weightScrollController = FixedExtentScrollController(
        initialItem: weightIndex.clamp(0, _weightMaxKg - _weightMinKg));
  }

  @override
  void dispose() {
    _heightScrollController.dispose();
    _weightScrollController.dispose();
    super.dispose();
  }

  // --- Height helpers ---

  int get _heightItemCount => _isMetric
      ? (_metricMax - _metricMin + 1)
      : (_imperialMaxInches - _imperialMinInches + 1);

  String _heightLabelForIndex(int index) {
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

  // --- Weight helpers ---

  int get _weightItemCount => _weightMaxKg - _weightMinKg + 1;

  String _weightDisplayLabel(double weightKg) {
    if (_isMetric) {
      return '${weightKg.round()} kg';
    } else {
      return '${(weightKg * 2.20462).round()} lbs';
    }
  }

  String _weightPickerLabel(int index) {
    final kg = _weightMinKg + index;
    if (_isMetric) {
      return '$kg';
    } else {
      return '${(kg * 2.20462).round()}';
    }
  }

  // --- Unit toggle ---

  void _onUnitsChanged(bool metric) {
    if (_isMetric == metric) return;
    PlatformAdapter.hapticSelection();

    // Save current values before switching
    final currentHeightCm = _heightCmForIndex(_selectedHeightIndex);

    setState(() {
      _isMetric = metric;
    });

    // Update the provider
    ref
        .read(onboardingProvider.notifier)
        .setUnits(metric ? 'metric' : 'imperial');

    // Recalculate height index for new unit system
    int newHeightIndex;
    if (_isMetric) {
      newHeightIndex =
          (currentHeightCm - _metricMin).round().clamp(0, _metricMax - _metricMin);
    } else {
      final inches = (currentHeightCm / 2.54).round();
      newHeightIndex =
          (inches - _imperialMinInches).clamp(0, _imperialMaxInches - _imperialMinInches);
    }

    _selectedHeightIndex = newHeightIndex;
    _heightScrollController.dispose();
    _heightScrollController =
        FixedExtentScrollController(initialItem: _selectedHeightIndex);
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.primaryColor;

    return Scaffold(
      body: Column(
        children: [
          const OnboardingProgressBar(currentStep: 4),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: StaggeredList(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Your body',
                    style: AppTextStyles.h1.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'This helps us personalize your plan.',
                    style: AppTextStyles.body.copyWith(
                      color: context.mutedForeground,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxl),

                  // Unit toggle (segmented control)
                  _buildUnitToggle(primary),
                  SizedBox(height: AppSpacing.sectionGap),

                  // Height section
                  Text(
                    'Height',
                    style: AppTextStyles.h2.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // Height display
                  Center(
                    child: Text(
                      _heightLabelForIndex(_selectedHeightIndex),
                      style: AppTextStyles.display.copyWith(
                        color: primary,
                        fontSize: 48.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // Height picker
                  SizedBox(
                    height: 180.h,
                    child: Stack(
                      children: [
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
                        ListWheelScrollView.useDelegate(
                          controller: _heightScrollController,
                          itemExtent: 56.h,
                          physics: const FixedExtentScrollPhysics(),
                          perspective: 0.003,
                          diameterRatio: 1.5,
                          onSelectedItemChanged: (index) {
                            setState(() => _selectedHeightIndex = index);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: _heightItemCount,
                            builder: (context, index) {
                              final isSelected = index == _selectedHeightIndex;
                              return Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: AppTextStyles.h2.copyWith(
                                    color: isSelected
                                        ? context.foreground
                                        : context.mutedForeground
                                            .withValues(alpha:0.6),
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    fontSize: isSelected ? 22.sp : 18.sp,
                                  ),
                                  child: Text(_heightLabelForIndex(index)),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sectionGap),

                  // Weight section
                  Text(
                    'Weight',
                    style: AppTextStyles.h2.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // Weight display (unit-aware)
                  Center(
                    child: Text(
                      _weightDisplayLabel(_selectedWeight),
                      style: AppTextStyles.display.copyWith(
                        color: primary,
                        fontSize: 48.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // Weight picker
                  SizedBox(
                    height: 180.h,
                    child: Stack(
                      children: [
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
                        ListWheelScrollView.useDelegate(
                          controller: _weightScrollController,
                          itemExtent: 56.h,
                          physics: const FixedExtentScrollPhysics(),
                          perspective: 0.003,
                          diameterRatio: 1.5,
                          onSelectedItemChanged: (index) {
                            setState(() {
                              _selectedWeight =
                                  (_weightMinKg + index).toDouble();
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: _weightItemCount,
                            builder: (context, index) {
                              final kg = _weightMinKg + index;
                              final isSelected = kg == _selectedWeight.round();
                              return Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: AppTextStyles.h2.copyWith(
                                    color: isSelected
                                        ? context.foreground
                                        : context.mutedForeground
                                            .withValues(alpha:0.6),
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    fontSize: isSelected ? 22.sp : 18.sp,
                                  ),
                                  child: Text(_weightPickerLabel(index)),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
          OnboardingBottomButton(
            text: 'Continue',
            onPressed: () {
              final notifier = ref.read(onboardingProvider.notifier);
              notifier.setHeight(_heightCmForIndex(_selectedHeightIndex));
              notifier.setWeight(_selectedWeight);
              context.push('/onboarding/email');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUnitToggle(Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: context.borderColor),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: ScaleTap(
              onTap: () => _onUnitsChanged(true),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: _isMetric
                      ? primary.withValues(alpha:0.1)
                      : Colors.transparent,
                  borderRadius: AppRadius.borderXl,
                  border: _isMetric
                      ? Border.all(color: primary, width: 2)
                      : null,
                ),
                child: Column(
                  children: [
                    Icon(
                      AppIcons.ruler,
                      size: 20.r,
                      color: _isMetric ? primary : context.mutedForeground,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Metric',
                      style: AppTextStyles.h4.copyWith(
                        color: _isMetric ? primary : context.foreground,
                        fontWeight:
                            _isMetric ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'kg, cm',
                      style: AppTextStyles.caption.copyWith(
                        color: context.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ScaleTap(
              onTap: () => _onUnitsChanged(false),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: !_isMetric
                      ? primary.withValues(alpha:0.1)
                      : Colors.transparent,
                  borderRadius: AppRadius.borderXl,
                  border: !_isMetric
                      ? Border.all(color: primary, width: 2)
                      : null,
                ),
                child: Column(
                  children: [
                    Icon(
                      AppIcons.scale,
                      size: 20.r,
                      color: !_isMetric ? primary : context.mutedForeground,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Imperial',
                      style: AppTextStyles.h4.copyWith(
                        color: !_isMetric ? primary : context.foreground,
                        fontWeight:
                            !_isMetric ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'lbs, ft/in',
                      style: AppTextStyles.caption.copyWith(
                        color: context.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
