import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
import '../../../shared/widgets/section_header.dart';
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
              child: Column(
                children: [
                  _buildStatsGrid(context, isDark, ref),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildTodaysWorkout(context, isDark),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildQuickActions(context, isDark),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildRecentActivity(context, isDark, ref),
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, WidgetRef ref) {
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const today = 2;

    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final stats = ref.watch(workoutStatsProvider).valueOrNull;

    final firstName = userProfile?.name.split(' ').first ?? 'there';
    final initials = userProfile?.initials ?? '--';
    final streak = stats?['streak'] as int? ?? 0;

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
              Row(
                children: [
                  Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(initials, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                  const Spacer(),
                  Text('GymRatz', style: AppTextStyles.h2.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
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
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(LucideIcons.user, size: 18.r, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xxl),
              Text(
                'Hi, $firstName \u{1F44B}',
                style: AppTextStyles.h2.copyWith(color: Colors.white),
              ),
              SizedBox(height: 4.h),
              Row(
                children: [
                  Icon(LucideIcons.flame, size: 16.r, color: Colors.white.withValues(alpha: 0.9)),
                  SizedBox(width: 6.w),
                  Text(
                    '$streak day streak',
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xxl),
              SizedBox(
                height: 80.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: weekDays.length,
                  separatorBuilder: (_, __) => SizedBox(width: 8.w),
                  itemBuilder: (context, index) {
                    final isToday = index == today;
                    return Container(
                      width: 56.w,
                      decoration: BoxDecoration(
                        color: isToday ? Colors.white : Colors.white.withValues(alpha: 0.2),
                        borderRadius: AppRadius.borderLg,
                        boxShadow: AppShadows.md,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            weekDays[index],
                            style: AppTextStyles.caption.copyWith(
                              color: isToday
                                  ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                                  : Colors.white,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${index + 10}',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: isToday
                                  ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                                  : Colors.white,
                            ),
                          ),
                          if (index < today) ...[
                            SizedBox(height: 4.h),
                            Container(
                              width: 6.r,
                              height: 6.r,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
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
        ),
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
          icon: LucideIcons.flame,
          iconColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          value: '$totalWorkouts',
          label: 'Workouts',
        ),
        StatsGridItem(
          icon: LucideIcons.trendingUp,
          iconColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
          value: formatVolume(weeklyVolume),
          label: 'Weekly Vol',
        ),
        StatsGridItem(
          icon: LucideIcons.award,
          iconColor: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
          value: recentPRWeight,
          label: 'Recent PR',
        ),
      ],
    );
  }

  Widget _buildTodaysWorkout(BuildContext context, bool isDark) {
    return Column(
      children: [
        SectionHeader(
          title: "Today's Workout",
          actionText: 'View All',
          onAction: () => context.go('/today'),
        ),
        SizedBox(height: AppSpacing.lg),
        Semantics(
          button: true,
          label: 'Start Push Day workout',
          child: GestureDetector(
          onTap: () => context.push('/workout/1'),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              gradient: AppGradients.primary(isDark: isDark),
              borderRadius: AppRadius.borderXl,
              boxShadow: AppShadows.lg,
            ),
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
                          Text('Push Day', style: AppTextStyles.h3.copyWith(color: Colors.white)),
                          SizedBox(height: 4.h),
                          Text('Upper Body Strength', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                    Container(
                      width: 48.r,
                      height: 48.r,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.play, size: 24.r, color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Text('6 Exercises', style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Text('\u2022', style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
                    ),
                    Text('45-60 min', style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: AppRadius.borderLg,
                        ),
                        child: Column(
                          children: [
                            Text('Sets', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                            Text('18', style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: AppRadius.borderLg,
                        ),
                        child: Column(
                          children: [
                            Text('Volume', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                            Text('4,200kg', style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),
      ],
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
              child: CustomCard(
                onTap: () => context.push('/progress'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.trendingUp, size: 24.r, color: context.primaryColor),
                    SizedBox(height: 8.h),
                    Text('Progress', style: AppTextStyles.h4.copyWith(color: context.foreground, fontWeight: FontWeight.w500)),
                    Text('View stats', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: CustomCard(
                onTap: () => context.go('/programs'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.award, size: 24.r, color: context.secondaryColor),
                    SizedBox(height: 8.h),
                    Text('Programs', style: AppTextStyles.h4.copyWith(color: context.foreground, fontWeight: FontWeight.w500)),
                    Text('Browse all', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                  ],
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
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Text(
                  'No recent workouts yet',
                  style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
                ),
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
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: CustomCard(
                    padding: EdgeInsets.all(12.r),
                    child: Row(
                      children: [
                        Container(
                          width: 40.r,
                          height: 40.r,
                          decoration: BoxDecoration(
                            color: context.mutedColor,
                            borderRadius: AppRadius.borderLg,
                          ),
                          child: Icon(LucideIcons.flame, size: 20.r, color: context.primaryColor),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: AppTextStyles.bodySmall.copyWith(color: context.foreground, fontWeight: FontWeight.w500)),
                              Text(statusLabel, style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                            ],
                          ),
                        ),
                        Icon(LucideIcons.chevronRight, size: 20.r, color: context.mutedForeground),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
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
