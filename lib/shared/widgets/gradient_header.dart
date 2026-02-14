import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_gradients.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../utils/platform_adapter.dart';

class GradientHeader extends StatelessWidget {
  final Widget child;
  final bool showBackButton;
  final List<Widget>? actions;

  const GradientHeader({
    super.key,
    required this.child,
    this.showBackButton = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppGradients.primary(isDark: isDark),
        boxShadow: AppShadows.lg,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            showBackButton ? 8.h : AppSpacing.xl,
            AppSpacing.screenPadding,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showBackButton || actions != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Row(
                    children: [
                      if (showBackButton)
                        Semantics(
                          button: true,
                          label: 'Go back',
                          child: GestureDetector(
                          onTap: () {
                            PlatformAdapter.hapticLight();
                            context.pop();
                          },
                          child: Container(
                            width: 40.r,
                            height: 40.r,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              LucideIcons.arrowLeft,
                              color: Colors.white,
                              size: 20.r,
                            ),
                          ),
                        ),
                        ),
                      const Spacer(),
                      if (actions != null) ...actions!,
                    ],
                  ),
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
