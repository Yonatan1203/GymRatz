# Phase 1: Cleanup & Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the dark/light mode quick-toggle from all screens, rework the subscription model to trial-only with monthly/yearly plans (no free tier), and clarify the "main program" concept in the UI.

**Architecture:** The app already has a `ThemeNotifier` with SharedPreferences persistence, RevenueCat integration with `isProProvider`, and an active program system using `isActive` flag on program documents. We'll extend ThemeNotifier to support system mode, gut the free-tier concept entirely, add a subscription gate that makes the app read-only when expired, and improve the main program UX in the Programs screen.

**Tech Stack:** Flutter/Dart, Riverpod, SharedPreferences, RevenueCat (purchases_flutter), Cloud Firestore

---

## File Structure

### Files to Modify:
- `lib/app/providers.dart` — Upgrade ThemeNotifier to support system/light/dark
- `lib/shared/widgets/custom_scaffold.dart` — Remove `_ThemeToggle` widget and its Positioned wrapper
- `lib/features/settings/presentation/settings_screen.dart` — Replace toggle with 3-option theme selector, remove "Upgrade to Pro" menu item
- `lib/features/profile/presentation/edit_profile_screen.dart` — Remove Dark Mode preference row
- `lib/features/profile/presentation/profile_screen.dart` — Remove subscription item section
- `lib/features/subscription/presentation/paywall_screen.dart` — Remove free vs pro comparison table, show trial/subscribe messaging
- `lib/core/constants.dart` — Remove free tier limits, remove weekly product
- `lib/app/providers/subscription_providers.dart` — Add `isTrialActiveProvider` and `subscriptionStateProvider`
- `lib/features/subscription/data/entitlement_repository.dart` — Add trial detection method
- `lib/features/programs/presentation/programs_screen.dart` — Add "Set as Main" action on non-active programs

### Files to Delete:
- `lib/shared/widgets/theme_toggle_button.dart` — Unused standalone toggle widget

### Files to Create:
- `lib/features/subscription/presentation/subscription_gate.dart` — Widget wrapper that blocks write actions when not subscribed
- `lib/features/subscription/presentation/expired_banner.dart` — Persistent banner shown when subscription expired

---

## Task 1: Upgrade ThemeNotifier to Support System Mode

**Files:**
- Modify: `lib/app/providers.dart`

- [ ] **Step 1: Update ThemeNotifier to support three modes**

Replace the entire ThemeNotifier section (lines 12-39) in `lib/app/providers.dart`:

```dart
// ─── Theme Provider ───
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'theme_mode';

  ThemeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    switch (value) {
      case 'light':
        state = ThemeMode.light;
        break;
      case 'dark':
        state = ThemeMode.dark;
        break;
      default:
        state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.light:
        await prefs.setString(_key, 'light');
        break;
      case ThemeMode.dark:
        await prefs.setString(_key, 'dark');
        break;
      case ThemeMode.system:
        await prefs.setString(_key, 'system');
        break;
    }
  }
}
```

- [ ] **Step 2: Verify the app still compiles**

Run: `flutter analyze lib/app/providers.dart`
Expected: No errors (the old `toggleTheme()` method is removed; callers will be fixed in subsequent tasks)

- [ ] **Step 3: Commit**

```bash
git add lib/app/providers.dart
git commit -m "refactor: upgrade ThemeNotifier to support system/light/dark modes"
```

---

## Task 2: Remove Theme Toggle from CustomScaffold

**Files:**
- Modify: `lib/shared/widgets/custom_scaffold.dart`
- Delete: `lib/shared/widgets/theme_toggle_button.dart`

- [ ] **Step 1: Remove the Positioned theme toggle and _ThemeToggle class**

In `lib/shared/widgets/custom_scaffold.dart`:

Remove lines 35-40 (the Positioned widget wrapping _ThemeToggle):
```dart
          // Theme toggle button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: _ThemeToggle(isDark: isDark, ref: ref),
          ),
```

Remove the entire `_ThemeToggle` class (lines 136-170):
```dart
class _ThemeToggle extends StatelessWidget {
  final bool isDark;
  final WidgetRef ref;

  const _ThemeToggle({required this.isDark, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Switch to ${isDark ? 'light' : 'dark'} mode',
      child: GestureDetector(
      onTap: () {
        PlatformAdapter.hapticMedium();
        ref.read(themeProvider.notifier).toggleTheme();
      },
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: AnimatedRotation(
            turns: isDark ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isDark ? AppIcons.sun : AppIcons.moon,
              size: 20,
              color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
            ),
          ),
        ),
      ),
    ),
    );
  }
}
```

Also remove unused imports that were only needed by `_ThemeToggle`:
- Remove `import '../../theme/app_icons.dart';` (check if still used by nav items — it IS used by nav items, so keep it)
- Remove `import '../../app/providers.dart';` ONLY if not used elsewhere in the file. (It's used by `activeWorkoutSessionProvider`, so keep it)
- Remove `import '../../theme/app_colors.dart';` ONLY if not used elsewhere. (Used by nav bar colors, so keep it)
- Remove `import '../utils/platform_adapter.dart';` ONLY if not used elsewhere. (Used by `_NavItem._handleTap`, so keep it)

After reviewing: no imports need removal — all are used by the bottom nav.

- [ ] **Step 2: Delete the unused ThemeToggleButton file**

Delete: `lib/shared/widgets/theme_toggle_button.dart`

- [ ] **Step 3: Verify compilation**

Run: `flutter analyze lib/shared/widgets/custom_scaffold.dart`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git rm lib/shared/widgets/theme_toggle_button.dart
git add lib/shared/widgets/custom_scaffold.dart
git commit -m "feat: remove dark/light mode quick-toggle from all screens"
```

---

## Task 3: Update Settings Screen with Three-Option Theme Selector

**Files:**
- Modify: `lib/features/settings/presentation/settings_screen.dart`

- [ ] **Step 1: Replace the APPEARANCE section (lines 50-66)**

Replace the current toggle card with a segmented theme selector:

```dart
                  _sectionTitle(context, 'APPEARANCE'),
                  CustomCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(isDark ? AppIcons.moon : AppIcons.sun, size: 20.r, color: context.mutedForeground),
                            SizedBox(width: 12.w),
                            Text('Theme', style: AppTextStyles.body.copyWith(color: context.foreground)),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        _buildThemeSelector(ref, isDark),
                      ],
                    ),
                  ),
```

- [ ] **Step 2: Add the _buildThemeSelector helper method**

Add this method inside `_SettingsScreenState`:

```dart
  Widget _buildThemeSelector(WidgetRef ref, bool isDark) {
    final currentMode = ref.watch(themeProvider);

    return Row(
      children: [
        _themeOption(ref, 'Light', ThemeMode.light, currentMode, isDark),
        SizedBox(width: 8.w),
        _themeOption(ref, 'Dark', ThemeMode.dark, currentMode, isDark),
        SizedBox(width: 8.w),
        _themeOption(ref, 'System', ThemeMode.system, currentMode, isDark),
      ],
    );
  }

  Widget _themeOption(WidgetRef ref, String label, ThemeMode mode, ThemeMode current, bool isDark) {
    final isSelected = current == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(themeProvider.notifier).setThemeMode(mode),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected
                ? context.primaryColor.withOpacity(0.12)
                : context.mutedColor,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected ? context.primaryColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? context.primaryColor : context.mutedForeground,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
```

- [ ] **Step 3: Remove "Upgrade to Pro" from the SUBSCRIPTION section**

Replace lines 148-163 (the conditional Upgrade to Pro menu item) with just `const SizedBox.shrink()`:

```dart
                        Divider(color: context.mutedForeground.withOpacity(0.15), height: 1),
                        MenuItemWidget(
                          icon: AppIcons.zap,
                          label: 'Subscribe',
                          onTap: () => context.push('/paywall'),
                        ),
```

This always shows "Subscribe" which navigates to the paywall. The paywall will handle showing the right messaging based on subscription state.

- [ ] **Step 4: Verify compilation**

Run: `flutter analyze lib/features/settings/presentation/settings_screen.dart`
Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/presentation/settings_screen.dart
git commit -m "feat: replace theme toggle with 3-option selector, simplify subscription menu"
```

---

## Task 4: Remove Dark Mode Toggle from Edit Profile Screen

**Files:**
- Modify: `lib/features/profile/presentation/edit_profile_screen.dart`

- [ ] **Step 1: Remove the Dark Mode preference row (lines 250-254)**

Remove these lines:
```dart
                  _prefRow(
                    'Dark Mode',
                    ref.watch(themeProvider) == ThemeMode.dark,
                    (_) => ref.read(themeProvider.notifier).toggleTheme(),
                  ),
```

- [ ] **Step 2: Verify compilation**

Run: `flutter analyze lib/features/profile/presentation/edit_profile_screen.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/profile/presentation/edit_profile_screen.dart
git commit -m "feat: remove dark mode toggle from edit profile (managed in settings only)"
```

---

## Task 5: Remove Subscription Section from Profile Screen

**Files:**
- Modify: `lib/features/profile/presentation/profile_screen.dart`

- [ ] **Step 1: Remove the _buildSubscriptionItem method call and method**

Find where `_buildSubscriptionItem` is called in the build method and remove that call (the entire section including the SUBSCRIPTION header and card). Also remove the method itself (lines 180-203).

- [ ] **Step 2: Remove the isProProvider import if no longer used**

Check if `isProProvider` is still referenced anywhere else in this file. If not, no import change needed (it comes from the barrel `providers.dart` export).

- [ ] **Step 3: Verify compilation**

Run: `flutter analyze lib/features/profile/presentation/profile_screen.dart`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add lib/features/profile/presentation/profile_screen.dart
git commit -m "feat: remove upgrade to pro section from profile screen"
```

---

## Task 6: Update Constants — Remove Free Tier Limits

**Files:**
- Modify: `lib/core/constants.dart`

- [ ] **Step 1: Remove free tier constants and weekly product**

Replace the entire file with:

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
  static const String productMonthly = 'monthly';
  static const String productYearly = 'yearly';

  // App info
  static const String appVersion = '1.0.0';
  static const String privacyPolicyUrl = 'https://gymratz-app.github.io/privacy';
  static const String termsOfServiceUrl = 'https://gymratz-app.github.io/terms';
}
```

Changes: removed `productWeekly`, removed `freeMaxActivePrograms`, removed `freeHistoryWeeks`, updated legal URLs to GitHub Pages.

- [ ] **Step 2: Search for usages of removed constants**

Run: `grep -r "freeMaxActivePrograms\|freeHistoryWeeks\|productWeekly" lib/`

If any files reference these, remove those references in subsequent steps.

- [ ] **Step 3: Verify compilation**

Run: `flutter analyze`
Expected: No errors referencing removed constants

- [ ] **Step 4: Commit**

```bash
git add lib/core/constants.dart
git commit -m "refactor: remove free tier limits and weekly product from constants"
```

---

## Task 7: Add Subscription State Detection (Trial/Active/Expired)

**Files:**
- Modify: `lib/features/subscription/data/entitlement_repository.dart`
- Modify: `lib/features/subscription/domain/entitlement_service.dart`
- Modify: `lib/app/providers/subscription_providers.dart`

- [ ] **Step 1: Add trial and expiry detection to EntitlementRepository**

Add these methods to `EntitlementRepository` (after the `restorePurchases` method, before the closing `}`):

```dart
  /// Get the subscription state: active, trial, or expired.
  Future<SubscriptionState> getSubscriptionState() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final entitlement = info.entitlements.active[AppConstants.entitlementId];
      if (entitlement == null) return SubscriptionState.expired;
      if (entitlement.periodType == PeriodType.trial) {
        return SubscriptionState.trial;
      }
      return SubscriptionState.active;
    } catch (_) {
      return SubscriptionState.expired;
    }
  }

  /// Stream of subscription state changes.
  Stream<SubscriptionState> subscriptionStateStream() {
    final controller = StreamController<SubscriptionState>.broadcast();

    getSubscriptionState().then((state) {
      if (!controller.isClosed) controller.add(state);
    });

    Purchases.addCustomerInfoUpdateListener((info) {
      if (controller.isClosed) return;
      final entitlement = info.entitlements.active[AppConstants.entitlementId];
      if (entitlement == null) {
        controller.add(SubscriptionState.expired);
      } else if (entitlement.periodType == PeriodType.trial) {
        controller.add(SubscriptionState.trial);
      } else {
        controller.add(SubscriptionState.active);
      }
    });

    return controller.stream;
  }
```

- [ ] **Step 2: Add the SubscriptionState enum**

Add at the top of `lib/features/subscription/data/entitlement_repository.dart` (after imports, before the class):

```dart
enum SubscriptionState { trial, active, expired }
```

- [ ] **Step 3: Expose in EntitlementService**

Add to `lib/features/subscription/domain/entitlement_service.dart`:

```dart
  SubscriptionState getSubscriptionState() => _repo.getSubscriptionState();
  Stream<SubscriptionState> subscriptionStateStream() => _repo.subscriptionStateStream();
```

Wait — the service is a thin wrapper. Let me read it first.

Actually, add these forwarding methods to the EntitlementService class:

```dart
  Future<SubscriptionState> getSubscriptionState() => _repo.getSubscriptionState();
  Stream<SubscriptionState> subscriptionStateStream() => _repo.subscriptionStateStream();
```

And add the import for `SubscriptionState` at the top of the service file:
```dart
import '../data/entitlement_repository.dart' show SubscriptionState;
```

- [ ] **Step 4: Add subscriptionStateProvider**

Add to `lib/app/providers/subscription_providers.dart`:

```dart
import '../../features/subscription/data/entitlement_repository.dart' show SubscriptionState;

final subscriptionStateProvider = StreamProvider<SubscriptionState>((ref) {
  return ref.watch(entitlementServiceProvider).subscriptionStateStream();
});
```

- [ ] **Step 5: Verify compilation**

Run: `flutter analyze`
Expected: No errors

- [ ] **Step 6: Commit**

```bash
git add lib/features/subscription/data/entitlement_repository.dart
git add lib/features/subscription/domain/entitlement_service.dart
git add lib/app/providers/subscription_providers.dart
git commit -m "feat: add subscription state detection (trial/active/expired)"
```

---

## Task 8: Create Subscription Gate Widget

**Files:**
- Create: `lib/features/subscription/presentation/subscription_gate.dart`

- [ ] **Step 1: Create the SubscriptionGate widget**

Create `lib/features/subscription/presentation/subscription_gate.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_spacing.dart';
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
      error: (_, __) => child, // Fail open — don't block on error
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
```

- [ ] **Step 2: Verify compilation**

Run: `flutter analyze lib/features/subscription/presentation/subscription_gate.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/subscription/presentation/subscription_gate.dart
git commit -m "feat: add SubscriptionGate widget for read-only mode when expired"
```

---

## Task 9: Integrate SubscriptionGate into Main App Shell

**Files:**
- Modify: `lib/shared/widgets/custom_scaffold.dart`

- [ ] **Step 1: Wrap the navigation shell content with SubscriptionGate**

In `custom_scaffold.dart`, wrap the `navigationShell` inside the Column with `SubscriptionGate`:

Replace:
```dart
              Expanded(child: navigationShell),
```

With:
```dart
              Expanded(
                child: SubscriptionGate(child: navigationShell),
              ),
```

Add import at the top:
```dart
import '../../features/subscription/presentation/subscription_gate.dart';
```

- [ ] **Step 2: Verify compilation**

Run: `flutter analyze lib/shared/widgets/custom_scaffold.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/custom_scaffold.dart
git commit -m "feat: integrate subscription gate into main app shell"
```

---

## Task 10: Rework Paywall Screen (No Free vs Pro Comparison)

**Files:**
- Modify: `lib/features/subscription/presentation/paywall_screen.dart`

- [ ] **Step 1: Replace the header text**

Replace line 112:
```dart
                  Text('Upgrade to Pro', style: AppTextStyles.h1.copyWith(color: Colors.white)),
```
With:
```dart
                  Text('GymRatz Premium', style: AppTextStyles.h1.copyWith(color: Colors.white)),
```

Replace line 114:
```dart
                  Text('Unlock your full potential', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
```
With:
```dart
                  Text('Track workouts, build programs, crush your goals', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
```

- [ ] **Step 2: Replace _buildFeatureComparison with a benefits list**

Replace the entire `_buildFeatureComparison` method (lines 151-188) with:

```dart
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
```

- [ ] **Step 3: Filter out weekly package from pricing cards**

In `_buildPricingCards`, after the `packages` assignment (line 192), add a filter:

```dart
    // Only show monthly and yearly
    packages.removeWhere((p) => p.packageType == PackageType.weekly);
```

- [ ] **Step 4: Add trial info text below pricing cards**

In the `build` method, after `_buildPricingCards` and before "Restore Purchases" (around line 128), add:

```dart
                  SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text(
                      '7-day free trial included \u2022 Cancel anytime',
                      style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
                      textAlign: TextAlign.center,
                    ),
                  ),
```

- [ ] **Step 5: Verify compilation**

Run: `flutter analyze lib/features/subscription/presentation/paywall_screen.dart`
Expected: No errors

- [ ] **Step 6: Commit**

```bash
git add lib/features/subscription/presentation/paywall_screen.dart
git commit -m "feat: rework paywall to premium model (no free tier comparison)"
```

---

## Task 11: Delete UpsellBanner Widget

**Files:**
- Delete: `lib/features/subscription/presentation/upsell_banner.dart`

- [ ] **Step 1: Verify UpsellBanner is not imported anywhere in lib/**

Run: `grep -r "upsell_banner" lib/`
Expected: No results (already confirmed it's only referenced in a spec doc)

- [ ] **Step 2: Delete the file**

```bash
git rm lib/features/subscription/presentation/upsell_banner.dart
```

- [ ] **Step 3: Commit**

```bash
git commit -m "chore: delete unused UpsellBanner widget"
```

---

## Task 12: Add "Set as Main" Action to Programs Screen

**Files:**
- Modify: `lib/features/programs/presentation/programs_screen.dart`

- [ ] **Step 1: Update _buildProgramCard to add "Set as Main" button for non-active programs**

Replace the badge section in `_buildProgramCard` (lines 148-156). The current code shows an "Active" badge when `p.isActive`. Update to also show a "Set as Main" button when not active:

Replace:
```dart
                if (p.isActive)
                  Padding(
                    padding: EdgeInsets.only(right: AppSpacing.md),
                    child: CustomBadge(
                      text: 'Active',
                      backgroundColor: context.coralColor.withOpacity(0.12),
                      textColor: context.coralColor,
                    ),
                  ),
```

With:
```dart
                if (p.isActive)
                  Padding(
                    padding: EdgeInsets.only(right: AppSpacing.md),
                    child: CustomBadge(
                      text: 'Main',
                      backgroundColor: context.coralColor.withOpacity(0.12),
                      textColor: context.coralColor,
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.only(right: AppSpacing.md),
                    child: GestureDetector(
                      onTap: () async {
                        final uid = ref.read(currentUidProvider);
                        if (uid == null) return;
                        await ref.read(programRepositoryProvider).setActiveProgram(uid, p.id);
                      },
                      child: CustomBadge(
                        text: 'Set as Main',
                        backgroundColor: context.primaryColor.withOpacity(0.08),
                        textColor: context.primaryColor,
                      ),
                    ),
                  ),
```

Note: `_buildProgramCard` needs to accept `WidgetRef ref` as a parameter. Update the method signature:

From:
```dart
Widget _buildProgramCard(BuildContext context, Program p) {
```

To:
```dart
Widget _buildProgramCard(BuildContext context, Program p, WidgetRef ref) {
```

And update all call sites of `_buildProgramCard` to pass `ref`.

- [ ] **Step 2: Update the empty state text for workout screen**

In `lib/features/workout/presentation/workout_screen.dart`, update the empty body message (line 115):

From:
```dart
                Text('No Active Program', style: AppTextStyles.h3.copyWith(color: context.foreground, fontWeight: FontWeight.w600)),
```

To:
```dart
                Text('No Main Program', style: AppTextStyles.h3.copyWith(color: context.foreground, fontWeight: FontWeight.w600)),
```

And line 117-120:
From:
```dart
                Text(
                  'Create or activate a program to start tracking your workouts.',
                  style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
                  textAlign: TextAlign.center,
                ),
```

To:
```dart
                Text(
                  'Set a main program to see your weekly workouts here.',
                  style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
                  textAlign: TextAlign.center,
                ),
```

- [ ] **Step 3: Verify compilation**

Run: `flutter analyze`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add lib/features/programs/presentation/programs_screen.dart
git add lib/features/workout/presentation/workout_screen.dart
git commit -m "feat: add 'Set as Main' action on programs, update empty state messaging"
```

---

## Task 13: Final Verification & Cleanup

**Files:** All modified files

- [ ] **Step 1: Run full static analysis**

Run: `flutter analyze`
Expected: No errors

- [ ] **Step 2: Run existing tests**

Run: `flutter test`
Expected: All existing tests pass (or skip if none exist)

- [ ] **Step 3: Search for any remaining references to removed items**

Run:
```bash
grep -r "toggleTheme\|Upgrade to Pro\|freeMaxActivePrograms\|freeHistoryWeeks\|productWeekly\|ThemeToggleButton" lib/
```

Expected: No matches. If any remain, fix them.

- [ ] **Step 4: Verify app builds for both platforms**

Run: `flutter build apk --debug`
Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Final commit (if any cleanup was needed)**

```bash
git add -A
git commit -m "chore: phase 1 cleanup — fix remaining references to removed code"
```
