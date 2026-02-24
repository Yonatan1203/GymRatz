import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_input.dart';
import '../../../shared/widgets/onboarding_progress_bar.dart';
import '../../../shared/widgets/onboarding_bottom_button.dart';
import '../providers/onboarding_provider.dart';

class OnboardingEmailScreen extends ConsumerStatefulWidget {
  const OnboardingEmailScreen({super.key});

  @override
  ConsumerState<OnboardingEmailScreen> createState() => _OnboardingEmailScreenState();
}

class _OnboardingEmailScreenState extends ConsumerState<OnboardingEmailScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _emailValid =>
      _emailController.text.contains('@') && _emailController.text.contains('.');
  bool get _passwordValid => _passwordController.text.length >= 6;
  bool get _isValid => _emailValid && _passwordValid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OnboardingProgressBar(currentStep: 9, totalSteps: 14),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Almost there!',
                    style: AppTextStyles.h1.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Create your account to save your progress',
                    style: AppTextStyles.body.copyWith(color: context.mutedForeground),
                  ),
                  SizedBox(height: 32.h),
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
                      onTap: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword
                            ? AppIcons.eyeOff
                            : AppIcons.eye,
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
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          OnboardingBottomButton(
            text: 'Continue',
            enabled: _isValid,
            onPressed: () {
              ref.read(onboardingProvider.notifier).setEmail(_emailController.text.trim());
              ref.read(onboardingProvider.notifier).setPassword(_passwordController.text);
              context.go('/onboarding/notifications');
            },
          ),
        ],
      ),
    );
  }
}
