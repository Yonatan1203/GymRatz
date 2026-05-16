import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../../app/providers.dart';
import '../../../core/constants.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/menu_item_widget.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

class CoachSettingsScreen extends ConsumerWidget {
  const CoachSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(coachProfileProvider).valueOrNull;
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final isAdmin = userProfile?.role.isAdmin ?? false;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, profile?.displayName ?? 'Coach'),
            Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(context, 'PROFILE'),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        _buildProfileInfo(
                            context, 'Name', profile?.displayName ?? '—'),
                        Divider(
                            color: context.mutedForeground
                                .withValues(alpha: 0.15),
                            height: 1),
                        _buildProfileInfo(
                            context, 'Email', profile?.email ?? '—'),
                        Divider(
                            color: context.mutedForeground
                                .withValues(alpha: 0.15),
                            height: 1),
                        _buildProfileInfo(context, 'Plan',
                            _formatPlanTier(profile?.planTier ?? '')),
                        Divider(
                            color: context.mutedForeground
                                .withValues(alpha: 0.15),
                            height: 1),
                        _buildProfileInfo(context, 'Clients',
                            '${profile?.clientCount ?? 0} / ${profile?.maxClients ?? 0}'),
                        Divider(
                            color: context.mutedForeground
                                .withValues(alpha: 0.15),
                            height: 1),
                        MenuItemWidget(
                          icon: AppIcons.edit,
                          label: 'Edit Profile',
                          onTap: () =>
                              GoRouter.of(context).push('/coach/profile/edit'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sectionGap),
                  _sectionTitle(context, 'MANAGEMENT'),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        MenuItemWidget(
                          icon: AppIcons.mail,
                          label: 'Manage Invites',
                          onTap: () => context.go('/coach/invites'),
                        ),
                        if (isAdmin) ...[
                          Divider(
                              color: context.mutedForeground
                                  .withValues(alpha: 0.15),
                              height: 1),
                          MenuItemWidget(
                            icon: AppIcons.shield,
                            label: 'Coach Approvals',
                            badge: _pendingBadge(ref),
                            onTap: () => context.go('/coach/approvals'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sectionGap),
                  _sectionTitle(context, 'SUBSCRIPTION'),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        MenuItemWidget(
                          icon: AppIcons.crown,
                          label: 'Manage Subscription',
                          onTap: () async {
                            try {
                              await RevenueCatUI.presentCustomerCenter();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Could not open subscription manager: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sectionGap),
                  _sectionTitle(context, 'APPEARANCE'),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                  context.isDark
                                      ? AppIcons.moon
                                      : AppIcons.sun,
                                  size: 20.r,
                                  color: context.mutedForeground),
                              SizedBox(width: 12.w),
                              Text('Theme',
                                  style: AppTextStyles.body
                                      .copyWith(color: context.foreground)),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          _buildThemeSelector(context, ref),
                        ],
                      ),
                    ),
                  ),
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
                    child: Text('GymRatz v${AppConstants.appVersion}',
                        style: AppTextStyles.caption
                            .copyWith(color: context.mutedForeground)),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    return GradientHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: AppTextStyles.h2.copyWith(
              color: context.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            name,
            style: AppTextStyles.bodySmall
                .copyWith(color: context.mutedForeground),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: context.mutedForeground,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildProfileInfo(
      BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Row(
        children: [
          Text(label,
              style: AppTextStyles.body
                  .copyWith(color: context.mutedForeground)),
          const Spacer(),
          Text(value,
              style: AppTextStyles.body.copyWith(
                  color: context.foreground, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatPlanTier(String tier) {
    switch (tier) {
      case 'coach_5':
        return '5 Clients';
      case 'coach_10':
        return '10 Clients';
      case 'coach_20':
        return '20 Clients';
      default:
        return tier;
    }
  }

  String? _pendingBadge(WidgetRef ref) {
    final apps = ref.watch(pendingApplicationsProvider).valueOrNull ?? [];
    if (apps.isEmpty) return null;
    return '${apps.length}';
  }

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeProvider);

    return Row(
      children: [
        _themeOption(context, ref, 'Light', ThemeMode.light, currentMode),
        SizedBox(width: 8.w),
        _themeOption(context, ref, 'Dark', ThemeMode.dark, currentMode),
        SizedBox(width: 8.w),
        _themeOption(context, ref, 'System', ThemeMode.system, currentMode),
      ],
    );
  }

  Widget _themeOption(BuildContext context, WidgetRef ref, String label,
      ThemeMode mode, ThemeMode current) {
    final isSelected = current == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(themeProvider.notifier).setThemeMode(mode),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected
                ? context.primaryColor.withValues(alpha: 0.12)
                : context.mutedColor,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color:
                  isSelected ? context.primaryColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected
                    ? context.primaryColor
                    : context.mutedForeground,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
