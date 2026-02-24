import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';

import '../../../theme/app_gradients.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_text_styles.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.network(
            'https://images.unsplash.com/photo-1741156229623-da94e6d7977d?w=1080',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.black,
            ),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(color: Colors.black);
            },
          ),

          // Gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.welcomeOverlay,
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Logo
                  Container(
                    width: 80.r,
                    height: 80.r,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary(),
                      borderRadius: AppRadius.borderXxl,
                      boxShadow: AppShadows.xxl,
                    ),
                    child: Icon(
                      AppIcons.dumbbell,
                      size: 40.r,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Title
                  Text(
                    'GymRatz',
                    style: AppTextStyles.display.copyWith(
                      color: Colors.white,
                      fontSize: 48.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Star row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: Icon(
                          AppIcons.star,
                          color: const Color(0xFFEAB308),
                          size: 28.r,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Tagline
                  Text(
                    'Best Fitness Tracking App',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  Text(
                    'Transform Your Life',
                    style: AppTextStyles.h2.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const Spacer(flex: 4),

                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.go('/onboarding/goal'),
                        borderRadius: AppRadius.borderXxl,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.borderXxl,
                            boxShadow: AppShadows.lg,
                          ),
                          child: Center(
                            child: Text(
                              "Let's get started!",
                              style: AppTextStyles.buttonText.copyWith(
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text(
                      'Already have an account? Sign in',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
