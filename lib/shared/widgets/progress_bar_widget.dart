import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';

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

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: trackColor ?? (isDark ? AppColors.darkMuted : AppColors.lightMuted),
        borderRadius: AppRadius.borderFull,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: fillGradient ?? AppGradients.primary(isDark: isDark),
            borderRadius: AppRadius.borderFull,
          ),
        ),
      ),
    );
  }
}
