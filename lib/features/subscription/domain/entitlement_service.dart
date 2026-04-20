import 'package:purchases_flutter/purchases_flutter.dart';

import '../data/entitlement_repository.dart';
import '../data/entitlement_repository.dart' show SubscriptionState;

class EntitlementService {
  final EntitlementRepository _repo;

  EntitlementService(this._repo);

  Future<void> initialize() => _repo.initialize();

  /// Call after Firebase sign-in to link user with RevenueCat.
  Future<void> loginUser(String uid) async {
    await _repo.initialize();
    await _repo.login(uid);
  }

  /// Call on sign-out.
  Future<void> logoutUser() async {
    await _repo.logout();
  }

  Future<bool> isPro() => _repo.isPro();

  Stream<bool> isProStream() => _repo.isProStream();

  Future<Offerings> getOfferings() => _repo.getOfferings();

  Future<bool> purchase(Package package) => _repo.purchase(package);

  Future<bool> restorePurchases() => _repo.restorePurchases();

  Future<SubscriptionState> getSubscriptionState() => _repo.getSubscriptionState();
  Stream<SubscriptionState> subscriptionStateStream() => _repo.subscriptionStateStream();
}
