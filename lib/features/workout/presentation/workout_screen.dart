import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
                      _buildWorkoutCard(context, isDark, 'Push Day', 'Upper Body', 6, '45-60 min', 18, '4,200', true, '1'),
                      SizedBox(height: AppSpacing.lg),
                      _buildWorkoutCard(context, isDark, 'Pull Day', 'Back & Biceps', 5, '40-50 min', 15, '3,800', false, '2'),
                      SizedBox(height: AppSpacing.lg),
                      _buildWorkoutCard(context, isDark, 'Leg Day', 'Lower Body', 6, '50-65 min', 20, '5,100', false, '3'),
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
      onTap: () => context.push('/workout/$dayId'),
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
              Text('$exercises Exercises', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
              Text('  \u2022  ', style: TextStyle(color: context.mutedForeground)),
              Text(duration, style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _miniStat(context, 'Sets', '$sets'),
              SizedBox(width: 8.w),
              _miniStat(context, 'Volume', '${volume}kg'),
            ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('This Week', style: AppTextStyles.h3.copyWith(color: context.foreground)),
        SizedBox(height: AppSpacing.lg),
        StatsGrid(
          items: [
            StatsGridItem(icon: LucideIcons.checkCircle, iconColor: context.primaryColor, value: '$completed', label: 'Completed'),
            StatsGridItem(icon: LucideIcons.clock, iconColor: context.secondaryColor, value: '$remaining', label: 'Remaining'),
            StatsGridItem(icon: LucideIcons.trendingUp, iconColor: context.accentColor, value: '$pct%', label: 'Complete'),
          ],
        ),
      ],
    );
  }
}
