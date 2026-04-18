import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: const CircularProgressIndicator(),
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
            Icon(Icons.error_outline, size: 48.sp, color: theme.colorScheme.error),
            SizedBox(height: 16.h),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: 8.h),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
