import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../app/providers.dart';
import '../../../theme/app_gradients.dart';

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
                  Text('GymRatz Premium', style: AppTextStyles.h1.copyWith(color: Colors.white)),
                  SizedBox(height: AppSpacing.sm),
                  Text('Track workouts, build programs, crush your goals', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
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
                  SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text(
                      '7-day free trial included \u2022 Cancel anytime',
                      style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
                      textAlign: TextAlign.center,
                    ),
                  ),
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
      ('Unlimited Programs', AppIcons.dumbbell),
      ('Full Workout History', AppIcons.calendar),
      ('Complete Exercise Library', AppIcons.list),
      ('Progressive Overload Tracking', AppIcons.trendingUp),
      ('Export Your Data', AppIcons.download),
      ('Priority Support', AppIcons.headphones),
    ];

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Everything included:', style: AppTextStyles.h4.copyWith(color: context.foreground, fontWeight: FontWeight.w600)),
          SizedBox(height: AppSpacing.lg),
          ...features.map((f) => Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(AppIcons.checkCircle, size: 18.r, color: context.primaryColor),
                SizedBox(width: AppSpacing.lg),
                Icon(f.$2, size: 16.r, color: context.mutedForeground),
                SizedBox(width: AppSpacing.md),
                Text(f.$1, style: AppTextStyles.bodySmall.copyWith(color: context.foreground)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPricingCards(BuildContext context, bool isDark) {
    final offering = _offerings?.current;
    final packages = [...(offering?.availablePackages ?? [])];
    packages.removeWhere((p) => p.packageType == PackageType.weekly);

    if (packages.isEmpty) {
      return CustomButton(
        text: 'Start Free Trial',
        variant: ButtonVariant.gradient,
        isLoading: _loading,
        onPressed: () async {
          setState(() => _loading = true);
          await _loadOfferings();
          if (_offerings?.current?.availablePackages.isNotEmpty == true) {
            // Offerings loaded — UI will rebuild with pricing cards
            return;
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unable to load subscription options. Please check your connection and try again.')),
            );
          }
        },
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

    // Calculate savings for yearly plan
    final monthlyPkg = packages.where((p) => p.packageType == PackageType.monthly).toList();
    int savingsPercent = 0;
    if (monthlyPkg.isNotEmpty) {
      final monthlyCost = monthlyPkg.first.storeProduct.price * 12;
      final yearlyPkg = packages.where((p) => p.packageType == PackageType.annual).toList();
      if (yearlyPkg.isNotEmpty && monthlyCost > 0) {
        final savings = monthlyCost - yearlyPkg.first.storeProduct.price;
        savingsPercent = ((savings / monthlyCost) * 100).round();
      }
    }

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
                            if (isYearly && savingsPercent > 0) ...[
                              SizedBox(height: AppSpacing.xs),
                              Text(
                                'Save $savingsPercent%',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
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
