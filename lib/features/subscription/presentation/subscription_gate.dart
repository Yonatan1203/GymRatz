import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../data/entitlement_repository.dart' show SubscriptionState;

/// Wraps a child widget and blocks interaction when subscription is expired.
/// Shows a banner at the top directing user to subscribe.
class SubscriptionGate extends ConsumerWidget {
  final Widget child;

  const SubscriptionGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subState = ref.watch(subscriptionStateProvider);

    return subState.when(
      data: (state) {
        if (state == SubscriptionState.expired) {
          return Column(
            children: [
              _ExpiredBanner(),
              Expanded(child: AbsorbPointer(child: Opacity(opacity: 0.6, child: child))),
            ],
          );
        }
        return child;
      },
      loading: () => child,
      error: (e, st) => child, // Fail open — don't block on error
    );
  }
}

class _ExpiredBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/paywall'),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        color: context.primaryColor,
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Icon(AppIcons.crown, size: 18.r, color: Colors.white),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Your trial has ended. Subscribe to continue.',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                ),
              ),
              Icon(AppIcons.chevronRight, size: 16.r, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}
