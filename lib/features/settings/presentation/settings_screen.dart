import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
              child: Text('Settings', style: AppTextStyles.h1.copyWith(color: context.foreground)),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(context, 'APPEARANCE'),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(isDark ? AppIcons.moon : AppIcons.sun, size: 20.r, color: context.mutedForeground),
                            SizedBox(width: 12.w),
                            Text('Theme', style: AppTextStyles.body.copyWith(color: context.foreground)),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        _buildThemeSelector(ref, isDark),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sectionGap),
                  _sectionTitle(context, 'UNITS'),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(AppIcons.scale, size: 20.r, color: context.mutedForeground),
                            SizedBox(width: 12.w),
                            Text('Measurement System', style: AppTextStyles.body.copyWith(color: context.foreground)),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        _buildUnitSelector(ref, isDark),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sectionGap),
                  _sectionTitle(context, 'WEEK START'),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(AppIcons.calendar, size: 20.r, color: context.mutedForeground),
                            SizedBox(width: 12.w),
                            Text('Week starts on', style: AppTextStyles.body.copyWith(color: context.foreground)),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        _buildWeekStartSelector(ref),
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
                        Divider(color: context.mutedForeground.withValues(alpha:0.15), height: 1),
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
                        Divider(color: context.mutedForeground.withValues(alpha:0.15), height: 1),
                        _toggleRow(
                          'Rest Timer Sound',
                          ref.watch(timerSettingsProvider).soundEnabled,
                          (v) => ref.read(timerSettingsProvider.notifier).setSoundEnabled(v),
                        ),
                        Divider(color: context.mutedForeground.withValues(alpha:0.15), height: 1),
                        _toggleRow(
                          'Auto-Start Rest Timer',
                          ref.watch(timerSettingsProvider).autoStartOnSetComplete,
                          (v) => ref.read(timerSettingsProvider.notifier).setAutoStartOnSetComplete(v),
                        ),
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
                        Divider(color: context.mutedForeground.withValues(alpha:0.15), height: 1),
                        MenuItemWidget(icon: AppIcons.shield, label: 'Privacy & Security', onTap: () {}),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sectionGap),
                  _sectionTitle(context, 'COACH'),
                  _buildCoachSection(context, ref),
                  SizedBox(height: AppSpacing.sectionGap),
                  _sectionTitle(context, 'DATA'),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        MenuItemWidget(icon: AppIcons.download, label: 'Export Data', onTap: () {}),
                        Divider(color: context.mutedForeground.withValues(alpha:0.15), height: 1),
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
                        Divider(color: context.mutedForeground.withValues(alpha:0.15), height: 1),
                        MenuItemWidget(
                          icon: AppIcons.zap,
                          label: 'Subscribe',
                          onTap: () => context.push('/paywall'),
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
                        MenuItemWidget(icon: AppIcons.helpCircle, label: 'Help & FAQ', onTap: () => context.push('/faq')),
                        Divider(color: context.mutedForeground.withValues(alpha:0.15), height: 1),
                        MenuItemWidget(icon: AppIcons.shield, label: 'Privacy Policy', onTap: () => launchUrl(Uri.parse(AppConstants.privacyPolicyUrl))),
                        Divider(color: context.mutedForeground.withValues(alpha:0.15), height: 1),
                        MenuItemWidget(icon: AppIcons.fileText, label: 'Terms of Service', onTap: () => launchUrl(Uri.parse(AppConstants.termsOfServiceUrl))),
                        Divider(color: context.mutedForeground.withValues(alpha:0.15), height: 1),
                        MenuItemWidget(icon: AppIcons.info, label: 'About', onTap: () => context.push('/about')),
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
                    child: Text('GymRatz v${AppConstants.appVersion}', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
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


  Widget _buildCoachSection(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final hasCoach = profile?.coachId != null;

    return CustomCard(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          if (hasCoach) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              child: Row(
                children: [
                  Icon(AppIcons.users, size: 20.r, color: context.primaryColor),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Linked to a Coach', style: AppTextStyles.body.copyWith(color: context.foreground)),
                        if (profile?.coachLinkedAt != null)
                          Text(
                            'Since ${DateFormat.yMMMd().format(profile!.coachLinkedAt!)}',
                            style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            MenuItemWidget(
              icon: AppIcons.userPlus,
              label: 'Join a Coach',
              onTap: () => context.push('/join-coach'),
            ),
            Divider(color: context.mutedForeground.withValues(alpha:0.15), height: 1),
            MenuItemWidget(
              icon: AppIcons.award,
              label: 'Apply to Become a Coach',
              onTap: () => context.push('/apply-coach'),
            ),
          ],
        ],
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

  Widget _buildThemeSelector(WidgetRef ref, bool isDark) {
    final currentMode = ref.watch(themeProvider);

    return Row(
      children: [
        _themeOption(ref, 'Light', ThemeMode.light, currentMode),
        SizedBox(width: 8.w),
        _themeOption(ref, 'Dark', ThemeMode.dark, currentMode),
        SizedBox(width: 8.w),
        _themeOption(ref, 'System', ThemeMode.system, currentMode),
      ],
    );
  }

  Widget _themeOption(WidgetRef ref, String label, ThemeMode mode, ThemeMode current) {
    final isSelected = current == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(themeProvider.notifier).setThemeMode(mode),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected
                ? context.primaryColor.withValues(alpha:0.12)
                : context.mutedColor,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected ? context.primaryColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? context.primaryColor : context.mutedForeground,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitSelector(WidgetRef ref, bool isDark) {
    final currentUnit = ref.watch(userProfileProvider).valueOrNull?.unit ?? 'kg';

    return Row(
      children: [
        _unitOption(ref, 'Metric (kg)', 'kg', currentUnit),
        SizedBox(width: 8.w),
        _unitOption(ref, 'Imperial (lbs)', 'lbs', currentUnit),
      ],
    );
  }

  Widget _unitOption(WidgetRef ref, String label, String value, String current) {
    final isSelected = current == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (value == current) return;
          final uid = ref.read(currentUidProvider);
          if (uid == null) return;
          final profile = ref.read(userProfileProvider).valueOrNull;
          final updates = <String, dynamic>{'unit': value};

          // Convert height
          if (profile != null) {
            final h = profile.height;
            if (value == 'kg' && !h.contains('cm')) {
              // Imperial → Metric
              final match = RegExp(r"(\d+)'?\s*(\d+)?").firstMatch(h);
              if (match != null) {
                final feet = int.tryParse(match.group(1)!) ?? 0;
                final inches = int.tryParse(match.group(2) ?? '0') ?? 0;
                final cm = ((feet * 12 + inches) * 2.54).round();
                updates['height'] = '$cm cm';
              }
            } else if (value == 'lbs' && h.contains('cm')) {
              // Metric → Imperial
              final cmMatch = RegExp(r'(\d+\.?\d*)').firstMatch(h);
              if (cmMatch != null) {
                final cm = double.tryParse(cmMatch.group(1)!) ?? 170;
                final totalInches = (cm / 2.54).round();
                final feet = totalInches ~/ 12;
                final inches = totalInches % 12;
                updates['height'] = "$feet'$inches\"";
              }
            }

            // Convert weight
            if (value == 'kg' && current == 'lbs') {
              updates['weight'] = double.parse((profile.weight * 0.453592).toStringAsFixed(1));
            } else if (value == 'lbs' && current == 'kg') {
              updates['weight'] = double.parse((profile.weight * 2.20462).toStringAsFixed(1));
            }
          }

          ref.read(userRepositoryProvider).updateUser(uid, updates);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected
                ? context.primaryColor.withValues(alpha: 0.12)
                : context.mutedColor,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected ? context.primaryColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? context.primaryColor : context.mutedForeground,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekStartSelector(WidgetRef ref) {
    final startsOnMonday = ref.watch(userProfileProvider).valueOrNull?.weekStartsOnMonday ?? true;

    return Row(
      children: [
        _weekStartOption(ref, 'Monday', true, startsOnMonday),
        SizedBox(width: 8.w),
        _weekStartOption(ref, 'Sunday', false, startsOnMonday),
      ],
    );
  }

  Widget _weekStartOption(WidgetRef ref, String label, bool value, bool current) {
    final isSelected = current == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          final uid = ref.read(currentUidProvider);
          if (uid != null) {
            ref.read(userRepositoryProvider).updateUser(uid, {'weekStartsOnMonday': value});
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected
                ? context.primaryColor.withValues(alpha: 0.12)
                : context.mutedColor,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected ? context.primaryColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? context.primaryColor : context.mutedForeground,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
