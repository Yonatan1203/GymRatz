import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';

import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_input.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../app/providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _emailController.text.contains('@') &&
      _emailController.text.contains('.') &&
      _passwordController.text.length >= 6;

  Future<void> _signIn() async {
    if (!_isValid) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 60.h),
              Center(
                child: Icon(
                  AppIcons.dumbbell,
                  size: 48.r,
                  color: context.primaryColor,
                ),
              ),
              SizedBox(height: 24.h),
              Center(
                child: Text(
                  'Welcome Back',
                  style: AppTextStyles.h1.copyWith(
                    color: context.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Center(
                child: Text(
                  'Sign in to continue your fitness journey',
                  style: AppTextStyles.body.copyWith(
                    color: context.mutedForeground,
                  ),
                ),
              ),
              SizedBox(height: 40.h),
              CustomInput(
                controller: _emailController,
                label: 'Email',
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
                hint: 'Enter your password',
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                prefixIcon: Icon(AppIcons.lock, size: 20.r),
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                  child: Icon(
                    _obscurePassword ? AppIcons.eyeOff : AppIcons.eye,
                    size: 20.r,
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) => _signIn(),
              ),
              SizedBox(height: 8.h),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: Text(
                    'Forgot Password?',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.primaryColor,
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                SizedBox(height: 8.h),
                Text(
                  _error!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.redAccent,
                  ),
                ),
              ],
              SizedBox(height: 24.h),
              CustomButton(
                text: 'Sign In',
                variant: ButtonVariant.gradient,
                isLoading: _isLoading,
                onPressed: _isValid ? _signIn : null,
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.mutedForeground,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/onboarding'),
                    child: Text(
                      'Create Account',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }
}
