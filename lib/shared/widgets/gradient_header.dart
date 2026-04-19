import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_icons.dart';

import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../utils/extensions.dart';
import '../utils/platform_adapter.dart';

enum HeaderVariant { subtle, hero }

class GradientHeader extends StatelessWidget {
  final Widget child;
  final bool showBackButton;
  final List<Widget>? actions;
  final HeaderVariant variant;

  const GradientHeader({
    super.key,
    required this.child,
    this.showBackButton = false,
    this.actions,
    this.variant = HeaderVariant.subtle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: variant == HeaderVariant.hero
          ? BoxDecoration(
              gradient: AppGradients.primary(isDark: isDark),
              borderRadius: AppRadius.headerBottom,
              boxShadow: AppShadows.lg,
            )
          : BoxDecoration(
              color: isDark
                  ? context.primaryColor.withOpacity(0.12)
                  : context.primaryColor.withOpacity(0.08),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? context.primaryColor.withOpacity(0.15)
                      : context.primaryColor.withOpacity(0.12),
                  width: 1,
                ),
              ),
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
                          child: SizedBox(
                            width: 40.r,
                            height: 40.r,
                            child: Center(
                              child: Icon(
                                AppIcons.arrowLeft,
                                color: variant == HeaderVariant.hero
                                    ? Colors.white
                                    : context.foreground,
                                size: 20.r,
                              ),
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
