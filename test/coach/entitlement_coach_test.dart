import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/shared/models/enums.dart';
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
}
