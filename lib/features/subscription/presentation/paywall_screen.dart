import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../app/providers.dart';
import '../../../theme/app_gradients.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/gym_ratz_background.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  Offerings? _offerings;
  bool _loading = true;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await ref.read(entitlementServiceProvider).getOfferings();
      if (mounted) setState(() { _offerings = offerings; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _purchase(Package package) async {
    setState(() => _purchasing = true);
    try {
      final success = await ref.read(entitlementServiceProvider).purchase(package);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase successful! Welcome to Pro.')),
        );
        context.pop();
      }
    } on PlatformException catch (e) {
      if (e.code == 'PURCHASE_CANCELLED') {
        // User cancelled — do nothing
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _purchasing = true);
    try {
      final success = await ref.read(entitlementServiceProvider).restorePurchases();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored!')),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No purchases found to restore')),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      body: GymRatzBackground(
        intensity: BackgroundIntensity.medium,
        child: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              showBackButton: true,
              child: Column(
                children: [
                  Icon(AppIcons.crown, size: 48.r, color: Colors.white),
                  SizedBox(height: 12.h),
                  Text('Upgrade to Pro', style: AppTextStyles.h1.copyWith(color: Colors.white)),
                  SizedBox(height: 4.h),
                  Text('Unlock your full potential', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                children: [
                  _buildFeatureComparison(context, isDark),
                  SizedBox(height: AppSpacing.sectionGap),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else
                    _buildPricingCards(context, isDark),
                  SizedBox(height: 16.h),
                  GestureDetector(
                    onTap: _purchasing ? null : _restore,
                    child: Text(
                      'Restore Purchases',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.primaryColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildFeatureComparison(BuildContext context, bool isDark) {
    final features = [
      ('Active Programs', '1', 'Unlimited', AppIcons.dumbbell),
      ('Workout History', '2 weeks', 'Full', AppIcons.calendar),
      ('Exercise Library', 'Basic', 'All', AppIcons.list),
      ('Progressive Overload', 'Basic', 'Advanced', AppIcons.trendingUp),
      ('Export Data', '-', 'Yes', AppIcons.download),
      ('Priority Support', '-', 'Yes', AppIcons.headphones),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: context.borderColor),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                Expanded(child: Text('Feature', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground, fontWeight: FontWeight.w600))),
                SizedBox(width: 60.w, child: Center(child: Text('Free', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground, fontWeight: FontWeight.w600)))),
                SizedBox(width: 60.w, child: Center(child: Text('Pro', style: AppTextStyles.bodySmall.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600)))),
              ],
            ),
          ),
          Divider(color: context.borderColor, height: 1),
          ...features.map((f) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                Icon(f.$4, size: 16.r, color: context.mutedForeground),
                SizedBox(width: 8.w),
                Expanded(child: Text(f.$1, style: AppTextStyles.bodySmall.copyWith(color: context.foreground))),
                SizedBox(width: 60.w, child: Center(child: Text(f.$2, style: AppTextStyles.caption.copyWith(color: context.mutedForeground)))),
                SizedBox(width: 60.w, child: Center(child: Text(f.$3, style: AppTextStyles.caption.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600)))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPricingCards(BuildContext context, bool isDark) {
    final offering = _offerings?.current;
    final packages = offering?.availablePackages ?? [];

    if (packages.isEmpty) {
      return CustomButton(
        text: 'Start Free Trial',
        variant: ButtonVariant.gradient,
        onPressed: () {},
      );
    }

    // Sort: weekly → monthly → yearly
    final sortOrder = {
      PackageType.weekly: 0,
      PackageType.monthly: 1,
      PackageType.annual: 2,
    };
    packages.sort((a, b) =>
        (sortOrder[a.packageType] ?? 99)
            .compareTo(sortOrder[b.packageType] ?? 99));

    return Column(
      children: packages.map((pkg) {
        final product = pkg.storeProduct;
        final isYearly = pkg.packageType == PackageType.annual;
        final perWeek = _perWeekPrice(pkg);

        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: GestureDetector(
            onTap: _purchasing ? null : () => _purchase(pkg),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    gradient: isYearly
                        ? AppGradients.primary(isDark: isDark)
                        : null,
                    color: isYearly ? null : context.cardColor,
                    borderRadius: AppRadius.borderXl,
                    border: isYearly
                        ? null
                        : Border.all(color: context.borderColor),
                    boxShadow: isYearly ? AppShadows.lg : AppShadows.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _packageLabel(pkg),
                              style: AppTextStyles.h3.copyWith(
                                color: isYearly
                                    ? Colors.white
                                    : context.foreground,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (perWeek != null) ...[
                              SizedBox(height: 2.h),
                              Text(
                                '$perWeek / week',
                                style: AppTextStyles.caption.copyWith(
                                  color: isYearly
                                      ? Colors.white70
                                      : context.mutedForeground,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        product.priceString,
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                          color:
                              isYearly ? Colors.white : context.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isYearly)
                  Positioned(
                    top: -10.h,
                    right: 16.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        'Best Value',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _packageLabel(Package pkg) {
    switch (pkg.packageType) {
      case PackageType.weekly:
        return 'Weekly';
      case PackageType.monthly:
        return 'Monthly';
      case PackageType.annual:
        return 'Yearly';
      default:
        return pkg.storeProduct.title;
    }
  }

  String? _perWeekPrice(Package pkg) {
    final price = pkg.storeProduct.price;
    if (price <= 0) return null;

    final String currencyCode = pkg.storeProduct.currencyCode;
    String symbol = currencyCode;
    // Common currency symbols
    if (currencyCode == 'USD') symbol = '\$';
    if (currencyCode == 'EUR') symbol = '€';
    if (currencyCode == 'GBP') symbol = '£';
    if (currencyCode == 'ILS') symbol = '₪';

    switch (pkg.packageType) {
      case PackageType.monthly:
        return '$symbol${(price / 4.33).toStringAsFixed(2)}';
      case PackageType.annual:
        return '$symbol${(price / 52).toStringAsFixed(2)}';
      default:
        return null; // No per-week for weekly
    }
  }
}
