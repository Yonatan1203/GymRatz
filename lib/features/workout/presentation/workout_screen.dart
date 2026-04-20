import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';

import '../../../app/providers.dart';
import '../../../theme/app_gradients.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/custom_badge.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/scale_tap.dart';
import '../../../shared/widgets/staggered_list.dart';
import '../../../shared/widgets/stats_grid.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final activeProgramAsync = ref.watch(activeProgramProvider);
    final stats = ref.watch(workoutStatsProvider).valueOrNull;

    return Scaffold(
      body: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context),
              activeProgramAsync.when(
              loading: () => _buildLoadingBody(context),
              error: (e, _) => _buildErrorBody(context, ref, e),
              data: (activeProgram) {
                final days = activeProgram?.days ?? [];
                if (days.isEmpty) {
                  return _buildEmptyBody(context, isDark);
                }
                return _buildContentBody(context, isDark, days, stats);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return GradientHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Workouts", style: AppTextStyles.h1.copyWith(color: context.foreground)),
          SizedBox(height: AppSpacing.sm),
          Text(Formatters.dayDate(DateTime.now()), style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
        ],
      ),
    );
  }

  Widget _buildLoadingBody(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          SizedBox(height: 80.h),
          CircularProgressIndicator(color: context.primaryColor),
          SizedBox(height: AppSpacing.xl),
          Text('Loading your workouts...', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
        ],
      ),
    );
  }

  Widget _buildErrorBody(BuildContext context, WidgetRef ref, Object error) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          SizedBox(height: 60.h),
          Icon(AppIcons.alertCircle, size: 48.r, color: context.destructiveColor),
          SizedBox(height: AppSpacing.xl),
          Text('Something went wrong', style: AppTextStyles.h3.copyWith(color: context.foreground)),
          SizedBox(height: AppSpacing.md),
          Text('Could not load your workouts. Please try again.', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground), textAlign: TextAlign.center),
          SizedBox(height: AppSpacing.sectionGap),
          CustomButton(
            text: 'Retry',
            variant: ButtonVariant.outline,
            icon: AppIcons.refreshCw,
            onPressed: () => ref.invalidate(activeProgramProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBody(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          SizedBox(height: 40.h),
          CustomCard(
            child: Column(
              children: [
                SizedBox(height: AppSpacing.xl),
                Icon(AppIcons.dumbbell, size: 36.r, color: context.primaryColor),
                SizedBox(height: 20.h),
                Text('No Main Program', style: AppTextStyles.h3.copyWith(color: context.foreground, fontWeight: FontWeight.w600)),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Set a main program to see your weekly workouts here.',
                  style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.sectionGap),
                CustomButton(
                  text: 'Browse Programs',
                  variant: ButtonVariant.gradient,
                  icon: AppIcons.list,
                  onPressed: () => context.go('/programs'),
                ),
                SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildContentBody(BuildContext context, bool isDark, List days, Map<String, dynamic>? stats) {
    final weeklyWorkouts = stats?['weeklyWorkouts'] as int? ?? 0;
    final totalDays = days.length;
    final remaining = (totalDays - weeklyWorkouts).clamp(0, totalDays);
    final pct = totalDays > 0 ? ((weeklyWorkouts / totalDays) * 100).round() : 0;

    final dayCards = days.asMap().entries.map((entry) {
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
    }).toList();

    return Padding(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: StaggeredList(
        children: [
          ...dayCards,
          SizedBox(height: AppSpacing.sectionGap),
          _buildWeeklyStats(context, isDark, weeklyWorkouts, remaining, pct),
          SizedBox(height: AppSpacing.xxl),
        ],
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
    return ScaleTap(
      onTap: () => context.push('/workout/$dayId'),
      child: CustomCard(
        variant: CardVariant.workout,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(AppSpacing.cardPadding),
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
                            ? context.coralColor.withOpacity(0.12)
                            : context.mutedColor,
                        textColor: isReady ? context.coralColor : context.mutedForeground,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Icon(AppIcons.dumbbell, size: 14.r, color: context.mutedForeground),
                      SizedBox(width: AppSpacing.sm),
                      Text('$exercises exercises', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
                      Text('  \u2022  ', style: TextStyle(color: context.mutedForeground)),
                      Icon(AppIcons.clock, size: 14.r, color: context.mutedForeground),
                      SizedBox(width: AppSpacing.sm),
                      Text(duration, style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
                    ],
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      _miniStat(context, 'Total Sets', '$sets'),
                      SizedBox(width: AppSpacing.md),
                      _miniStat(context, 'Est. Volume', '$volume kg'),
                    ],
                  ),
                ],
              ),
            ),
            if (isReady)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
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
                    SizedBox(
                      width: 28.r,
                      height: 28.r,
                      child: Center(child: Icon(AppIcons.play, size: 16.r, color: Colors.white)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(BuildContext context, String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
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
          SizedBox(height: AppSpacing.sm),
          Text(
            pct >= 100
                ? 'All workouts done \u2014 great week!'
                : pct >= 50
                    ? 'Keep it up, you\u2019re on track!'
                    : 'Let\u2019s get moving this week!',
            style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
          ),
          SizedBox(height: AppSpacing.xl),
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
