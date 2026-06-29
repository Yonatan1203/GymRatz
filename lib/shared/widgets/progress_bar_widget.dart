import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';

/// Concrete horizontal progress bar with app gradient fill and ARIA semantics.
///
/// Covers the common case: a track + animated fill using the primary gradient.
/// Accepts an optional [trackColor] and [fillGradient] for overrides.
///
/// Use [AnimatedProgress] instead when you need a custom builder (e.g. an
/// animated text counter or non-bar visualisation).
class ProgressBarWidget extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color? trackColor;
  final Gradient? fillGradient;

  const ProgressBarWidget({
    super.key,
    required this.progress,
    this.height = 8,
    this.trackColor,
    this.fillGradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressPercent = (progress.clamp(0.0, 1.0) * 100).round();

    return Semantics(
      label: 'Progress: $progressPercent percent',
      value: '$progressPercent%',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: trackColor ?? (isDark ? AppColors.darkMuted : AppColors.lightMuted),
          borderRadius: AppRadius.borderFull,
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          builder: (context, animatedValue, _) {
            return FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: animatedValue,
              child: Container(
                decoration: BoxDecoration(
                  gradient: fillGradient ?? AppGradients.primary(isDark: isDark),
                  borderRadius: AppRadius.borderFull,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
