import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';

import '../../../theme/app_radius.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_input.dart';
import '../../../shared/widgets/custom_toggle.dart';
import '../../../shared/widgets/onboarding_progress_bar.dart';
import '../../../shared/widgets/onboarding_bottom_button.dart';
import '../../../shared/widgets/staggered_list.dart';
import '../../auth/presentation/widgets/social_auth_buttons.dart';
import '../../../app/providers/auth_providers.dart';
import '../providers/onboarding_provider.dart';

class OnboardingEmailScreen extends ConsumerStatefulWidget {
  const OnboardingEmailScreen({super.key});

  @override
  ConsumerState<OnboardingEmailScreen> createState() =>
      _OnboardingEmailScreenState();
}

class _OnboardingEmailScreenState extends ConsumerState<OnboardingEmailScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _notificationsEnabled = true;
  bool _isSocialLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _nameValid => _nameController.text.trim().isNotEmpty;
  bool get _emailValid =>
      _emailController.text.contains('@') && _emailController.text.contains('.');
  bool get _passwordValid => _passwordController.text.length >= 6;
  bool get _isValid => _nameValid && _emailValid && _passwordValid;

  Future<void> _signInWithGoogle() async {
    setState(() => _isSocialLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSocialLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isSocialLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithApple();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSocialLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OnboardingProgressBar(currentStep: 5),
          Expanded(
            child: SingleChildScrollView(
              padding:
                  EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: StaggeredList(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Create your account',
                    style: AppTextStyles.h1.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Save your progress and unlock all features.',
                    style: AppTextStyles.body
                        .copyWith(color: context.mutedForeground),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  CustomInput(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'Your name',
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icon(AppIcons.user, size: 20.r),
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 16.h),
                  CustomInput(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icon(AppIcons.mail, size: 20.r),
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 16.h),
                  CustomInput(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'At least 6 characters',
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icon(AppIcons.lock, size: 20.r),
                    suffixIcon: GestureDetector(
                      onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword ? AppIcons.eyeOff : AppIcons.eye,
                        size: 20.r,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_passwordController.text.isNotEmpty && !_passwordValid)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text(
                        'Password must be at least 6 characters',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.destructiveColor,
                        ),
                      ),
                    ),
                  SizedBox(height: AppSpacing.sectionGap),

                  // Notifications toggle card
                  Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: AppRadius.borderXl,
                      border: Border.all(color: context.borderColor),
                      boxShadow: AppShadows.md,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40.r,
                          height: 40.r,
                          decoration: BoxDecoration(
                            color: context.primaryColor.withValues(alpha:0.1),
                            borderRadius: AppRadius.borderLg,
                          ),
                          child: Icon(
                            AppIcons.bell,
                            size: 20.r,
                            color: context.primaryColor,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Push Notifications',
                                style: AppTextStyles.h4.copyWith(
                                  color: context.foreground,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Workout reminders & streak alerts',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: context.mutedForeground),
                              ),
                            ],
                          ),
                        ),
                        CustomToggle(
                          value: _notificationsEnabled,
                          onChanged: (val) =>
                              setState(() => _notificationsEnabled = val),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  SocialAuthButtons(
                    onGooglePressed: _signInWithGoogle,
                    onApplePressed: _signInWithApple,
                    isLoading: _isSocialLoading,
                  ),
                  SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
          OnboardingBottomButton(
            text: 'Create Account',
            enabled: _isValid,
            onPressed: () {
              final notifier = ref.read(onboardingProvider.notifier);
              notifier.setFullName(_nameController.text.trim());
              notifier.setEmail(_emailController.text.trim());
              notifier.setPassword(_passwordController.text);
              notifier.setNotificationsEnabled(_notificationsEnabled);
              context.push('/onboarding/summary');
            },
          ),
        ],
      ),
    );
  }
}
