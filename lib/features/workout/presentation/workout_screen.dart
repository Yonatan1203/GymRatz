import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';

import '../../../app/providers.dart';
import '../../../theme/app_gradients.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/models/workout.dart';
import '../../../shared/models/workout_day.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_badge.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/scale_tap.dart';
import '../../../shared/widgets/staggered_list.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  static const _weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _weekDaysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final activeProgramAsync = ref.watch(activeProgramProvider);
    final recentWorkoutsAsync = ref.watch(recentWorkoutsProvider);

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
                final recentWorkouts = recentWorkoutsAsync.valueOrNull ?? [];
                return _buildWeeklyBody(context, isDark, days, recentWorkouts);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final mondayOffset = now.weekday - 1;
    final monday = now.subtract(Duration(days: mondayOffset));
    final sunday = monday.add(const Duration(days: 6));

    final dateRange = '${_months[monday.month - 1]} ${monday.day} - ${_months[sunday.month - 1]} ${sunday.day}';

    return GradientHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This Week', style: AppTextStyles.h1.copyWith(color: context.foreground)),
          SizedBox(height: AppSpacing.sm),
          Text(dateRange, style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
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

  Widget _buildWeeklyBody(BuildContext context, bool isDark, List<WorkoutDay> days, List<Workout> recentWorkouts) {
    final now = DateTime.now();
    final mondayOffset = now.weekday - 1;
    final monday = now.subtract(Duration(days: mondayOffset));

    // Map dayOfWeek string to WorkoutDay
    final dayMap = <String, WorkoutDay>{};
    for (final day in days) {
      dayMap[day.dayOfWeek] = day;
    }

    // Get completed workout day IDs for this week
    final completedDayIds = <String>{};
    for (final workout in recentWorkouts) {
      if (workout.status == WorkoutStatus.completed && workout.workoutDayId != null) {
        // Check if the workout date is within this week (Monday to Sunday)
        final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        if (!workout.date.isBefore(monday) && !workout.date.isAfter(sunday)) {
          completedDayIds.add(workout.workoutDayId!);
        }
      }
    }

    final dayRows = <Widget>[];
    for (int i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      final dayName = _weekDays[i];
      final dayShort = _weekDaysShort[i];
      final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
      final scheduledDay = dayMap[dayName];
      final isCompleted = scheduledDay != null && completedDayIds.contains(scheduledDay.id);
      final isPast = date.isBefore(DateTime(now.year, now.month, now.day)) && !isToday;

      dayRows.add(
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: _buildDayRow(
            context,
            isDark,
            dayShort: dayShort,
            dayName: dayName,
            dateNum: date.day,
            isToday: isToday,
            isPast: isPast,
            workoutDay: scheduledDay,
            isCompleted: isCompleted,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: StaggeredList(
        children: [
          ...dayRows,
          SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildDayRow(
    BuildContext context,
    bool isDark, {
    required String dayShort,
    required String dayName,
    required int dateNum,
    required bool isToday,
    required bool isPast,
    required WorkoutDay? workoutDay,
    required bool isCompleted,
  }) {
    final isRestDay = workoutDay == null;
    final isMissed = isPast && !isRestDay && !isCompleted;

    return ScaleTap(
      onTap: isRestDay
          ? null
          : () => _onDayTapped(context, dayName, isToday, workoutDay),
      child: CustomCard(
        padding: EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          children: [
            // Date circle
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isToday ? AppGradients.primary(isDark: isDark) : null,
                color: isToday ? null : context.mutedColor,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayShort,
                    style: AppTextStyles.caption.copyWith(
                      color: isToday ? Colors.white : context.mutedForeground,
                      fontWeight: FontWeight.w600,
                      fontSize: 9.sp,
                    ),
                  ),
                  Text(
                    '$dateNum',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isToday ? Colors.white : context.foreground,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.lg),
            // Workout info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRestDay ? 'Rest Day' : workoutDay.name,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isRestDay ? context.mutedForeground : context.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!isRestDay) ...[
                    SizedBox(height: 2.h),
                    Text(
                      '${workoutDay.exercises.length} exercises',
                      style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
                    ),
                  ],
                ],
              ),
            ),
            // Status badge
            if (!isRestDay)
              _buildStatusBadge(context, isCompleted: isCompleted, isMissed: isMissed, isToday: isToday),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, {required bool isCompleted, required bool isMissed, required bool isToday}) {
    if (isCompleted) {
      return CustomBadge(
        text: 'Done',
        icon: AppIcons.check,
        backgroundColor: context.primaryColor.withValues(alpha: 0.12),
        textColor: context.primaryColor,
      );
    }
    if (isMissed) {
      return CustomBadge(
        text: 'Missed',
        backgroundColor: context.destructiveColor.withValues(alpha: 0.12),
        textColor: context.destructiveColor,
      );
    }
    if (isToday) {
      return CustomBadge(
        text: 'Today',
        icon: AppIcons.play,
        backgroundColor: context.coralColor.withValues(alpha: 0.12),
        textColor: context.coralColor,
      );
    }
    return CustomBadge(
      text: 'Scheduled',
      backgroundColor: context.mutedColor,
      textColor: context.mutedForeground,
    );
  }

  Future<void> _onDayTapped(BuildContext context, String dayName, bool isToday, WorkoutDay workoutDay) async {
    if (isToday) {
      context.push('/workout/${workoutDay.id}');
      return;
    }

    final confirmed = await _showDifferentDayDialog(context, dayName);
    if (confirmed && context.mounted) {
      context.push('/workout/${workoutDay.id}');
    }
  }

  Future<bool> _showDifferentDayDialog(BuildContext context, String dayName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Different Day'),
        content: Text('This workout is scheduled for $dayName. Are you sure you want to log it today?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Start Anyway'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
