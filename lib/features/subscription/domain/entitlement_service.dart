import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/exceptions.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/user_profile.dart';
import '../data/entitlement_repository.dart';

class EntitlementService {
  /// Check if a role grants permanent pro access.
  static bool isRoleBasedPro(UserRole role) => role.isAdmin;

  /// Pro access granted without a purchase: either an admin role OR an
  /// explicit complimentary grant (testers/comps). Decoupled from admin so a
  /// tester gets full feature access without admin privileges or being routed
  /// into the coach experience.
  static bool hasComplimentaryPro(UserProfile profile) =>
      isRoleBasedPro(profile.role) || profile.complimentaryPro;

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

  /// Throws [SubscriptionExpiredException] if user's subscription is expired.
  /// Call before write operations.
  Future<void> requireActiveSubscription() async {
    final state = await getSubscriptionState();
    if (state == SubscriptionState.expired) {
      throw SubscriptionExpiredException();
    }
  }
}
