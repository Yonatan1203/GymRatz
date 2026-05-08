import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/shared/models/enums.dart';
import 'package:gymratz/shared/models/user_profile.dart';
import 'package:gymratz/shared/models/coach_profile.dart';
import 'package:gymratz/shared/models/coach_invite.dart';
import 'package:gymratz/shared/models/coach_client.dart';
import 'package:gymratz/shared/models/program.dart';

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

  group('CoachProfile', () {
    test('toJson and fromJson round-trip', () {
      final profile = CoachProfile(
        uid: 'c1',
        displayName: 'Coach A',
        email: 'coach@test.com',
        bio: 'Expert',
        specializations: ['Strength', 'HIIT'],
        planTier: 'coach_10',
        clientCount: 3,
        maxClients: 10,
        approvedAt: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      );
      final json = profile.toJson();
      final restored = CoachProfile.fromJson(json);
      expect(restored.uid, 'c1');
      expect(restored.displayName, 'Coach A');
      expect(restored.planTier, 'coach_10');
      expect(restored.maxClients, 10);
      expect(restored.specializations, ['Strength', 'HIIT']);
    });

    test('isFull returns true when clientCount >= maxClients', () {
      final full = CoachProfile(
        uid: 'c1', displayName: 'C', email: 'c@t.com',
        planTier: 'coach_5', clientCount: 5, maxClients: 5,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(full.isFull, true);
    });

    test('isFull returns false when clientCount < maxClients', () {
      final notFull = CoachProfile(
        uid: 'c1', displayName: 'C', email: 'c@t.com',
        planTier: 'coach_10', clientCount: 3, maxClients: 10,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(notFull.isFull, false);
    });

    test('fromJson uses correct defaults for missing optional fields', () {
      final json = {
        'uid': 'c1',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      };
      final profile = CoachProfile.fromJson(json);
      expect(profile.clientCount, 0);
      expect(profile.maxClients, 5);
      expect(profile.specializations, <String>[]);
    });

    test('copyWith overrides specified fields', () {
      final profile = CoachProfile(
        uid: 'c1',
        displayName: 'Coach A',
        email: 'coach@test.com',
        planTier: 'coach_5',
        clientCount: 2,
        maxClients: 5,
        createdAt: DateTime(2026, 1, 1),
      );
      final updated = profile.copyWith(
        displayName: 'Coach B',
        clientCount: 4,
        specializations: ['Yoga'],
      );
      expect(updated.displayName, 'Coach B');
      expect(updated.clientCount, 4);
      expect(updated.specializations, ['Yoga']);
      // unchanged fields
      expect(updated.uid, 'c1');
      expect(updated.email, 'coach@test.com');
      expect(updated.planTier, 'coach_5');
    });
  });

  group('CoachInvite', () {
    test('toJson and fromJson round-trip', () {
      final invite = CoachInvite(
        id: 'inv1',
        code: 'ABC123',
        clientEmail: 'client@test.com',
        status: 'pending',
        createdAt: DateTime(2026, 1, 1),
        expiresAt: DateTime(2026, 1, 8),
      );
      final json = invite.toJson();
      final restored = CoachInvite.fromJson(json);
      expect(restored.code, 'ABC123');
      expect(restored.status, 'pending');
      expect(restored.clientEmail, 'client@test.com');
    });

    test('isExpired returns true for past dates', () {
      final expired = CoachInvite(
        id: 'inv1', code: 'ABC', status: 'pending',
        createdAt: DateTime(2025, 1, 1),
        expiresAt: DateTime(2025, 1, 8),
      );
      expect(expired.isExpired, true);
    });

    test('isPending returns true for a pending invite with future expiry', () {
      final invite = CoachInvite(
        id: 'inv1', code: 'ABC', status: 'pending',
        createdAt: DateTime(2026, 1, 1),
        expiresAt: DateTime(2099, 12, 31),
      );
      expect(invite.isPending, true);
    });

    test('isPending returns false for an expired pending invite', () {
      final invite = CoachInvite(
        id: 'inv1', code: 'ABC', status: 'pending',
        createdAt: DateTime(2025, 1, 1),
        expiresAt: DateTime(2025, 1, 8),
      );
      expect(invite.isPending, false);
    });

    test('copyWith overrides specified fields', () {
      final invite = CoachInvite(
        id: 'inv1',
        code: 'ABC123',
        clientEmail: 'client@test.com',
        status: 'pending',
        createdAt: DateTime(2026, 1, 1),
        expiresAt: DateTime(2026, 1, 8),
      );
      final updated = invite.copyWith(
        status: 'accepted',
        clientEmail: 'new@test.com',
      );
      expect(updated.status, 'accepted');
      expect(updated.clientEmail, 'new@test.com');
      // unchanged fields
      expect(updated.id, 'inv1');
      expect(updated.code, 'ABC123');
    });
  });

  group('CoachClient', () {
    test('toJson and fromJson round-trip', () {
      final client = CoachClient(
        clientUid: 'u1',
        clientName: 'User A',
        clientEmail: 'user@test.com',
        linkedAt: DateTime(2026, 2, 1),
        inviteMethod: 'code',
      );
      final json = client.toJson();
      final restored = CoachClient.fromJson(json);
      expect(restored.clientUid, 'u1');
      expect(restored.inviteMethod, 'code');
    });

    test('fromJson defaults inviteMethod to code when missing', () {
      final json = {
        'clientUid': 'u1',
        'clientName': 'User A',
        'clientEmail': 'user@test.com',
        'linkedAt': DateTime(2026, 2, 1).toIso8601String(),
      };
      final client = CoachClient.fromJson(json);
      expect(client.inviteMethod, 'code');
    });
  });

  group('Program coach fields', () {
    test('toJson includes assignedByCoach and coachId', () {
      final program = Program(
        id: 'p1',
        name: 'Test Program',
        workouts: 3,
        weeks: 4,
        assignedByCoach: true,
        coachId: 'coach-123',
      );

      final json = program.toJson();
      expect(json['assignedByCoach'], true);
      expect(json['coachId'], 'coach-123');
    });

    test('fromJson parses assignedByCoach and coachId', () {
      final json = {
        'id': 'p1',
        'name': 'Test Program',
        'workouts': 3,
        'weeks': 4,
        'assignedByCoach': true,
        'coachId': 'coach-456',
      };

      final program = Program.fromJson(json);
      expect(program.assignedByCoach, true);
      expect(program.coachId, 'coach-456');
    });

    test('fromJson defaults assignedByCoach to false when missing', () {
      final json = {
        'id': 'p1',
        'name': 'Test Program',
        'workouts': 3,
        'weeks': 4,
      };

      final program = Program.fromJson(json);
      expect(program.assignedByCoach, false);
      expect(program.coachId, isNull);
    });
  });
}
