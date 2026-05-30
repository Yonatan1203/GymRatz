import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/shared/models/enums.dart';
import 'package:gymratz/shared/models/user_profile.dart';
import 'package:gymratz/features/subscription/domain/entitlement_service.dart';

void main() {
  group('EntitlementService.isRoleBasedPro', () {
    test('admin_user is pro', () {
      expect(EntitlementService.isRoleBasedPro(UserRole.adminUser), true);
    });

    test('admin_coach is pro', () {
      expect(EntitlementService.isRoleBasedPro(UserRole.adminCoach), true);
    });

    test('user is not pro by role', () {
      expect(EntitlementService.isRoleBasedPro(UserRole.user), false);
    });

    test('coach is not pro by role', () {
      expect(EntitlementService.isRoleBasedPro(UserRole.coach), false);
    });
  });

  group('EntitlementService.hasComplimentaryPro', () {
    UserProfile profile({UserRole role = UserRole.user, bool comp = false}) =>
        UserProfile(
          name: 'Tester',
          initials: 'T',
          email: 't@example.com',
          role: role,
          complimentaryPro: comp,
        );

    test('complimentary grant gives pro without admin role', () {
      final p = profile(role: UserRole.user, comp: true);
      expect(EntitlementService.hasComplimentaryPro(p), true);
      // Decoupled: a comp tester is NOT an admin and stays a normal user.
      expect(p.role.isAdmin, false);
      expect(p.role.isCoachRole, false);
    });

    test('admin role still grants pro (back-compat)', () {
      expect(
          EntitlementService.hasComplimentaryPro(
              profile(role: UserRole.adminUser)),
          true);
    });

    test('plain user without grant is not pro', () {
      expect(EntitlementService.hasComplimentaryPro(profile()), false);
    });

    test('coach without grant is not pro', () {
      expect(
          EntitlementService.hasComplimentaryPro(profile(role: UserRole.coach)),
          false);
    });

    test('complimentaryPro survives JSON round-trip', () {
      final restored = UserProfile.fromJson(profile(comp: true).toJson());
      expect(restored.complimentaryPro, true);
    });

    test('complimentaryPro defaults to false for legacy docs', () {
      final restored = UserProfile.fromJson({
        'name': 'Legacy',
        'initials': 'L',
        'email': 'l@example.com',
        'role': 'user',
      });
      expect(restored.complimentaryPro, false);
    });
  });
}
