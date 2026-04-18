import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/constants.dart';

class EntitlementRepository {
  bool _initialized = false;

  /// Initialize RevenueCat SDK (call once at app startup or after first auth).
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final apiKey = Platform.isIOS
        ? AppConstants.revenueCatAppleApiKey
        : AppConstants.revenueCatGoogleApiKey;

    if (apiKey.contains('REPLACE_ME')) {
      debugPrint('RevenueCat: placeholder API key detected — subscription features disabled');
      return;
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

  /// Check if the user has the "pro" entitlement.
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
