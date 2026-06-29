import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_gradients.dart';
import '../../../../theme/app_icons.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../shared/utils/extensions.dart';
import '../../../../shared/utils/platform_adapter.dart';

class WorkoutScreenHeader extends StatelessWidget {
  final String workoutName;
  final String formattedElapsed;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onFinish;

  const WorkoutScreenHeader({
    super.key,
    required this.workoutName,
    required this.formattedElapsed,
    required this.saving,
    required this.onBack,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppGradients.primary(isDark: isDark),
        boxShadow: AppShadows.lg,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: 'Go back',
                child: GestureDetector(
                  onTap: () {
                    PlatformAdapter.hapticLight();
                    onBack();
                  },
                  child: Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: AppRadius.borderLg,
                    ),
                    child: Icon(AppIcons.arrowLeft, size: 20.r, color: Colors.white),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      workoutName,
                      style: AppTextStyles.h3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      formattedElapsed,
                      style: AppTextStyles.tabular.copyWith(
                        color: Colors.white70,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: 'Finish workout',
                child: GestureDetector(
                  onTap: saving ? null : () {
                    PlatformAdapter.hapticMedium();
                    onFinish();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: AppRadius.borderLg,
                    ),
                    child: saving
                        ? SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Finish',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
