import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/staggered_list.dart';
import '../../../shared/widgets/stats_grid.dart';

class CoachDashboardScreen extends ConsumerWidget {
  const CoachDashboardScreen({super.key});

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
                  _buildClientsNeedingAttention(context, isDark, ref),
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
    final profile = ref.watch(coachProfileProvider).valueOrNull;
    final firstName = profile?.displayName.split(' ').first ?? 'Coach';

    return GradientHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: AppTextStyles.h2.copyWith(
              color: context.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Hi, Coach $firstName',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, bool isDark, WidgetRef ref) {
    final profile = ref.watch(coachProfileProvider).valueOrNull;
    final invites = ref.watch(coachInvitesProvider).valueOrNull ?? [];
    final clients = ref.watch(coachClientsProvider).valueOrNull ?? [];

    final clientCount = profile?.clientCount ?? 0;
    final maxClients = profile?.maxClients ?? 5;
    final pendingCount = invites.where((i) => i.isPending).length;
    final workoutsThisWeek = clients.length;

    return StatsGrid(
      items: [
        StatsGridItem(
          icon: AppIcons.users,
          iconColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          value: '$clientCount / $maxClients',
          label: 'Active Clients',
        ),
        StatsGridItem(
          icon: AppIcons.mail,
          iconColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
          value: '$pendingCount',
          label: 'Pending Invites',
        ),
        StatsGridItem(
          icon: AppIcons.dumbbell,
          iconColor: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
          value: '$workoutsThisWeek',
          label: 'Workouts/Wk',
        ),
      ],
    );
  }

  Widget _buildClientsNeedingAttention(
      BuildContext context, bool isDark, WidgetRef ref) {
    final clients = ref.watch(coachClientsProvider).valueOrNull ?? [];
    final now = DateTime.now();
    final inactiveClients = clients.where((c) {
      final daysSinceLinked = now.difference(c.linkedAt).inDays;
      return daysSinceLinked >= 3;
    }).toList();

    return Column(
      children: [
        SectionHeader(title: 'Clients Needing Attention'),
        SizedBox(height: AppSpacing.lg),
        if (inactiveClients.isEmpty)
          CustomCard(
            variant: CardVariant.standard,
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: [
                Icon(AppIcons.checkCircle, size: 20.r, color: context.primaryColor),
                SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Text(
                    'All clients are on track!',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...inactiveClients.map((client) {
            final daysInactive = now.difference(client.linkedAt).inDays;
            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: CustomCard(
                variant: CardVariant.standard,
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        color: context.coralColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(AppIcons.alertCircle,
                            size: 20.r, color: context.coralColor),
                      ),
                    ),
                    SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.clientName,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.foreground,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'No workout in $daysInactive days',
                            style: AppTextStyles.caption.copyWith(
                              color: context.coralColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(AppIcons.chevronRight,
                        size: 20.r, color: context.mutedForeground),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildRecentActivity(
      BuildContext context, bool isDark, WidgetRef ref) {
    final clients = ref.watch(coachClientsProvider).valueOrNull ?? [];

    return Column(
      children: [
        SectionHeader(title: 'Recent Activity'),
        SizedBox(height: AppSpacing.lg),
        if (clients.isEmpty)
          CustomCard(
            variant: CardVariant.standard,
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: [
                Icon(AppIcons.clock, size: 20.r, color: context.mutedForeground),
                SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Text(
                    'No recent client activity yet',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...clients.take(5).map((client) {
            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: CustomCard(
                variant: CardVariant.standard,
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(AppIcons.flame,
                            size: 20.r, color: context.primaryColor),
                      ),
                    ),
                    SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.clientName,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.foreground,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Completed a workout',
                            style: AppTextStyles.caption.copyWith(
                              color: context.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(AppIcons.chevronRight,
                        size: 20.r, color: context.mutedForeground),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
