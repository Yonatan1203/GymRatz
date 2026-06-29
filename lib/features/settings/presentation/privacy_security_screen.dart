import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../core/constants.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/menu_item_widget.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

class PrivacySecurityScreen extends ConsumerStatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  ConsumerState<PrivacySecurityScreen> createState() =>
      _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState
    extends ConsumerState<PrivacySecurityScreen> {
  bool _isDeletingAccount = false;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account, all workout data, '
          'programs, and achievements. This action cannot be undone.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              showBackButton: true,
              child: Text(
                'Privacy & Security',
                style:
                    AppTextStyles.h1.copyWith(color: context.foreground),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Legal ───────────────────────────────────────────
                  _sectionTitle(context, 'LEGAL'),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        MenuItemWidget(
                          icon: AppIcons.shield,
                          label: 'Privacy Policy',
                          onTap: () =>
                              _launchUrl(AppConstants.privacyPolicyUrl),
                        ),
                        Divider(
                          color: context.mutedForeground
                              .withValues(alpha: 0.15),
                          height: 1,
                        ),
                        MenuItemWidget(
                          icon: AppIcons.fileText,
                          label: 'Terms of Service',
                          onTap: () =>
                              _launchUrl(AppConstants.termsOfServiceUrl),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sectionGap),

                  // ─── Data ─────────────────────────────────────────────
                  _sectionTitle(context, 'YOUR DATA'),
                  CustomCard(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'Your workout data is stored securely in Firebase. '
                      'We never sell your data.',
                      style: AppTextStyles.body.copyWith(
                        color: context.foreground,
                        height: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.sectionGap),

                  // ─── Danger zone ──────────────────────────────────────
                  _sectionTitle(context, 'DANGER ZONE'),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: MenuItemWidget(
                      icon: AppIcons.trash2,
                      label: 'Delete Account',
                      iconColor: context.destructiveColor,
                      onTap: _isDeletingAccount
                          ? null
                          : _handleDeleteAccount,
                    ),
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
}
