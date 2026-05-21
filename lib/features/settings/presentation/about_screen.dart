import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              showBackButton: true,
              child: Column(
                children: [
                  Container(
                    width: 80.r,
                    height: 80.r,
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(AppIcons.dumbbell, size: 36.r, color: context.primaryColor),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'GymRatz',
                    style: AppTextStyles.h1.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'v${AppConstants.appVersion}',
                    style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomCard(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'GymRatz is your personal fitness companion. Track workouts, '
                      'follow structured programs with progressive overload, set personal records, '
                      'and level up your fitness journey — all in one app.',
                      style: AppTextStyles.body.copyWith(
                        color: context.foreground,
                        height: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.sectionGap),
                  _sectionTitle(context, 'FEATURES'),
                  CustomCard(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        _featureRow(context, AppIcons.trendingUp, 'Progressive Overload',
                            'Smart weight suggestions based on your performance'),
                        SizedBox(height: AppSpacing.lg),
                        _featureRow(context, AppIcons.calendar, 'Program Scheduling',
                            'Structured weekly programs with rest day management'),
                        SizedBox(height: AppSpacing.lg),
                        _featureRow(context, AppIcons.trophy, 'Personal Records',
                            'Automatic PR tracking across all exercises'),
                        SizedBox(height: AppSpacing.lg),
                        _featureRow(context, AppIcons.barChart2, 'Progress Analytics',
                            'Volume charts, streak tracking, and achievements'),
                        SizedBox(height: AppSpacing.lg),
                        _featureRow(context, AppIcons.users, 'Coach Support',
                            'Connect with a coach for guided programming'),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sectionGap),
                  _sectionTitle(context, 'LEGAL'),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        _linkRow(context, 'Privacy Policy', () =>
                            launchUrl(Uri.parse(AppConstants.privacyPolicyUrl))),
                        Divider(color: context.mutedForeground.withValues(alpha: 0.15), height: 1),
                        _linkRow(context, 'Terms of Service', () =>
                            launchUrl(Uri.parse(AppConstants.termsOfServiceUrl))),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sectionGap),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Made with dedication',
                          style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          '\u00a9 2025 GymRatz. All rights reserved.',
                          style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
                        ),
                      ],
                    ),
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

  Widget _featureRow(BuildContext context, IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20.r, color: context.primaryColor),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.body.copyWith(
                color: context.foreground,
                fontWeight: FontWeight.w500,
              )),
              SizedBox(height: 2.h),
              Text(subtitle, style: AppTextStyles.caption.copyWith(
                color: context.mutedForeground,
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _linkRow(BuildContext context, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: AppTextStyles.body.copyWith(color: context.foreground)),
            ),
            Icon(AppIcons.chevronRight, size: 16.r, color: context.mutedForeground),
          ],
        ),
      ),
    );
  }
}
