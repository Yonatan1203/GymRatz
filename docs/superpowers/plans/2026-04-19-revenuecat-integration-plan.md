# RevenueCat Integration Update — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire up RevenueCat with real API key, correct entitlement ID, Customer Center, and improved paywall pricing UX.

**Architecture:** Update existing subscription infrastructure (repository → service → providers → UI). Make EntitlementRepository a singleton, update constants, add `purchases_ui_flutter` for Customer Center, and improve paywall pricing cards.

**Tech Stack:** Flutter, purchases_flutter ^8.5.1, purchases_ui_flutter (new), Riverpod

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `pubspec.yaml` | Modify | Add `purchases_ui_flutter` dependency |
| `lib/core/constants.dart` | Modify | Update API key, entitlement ID, add product IDs |
| `lib/features/subscription/data/entitlement_repository.dart` | Modify | Singleton pattern, debug logging, getCustomerInfo |
| `lib/features/subscription/presentation/paywall_screen.dart` | Modify | Sort packages, best value badge, per-week pricing |
| `lib/features/settings/presentation/settings_screen.dart` | Modify | Replace subscription section with Customer Center |

---

### Task 1: Add `purchases_ui_flutter` dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the dependency**

Run:
```bash
cd C:/Personal_Projects/GymRatz/Development/Version_0/GymRatz
flutter pub add purchases_ui_flutter
```

- [ ] **Step 2: Verify installation**

Run:
```bash
flutter pub deps | grep purchases
```

Expected output should show both `purchases_flutter` and `purchases_ui_flutter`.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add purchases_ui_flutter for Customer Center support"
```

---

### Task 2: Update constants

**Files:**
- Modify: `lib/core/constants.dart`

- [ ] **Step 1: Update constants.dart**

Replace the entire file content with:

```dart
/// App-wide constants and RevenueCat configuration.
class AppConstants {
  AppConstants._();

  // RevenueCat API Keys — pass via: --dart-define=RC_GOOGLE_KEY=goog_xxx
  static const String revenueCatAppleApiKey =
      String.fromEnvironment('RC_APPLE_KEY', defaultValue: 'appl_REPLACE_ME');
  static const String revenueCatGoogleApiKey =
      String.fromEnvironment('RC_GOOGLE_KEY',
          defaultValue: 'test_QPrCcBDWPprQOPWibhFNchqaTPB');

  // RevenueCat identifiers
  static const String entitlementId = 'GymRatz';

  // Product identifiers (must match RevenueCat dashboard)
  static const String productWeekly = 'weekly';
  static const String productMonthly = 'monthly';
  static const String productYearly = 'yearly';

  // Free tier limits
  static const int freeMaxActivePrograms = 1;
  static const int freeHistoryWeeks = 2;

  // App info
  static const String appVersion = '1.0.0';
  static const String privacyPolicyUrl = 'https://gymratz.app/privacy';
  static const String termsOfServiceUrl = 'https://gymratz.app/terms';
}
```

- [ ] **Step 2: Verify no compile errors**

Run:
```bash
cd C:/Personal_Projects/GymRatz/Development/Version_0/GymRatz
dart analyze lib/core/constants.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/core/constants.dart
git commit -m "feat: update RevenueCat config — real API key, GymRatz entitlement, product IDs"
```

---

### Task 3: Convert EntitlementRepository to singleton with debug logging

**Files:**
- Modify: `lib/features/subscription/data/entitlement_repository.dart`

- [ ] **Step 1: Update entitlement_repository.dart**

Replace the entire file content with:

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/constants.dart';

class EntitlementRepository {
  static final EntitlementRepository _instance =
      EntitlementRepository._internal();
  factory EntitlementRepository() => _instance;
  EntitlementRepository._internal();

  bool _initialized = false;

  /// Initialize RevenueCat SDK (call once at app startup).
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final apiKey = Platform.isIOS
        ? AppConstants.revenueCatAppleApiKey
        : AppConstants.revenueCatGoogleApiKey;

    if (apiKey.contains('REPLACE_ME')) {
      debugPrint(
          'RevenueCat: placeholder API key detected — subscription features disabled');
      return;
    }

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    await Purchases.configure(PurchasesConfiguration(apiKey));
  }

  /// Associate a Firebase UID with RevenueCat.
  Future<void> login(String uid) async {
    await Purchases.logIn(uid);
  }

  /// Detach the current user.
  Future<void> logout() async {
    await Purchases.logOut();
  }

  /// Check if the user has the active entitlement.
  Future<bool> isPro() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(AppConstants.entitlementId);
    } catch (_) {
      return false;
    }
  }

  /// Stream of pro status changes.
  Stream<bool> isProStream() {
    final controller = StreamController<bool>.broadcast();

    // Initial check
    isPro().then((val) {
      if (!controller.isClosed) controller.add(val);
    });

    // Listen for updates
    Purchases.addCustomerInfoUpdateListener((info) {
      if (!controller.isClosed) {
        controller.add(
          info.entitlements.active.containsKey(AppConstants.entitlementId),
        );
      }
    });

    return controller.stream;
  }

  /// Get current customer info.
  Future<CustomerInfo> getCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }

  /// Get available offerings.
  Future<Offerings> getOfferings() async {
    return await Purchases.getOfferings();
  }

  /// Purchase a package.
  Future<bool> purchase(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      return result.entitlements.active
          .containsKey(AppConstants.entitlementId);
    } catch (_) {
      return false;
    }
  }

  /// Restore previous purchases.
  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active
          .containsKey(AppConstants.entitlementId);
    } catch (_) {
      return false;
    }
  }
}
```

- [ ] **Step 2: Verify no compile errors**

Run:
```bash
dart analyze lib/features/subscription/data/entitlement_repository.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/features/subscription/data/entitlement_repository.dart
git commit -m "refactor: make EntitlementRepository singleton, add debug logging"
```

---

### Task 4: Update paywall pricing cards

**Files:**
- Modify: `lib/features/subscription/presentation/paywall_screen.dart`

- [ ] **Step 1: Update the `_buildPricingCards` method**

In `paywall_screen.dart`, replace the existing `_buildPricingCards` method (lines 196-248) with:

```dart
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
```

- [ ] **Step 2: Add missing import for AppShadows**

At the top of `paywall_screen.dart`, verify these imports are present (add any that are missing):

```dart
import '../../../theme/app_shadows.dart';
```

This import is already present in the file. No change needed.

- [ ] **Step 3: Verify no compile errors**

Run:
```bash
dart analyze lib/features/subscription/presentation/paywall_screen.dart
```

Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/features/subscription/presentation/paywall_screen.dart
git commit -m "feat: improve paywall pricing — sorted tiers, best value badge, per-week pricing"
```

---

### Task 5: Add Customer Center to settings

**Files:**
- Modify: `lib/features/settings/presentation/settings_screen.dart`

- [ ] **Step 1: Add the Customer Center import**

At the top of `settings_screen.dart`, add this import alongside the existing ones:

```dart
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
```

- [ ] **Step 2: Replace the SUBSCRIPTION section**

In `settings_screen.dart`, find the SUBSCRIPTION section (lines 127-137):

```dart
                  _sectionTitle(context, 'SUBSCRIPTION'),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        MenuItemWidget(icon: AppIcons.crown, label: 'Manage Subscription', onTap: () => context.push('/paywall')),
                        Divider(color: context.borderColor, height: 1),
                        MenuItemWidget(icon: AppIcons.refreshCw, label: 'Restore Purchases', onTap: _restorePurchases),
                      ],
                    ),
                  ),
```

Replace it with:

```dart
                  _sectionTitle(context, 'SUBSCRIPTION'),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        MenuItemWidget(
                          icon: AppIcons.crown,
                          label: 'Manage Subscription',
                          onTap: () async {
                            try {
                              await RevenueCatUI.presentCustomerCenter();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Could not open subscription manager: $e')),
                                );
                              }
                            }
                          },
                        ),
                        Divider(color: context.borderColor, height: 1),
                        ref.watch(isProProvider).when(
                          data: (isPro) => isPro
                              ? const SizedBox.shrink()
                              : MenuItemWidget(
                                  icon: AppIcons.zap,
                                  label: 'Upgrade to Pro',
                                  onTap: () => context.push('/paywall'),
                                ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => MenuItemWidget(
                            icon: AppIcons.zap,
                            label: 'Upgrade to Pro',
                            onTap: () => context.push('/paywall'),
                          ),
                        ),
                      ],
                    ),
                  ),
```

- [ ] **Step 3: Remove the now-unused `_restorePurchases` method**

Delete the `_restorePurchases` method (lines 224-240) since Customer Center handles restore:

```dart
  // DELETE THIS ENTIRE METHOD:
  Future<void> _restorePurchases() async {
    try {
      final service = ref.read(entitlementServiceProvider);
      await service.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }
```

- [ ] **Step 4: Check if `isProProvider` import is available**

The file already imports `../../../app/providers.dart` which exports `subscription_providers.dart` containing `isProProvider`. No new import needed.

- [ ] **Step 5: Verify no compile errors**

Run:
```bash
dart analyze lib/features/settings/presentation/settings_screen.dart
```

Expected: No issues found.

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/presentation/settings_screen.dart
git commit -m "feat: add RevenueCat Customer Center, conditionally show upgrade option"
```

---

### Task 6: Full build verification

- [ ] **Step 1: Run full analysis**

```bash
cd C:/Personal_Projects/GymRatz/Development/Version_0/GymRatz
dart analyze lib/
```

Expected: No errors. Warnings about unused imports or variables are OK to note but should not block.

- [ ] **Step 2: Build APK**

```bash
flutter build apk --debug --dart-define=ENV=dev
```

Expected: Build succeeds.

- [ ] **Step 3: Launch on emulator and verify**

```bash
flutter run --dart-define=ENV=dev
```

Verify in the debug logs:
- RevenueCat initializes with debug-level logging (no more "placeholder API key" message)
- No crash on launch

- [ ] **Step 4: Manual verification checklist**

1. Open the app → sign in or create account
2. Check debug logs for `RevenueCat` — should show SDK init and user login
3. Navigate to Settings → tap "Manage Subscription" → Customer Center should open
4. If not pro, "Upgrade to Pro" row should appear → tap it → paywall opens
5. Paywall should show pricing cards (if offerings are configured in RevenueCat dashboard)
6. If no offerings configured yet, the "Start Free Trial" fallback button should appear

- [ ] **Step 5: Final commit if any fixups needed**

```bash
git add -A
git commit -m "fix: address any issues found during verification"
```

Only run this if fixups were needed. Otherwise skip.
