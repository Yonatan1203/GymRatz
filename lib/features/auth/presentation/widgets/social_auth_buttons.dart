import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SocialAuthButtons extends StatelessWidget {
  final VoidCallback onGooglePressed;
  final VoidCallback onApplePressed;
  final bool isLoading;

  const SocialAuthButtons({
    super.key,
    required this.onGooglePressed,
    required this.onApplePressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _dividerRow(theme),
        SizedBox(height: 16.h),
        _socialButton(
          context,
          label: 'Continue with Google',
          icon: Icons.g_mobiledata_rounded,
          onPressed: isLoading ? null : onGooglePressed,
        ),
        if (Platform.isIOS) ...[
          SizedBox(height: 12.h),
          _socialButton(
            context,
            label: 'Continue with Apple',
            icon: Icons.apple,
            onPressed: isLoading ? null : onApplePressed,
          ),
        ],
      ],
    );
  }

  Widget _dividerRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: Divider(color: theme.dividerColor)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text('or', style: theme.textTheme.bodySmall),
        ),
        Expanded(child: Divider(color: theme.dividerColor)),
      ],
    );
  }

  Widget _socialButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24.sp),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
          side: BorderSide(color: theme.dividerColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }
}
