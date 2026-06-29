import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import '../utils/extensions.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.h3.copyWith(color: context.foreground),
        ),
        if (actionText != null)
          // TextButton provides: Material ripple, 48dp minimum tap target,
          // correct button semantics, and keyboard focus — unlike GestureDetector.
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: context.primaryColor,
              textStyle: AppTextStyles.bodySmall,
              // Shrink visual padding while keeping 48dp touch target via tapTargetSize.
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.padded,
              minimumSize: Size.zero,
            ),
            child: Text(actionText!),
          ),
      ],
    );
  }
}
