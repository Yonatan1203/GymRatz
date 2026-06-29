import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_durations.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text_styles.dart';
import '../utils/extensions.dart';

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

    // Color helpers — resolved once per build, used inside the map closure.
    // useTransparentBg is for overlay contexts (e.g. gradient headers) where the
    // card sits on top of a colored background and must be semi-transparent.
    final valueColor = useTransparentBg && isDark ? Colors.white : context.foreground;
    final labelColor =
        useTransparentBg && isDark ? Colors.white70 : context.mutedForeground;

    return IntrinsicHeight(
      child: Row(
        children: items.map((item) {
          final numericValue = double.tryParse(item.value);

          return Expanded(
            child: Semantics(
              // GYM-56: announce the composed value + label as a single unit.
              // excludeSemantics prevents the icon and individual Text widgets
              // from being read a second time by TalkBack / VoiceOver.
              label: '${item.value} ${item.label}',
              excludeSemantics: true,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: useTransparentBg
                      ? (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppColors.lightPrimary.withValues(alpha: 0.18))
                      : context.cardColor,
                  borderRadius: AppRadius.borderXl,
                  border: useTransparentBg
                      ? Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : AppColors.lightPrimary.withValues(alpha: 0.3),
                        )
                      : Border.all(color: context.borderColor),
                  boxShadow: useTransparentBg ? null : AppShadows.md,
                ),
                child: Column(
                  children: [
                    Icon(item.icon, size: 20.r, color: item.iconColor),
                    SizedBox(height: 8.h),
                    if (numericValue != null)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: numericValue),
                        duration: AppDurations.fast,
                        curve: Curves.easeOut,
                        builder: (context, value, _) => Text(
                          value.toStringAsFixed(0),
                          style: AppTextStyles.h2.copyWith(
                            color: valueColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Text(
                        item.value,
                        style: AppTextStyles.h2.copyWith(
                          color: valueColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    SizedBox(height: 2.h),
                    Text(
                      item.label,
                      style: AppTextStyles.caption.copyWith(color: labelColor),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
