import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/providers.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/workout.dart';
import '../../../shared/models/workout_set.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/utils/weight_utils.dart';
import '../../../shared/widgets/custom_badge.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// Read-only view of a single workout's exercises, sets, and stats.
///
/// [initialWorkout] is the fast path — both call sites already hold the full
/// Workout in memory when they navigate here, so it's passed via route
/// `extra` to avoid a refetch. Falls back to fetching by [workoutId] via
/// [workoutByIdProvider] for cold-start/deep-link navigation, where `extra`
/// doesn't survive (mirrors the existing `/programs/detail/:id/edit` pattern).
class WorkoutDetailScreen extends ConsumerWidget {
  final String workoutId;
  final Workout? initialWorkout;

  const WorkoutDetailScreen({
    super.key,
    required this.workoutId,
    this.initialWorkout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initialWorkout != null) {
      return _buildBody(context, ref, initialWorkout!);
    }

    final asyncWorkout = ref.watch(workoutByIdProvider(workoutId));
    return asyncWorkout.when(
      data: (w) => w == null ? _buildNotFound(context) : _buildBody(context, ref, w),
      loading: () => _buildLoading(context),
      error: (_, __) => _buildError(context),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildError(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(showBackButton: true, child: SizedBox.shrink()),
          Expanded(
            child: EmptyStateWidget(
              icon: AppIcons.dumbbell,
              title: 'Could not load workout',
              subtitle: 'Something went wrong. Please try again.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(showBackButton: true, child: SizedBox.shrink()),
          Expanded(
            child: EmptyStateWidget(
              icon: AppIcons.dumbbell,
              title: 'Workout not found',
              subtitle: 'This workout may have been deleted.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, Workout workout) {
    final userUnit = ref.watch(userProfileProvider).valueOrNull?.unit ?? 'lbs';
    final statusLabel = switch (workout.status) {
      WorkoutStatus.completed => 'Completed',
      WorkoutStatus.inProgress => 'In Progress',
      WorkoutStatus.missed => 'Missed',
      WorkoutStatus.scheduled => 'Scheduled',
    };

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            showBackButton: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.dayDate(workout.date),
                  style: AppTextStyles.h2.copyWith(color: context.foreground),
                ),
                SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  children: [
                    CustomBadge(text: statusLabel),
                    if (workout.duration > 0)
                      CustomBadge(text: Formatters.duration(workout.duration ~/ 60)),
                    CustomBadge(text: '${Formatters.volume(workout.totalVolume)} $userUnit'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: workout.exercises.isEmpty
                ? EmptyStateWidget(
                    icon: AppIcons.dumbbell,
                    title: 'No exercises logged',
                    subtitle: 'This workout has no recorded exercises.',
                  )
                : ListView(
                    padding: EdgeInsets.all(AppSpacing.screenPadding),
                    children: [
                      ...workout.exercises.map(
                        (exercise) => Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.lg),
                          child: CustomCard(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise.name,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: context.foreground,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.md),
                                ...exercise.sets.asMap().entries.map(
                                  (entry) => _buildSetRow(context, entry.key + 1, entry.value, userUnit),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (workout.notes != null && workout.notes!.isNotEmpty) ...[
                        Text(
                          'Notes',
                          style: AppTextStyles.caption.copyWith(
                            color: context.mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          workout.notes!,
                          style: AppTextStyles.bodySmall.copyWith(color: context.foreground),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(BuildContext context, int setNumber, WorkoutSet set, String userUnit) {
    final parts = <String>[
      '${set.reps} reps',
      WeightUtils.format(set.weight, userUnit),
      if (set.rir != null) 'RIR ${set.rir}',
    ];
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          SizedBox(
            width: 28.w,
            child: Text(
              set.isWarmup ? 'W' : '$setNumber',
              style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
            ),
          ),
          Expanded(
            child: Text(
              parts.join(' • '),
              style: AppTextStyles.bodySmall.copyWith(
                color: set.completed ? context.foreground : context.mutedForeground,
              ),
            ),
          ),
          if (set.isAmrap)
            CustomBadge(text: 'AMRAP', backgroundColor: context.primaryColor.withValues(alpha: 0.15)),
        ],
      ),
    );
  }
}
