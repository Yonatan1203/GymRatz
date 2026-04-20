import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:gymratz/shared/widgets/skeleton_loader.dart';
import 'package:gymratz/shared/widgets/fade_in.dart';
import 'package:gymratz/shared/widgets/slide_up.dart';
import 'package:gymratz/shared/utils/extensions.dart';
import 'package:gymratz/theme/app_spacing.dart';
import 'package:gymratz/theme/app_radius.dart';
import 'package:gymratz/theme/app_icons.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget Function()? loading;
  final Widget Function(Object error, StackTrace? stack)? error;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => loading?.call() ?? _defaultLoading(),
      error: (e, s) => error?.call(e, s) ?? _defaultError(context, e),
    );
  }

  Widget _defaultLoading() {
    return SkeletonLoader(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: [
            SkeletonCard(height: 80),
            SizedBox(height: AppSpacing.itemGap),
            SkeletonCard(height: 80),
            SizedBox(height: AppSpacing.itemGap),
            SkeletonCard(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _defaultError(BuildContext context, Object error) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon container
            FadeIn(
              delay: Duration.zero,
              child: Container(
                width: 64.r,
                height: 64.r,
                decoration: BoxDecoration(
                  color: context.destructiveColor.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderXl,
                  border: Border.all(
                    color: context.destructiveColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Center(
                  child: Icon(
                    AppIcons.alertCircle,
                    size: 28.sp,
                    color: context.destructiveColor,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // Title
            SlideUp(
              delay: const Duration(milliseconds: 100),
              child: Text(
                'Something went wrong',
                style: theme.textTheme.titleMedium,
              ),
            ),
            SizedBox(height: 8.h),
            // Error message
            FadeIn(
              delay: const Duration(milliseconds: 200),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 260.w),
                child: Text(
                  error.toString(),
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
