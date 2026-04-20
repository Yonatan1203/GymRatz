import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
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
                      child: Text('GymRatz v1.0.0', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
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
          onTap: () => context.push('/profile/edit'),
          child: Icon(AppIcons.edit, size: 22.r, color: context.foreground),
        ),
      ],
      child: Column(
        children: [
          Container(
            width: 96.r,
            height: 96.r,
            decoration: BoxDecoration(
              color: context.primaryColor.withOpacity(0.15),
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
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: ScaleTap(
            onTap: () {},
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
                        Text('${pr['exercise']}', style: AppTextStyles.bodySmall.copyWith(color: context.foreground, fontWeight: FontWeight.w500)),
                        Text('${pr['date']}', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                      ],
                    ),
                  ),
                  Text(
                    '${pr['weight']} ${pr['unit']}',
                    style: AppTextStyles.h4.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Icon(AppIcons.share2, size: 16.r, color: context.mutedForeground),
                ],
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildSignOut(BuildContext context, WidgetRef ref) {
    return ScaleTap(
      onTap: () async {
        final authService = ref.read(authServiceProvider);
        await authService.signOut();
        if (context.mounted) context.go('/onboarding');
      },
      child: CustomCard(
        variant: CardVariant.standard,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
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
    );
  }

  Widget _buildMenuSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.caption.copyWith(color: context.mutedForeground, fontWeight: FontWeight.w600, letterSpacing: 1)),
        SizedBox(height: AppSpacing.md),
        ScaleTap(
          onTap: () {},
          child: CustomCard(
            variant: CardVariant.standard,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(children: items),
          ),
        ),
      ],
    );
  }
}
