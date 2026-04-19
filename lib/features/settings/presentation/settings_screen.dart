import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants.dart';
import '../../../theme/app_icons.dart';

import '../../../app/providers.dart';
import '../../../core/notification_service.dart';
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
  bool _isDeletingAccount = false;

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
                        Icon(isDark ? AppIcons.moon : AppIcons.sun, size: 20.r, color: context.mutedForeground),
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
                        _toggleRow('Push Notifications', _pushNotifications, (v) {
                          setState(() => _pushNotifications = v);
                          if (v) {
                            NotificationService().requestPermission();
                          }
                        }),
                        Divider(color: context.borderColor, height: 1),
                        _toggleRow('Workout Reminders', _workoutReminders, (v) {
                          setState(() => _workoutReminders = v);
                          if (v) {
                            NotificationService().requestPermission();
                            NotificationService().scheduleWorkoutReminder(
                              hour: 18,
                              minute: 0,
                              weekdays: [1, 2, 3, 4, 5],
                            );
                          } else {
                            NotificationService().cancelWorkoutReminders();
                          }
                        }),
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
                        MenuItemWidget(icon: AppIcons.user, label: 'Edit Profile', onTap: () => context.push('/profile/edit')),
                        Divider(color: context.borderColor, height: 1),
                        MenuItemWidget(icon: AppIcons.shield, label: 'Privacy & Security', onTap: () {}),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sectionGap),
                  _sectionTitle(context, 'DATA'),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        MenuItemWidget(icon: AppIcons.download, label: 'Export Data', onTap: () {}),
                        Divider(color: context.borderColor, height: 1),
                        MenuItemWidget(
                          icon: AppIcons.trash2,
                          label: 'Delete Account',
                          iconColor: context.destructiveColor,
                          onTap: _isDeletingAccount ? null : _handleDeleteAccount,
                        ),
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
                                  SnackBar(content: Text('Could not open subscription manager: $e')),
                                );
                              }
                            }
                          },
                        ),
                        Divider(color: context.borderColor, height: 1),
                        ref.watch(isProProvider).when(
                          data: (isPro) => isPro
                              ? const SizedBox.shrink()
                              : MenuItemWidget(
                                  icon: AppIcons.zap,
                                  label: 'Upgrade to Pro',
                                  onTap: () => context.push('/paywall'),
                                ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => MenuItemWidget(
                            icon: AppIcons.zap,
                            label: 'Upgrade to Pro',
                            onTap: () => context.push('/paywall'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sectionGap),
                  _sectionTitle(context, 'SUPPORT'),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        MenuItemWidget(icon: AppIcons.helpCircle, label: 'Help & FAQ', onTap: () {}),
                        Divider(color: context.borderColor, height: 1),
                        MenuItemWidget(icon: AppIcons.shield, label: 'Privacy Policy', onTap: () => launchUrl(Uri.parse(AppConstants.privacyPolicyUrl))),
                        Divider(color: context.borderColor, height: 1),
                        MenuItemWidget(icon: AppIcons.fileText, label: 'Terms of Service', onTap: () => launchUrl(Uri.parse(AppConstants.termsOfServiceUrl))),
                        Divider(color: context.borderColor, height: 1),
                        MenuItemWidget(icon: AppIcons.info, label: 'About', onTap: () {}),
                      ],
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

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account, all workout data, programs, and achievements. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeletingAccount = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.deleteAccount();
      if (mounted) {
        context.go('/onboarding/welcome');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeletingAccount = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    }
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
