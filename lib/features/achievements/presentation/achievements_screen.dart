import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_icons.dart';

import '../../../app/providers.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/utils/platform_adapter.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/custom_badge.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/stats_grid.dart';
import '../../../shared/widgets/progress_bar_widget.dart';
import '../../../shared/data/sample_data.dart';
import '../../../shared/models/achievement.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  String _selectedTab = 'All';

  IconData _iconForName(String iconName) {
    switch (iconName) {
      case 'trophy':
        return AppIcons.trophy;
      case 'flame':
        return AppIcons.flame;
      case 'award':
        return AppIcons.award;
      case 'target':
        return AppIcons.target;
      case 'star':
        return AppIcons.star;
      case 'crown':
        return AppIcons.crown;
      case 'calendar':
        return AppIcons.calendar;
      case 'sunrise':
        return AppIcons.sunrise;
      case 'checkCircle':
        return AppIcons.checkCircle;
      default:
        return AppIcons.trophy;
    }
  }

  Color _rarityBgColor(BuildContext context, String rarity) {
    switch (rarity) {
      case 'Common':
        return context.mutedColor;
      case 'Rare':
        return context.accentColor.withValues(alpha: 0.2);
      case 'Epic':
        return context.primaryColor.withValues(alpha: 0.2);
      case 'Legendary':
        return context.secondaryColor.withValues(alpha: 0.2);
      default:
        return context.mutedColor;
    }
  }

  Color _rarityTextColor(BuildContext context, String rarity) {
    switch (rarity) {
      case 'Common':
        return context.mutedForeground;
      case 'Rare':
        return context.accentColor;
      case 'Epic':
        return context.primaryColor;
      case 'Legendary':
        return context.secondaryColor;
      default:
        return context.mutedForeground;
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievements = ref.watch(achievementsProvider).valueOrNull ?? SampleData.achievements;
    final unlockedCount = achievements.where((a) => a.unlocked).length;
    final totalPoints = achievements.where((a) => a.unlocked).fold<int>(0, (sum, a) => sum + a.points);

    final filtered = achievements.where((a) {
      if (_selectedTab == 'Unlocked') return a.unlocked;
      if (_selectedTab == 'Locked') return !a.unlocked;
      return true;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            showBackButton: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Achievements', style: AppTextStyles.h1.copyWith(color: Colors.white)),
                SizedBox(height: 16.h),
                StatsGrid(
                  useTransparentBg: true,
                  items: [
                    StatsGridItem(icon: AppIcons.trophy, iconColor: Colors.white, value: '$unlockedCount', label: 'Unlocked'),
                    StatsGridItem(icon: AppIcons.target, iconColor: Colors.white, value: '${achievements.length}', label: 'Total'),
                    StatsGridItem(icon: AppIcons.star, iconColor: Colors.white, value: '$totalPoints', label: 'Points'),
                  ],
                ),
              ],
            ),
          ),
          _buildTabBar(context),
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: EdgeInsets.all(AppSpacing.screenPadding),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildAchievementCard(context, filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final tabs = ['All', 'Unlocked', 'Locked'];
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Row(
          children: tabs.map((tab) {
            final isSelected = _selectedTab == tab;
            return Semantics(
              button: true,
              label: tab,
              selected: isSelected,
              child: GestureDetector(
              onTap: () {
                if (tab == 'Unlocked') {
                  PlatformAdapter.hapticHeavy();
                } else {
                  PlatformAdapter.hapticSelection();
                }
                setState(() => _selectedTab = tab);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
                margin: EdgeInsets.only(right: 16.w),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? context.primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? context.primaryColor : context.mutedForeground,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
            ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(BuildContext context, Achievement achievement) {
    final progressPercent = achievement.total > 0 ? achievement.progress / achievement.total : 0.0;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Opacity(
        opacity: achievement.unlocked ? 1.0 : 0.75,
        child: CustomCard(
          padding: EdgeInsets.all(16.r),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56.r,
                height: 56.r,
                child: Center(
                  child: Icon(
                    achievement.unlocked ? _iconForName(achievement.iconName) : AppIcons.lock,
                    size: 28.r,
                    color: achievement.unlocked ? context.primaryColor : context.mutedForeground,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            achievement.title,
                            style: AppTextStyles.h4.copyWith(color: context.foreground, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(AppIcons.star, size: 16.r, color: context.primaryColor),
                            SizedBox(width: 4.w),
                            Text(
                              '${achievement.points}',
                              style: AppTextStyles.bodySmall.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      achievement.description,
                      style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        CustomBadge(
                          text: achievement.rarity,
                          backgroundColor: _rarityBgColor(context, achievement.rarity),
                          textColor: _rarityTextColor(context, achievement.rarity),
                        ),
                        if (achievement.unlocked && achievement.unlockedDate != null) ...[
                          SizedBox(width: 8.w),
                          Text(
                            'Unlocked ${achievement.unlockedDate!.month}/${achievement.unlockedDate!.day}/${achievement.unlockedDate!.year}',
                            style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
                          ),
                        ],
                      ],
                    ),
                    if (!achievement.unlocked) ...[
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Progress', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                          Text(
                            '${achievement.progress} / ${achievement.total}',
                            style: AppTextStyles.caption.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      ProgressBarWidget(progress: progressPercent),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.trophy, size: 48.r, color: context.mutedForeground.withValues(alpha: 0.5)),
          SizedBox(height: 12.h),
          Text('No achievements in this category', style: AppTextStyles.body.copyWith(color: context.mutedForeground)),
        ],
      ),
    );
  }
}
