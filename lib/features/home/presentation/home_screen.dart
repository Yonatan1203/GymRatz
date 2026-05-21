import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';

import '../../../app/providers.dart';
import '../../../shared/models/enums.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_gradients.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/scale_tap.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/staggered_list.dart';
import '../../../shared/widgets/stats_grid.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;

    return Scaffold(
      body: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context, isDark, ref),
              Padding(
                padding: EdgeInsets.all(AppSpacing.screenPadding),
                child: StaggeredList(
                  children: [
                    _buildStatsGrid(context, isDark, ref),
                    SizedBox(height: AppSpacing.sectionGap),
                    _buildTodaysWorkout(context, isDark, ref),
                    SizedBox(height: AppSpacing.sectionGap),
                    _buildQuickActions(context, isDark),
                    SizedBox(height: AppSpacing.sectionGap),
                    _buildRecentActivity(context, isDark, ref),
                    SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, WidgetRef ref) {
    final dayAbbrev = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Show 21 days: 10 before today, today, 10 after
    const totalDays = 21;
    const centerIndex = 10;
    final startDate = today.subtract(const Duration(days: centerIndex));

    // Get active program's scheduled days
    final activeProgram = ref.watch(activeProgramProvider).valueOrNull;
    final scheduledDayNames = <String>{};
    if (activeProgram != null) {
      for (final day in activeProgram.days) {
        scheduledDayNames.add(day.dayOfWeek);
      }
    }

    // Get completed workout dates
    final recentWorkouts = ref.watch(recentWorkoutsProvider).valueOrNull ?? [];
    final completedDates = <DateTime>{};
    for (final workout in recentWorkouts) {
      if (workout.status == WorkoutStatus.completed) {
        completedDates.add(DateTime(workout.date.year, workout.date.month, workout.date.day));
      }
    }

    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final stats = ref.watch(workoutStatsProvider).valueOrNull;

    final firstName = userProfile?.name.split(' ').first ?? 'there';
    final initials = userProfile?.initials ?? '--';
    final streak = stats?['streak'] as int? ?? 0;

    // ScrollController to center today
    final scrollController = ScrollController(
      initialScrollOffset: centerIndex * (56.w + AppSpacing.md) - (MediaQuery.of(context).size.width / 2) + 28.w,
    );

    return GradientHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha:0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(initials, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: context.foreground)),
                ),
              ),
              const Spacer(),
              Text('GymRatz', style: AppTextStyles.h2.copyWith(color: context.foreground, fontWeight: FontWeight.w700)),
              const Spacer(),
              Semantics(
                button: true,
                label: 'Go to profile',
                child: GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha:0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(AppIcons.user, size: 18.r, color: context.foreground),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xxl),
          Text(
            'Hi, $firstName \u{1F44B}',
            style: AppTextStyles.h2.copyWith(color: context.foreground),
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: context.coralColor.withValues(alpha:0.12),
                  borderRadius: AppRadius.borderLg,
                  border: Border.all(color: context.coralColor.withValues(alpha:0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.flame, size: 16.r, color: context.coralColor),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      '$streak day streak',
                      style: AppTextStyles.bodySmall.copyWith(color: context.coralColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xxl),
          SizedBox(
            height: 80.h,
            child: ListView.separated(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: totalDays,
              separatorBuilder: (_, __) => SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final date = startDate.add(Duration(days: index));
                final isToday = date == today;
                final hasCompleted = completedDates.contains(date);
                final dayName = dayNames[date.weekday - 1];
                final isScheduled = scheduledDayNames.contains(dayName);
                final isMissed = !hasCompleted && isScheduled && date.isBefore(today);

                // Color logic: completed=green, missed=red, scheduled(future)=primary, rest=muted
                Color bgColor;
                Color textColor;
                Color dayTextColor;
                Border? border;

                if (isToday) {
                  bgColor = context.primaryColor.withValues(alpha: 0.15);
                  textColor = context.primaryColor;
                  dayTextColor = context.primaryColor;
                  border = Border.all(color: context.primaryColor.withValues(alpha: 0.4), width: 1.5);
                } else if (hasCompleted) {
                  bgColor = Colors.green.withValues(alpha: 0.12);
                  textColor = Colors.green;
                  dayTextColor = Colors.green;
                  border = null;
                } else if (isMissed) {
                  bgColor = context.destructiveColor.withValues(alpha: 0.08);
                  textColor = context.destructiveColor.withValues(alpha: 0.7);
                  dayTextColor = context.destructiveColor.withValues(alpha: 0.7);
                  border = null;
                } else if (isScheduled) {
                  bgColor = context.primaryColor.withValues(alpha: 0.08);
                  textColor = context.foreground;
                  dayTextColor = context.mutedForeground;
                  border = null;
                } else {
                  bgColor = context.primaryColor.withValues(alpha: 0.04);
                  textColor = context.foreground.withValues(alpha: 0.5);
                  dayTextColor = context.mutedForeground.withValues(alpha: 0.6);
                  border = null;
                }

                return Container(
                  width: 56.w,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: AppRadius.borderLg,
                    border: border,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayAbbrev[date.weekday - 1],
                        style: AppTextStyles.caption.copyWith(color: dayTextColor),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      if (hasCompleted) ...[
                        SizedBox(height: AppSpacing.sm),
                        Container(
                          width: 6.r,
                          height: 6.r,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ] else if (isScheduled && !isMissed && !isToday) ...[
                        SizedBox(height: AppSpacing.sm),
                        Container(
                          width: 6.r,
                          height: 6.r,
                          decoration: BoxDecoration(
                            color: context.primaryColor.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, bool isDark, WidgetRef ref) {
    final stats = ref.watch(workoutStatsProvider).valueOrNull;
    final prs = ref.watch(personalRecordsProvider).valueOrNull;

    final totalWorkouts = stats?['totalWorkouts'] as int? ?? 0;
    final weeklyVolume = stats?['weeklyVolume'] as double? ?? 0;
    final recentPRWeight = (prs != null && prs.isNotEmpty)
        ? prs.first.weight.toStringAsFixed(0)
        : '0';

    String formatVolume(double vol) {
      if (vol >= 1000) {
        final k = vol / 1000;
        return k == k.roundToDouble()
            ? '${k.toStringAsFixed(0)}k'
            : '${k.toStringAsFixed(1)}k';
      }
      return vol.toStringAsFixed(0);
    }

    return StatsGrid(
      items: [
        StatsGridItem(
          icon: AppIcons.flame,
          iconColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          value: '$totalWorkouts',
          label: 'Workouts',
        ),
        StatsGridItem(
          icon: AppIcons.trendingUp,
          iconColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
          value: formatVolume(weeklyVolume),
          label: 'Weekly Vol',
        ),
        StatsGridItem(
          icon: AppIcons.award,
          iconColor: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
          value: recentPRWeight,
          label: 'Recent PR',
        ),
      ],
    );
  }

  Widget _buildTodaysWorkout(BuildContext context, bool isDark, WidgetRef ref) {
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final todayName = dayNames[DateTime.now().weekday - 1];

    final programAsync = ref.watch(activeProgramProvider);

    return programAsync.when(
      data: (program) {
        if (program == null) {
          // No active program
          return Column(
            children: [
              SectionHeader(
                title: "Today's Workout",
                actionText: 'View All',
                onAction: () => context.go('/today'),
              ),
              SizedBox(height: AppSpacing.lg),
              CustomCard(
                child: Column(
                  children: [
                    Icon(AppIcons.dumbbell, size: 36.r, color: context.mutedForeground),
                    SizedBox(height: AppSpacing.lg),
                    Text('No Active Program', style: AppTextStyles.h3.copyWith(color: context.foreground)),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Set an active program to see your daily workouts here.',
                      style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        final todaysWorkout = program.days.where((d) => d.dayOfWeek == todayName).firstOrNull;

        if (todaysWorkout == null) {
          // Rest day
          return Column(
            children: [
              SectionHeader(
                title: "Today's Workout",
                actionText: 'View All',
                onAction: () => context.go('/today'),
              ),
              SizedBox(height: AppSpacing.lg),
              CustomCard(
                child: Column(
                  children: [
                    Icon(AppIcons.moon, size: 36.r, color: context.mutedForeground),
                    SizedBox(height: AppSpacing.lg),
                    Text('Rest Day', style: AppTextStyles.h3.copyWith(color: context.foreground)),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'No workout scheduled for today. Enjoy your recovery!',
                      style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        // Active workout for today
        final exerciseCount = todaysWorkout.exercises.length;
        final totalSets = todaysWorkout.exercises.fold<int>(0, (sum, e) => sum + e.sets);

        return Column(
          children: [
            SectionHeader(
              title: "Today's Workout",
              actionText: 'View All',
              onAction: () => context.go('/today'),
            ),
            SizedBox(height: AppSpacing.lg),
            ScaleTap(
              onTap: () => context.push('/workout/${todaysWorkout.id}'),
              child: CustomCard(
                variant: CardVariant.workout,
                gradient: AppGradients.primary(isDark: isDark),
                boxShadow: AppShadows.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(todaysWorkout.name, style: AppTextStyles.h3.copyWith(color: Colors.white)),
                              SizedBox(height: AppSpacing.sm),
                              Text(program.name, style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 48.r,
                          height: 48.r,
                          child: Center(child: Icon(AppIcons.play, size: 24.r, color: Colors.white)),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Text('$exerciseCount Exercises', style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Text('\u2022', style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
                        ),
                        Text('$totalSets Sets', style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => Column(
        children: [
          SectionHeader(
            title: "Today's Workout",
            actionText: 'View All',
            onAction: () => context.go('/today'),
          ),
          SizedBox(height: AppSpacing.lg),
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sectionGap),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
      error: (error, _) => Column(
        children: [
          SectionHeader(
            title: "Today's Workout",
            actionText: 'View All',
            onAction: () => context.go('/today'),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'Could not load workout',
            style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTextStyles.h3.copyWith(color: context.foreground)),
        SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: ScaleTap(
                onTap: () => context.push('/progress'),
                child: CustomCard(
                  variant: CardVariant.standard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(AppIcons.trendingUp, size: 24.r, color: context.primaryColor),
                      SizedBox(height: AppSpacing.md),
                      Text('Progress', style: AppTextStyles.h4.copyWith(color: context.foreground, fontWeight: FontWeight.w500)),
                      Text('View stats', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: ScaleTap(
                onTap: () => context.go('/programs'),
                child: CustomCard(
                  variant: CardVariant.standard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(AppIcons.award, size: 24.r, color: context.secondaryColor),
                      SizedBox(height: AppSpacing.md),
                      Text('Programs', style: AppTextStyles.h4.copyWith(color: context.foreground, fontWeight: FontWeight.w500)),
                      Text('Browse all', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, bool isDark, WidgetRef ref) {
    final recentWorkouts = ref.watch(recentWorkoutsProvider);

    return Column(
      children: [
        SectionHeader(title: 'Recent Activity', actionText: 'See All', onAction: () {}),
        SizedBox(height: AppSpacing.lg),
        recentWorkouts.when(
          data: (workouts) {
            if (workouts.isEmpty) {
              return EmptyStateWidget(
                icon: AppIcons.dumbbell,
                title: 'No recent activity',
                subtitle: 'Your completed workouts will appear here',
              );
            }
            return Column(
              children: workouts.map((workout) {
                final statusLabel = workout.status == WorkoutStatus.completed
                    ? 'Completed'
                    : workout.status == WorkoutStatus.inProgress
                        ? 'In Progress'
                        : workout.status == WorkoutStatus.missed
                            ? 'Missed'
                            : 'Scheduled';
                final exerciseCount = workout.exercises.length;
                final title = exerciseCount > 0
                    ? '$exerciseCount exercises \u2022 ${workout.totalVolume.toStringAsFixed(0)}kg'
                    : 'Workout';

                return Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: CustomCard(
                    variant: CardVariant.standard,
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40.r,
                          height: 40.r,
                          child: Center(child: Icon(AppIcons.flame, size: 20.r, color: context.primaryColor)),
                        ),
                        SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: AppTextStyles.bodySmall.copyWith(color: context.foreground, fontWeight: FontWeight.w500)),
                              Text(statusLabel, style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                            ],
                          ),
                        ),
                        Icon(AppIcons.chevronRight, size: 20.r, color: context.mutedForeground),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sectionGap),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sectionGap),
            child: Text(
              'Could not load recent activity',
              style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
            ),
          ),
        ),
      ],
    );
  }
}
