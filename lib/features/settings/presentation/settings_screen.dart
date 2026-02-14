import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/providers.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/custom_toggle.dart';
import '../../../shared/widgets/menu_item_widget.dart';
import '../../../shared/widgets/gradient_header.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushNotifications = true;
  bool _workoutReminders = true;
  bool _restTimerSound = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              showBackButton: true,
              child: Text('Settings', style: AppTextStyles.h1.copyWith(color: Colors.white)),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(context, 'APPEARANCE'),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: Row(
                      children: [
                        Icon(isDark ? LucideIcons.moon : LucideIcons.sun, size: 20.r, color: context.mutedForeground),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text('Dark Mode', style: AppTextStyles.body.copyWith(color: context.foreground)),
                        ),
                        CustomToggle(
                          value: isDark,
                          onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sectionGap),
                  _sectionTitle(context, 'NOTIFICATIONS'),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        _toggleRow('Push Notifications', _pushNotifications, (v) => setState(() => _pushNotifications = v)),
                        Divider(color: context.borderColor, height: 1),
                        _toggleRow('Workout Reminders', _workoutReminders, (v) => setState(() => _workoutReminders = v)),
                        Divider(color: context.borderColor, height: 1),
                        _toggleRow('Rest Timer Sound', _restTimerSound, (v) => setState(() => _restTimerSound = v)),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sectionGap),
                  _sectionTitle(context, 'ACCOUNT'),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        MenuItemWidget(icon: LucideIcons.user, label: 'Edit Profile', onTap: () => context.push('/profile/edit')),
                        Divider(color: context.borderColor, height: 1),
                        MenuItemWidget(icon: LucideIcons.shield, label: 'Privacy & Security', onTap: () {}),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sectionGap),
                  _sectionTitle(context, 'DATA'),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        MenuItemWidget(icon: LucideIcons.download, label: 'Export Data', onTap: () {}),
                        Divider(color: context.borderColor, height: 1),
                        MenuItemWidget(icon: LucideIcons.trash2, label: 'Clear All Data', iconColor: context.destructiveColor, onTap: () {}),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sectionGap),
                  _sectionTitle(context, 'SUBSCRIPTION'),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        MenuItemWidget(icon: LucideIcons.crown, label: 'Manage Subscription', onTap: () => context.push('/paywall')),
                        Divider(color: context.borderColor, height: 1),
                        MenuItemWidget(icon: LucideIcons.refreshCw, label: 'Restore Purchases', onTap: () async {
                          final success = await ref.read(entitlementServiceProvider).restorePurchases();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(success ? 'Purchases restored!' : 'No purchases found')),
                            );
                          }
                        }),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sectionGap),
                  _sectionTitle(context, 'SUPPORT'),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        MenuItemWidget(icon: LucideIcons.helpCircle, label: 'Help & FAQ', onTap: () {}),
                        Divider(color: context.borderColor, height: 1),
                        MenuItemWidget(icon: LucideIcons.info, label: 'About', onTap: () {}),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sectionGap),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: MenuItemWidget(
                      icon: LucideIcons.logOut,
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
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(title, style: AppTextStyles.caption.copyWith(color: context.mutedForeground, fontWeight: FontWeight.w600, letterSpacing: 1)),
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body.copyWith(color: context.foreground))),
          CustomToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
