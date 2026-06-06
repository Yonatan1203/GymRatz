import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants.dart';
import '../../../theme/app_icons.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/menu_item_widget.dart';
import '../../../shared/widgets/scale_tap.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/staggered_list.dart';
import '../../../shared/widgets/stats_grid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../shared/data/sample_data.dart';
import '../../../shared/models/personal_record.dart';
import '../../../shared/utils/weight_utils.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context, ref),
              Padding(
                padding: EdgeInsets.all(AppSpacing.screenPadding),
                child: StaggeredList(
                  children: [
                    _buildPersonalRecords(context, ref),
                    SizedBox(height: AppSpacing.sectionGap),
                    _buildActivityHeatmap(context, ref),
                    SizedBox(height: AppSpacing.sectionGap),
                    _buildMenuSection(context, 'WORKOUTS & TRAINING', [
                      MenuItemWidget(icon: AppIcons.dumbbell, label: 'Exercises', onTap: () => context.push('/exercises')),
                      MenuItemWidget(icon: AppIcons.heart, label: 'Favorites', onTap: () => context.push('/favorites')),
                      MenuItemWidget(icon: AppIcons.trendingUp, label: 'Progress', onTap: () => context.push('/progress')),
                      MenuItemWidget(
                        icon: AppIcons.trophy,
                        label: 'Achievements',
                        badge: '${(ref.watch(achievementsProvider).valueOrNull ?? []).length}',
                        onTap: () => context.push('/achievements'),
                      ),
                      MenuItemWidget(icon: AppIcons.calendar, label: 'Calendar', onTap: () => context.go('/calendar')),
                    ]),
                    SizedBox(height: AppSpacing.sectionGap),
                    _buildMenuSection(context, 'ACCOUNT', [
                      MenuItemWidget(icon: AppIcons.settings, label: 'Settings', onTap: () => context.push('/settings')),
                    ]),
                    SizedBox(height: AppSpacing.sectionGap),
                    _buildSignOut(context, ref),
                    SizedBox(height: AppSpacing.xxl),
                    Center(
                      child: Text('GymRatz v${AppConstants.appVersion}', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                    ),
                    SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).valueOrNull ?? SampleData.user;
    final stats = ref.watch(workoutStatsProvider).valueOrNull ?? {};
    final achievements = ref.watch(achievementsProvider).valueOrNull ?? [];
    final totalWorkouts = stats['totalWorkouts'] ?? 0;
    final streak = stats['streak'] ?? 0;
    final badgeCount = achievements.length;

    final subtitle = user.createdAt != null
        ? 'Member since ${DateFormat.yMMMM().format(user.createdAt!)}'
        : user.experienceLevel;

    return GradientHeader(
      actions: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/profile/edit');
          },
          child: Icon(AppIcons.edit, size: 22.r, color: context.foreground),
        ),
      ],
      child: Column(
        children: [
          Container(
            width: 96.r,
            height: 96.r,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha:0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(user.initials, style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.w700, color: context.foreground)),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(user.name, style: AppTextStyles.h2.copyWith(color: context.foreground, fontWeight: FontWeight.w600)),
          SizedBox(height: AppSpacing.sm),
          Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
          SizedBox(height: AppSpacing.xl),
          StatsGrid(
            useTransparentBg: true,
            items: [
              StatsGridItem(icon: AppIcons.flame, iconColor: context.primaryColor, value: '$totalWorkouts', label: 'Workouts'),
              StatsGridItem(icon: AppIcons.flame, iconColor: context.coralColor, value: '$streak', label: 'Streak'),
              StatsGridItem(icon: AppIcons.award, iconColor: context.primaryColor, value: '$badgeCount', label: 'Badges'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalRecords(BuildContext context, WidgetRef ref) {
    final prsAsync = ref.watch(personalRecordsProvider);
    final allPrs = prsAsync.valueOrNull ?? <PersonalRecord>[];
    final userUnit = ref.watch(userProfileProvider).valueOrNull?.unit ?? 'lbs';
    // Show top 5 sorted by most recent; "View All" in the header goes to /progress.
    final prs = (allPrs.toList()..sort((a, b) => b.date.compareTo(a.date))).take(5).toList();

    return Column(
      children: [
        SectionHeader(title: 'PERSONAL RECORDS', actionText: 'View All', onAction: () => context.push('/progress')),
        SizedBox(height: AppSpacing.lg),
        if (prs.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Text('No personal records yet. Complete workouts to set PRs!', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
          ),
        ...prs.map((pr) {
          // Convert stored weight to user's current unit when known; for legacy
          // records without a unit field, display the stored value as-is.
          final displayWeight = pr.unit.isNotEmpty && pr.unit != userUnit
              ? WeightUtils.convert(pr.weight, pr.unit, userUnit)
              : pr.weight;
          final displayFormatted = WeightUtils.format(displayWeight, userUnit);
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: ScaleTap(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/progress');
              },
              child: CustomCard(
                variant: CardVariant.standard,
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40.r,
                      height: 40.r,
                      child: Center(child: Icon(AppIcons.trophy, size: 20.r, color: context.primaryColor)),
                    ),
                    SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pr.exerciseName, style: AppTextStyles.bodySmall.copyWith(color: context.foreground, fontWeight: FontWeight.w500)),
                          Text('${pr.date.month}/${pr.date.day}/${pr.date.year}', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                        ],
                      ),
                    ),
                    Text(
                      displayFormatted,
                      style: AppTextStyles.h4.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(width: AppSpacing.md),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Share.share(
                          '🏆 New PR: ${pr.exerciseName} — $displayFormatted × ${pr.reps} reps 💪 #GymRatz',
                        );
                      },
                      child: Icon(AppIcons.share2, size: 16.r, color: context.mutedForeground),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActivityHeatmap(BuildContext context, WidgetRef ref) {
    final recentWorkoutsAsync = ref.watch(activityHeatmapProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'ACTIVITY'),
        SizedBox(height: AppSpacing.lg),
        recentWorkoutsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              'Could not load activity',
              style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
            ),
          ),
          data: (workouts) {
            if (workouts.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(
                  'No activity yet. Complete a workout to see your history here.',
                  style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
                ),
              );
            }
            final workoutCounts = <String, int>{};
            for (final w in workouts) {
              final key = '${w.date.year}-${w.date.month}-${w.date.day}';
              workoutCounts[key] = (workoutCounts[key] ?? 0) + 1;
            }

            final today = DateTime.now();
            final mondayThis = today.subtract(Duration(days: today.weekday - 1));
            final heatmapStart = mondayThis.subtract(const Duration(days: 7 * 11));
            const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

            return CustomCard(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: dayLabels.map((l) => Expanded(
                        child: Center(
                          child: Text(
                            l,
                            style: AppTextStyles.caption.copyWith(
                              color: context.mutedForeground,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )).toList(),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 3.r,
                        crossAxisSpacing: 3.r,
                        childAspectRatio: 1,
                      ),
                      itemCount: 84,
                      itemBuilder: (ctx, i) {
                        final cell = heatmapStart.add(Duration(days: i));
                        final key = '${cell.year}-${cell.month}-${cell.day}';
                        final count = workoutCounts[key] ?? 0;
                        final isFuture = cell.isAfter(today);

                        final Color cellColor;
                        if (isFuture || count == 0) {
                          cellColor = context.mutedColor;
                        } else if (count == 1) {
                          cellColor = context.primaryColor.withValues(alpha: 0.5);
                        } else {
                          cellColor = context.primaryColor;
                        }
                        return Container(
                          decoration: BoxDecoration(
                            color: cellColor,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSignOut(BuildContext context, WidgetRef ref) {
    return CustomCard(
      variant: CardVariant.standard,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: MenuItemWidget(
        icon: AppIcons.logOut,
        label: 'Sign Out',
        iconColor: context.destructiveColor,
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Sign Out'),
              content: const Text('Are you sure you want to sign out?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: TextButton.styleFrom(foregroundColor: context.destructiveColor),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          );
          if (confirmed != true) return;
          if (!context.mounted) return;
          final authService = ref.read(authServiceProvider);
          await authService.signOut();
          if (context.mounted) context.go('/onboarding');
        },
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.caption.copyWith(color: context.mutedForeground, fontWeight: FontWeight.w600, letterSpacing: 1)),
        SizedBox(height: AppSpacing.md),
        CustomCard(
          variant: CardVariant.standard,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(children: items),
        ),
      ],
    );
  }
}
