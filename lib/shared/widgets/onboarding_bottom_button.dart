import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text_styles.dart';
import '../utils/platform_adapter.dart';

class OnboardingBottomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool enabled;

  const OnboardingBottomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52.h,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? () {
            PlatformAdapter.hapticLight();
            onPressed?.call();
          } : null,
            borderRadius: AppRadius.borderXxl,
            child: Container(
              decoration: BoxDecoration(
                color: enabled ? primary : muted,
                borderRadius: AppRadius.borderXxl,
                boxShadow: enabled ? AppShadows.md : null,
              ),
              child: Center(
                child: Text(
                  text,
                  style: AppTextStyles.buttonText.copyWith(
                    color: enabled
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkMutedForeground
                            : AppColors.lightMutedForeground),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
