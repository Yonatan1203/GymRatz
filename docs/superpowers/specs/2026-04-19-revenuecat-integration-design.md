# RevenueCat Integration Update — Design Spec

**Date:** 2026-04-19
**Branch:** `feature/production-readiness`
**Status:** Approved

## Summary

Update the existing RevenueCat integration from placeholder configuration to a fully functional subscription system. Wire up the real API key, correct entitlement ID, add Customer Center for subscription management, and improve the paywall's pricing card UX.

## Scope

**In scope:**
- Configure real API key and entitlement ID
- Add `purchases_ui_flutter` dependency for Customer Center
- Make `EntitlementRepository` a singleton (fix main.dart/provider mismatch)
- Enable debug logging in dev mode
- Improve paywall pricing cards (sort by duration, best value badge, per-week pricing)
- Replace manual "Manage Subscription" + "Restore Purchases" in settings with RevenueCat Customer Center

**Out of scope:**
- Feature gating enforcement (free tier limits not enforced yet — separate task)
- Remote paywall UI (keeping custom PaywallScreen)
- Apple-specific configuration (no Apple Developer Account yet)
- RevenueCat webhook/server-side integration

## Configuration Changes

### constants.dart

| Constant | Before | After |
|----------|--------|-------|
| `revenueCatGoogleApiKey` default | `goog_REPLACE_ME` | `test_QPrCcBDWPprQOPWibhFNchqaTPB` |
| `revenueCatAppleApiKey` default | `appl_REPLACE_ME` | `appl_REPLACE_ME` (unchanged — no Apple account yet) |
| `entitlementId` | `pro` | `GymRatz` |
| `defaultOfferingId` | `default` | Removed (unused) |

Add product identifier constants:
- `productWeekly = 'weekly'`
- `productMonthly = 'monthly'`
- `productYearly = 'yearly'`

### RevenueCat Dashboard (manual, not code)

These must be configured in the RevenueCat dashboard to match:
- **Entitlement:** `GymRatz`
- **Products:** `weekly`, `monthly`, `yearly` (linked to Google Play product IDs)
- **Offering:** default offering containing all three products

## File Changes

### 1. `pubspec.yaml` — Add dependency

Add `purchases_ui_flutter` alongside existing `purchases_flutter`.

### 2. `lib/core/constants.dart` — Update config

- Change `revenueCatGoogleApiKey` default to `test_QPrCcBDWPprQOPWibhFNchqaTPB`
- Change `entitlementId` from `pro` to `GymRatz`
- Remove `defaultOfferingId`
- Add `productWeekly`, `productMonthly`, `productYearly` constants

### 3. `lib/features/subscription/data/entitlement_repository.dart` — Singleton + debug logs

Convert to singleton pattern so `main.dart` and the Riverpod provider share the same instance:

```dart
class EntitlementRepository {
  static final EntitlementRepository _instance = EntitlementRepository._internal();
  factory EntitlementRepository() => _instance;
  EntitlementRepository._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final apiKey = Platform.isIOS
        ? AppConstants.revenueCatAppleApiKey
        : AppConstants.revenueCatGoogleApiKey;

    if (apiKey.contains('REPLACE_ME')) {
      debugPrint('RevenueCat: placeholder API key — subscription features disabled');
      return;
    }

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    await Purchases.configure(PurchasesConfiguration(apiKey));
  }

  // ... rest unchanged, entitlement checks already use AppConstants.entitlementId
}
```

Add `getCustomerInfo()` method:

```dart
Future<CustomerInfo> getCustomerInfo() async {
  return await Purchases.getCustomerInfo();
}
```

### 4. `lib/features/subscription/presentation/paywall_screen.dart` — Pricing UX

Update `_buildPricingCards` to:

- Sort packages: weekly → monthly → yearly (by `packageType` enum order)
- Add "Best Value" badge on the yearly package
- Show per-week equivalent price on monthly and yearly packages
- Highlight yearly card with a distinct border/gradient

Package sorting logic:
```dart
final sortOrder = {
  PackageType.weekly: 0,
  PackageType.monthly: 1,
  PackageType.annual: 2,
};
packages.sort((a, b) =>
  (sortOrder[a.packageType] ?? 99).compareTo(sortOrder[b.packageType] ?? 99));
```

Per-week calculation:
- Weekly: show price as-is
- Monthly: `price / 4.33` per week
- Yearly: `price / 52` per week

### 5. `lib/features/settings/presentation/settings_screen.dart` — Customer Center

Replace the SUBSCRIPTION section:

**Before:**
```
Manage Subscription → routes to /paywall
Restore Purchases → calls restorePurchases()
```

**After:**
```
Manage Subscription → opens RevenueCat CustomerCenterView
Upgrade to Pro → routes to /paywall (only shown if NOT pro)
```

Customer Center implementation:
```dart
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

// In the menu item onTap:
onTap: () async {
  await RevenueCatUI.presentCustomerCenter();
}
```

Customer Center handles:
- View active subscription details
- Cancel/manage subscription
- Restore purchases
- Contact support

The separate "Restore Purchases" row is removed since Customer Center includes it.

### 6. `lib/main.dart` — No structural change

`EntitlementRepository()` in main.dart now returns the singleton, so it automatically shares state with the provider. No code change needed — the singleton pattern fix in `entitlement_repository.dart` resolves this.

## Files NOT Changed

| File | Reason |
|------|--------|
| `entitlement_service.dart` | Thin wrapper, delegates to repository — still valid |
| `auth_service.dart` | RevenueCat login/logout calls unchanged — entitlement ID change is in constants |
| `subscription_providers.dart` | Provider structure unchanged — singleton means same instance |
| `upsell_banner.dart` | No changes needed |
| `profile_screen.dart` | Watches `isProProvider` — no changes needed |
| `router.dart` | Routes unchanged |

## Testing Plan

1. **Build succeeds** — `flutter build apk --dart-define=ENV=dev`
2. **App launches** — no ANR, RevenueCat initializes with debug logs visible
3. **Paywall loads** — offerings display with weekly/monthly/yearly sorted correctly
4. **Customer Center opens** — from settings, shows subscription management UI
5. **Entitlement check** — `isProProvider` correctly reflects `GymRatz` entitlement
6. **Auth flow** — sign up/in still links user with RevenueCat (check debug logs)
7. **Sandbox purchase** — test purchase flow with RevenueCat sandbox/test user
