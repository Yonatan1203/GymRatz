import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_input.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../app/providers/auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _emailController.text.contains('@') &&
      _emailController.text.contains('.');

  Future<void> _sendReset() async {
    if (!_isValid) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendPasswordReset(_emailController.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24.h),
              Text(
                'Reset Password',
                style: AppTextStyles.h1.copyWith(
                  color: context.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Enter your email and we\'ll send you a reset link',
                style: AppTextStyles.body.copyWith(
                  color: context.mutedForeground,
                ),
              ),
              SizedBox(height: 32.h),
              if (_sent) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.checkCircle, color: Colors.green, size: 20.r),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Reset link sent! Check your email.',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                CustomInput(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icon(LucideIcons.mail, size: 20.r),
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => _sendReset(),
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
                  text: 'Send Reset Link',
                  variant: ButtonVariant.gradient,
                  isLoading: _isLoading,
                  onPressed: _isValid ? _sendReset : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
