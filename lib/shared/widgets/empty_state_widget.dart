import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:gymratz/shared/widgets/fade_in.dart';
import 'package:gymratz/shared/widgets/slide_up.dart';
import 'package:gymratz/shared/utils/extensions.dart';
import 'package:gymratz/theme/app_radius.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container
            FadeIn(
              delay: Duration.zero,
              child: Container(
                width: 64.r,
                height: 64.r,
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderXl,
                  border: Border.all(
                    color: context.primaryColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 28.sp,
                    color: context.primaryColor,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // Title
            SlideUp(
              delay: const Duration(milliseconds: 100),
              child: Text(
                title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 8.h),
            // Subtitle with max width constraint
            FadeIn(
              delay: const Duration(milliseconds: 200),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 260.w),
                child: Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 24.h),
              // Coral action button
              SlideUp(
                delay: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: onAction,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: context.coralColor.withValues(alpha: 0.08),
                      borderRadius: AppRadius.borderLg,
                      border: Border.all(
                        color: context.coralColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      actionLabel!,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: context.coralColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
