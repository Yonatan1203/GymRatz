import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_icons.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../shared/utils/extensions.dart';

class ProgramScreenHeader extends StatelessWidget {
  final bool isEditing;
  final bool saving;
  final VoidCallback onSave;

  const ProgramScreenHeader({
    super.key,
    required this.isEditing,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenPadding, 8.h, AppSpacing.screenPadding, 16.h,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Padding(
                  padding: EdgeInsets.all(8.r),
                  child: Icon(AppIcons.arrowLeft, size: 20.r, color: context.foreground),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  isEditing ? 'Edit Program' : 'Create Program',
                  style: AppTextStyles.h2.copyWith(color: context.foreground),
                ),
              ),
              GestureDetector(
                onTap: saving ? null : onSave,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: saving ? context.mutedForeground : context.primaryColor,
                    borderRadius: AppRadius.borderLg,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (saving)
                        SizedBox(
                          width: 16.r,
                          height: 16.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      else
                        Icon(
                          AppIcons.save,
                          size: 16.r,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      SizedBox(width: 4.w),
                      Text(
                        saving ? 'Saving...' : 'Save',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
