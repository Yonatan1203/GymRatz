import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';

class MenuItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Widget? trailing;

  const MenuItemWidget({
    super.key,
    required this.icon,
    required this.label,
    this.badge,
    this.onTap,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkForeground : AppColors.lightForeground;
    final mutedFg = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Semantics(
      label: label,
      child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Row(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: muted,
                borderRadius: AppRadius.borderLg,
              ),
              child: Icon(icon, size: 20.r, color: iconColor ?? mutedFg),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(color: fg),
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPrimary.withValues(alpha: 0.2)
                      : AppColors.lightPrimary.withValues(alpha: 0.2),
                  borderRadius: AppRadius.borderFull,
                ),
                child: Text(
                  badge!,
                  style: AppTextStyles.caption.copyWith(
                    color: isDark
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
            ],
            trailing ??
                Icon(
                  LucideIcons.chevronRight,
                  size: 20.r,
                  color: mutedFg,
                ),
          ],
        ),
      ),
    ),
    );
  }
}
