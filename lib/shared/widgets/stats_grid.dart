import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text_styles.dart';

class StatsGridItem {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const StatsGridItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });
}

class StatsGrid extends StatelessWidget {
  final List<StatsGridItem> items;
  final bool useTransparentBg;

  const StatsGrid({
    super.key,
    required this.items,
    this.useTransparentBg = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: items.map((item) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: useTransparentBg
                  ? Colors.white.withValues(alpha: 0.1)
                  : (isDark ? AppColors.darkCard : AppColors.lightCard),
              borderRadius: AppRadius.borderLg,
              border: useTransparentBg
                  ? null
                  : Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
              boxShadow: useTransparentBg ? null : AppShadows.md,
            ),
            child: Column(
              children: [
                Icon(item.icon, size: 20.r, color: item.iconColor),
                SizedBox(height: 8.h),
                Text(
                  item.value,
                  style: AppTextStyles.h2.copyWith(
                    color: useTransparentBg
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkForeground
                            : AppColors.lightForeground),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  item.label,
                  style: AppTextStyles.caption.copyWith(
                    color: useTransparentBg
                        ? Colors.white70
                        : (isDark
                            ? AppColors.darkMutedForeground
                            : AppColors.lightMutedForeground),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
