import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/app_gradients.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';

class UpsellBanner extends StatelessWidget {
  final String title;
  final String subtitle;

  const UpsellBanner({
    super.key,
    this.title = 'Upgrade to Pro',
    this.subtitle = 'Unlock unlimited programs & full history',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return GestureDetector(
      onTap: () => context.push('/paywall'),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          gradient: AppGradients.primary(isDark: isDark),
          borderRadius: AppRadius.borderXl,
          boxShadow: AppShadows.md,
        ),
        child: Row(
          children: [
            Icon(LucideIcons.crown, size: 24.r, color: Colors.white),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h4.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 20.r, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
