import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text_styles.dart';
import '../utils/platform_adapter.dart';

enum ButtonVariant { primary, secondary, outline, dashed, gradient }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final ButtonVariant variant;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (variant == ButtonVariant.gradient) {
      return _buildGradientButton(isDark);
    }
    if (variant == ButtonVariant.dashed) {
      return _buildDashedButton(isDark);
    }

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 48.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : () {
          PlatformAdapter.hapticLight();
          onPressed?.call();
        },
        style: _getStyle(isDark),
        child: _buildChild(isDark),
      ),
    );
  }

  Widget _buildGradientButton(bool isDark) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 48.h,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.primary(isDark: isDark),
          borderRadius: AppRadius.borderXxl,
          boxShadow: AppShadows.lg,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : () {
              PlatformAdapter.hapticLight();
              onPressed?.call();
            },
            borderRadius: AppRadius.borderXxl,
            child: Center(child: _buildChild(isDark, forceWhite: true)),
          ),
        ),
      ),
    );
  }

  Widget _buildDashedButton(bool isDark) {
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final fgColor =
        isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 48.h,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed != null ? () {
            PlatformAdapter.hapticLight();
            onPressed!.call();
          } : null,
          borderRadius: AppRadius.borderLg,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderLg,
              border: Border.all(
                color: borderColor,
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18.r, color: fgColor),
                    SizedBox(width: 8.w),
                  ],
                  Text(
                    text,
                    style: AppTextStyles.bodySmall.copyWith(color: fgColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChild(bool isDark, {bool forceWhite = false}) {
    if (isLoading) {
      return SizedBox(
        width: 20.r,
        height: 20.r,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    final color = forceWhite
        ? Colors.white
        : (textColor ?? Colors.white);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20.r, color: color),
          SizedBox(width: 8.w),
        ],
        Text(text, style: AppTextStyles.buttonText.copyWith(color: color)),
      ],
    );
  }

  ButtonStyle _getStyle(bool isDark) {
    switch (variant) {
      case ButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ??
              (isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
          foregroundColor: Colors.white,
          elevation: 1,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        );
      case ButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor:
              isDark ? AppColors.darkMuted : AppColors.lightMuted,
          foregroundColor:
              isDark ? AppColors.darkForeground : AppColors.lightForeground,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        );
      case ButtonVariant.outline:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor:
              isDark ? AppColors.darkForeground : AppColors.lightForeground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderLg,
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        );
      default:
        return ElevatedButton.styleFrom();
    }
  }
}
