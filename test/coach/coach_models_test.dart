import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/shared/models/enums.dart';
import 'package:gymratz/shared/models/user_profile.dart';

void main() {
  group('UserRole enum', () {
    test('has correct string values', () {
      expect(UserRole.user.value, 'user');
      expect(UserRole.coach.value, 'coach');
      expect(UserRole.adminUser.value, 'admin_user');
      expect(UserRole.adminCoach.value, 'admin_coach');
    });

    test('fromString parses known values', () {
      expect(UserRole.fromString('user'), UserRole.user);
      expect(UserRole.fromString('coach'), UserRole.coach);
      expect(UserRole.fromString('admin_user'), UserRole.adminUser);
      expect(UserRole.fromString('admin_coach'), UserRole.adminCoach);
    });

    test('fromString defaults to user for unknown', () {
      expect(UserRole.fromString(null), UserRole.user);
      expect(UserRole.fromString('unknown'), UserRole.user);
      expect(UserRole.fromString(''), UserRole.user);
    });

    test('isAdmin returns true only for admin roles', () {
      expect(UserRole.user.isAdmin, false);
      expect(UserRole.coach.isAdmin, false);
      expect(UserRole.adminUser.isAdmin, true);
      expect(UserRole.adminCoach.isAdmin, true);
    });

    test('isCoachRole returns true only for coach roles', () {
      expect(UserRole.user.isCoachRole, false);
      expect(UserRole.coach.isCoachRole, true);
      expect(UserRole.adminUser.isCoachRole, false);
      expect(UserRole.adminCoach.isCoachRole, true);
    });
  });

  group('UserProfile coach fields', () {
    test('toJson includes role, coachId, and coachLinkedAt', () {
      final now = DateTime(2026, 1, 15, 10, 30);
      final profile = UserProfile(
        name: 'Test User',
        initials: 'TU',
        email: 'test@example.com',
        role: UserRole.coach,
        coachId: 'coach-123',
        coachLinkedAt: now,
      );

      final json = profile.toJson();
      expect(json['role'], 'coach');
      expect(json['coachId'], 'coach-123');
      expect(json['coachLinkedAt'], now.toIso8601String());
    });

    test('fromJson parses role, coachId, and coachLinkedAt', () {
      final now = DateTime(2026, 1, 15, 10, 30);
      final json = {
        'name': 'Test User',
        'initials': 'TU',
        'email': 'test@example.com',
        'role': 'admin_coach',
        'coachId': 'coach-456',
        'coachLinkedAt': now.toIso8601String(),
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.role, UserRole.adminCoach);
      expect(profile.coachId, 'coach-456');
      expect(profile.coachLinkedAt, now);
    });

    test('fromJson defaults role to user when missing', () {
      final json = {
        'name': 'Test User',
        'initials': 'TU',
        'email': 'test@example.com',
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.role, UserRole.user);
      expect(profile.coachId, isNull);
      expect(profile.coachLinkedAt, isNull);
    });

    test('copyWith updates coach fields', () {
      final profile = UserProfile(
        name: 'Test User',
        initials: 'TU',
        email: 'test@example.com',
      );

      expect(profile.role, UserRole.user);
      expect(profile.coachId, isNull);

      final updated = profile.copyWith(
        role: UserRole.coach,
        coachId: 'coach-789',
      );

      expect(updated.role, UserRole.coach);
      expect(updated.coachId, 'coach-789');
      expect(updated.name, 'Test User');
    });
  });
}
