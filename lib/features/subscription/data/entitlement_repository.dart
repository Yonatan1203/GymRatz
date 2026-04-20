import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/constants.dart';

enum SubscriptionState { trial, active, expired }

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
}
