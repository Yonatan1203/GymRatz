import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';

import '../../../theme/app_gradients.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/gym_ratz_background.dart';
import '../../../shared/widgets/menu_item_widget.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stats_grid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../shared/data/sample_data.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;

    return Scaffold(
      body: GymRatzBackground(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context, isDark, ref),
              Padding(
                padding: EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  children: [
                    _buildPersonalRecords(context, ref),
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
                  _buildSubscriptionItem(context, ref),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildMenuSection(context, 'ACCOUNT', [
                    MenuItemWidget(icon: AppIcons.settings, label: 'Settings', onTap: () => context.push('/settings')),
                  ]),
                  SizedBox(height: AppSpacing.sectionGap),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: MenuItemWidget(
                      icon: AppIcons.logOut,
                      label: 'Sign Out',
                      iconColor: context.destructiveColor,
                      onTap: () async {
                        final authService = ref.read(authServiceProvider);
                        await authService.signOut();
                        if (context.mounted) context.go('/onboarding');
                      },
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Center(
                    child: Text('GymRatz v1.0.0', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).valueOrNull ?? SampleData.user;
    final stats = ref.watch(workoutStatsProvider).valueOrNull ?? {};
    final achievements = ref.watch(achievementsProvider).valueOrNull ?? [];
    final totalWorkouts = stats['totalWorkouts'] ?? 0;
    final streak = stats['streak'] ?? 0;
    final badgeCount = achievements.length;

    final subtitle = user.createdAt != null
        ? 'Member since ${DateFormat.yMMMM().format(user.createdAt!)}'
        : user.experienceLevel;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppGradients.primary(isDark: isDark),
        borderRadius: AppRadius.headerBottom,
        boxShadow: AppShadows.lg,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.screenPadding, 12.h, AppSpacing.screenPadding, AppSpacing.xxl),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Profile', style: AppTextStyles.h1.copyWith(color: Colors.white)),
                  GestureDetector(
                    onTap: () => context.push('/profile/edit'),
                    child: Icon(AppIcons.edit, size: 22.r, color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Container(
                width: 96.r,
                height: 96.r,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.lg,
                ),
                child: Center(
                  child: Text(user.initials, style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              SizedBox(height: 12.h),
              Text(user.name, style: AppTextStyles.h2.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
              SizedBox(height: 4.h),
              Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
              SizedBox(height: 20.h),
              StatsGrid(
                useTransparentBg: true,
                items: [
                  StatsGridItem(icon: AppIcons.flame, iconColor: Colors.white, value: '$totalWorkouts', label: 'Workouts'),
                  StatsGridItem(icon: AppIcons.flame, iconColor: Colors.orange, value: '$streak', label: 'Streak'),
                  StatsGridItem(icon: AppIcons.award, iconColor: Colors.white, value: '$badgeCount', label: 'Badges'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalRecords(BuildContext context, WidgetRef ref) {
    final prsAsync = ref.watch(personalRecordsProvider);
    final prs = prsAsync.valueOrNull;

    // Fall back to sample data if no Firestore data yet
    final prList = prs != null && prs.isNotEmpty
        ? prs
            .map((p) => {
                  'exercise': p.exerciseName,
                  'weight': p.weight.toInt(),
                  'unit': 'lbs',
                  'date': '${p.date.month}/${p.date.day}/${p.date.year}',
                })
            .toList()
        : SampleData.personalRecords;

    return Column(
      children: [
        SectionHeader(title: 'PERSONAL RECORDS', actionText: 'View All', onAction: () => context.push('/progress')),
        SizedBox(height: AppSpacing.lg),
        ...prList.map((pr) => Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: CustomCard(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                SizedBox(
                  width: 40.r,
                  height: 40.r,
                  child: Center(child: Icon(AppIcons.trophy, size: 20.r, color: context.primaryColor)),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${pr['exercise']}', style: AppTextStyles.bodySmall.copyWith(color: context.foreground, fontWeight: FontWeight.w500)),
                      Text('${pr['date']}', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                    ],
                  ),
                ),
                Text(
                  '${pr['weight']} ${pr['unit']}',
                  style: AppTextStyles.h4.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 8.w),
                Icon(AppIcons.share2, size: 16.r, color: context.mutedForeground),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildSubscriptionItem(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProProvider).valueOrNull ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SUBSCRIPTION', style: AppTextStyles.caption.copyWith(color: context.mutedForeground, fontWeight: FontWeight.w600, letterSpacing: 1)),
        SizedBox(height: 8.h),
        CustomCard(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: MenuItemWidget(
            icon: AppIcons.crown,
            label: isPro ? 'GymRatz Pro' : 'Upgrade to Pro',
            iconColor: isPro ? context.primaryColor : null,
            onTap: isPro ? null : () => context.push('/paywall'),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.caption.copyWith(color: context.mutedForeground, fontWeight: FontWeight.w600, letterSpacing: 1)),
        SizedBox(height: 8.h),
        CustomCard(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(children: items),
        ),
      ],
    );
  }
}
