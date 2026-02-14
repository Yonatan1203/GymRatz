import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/app_gradients.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/menu_item_widget.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stats_grid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../shared/data/sample_data.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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
                  _buildInviteCard(context, isDark),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildPersonalRecords(context, ref),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildMenuSection(context, 'WORKOUTS & TRAINING', [
                    MenuItemWidget(icon: LucideIcons.dumbbell, label: 'Exercises', onTap: () => context.push('/exercises')),
                    MenuItemWidget(icon: LucideIcons.heart, label: 'Favorites', onTap: () => context.push('/favorites')),
                    MenuItemWidget(icon: LucideIcons.trendingUp, label: 'Progress', onTap: () => context.push('/progress')),
                    MenuItemWidget(icon: LucideIcons.trophy, label: 'Achievements', badge: '4', onTap: () => context.push('/achievements')),
                    MenuItemWidget(icon: LucideIcons.calendar, label: 'Calendar', onTap: () => context.go('/calendar')),
                  ]),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildMenuSection(context, 'ACCOUNT', [
                    MenuItemWidget(icon: LucideIcons.settings, label: 'Settings', onTap: () => context.push('/settings')),
                    MenuItemWidget(icon: LucideIcons.helpCircle, label: 'Help & FAQ', onTap: () {}),
                  ]),
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
    final user = ref.watch(userProfileProvider).valueOrNull ?? SampleData.user;
    final stats = ref.watch(workoutStatsProvider).valueOrNull ?? {};
    final totalWorkouts = stats['totalWorkouts'] ?? 24;
    final streak = stats['streak'] ?? 12;
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
        boxShadow: AppShadows.md,
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
                  Text('Profile', style: AppTextStyles.h1.copyWith(color: context.foreground)),
                  GestureDetector(
                    onTap: () => context.push('/profile/edit'),
                    child: Icon(LucideIcons.edit, size: 22.r, color: context.primaryColor),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Container(
                width: 96.r,
                height: 96.r,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary(isDark: isDark),
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.lg,
                ),
                child: Center(
                  child: Text(user.initials, style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              SizedBox(height: 12.h),
              Text(user.name, style: AppTextStyles.h2.copyWith(color: context.foreground, fontWeight: FontWeight.w600)),
              SizedBox(height: 4.h),
              Text('Fitness Enthusiast', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
              SizedBox(height: 20.h),
              StatsGrid(items: [
                StatsGridItem(icon: LucideIcons.flame, iconColor: context.primaryColor, value: '$totalWorkouts', label: 'Workouts'),
                StatsGridItem(icon: LucideIcons.flame, iconColor: Colors.orange, value: '$streak', label: 'Streak'),
                StatsGridItem(icon: LucideIcons.award, iconColor: context.secondaryColor, value: '4', label: 'Badges'),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInviteCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: AppGradients.primary(isDark: isDark),
        borderRadius: AppRadius.borderXl,
        boxShadow: AppShadows.lg,
      ),
      child: Row(
        children: [
          Icon(LucideIcons.users, size: 24.r, color: Colors.white),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invite Friends', style: AppTextStyles.h4.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                Text('Share GymRatz with your gym buddies', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 20.r, color: Colors.white70),
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
        const SectionHeader(title: 'Personal Records'),
        SizedBox(height: AppSpacing.lg),
        ...prList.map((pr) => Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: CustomCard(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.2),
                    borderRadius: AppRadius.borderLg,
                  ),
                  child: Icon(LucideIcons.trophy, size: 20.r, color: context.primaryColor),
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
                Icon(LucideIcons.share2, size: 16.r, color: context.mutedForeground),
              ],
            ),
          ),
        )),
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
