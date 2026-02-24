import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';

import '../../../app/providers.dart';
import '../../../theme/app_gradients.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_badge.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/stats_grid.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final activeProgram = ref.watch(activeProgramProvider).valueOrNull;
    final stats = ref.watch(workoutStatsProvider).valueOrNull;

    final days = activeProgram?.days ?? [];
    final weeklyWorkouts = stats?['weeklyWorkouts'] as int? ?? 0;
    final totalDays = days.length;
    final remaining = (totalDays - weeklyWorkouts).clamp(0, totalDays);
    final pct = totalDays > 0 ? ((weeklyWorkouts / totalDays) * 100).round() : 0;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (days.isEmpty)
                    ...[
                      _buildWorkoutCard(context, isDark, 'Push Day', 'Upper Body', 6, '45-60 min', 18, '4.2k', true, '1'),
                      SizedBox(height: AppSpacing.lg),
                      _buildWorkoutCard(context, isDark, 'Pull Day', 'Back & Biceps', 5, '40-50 min', 15, '4.2k', false, '2'),
                      SizedBox(height: AppSpacing.lg),
                      _buildWorkoutCard(context, isDark, 'Leg Day', 'Lower Body', 6, '50-65 min', 20, '5.1k', false, '3'),
                    ]
                  else
                    ...days.asMap().entries.map((entry) {
                      final i = entry.key;
                      final day = entry.value;
                      final exCount = day.exercises.length;
                      return Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.lg),
                        child: _buildWorkoutCard(
                          context, isDark,
                          day.name, day.dayOfWeek,
                          exCount, '${exCount * 8}-${exCount * 12} min',
                          exCount * 3, '--',
                          i == 0, day.id,
                        ),
                      );
                    }),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildWeeklyStats(context, isDark, weeklyWorkouts, remaining, pct),
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppGradients.primary(isDark: isDark),
        boxShadow: AppShadows.lg,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.screenPadding, 12.h, AppSpacing.screenPadding, AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today's Workouts", style: AppTextStyles.h1.copyWith(color: Colors.white)),
              SizedBox(height: 4.h),
              Text('Wednesday, Feb 12', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(
    BuildContext context,
    bool isDark,
    String name,
    String subtitle,
    int exercises,
    String duration,
    int sets,
    String volume,
    bool isReady,
    String dayId,
  ) {
    return CustomCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/workout/$dayId'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: AppTextStyles.h3.copyWith(color: context.foreground, fontWeight: FontWeight.w600)),
                          SizedBox(height: 2.h),
                          Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
                        ],
                      ),
                    ),
                    CustomBadge(
                      text: isReady ? 'Start Now' : 'Scheduled',
                      backgroundColor: isReady
                          ? context.primaryColor.withValues(alpha: 0.2)
                          : context.secondaryColor.withValues(alpha: 0.2),
                      textColor: isReady ? context.primaryColor : context.secondaryColor,
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Icon(AppIcons.dumbbell, size: 14.r, color: context.mutedForeground),
                    SizedBox(width: 4.w),
                    Text('$exercises exercises', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
                    Text('  \u2022  ', style: TextStyle(color: context.mutedForeground)),
                    Icon(AppIcons.clock, size: 14.r, color: context.mutedForeground),
                    SizedBox(width: 4.w),
                    Text(duration, style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    _miniStat(context, 'Total Sets', '$sets'),
                    SizedBox(width: 8.w),
                    _miniStat(context, 'Est. Volume', '$volume kg'),
                  ],
                ),
              ],
            ),
          ),
          if (isReady)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                gradient: AppGradients.primary(isDark: isDark),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(14.r),
                  bottomRight: Radius.circular(14.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Start Workout', style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                  Container(
                    width: 28.r,
                    height: 28.r,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(AppIcons.play, size: 16.r, color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _miniStat(BuildContext context, String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: context.mutedColor,
          borderRadius: AppRadius.borderLg,
        ),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
            Text(value, style: AppTextStyles.bodySmall.copyWith(color: context.foreground, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStats(BuildContext context, bool isDark, int completed, int remaining, int pct) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This Week', style: AppTextStyles.h3.copyWith(color: context.foreground)),
          SizedBox(height: 4.h),
          Text(
            pct >= 100
                ? 'All workouts done \u2014 great week!'
                : pct >= 50
                    ? 'Keep it up, you\u2019re on track!'
                    : 'Let\u2019s get moving this week!',
            style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
          ),
          SizedBox(height: 16.h),
          StatsGrid(
            items: [
              StatsGridItem(icon: AppIcons.checkCircle, iconColor: context.primaryColor, value: '$completed', label: 'Completed'),
              StatsGridItem(icon: AppIcons.clock, iconColor: context.secondaryColor, value: '$remaining', label: 'Remaining'),
              StatsGridItem(icon: AppIcons.trendingUp, iconColor: context.accentColor, value: '$pct%', label: 'Progress'),
            ],
          ),
        ],
      ),
    );
  }
}
