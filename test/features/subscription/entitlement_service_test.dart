import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/core/exceptions.dart';
import 'package:gymratz/features/subscription/data/entitlement_repository.dart';
import 'package:gymratz/features/subscription/domain/entitlement_service.dart';
import 'package:gymratz/shared/models/enums.dart';

/// Test double: overrides getSubscriptionState to return a fixed value
/// without touching RevenueCat or Firestore.
class _FakeEntitlementService extends EntitlementService {
  final SubscriptionState _state;

  // EntitlementRepository() returns the singleton — safe to pass since
  // getSubscriptionState() is overridden and never calls the repo.
  _FakeEntitlementService(this._state) : super(EntitlementRepository());

  @override
  Future<SubscriptionState> getSubscriptionState() async => _state;
}

void main() {
  group('EntitlementService.requireActiveSubscription', () {
    test('throws SubscriptionExpiredException when state is expired', () async {
      final service = _FakeEntitlementService(SubscriptionState.expired);
      await expectLater(
        service.requireActiveSubscription(),
        throwsA(isA<SubscriptionExpiredException>()),
      );
    });

    test('does NOT throw when state is active', () async {
      final service = _FakeEntitlementService(SubscriptionState.active);
      await expectLater(service.requireActiveSubscription(), completes);
    });

    test('does NOT throw when state is trialing', () async {
      final service = _FakeEntitlementService(SubscriptionState.trial);
      await expectLater(service.requireActiveSubscription(), completes);
    });
  });

  group('EntitlementService.isRoleBasedPro', () {
    test('adminUser returns true', () {
      expect(EntitlementService.isRoleBasedPro(UserRole.adminUser), true);
    });

    test('adminCoach returns true', () {
      expect(EntitlementService.isRoleBasedPro(UserRole.adminCoach), true);
    });

    test('regular user returns false', () {
      expect(EntitlementService.isRoleBasedPro(UserRole.user), false);
    });
  });
}
