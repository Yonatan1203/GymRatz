import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../utils/extensions.dart';
import 'app_bottom_sheet.dart';

/// Tappable dropdown-style field that opens a [showAppBottomSheet] picker.
///
/// Pass [onDark] when the field sits on a gradient background (e.g. inside a
/// workout day card header) — colours flip to contrast against the gradient
/// instead of the normal surface.
class SelectField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final bool onDark;
  final IconData? icon;
  final String? sheetTitle;

  const SelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.onDark = false,
    this.icon,
    this.sheetTitle,
  });

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final onPrimaryMuted = onPrimary.withValues(alpha: 0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: onDark ? onPrimaryMuted : context.mutedForeground,
            ),
          ),
          SizedBox(height: 8.h),
        ],
        GestureDetector(
          onTap: () => showAppBottomSheet(
            context,
            title: sheetTitle ?? label,
            currentValue: value,
            options: options,
            onChanged: onChanged,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: onDark ? onPrimary.withValues(alpha: 0.1) : context.mutedColor,
              borderRadius: AppRadius.borderLg,
              border: Border.all(
                color: onDark ? onPrimary.withValues(alpha: 0.2) : context.borderColor,
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16.r,
                    color: onDark ? onPrimaryMuted : context.mutedForeground,
                  ),
                  SizedBox(width: 8.w),
                ],
                Expanded(
                  child: Text(
                    value,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: onDark ? onPrimary : context.foreground,
                    ),
                  ),
                ),
                Icon(
                  AppIcons.chevronDown,
                  size: 16.r,
                  color: onDark ? onPrimaryMuted : context.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
