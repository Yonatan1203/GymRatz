import 'package:flutter/material.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';

/// Shows a modal bottom sheet with a scrollable list of selectable options.
///
/// Consolidates the two near-identical sheet implementations that existed in
/// create_program_screen.dart (`_showConfigSheet` / `_showSelectionSheet`).
/// Use [displayTransform] to map raw option strings to display labels (e.g.
/// '30' → '30s').
void showAppBottomSheet(
  BuildContext context, {
  required String title,
  required String currentValue,
  required List<String> options,
  required ValueChanged<String> onChanged,
  String Function(String)? displayTransform,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final colorScheme = Theme.of(ctx).colorScheme;
      final fg = colorScheme.onSurface;
      final mutedFg = colorScheme.onSurfaceVariant;
      final primaryColor = colorScheme.primary;

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: mutedFg.withValues(alpha: 0.3),
                  borderRadius: AppRadius.borderFull,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(title, style: AppTextStyles.h3.copyWith(color: fg)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Icon(AppIcons.x, size: 20, color: mutedFg),
                    ),
                  ],
                ),
              ),
              Divider(color: mutedFg.withValues(alpha: 0.15), height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: options.map((option) {
                    final display = displayTransform != null ? displayTransform(option) : option;
                    final isSelected = option == currentValue ||
                        (displayTransform != null && display == currentValue);
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        WidgetsBinding.instance
                            .addPostFrameCallback((_) => onChanged(option));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor.withValues(alpha: 0.08) : null,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                display,
                                style: AppTextStyles.body.copyWith(
                                  color: isSelected ? primaryColor : fg,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(AppIcons.check, size: 20, color: primaryColor),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}
