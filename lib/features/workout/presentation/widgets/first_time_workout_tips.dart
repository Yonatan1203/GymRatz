import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_icons.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../shared/utils/extensions.dart';
import '../../../../shared/widgets/custom_card.dart';

class FirstTimeWorkoutTips extends StatelessWidget {
  final VoidCallback onClose;

  const FirstTimeWorkoutTips({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: CustomCard(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.info, size: 18.r, color: context.primaryColor),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Quick Start Guide',
                    style: AppTextStyles.h4.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: Icon(AppIcons.x, size: 18.r, color: context.mutedForeground),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _TipRow(icon: AppIcons.check, text: 'Tap the circle to complete a set'),
            SizedBox(height: 8.h),
            _TipRow(icon: AppIcons.edit, text: 'Edit weight, reps, and RIR for each set'),
            SizedBox(height: 8.h),
            _TipRow(icon: AppIcons.timer, text: 'Rest timer starts automatically after each set'),
            SizedBox(height: 8.h),
            _TipRow(
              icon: AppIcons.trendingUp,
              text: 'Weights auto-adjust next session based on performance',
            ),
          ],
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14.r, color: context.primaryColor),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
          ),
        ),
      ],
    );
  }
}
