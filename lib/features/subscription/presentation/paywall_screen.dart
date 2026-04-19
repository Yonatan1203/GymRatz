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
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/scale_tap.dart';
import '../../../shared/widgets/staggered_list.dart';

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
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              showBackButton: true,
              variant: HeaderVariant.hero,
              child: Column(
                children: [
                  Icon(AppIcons.crown, size: 48.r, color: Colors.white),
                  SizedBox(height: AppSpacing.lg),
                  Text('Upgrade to Pro', style: AppTextStyles.h1.copyWith(color: Colors.white)),
                  SizedBox(height: AppSpacing.sm),
                  Text('Unlock your full potential', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: StaggeredList(
                children: [
                  _buildFeatureComparison(context, isDark),
                  SizedBox(height: AppSpacing.sectionGap),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else
                    _buildPricingCards(context, isDark),
                  SizedBox(height: AppSpacing.xl),
                  Center(
                    child: ScaleTap(
                      onTap: _purchasing ? null : _restore,
                      child: Text(
                        'Restore Purchases',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ],
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

    return CustomCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('Feature', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground, fontWeight: FontWeight.w600))),
              SizedBox(width: 60.w, child: Center(child: Text('Free', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground, fontWeight: FontWeight.w600)))),
              SizedBox(width: 60.w, child: Center(child: Text('Pro', style: AppTextStyles.bodySmall.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600)))),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Divider(color: context.mutedForeground.withOpacity(0.15), height: 1),
          ...features.map((f) => Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Row(
              children: [
                Icon(f.$4, size: 16.r, color: context.mutedForeground),
                SizedBox(width: AppSpacing.md),
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

    // Sort: weekly -> monthly -> yearly
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
          padding: EdgeInsets.only(bottom: AppSpacing.lg),
          child: ScaleTap(
            onTap: _purchasing ? null : () => _purchase(pkg),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomCard(
                  gradient: isYearly
                      ? AppGradients.primary(isDark: isDark)
                      : null,
                  padding: EdgeInsets.all(AppSpacing.xxl),
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
                              SizedBox(height: AppSpacing.xs),
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
                    right: AppSpacing.xl,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
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
