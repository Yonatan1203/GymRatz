# Coach Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a coach-level layer to GymRatz allowing coaches to manage client memberships, programs, and workout data via tiered subscriptions.

**Architecture:** Role-based routing splits the app into two shells (user 5-tab, coach 4-tab). Coach data lives in `coaches/{uid}` collections alongside existing `users/{uid}` data. Entitlement resolution chains: own sub -> admin role -> coach-sponsored pro.

**Tech Stack:** Flutter/Dart, Riverpod, GoRouter, Cloud Firestore, RevenueCat

---

## File Structure

### New Files
| File | Responsibility |
|------|---------------|
| `lib/shared/models/coach_profile.dart` | CoachProfile model (Firestore serialization) |
| `lib/shared/models/coach_invite.dart` | CoachInvite model |
| `lib/shared/models/coach_client.dart` | CoachClient model |
| `lib/features/coach/data/coach_repository.dart` | Firestore CRUD for coaches, clients, invites, applications |
| `lib/features/coach/domain/coach_service.dart` | Business logic: invite, link, remove, assign program |
| `lib/app/providers/coach_providers.dart` | Riverpod providers for coach state |
| `lib/app/coach_router.dart` | Coach shell routes (4-tab nav) |
| `lib/shared/widgets/coach_scaffold.dart` | Coach bottom nav scaffold |
| `lib/features/coach/presentation/coach_dashboard_screen.dart` | Coach dashboard |
| `lib/features/coach/presentation/clients_screen.dart` | Client roster list |
| `lib/features/coach/presentation/client_detail_screen.dart` | Single client overview |
| `lib/features/coach/presentation/assign_program_screen.dart` | Assign program to client |
| `lib/features/coach/presentation/coach_programs_screen.dart` | Coach template library |
| `lib/features/coach/presentation/invite_management_screen.dart` | Manage invites |
| `lib/features/coach/presentation/coach_settings_screen.dart` | Coach profile + subscription |
| `lib/features/coach/presentation/coach_application_screen.dart` | User applies to become coach |
| `lib/features/coach/presentation/coach_approval_screen.dart` | Admin approves coach apps |
| `lib/features/coach/presentation/join_coach_screen.dart` | Client enters invite code |
| `test/coach/coach_models_test.dart` | Model serialization tests |
| `test/coach/coach_repository_test.dart` | Repository tests |
| `test/coach/coach_service_test.dart` | Service logic tests |
| `test/coach/entitlement_coach_test.dart` | Coach-sponsored entitlement tests |

### Modified Files
| File | Changes |
|------|---------|
| `lib/shared/models/user_profile.dart` | Add `role`, `coachId`, `coachLinkedAt` fields |
| `lib/shared/models/enums.dart` | Add `UserRole` enum |
| `lib/shared/models/program.dart` | Add `assignedByCoach`, `coachId` fields |
| `lib/core/constants.dart` | Add coach product IDs |
| `lib/features/subscription/data/entitlement_repository.dart` | Add role-based + coach-sponsored pro checks |
| `lib/features/subscription/domain/entitlement_service.dart` | Accept UserRepository dep for coach check |
| `lib/app/providers/subscription_providers.dart` | Wire updated entitlement with user role |
| `lib/app/router.dart` | Role-based redirect to coach shell |
| `lib/shared/widgets/custom_scaffold.dart` | No changes (coach gets own scaffold) |
| `lib/features/profile/presentation/profile_screen.dart` | Add "My Coach" section |
| `lib/features/settings/presentation/settings_screen.dart` | Add "Join a Coach" / coach info |
| `lib/features/programs/presentation/programs_screen.dart` | Show "Assigned by Coach" badge |

---

## Task 1: Add UserRole Enum and Update UserProfile Model

**Files:**
- Modify: `lib/shared/models/enums.dart`
- Modify: `lib/shared/models/user_profile.dart`
- Create: `test/coach/coach_models_test.dart`

- [ ] **Step 1: Write failing test for UserRole enum**

```dart
// test/coach/coach_models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/shared/models/enums.dart';

void main() {
  group('UserRole', () {
    test('has correct string values', () {
      expect(UserRole.user.value, 'user');
      expect(UserRole.coach.value, 'coach');
      expect(UserRole.adminUser.value, 'admin_user');
      expect(UserRole.adminCoach.value, 'admin_coach');
    });

    test('fromString parses valid values', () {
      expect(UserRole.fromString('user'), UserRole.user);
      expect(UserRole.fromString('coach'), UserRole.coach);
      expect(UserRole.fromString('admin_user'), UserRole.adminUser);
      expect(UserRole.fromString('admin_coach'), UserRole.adminCoach);
    });

    test('fromString defaults to user for unknown', () {
      expect(UserRole.fromString(null), UserRole.user);
      expect(UserRole.fromString('garbage'), UserRole.user);
    });

    test('isAdmin returns true for admin roles', () {
      expect(UserRole.user.isAdmin, false);
      expect(UserRole.coach.isAdmin, false);
      expect(UserRole.adminUser.isAdmin, true);
      expect(UserRole.adminCoach.isAdmin, true);
    });

    test('isCoachRole returns true for coach roles', () {
      expect(UserRole.user.isCoachRole, false);
      expect(UserRole.coach.isCoachRole, true);
      expect(UserRole.adminUser.isCoachRole, false);
      expect(UserRole.adminCoach.isCoachRole, true);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd GymRatz && flutter test test/coach/coach_models_test.dart`
Expected: FAIL — `UserRole` not found

- [ ] **Step 3: Add UserRole enum to enums.dart**

Append to end of `lib/shared/models/enums.dart`:

```dart
/// User role within the app.
enum UserRole {
  user('user'),
  coach('coach'),
  adminUser('admin_user'),
  adminCoach('admin_coach');

  final String value;
  const UserRole(this.value);

  bool get isAdmin => this == adminUser || this == adminCoach;
  bool get isCoachRole => this == coach || this == adminCoach;

  static UserRole fromString(String? value) {
    switch (value) {
      case 'user':
        return UserRole.user;
      case 'coach':
        return UserRole.coach;
      case 'admin_user':
        return UserRole.adminUser;
      case 'admin_coach':
        return UserRole.adminCoach;
      default:
        return UserRole.user;
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd GymRatz && flutter test test/coach/coach_models_test.dart`
Expected: All PASS

- [ ] **Step 5: Add coach fields test for UserProfile**

Add to `test/coach/coach_models_test.dart` inside `main()`:

```dart
  group('UserProfile coach fields', () {
    test('toJson includes role, coachId, coachLinkedAt', () {
      final profile = UserProfile(
        name: 'Test',
        initials: 'T',
        email: 'test@test.com',
        role: UserRole.user,
        coachId: 'coach123',
        coachLinkedAt: DateTime(2026, 1, 1),
      );
      final json = profile.toJson();
      expect(json['role'], 'user');
      expect(json['coachId'], 'coach123');
      expect(json['coachLinkedAt'], '2026-01-01T00:00:00.000');
    });

    test('fromJson parses role, coachId, coachLinkedAt', () {
      final json = {
        'name': 'Test',
        'initials': 'T',
        'email': 'test@test.com',
        'role': 'coach',
        'coachId': 'coach456',
        'coachLinkedAt': '2026-03-15T00:00:00.000',
      };
      final profile = UserProfile.fromJson(json);
      expect(profile.role, UserRole.coach);
      expect(profile.coachId, 'coach456');
      expect(profile.coachLinkedAt, DateTime(2026, 3, 15));
    });

    test('fromJson defaults role to user when missing', () {
      final json = {'name': 'Test', 'initials': 'T', 'email': 'test@test.com'};
      final profile = UserProfile.fromJson(json);
      expect(profile.role, UserRole.user);
      expect(profile.coachId, isNull);
      expect(profile.coachLinkedAt, isNull);
    });
  });
```

- [ ] **Step 6: Run test to verify it fails**

Run: `cd GymRatz && flutter test test/coach/coach_models_test.dart`
Expected: FAIL — UserProfile has no `role` parameter

- [ ] **Step 7: Update UserProfile with coach fields**

In `lib/shared/models/user_profile.dart`, add import and three new fields:

Add at top:
```dart
import 'enums.dart';
```

Add fields to class:
```dart
  final UserRole role;
  final String? coachId;
  final DateTime? coachLinkedAt;
```

Update constructor — add after `updatedAt`:
```dart
    this.role = UserRole.user,
    this.coachId,
    this.coachLinkedAt,
```

Update `toJson()` — add entries:
```dart
        'role': role.value,
        'coachId': coachId,
        'coachLinkedAt': coachLinkedAt?.toIso8601String(),
```

Update `fromJson()` — add parsing:
```dart
        role: UserRole.fromString(json['role'] as String?),
        coachId: json['coachId'] as String?,
        coachLinkedAt: json['coachLinkedAt'] != null
            ? DateTime.tryParse(json['coachLinkedAt'] as String)
            : null,
```

Update `copyWith()` — add parameters and fields:
```dart
    UserRole? role,
    String? coachId,
    DateTime? coachLinkedAt,
```
And in the return:
```dart
        role: role ?? this.role,
        coachId: coachId ?? this.coachId,
        coachLinkedAt: coachLinkedAt ?? this.coachLinkedAt,
```

- [ ] **Step 8: Run test to verify it passes**

Run: `cd GymRatz && flutter test test/coach/coach_models_test.dart`
Expected: All PASS

- [ ] **Step 9: Commit**

```bash
git add lib/shared/models/enums.dart lib/shared/models/user_profile.dart test/coach/coach_models_test.dart
git commit -m "feat(coach): add UserRole enum and coach fields to UserProfile"
```

---

## Task 2: Add Coach Models (CoachProfile, CoachInvite, CoachClient)

**Files:**
- Create: `lib/shared/models/coach_profile.dart`
- Create: `lib/shared/models/coach_invite.dart`
- Create: `lib/shared/models/coach_client.dart`
- Modify: `test/coach/coach_models_test.dart`

- [ ] **Step 1: Write failing tests for all three models**

Add to `test/coach/coach_models_test.dart` inside `main()`:

```dart
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
  });
```

Add imports at top of test file:
```dart
import 'package:gymratz/shared/models/coach_profile.dart';
import 'package:gymratz/shared/models/coach_invite.dart';
import 'package:gymratz/shared/models/coach_client.dart';
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd GymRatz && flutter test test/coach/coach_models_test.dart`
Expected: FAIL — models not found

- [ ] **Step 3: Create CoachProfile model**

```dart
// lib/shared/models/coach_profile.dart
class CoachProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? bio;
  final List<String> specializations;
  final String planTier;
  final int clientCount;
  final int maxClients;
  final DateTime? approvedAt;
  final DateTime createdAt;

  const CoachProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.bio,
    this.specializations = const [],
    required this.planTier,
    this.clientCount = 0,
    this.maxClients = 5,
    this.approvedAt,
    required this.createdAt,
  });

  bool get isFull => clientCount >= maxClients;

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'bio': bio,
        'specializations': specializations,
        'planTier': planTier,
        'clientCount': clientCount,
        'maxClients': maxClients,
        'approvedAt': approvedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory CoachProfile.fromJson(Map<String, dynamic> json) => CoachProfile(
        uid: json['uid'] as String,
        displayName: json['displayName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        bio: json['bio'] as String?,
        specializations: (json['specializations'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        planTier: json['planTier'] as String? ?? 'coach_5',
        clientCount: json['clientCount'] as int? ?? 0,
        maxClients: json['maxClients'] as int? ?? 5,
        approvedAt: json['approvedAt'] != null
            ? DateTime.tryParse(json['approvedAt'] as String)
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );

  CoachProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? bio,
    List<String>? specializations,
    String? planTier,
    int? clientCount,
    int? maxClients,
    DateTime? approvedAt,
    DateTime? createdAt,
  }) =>
      CoachProfile(
        uid: uid ?? this.uid,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        bio: bio ?? this.bio,
        specializations: specializations ?? this.specializations,
        planTier: planTier ?? this.planTier,
        clientCount: clientCount ?? this.clientCount,
        maxClients: maxClients ?? this.maxClients,
        approvedAt: approvedAt ?? this.approvedAt,
        createdAt: createdAt ?? this.createdAt,
      );
}
```

- [ ] **Step 4: Create CoachInvite model**

```dart
// lib/shared/models/coach_invite.dart
class CoachInvite {
  final String id;
  final String code;
  final String? clientEmail;
  final String status; // "pending" | "accepted" | "expired"
  final DateTime createdAt;
  final DateTime expiresAt;

  const CoachInvite({
    required this.id,
    required this.code,
    this.clientEmail,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => status == 'pending' && !isExpired;

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'clientEmail': clientEmail,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory CoachInvite.fromJson(Map<String, dynamic> json) => CoachInvite(
        id: json['id'] as String,
        code: json['code'] as String? ?? '',
        clientEmail: json['clientEmail'] as String?,
        status: json['status'] as String? ?? 'pending',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : DateTime.now().add(const Duration(days: 7)),
      );

  CoachInvite copyWith({
    String? id,
    String? code,
    String? clientEmail,
    String? status,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) =>
      CoachInvite(
        id: id ?? this.id,
        code: code ?? this.code,
        clientEmail: clientEmail ?? this.clientEmail,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
      );
}
```

- [ ] **Step 5: Create CoachClient model**

```dart
// lib/shared/models/coach_client.dart
class CoachClient {
  final String clientUid;
  final String clientName;
  final String clientEmail;
  final DateTime linkedAt;
  final String inviteMethod; // "code" | "email"

  const CoachClient({
    required this.clientUid,
    required this.clientName,
    required this.clientEmail,
    required this.linkedAt,
    required this.inviteMethod,
  });

  Map<String, dynamic> toJson() => {
        'clientUid': clientUid,
        'clientName': clientName,
        'clientEmail': clientEmail,
        'linkedAt': linkedAt.toIso8601String(),
        'inviteMethod': inviteMethod,
      };

  factory CoachClient.fromJson(Map<String, dynamic> json) => CoachClient(
        clientUid: json['clientUid'] as String,
        clientName: json['clientName'] as String? ?? '',
        clientEmail: json['clientEmail'] as String? ?? '',
        linkedAt: json['linkedAt'] != null
            ? DateTime.parse(json['linkedAt'] as String)
            : DateTime.now(),
        inviteMethod: json['inviteMethod'] as String? ?? 'code',
      );
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `cd GymRatz && flutter test test/coach/coach_models_test.dart`
Expected: All PASS

- [ ] **Step 7: Commit**

```bash
git add lib/shared/models/coach_profile.dart lib/shared/models/coach_invite.dart lib/shared/models/coach_client.dart test/coach/coach_models_test.dart
git commit -m "feat(coach): add CoachProfile, CoachInvite, CoachClient models"
```

---

## Task 3: Update Program Model with Coach Fields

**Files:**
- Modify: `lib/shared/models/program.dart`
- Modify: `test/coach/coach_models_test.dart`

- [ ] **Step 1: Write failing test for Program coach fields**

Add to `test/coach/coach_models_test.dart` inside `main()`:

```dart
  group('Program coach fields', () {
    test('toJson includes assignedByCoach and coachId', () {
      final program = Program(
        id: 'p1',
        name: 'Push Pull',
        workouts: 4,
        weeks: 8,
        assignedByCoach: true,
        coachId: 'coach1',
      );
      final json = program.toJson();
      expect(json['assignedByCoach'], true);
      expect(json['coachId'], 'coach1');
    });

    test('fromJson parses assignedByCoach and coachId', () {
      final json = {
        'id': 'p1',
        'name': 'Test',
        'workouts': 3,
        'weeks': 4,
        'assignedByCoach': true,
        'coachId': 'coach2',
      };
      final program = Program.fromJson(json);
      expect(program.assignedByCoach, true);
      expect(program.coachId, 'coach2');
    });

    test('fromJson defaults assignedByCoach to false', () {
      final json = {'id': 'p1', 'name': 'Test', 'workouts': 3, 'weeks': 4};
      final program = Program.fromJson(json);
      expect(program.assignedByCoach, false);
      expect(program.coachId, isNull);
    });
  });
```

Add import:
```dart
import 'package:gymratz/shared/models/program.dart';
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd GymRatz && flutter test test/coach/coach_models_test.dart`
Expected: FAIL — Program has no `assignedByCoach` parameter

- [ ] **Step 3: Add coach fields to Program**

In `lib/shared/models/program.dart`:

Add fields:
```dart
  final bool assignedByCoach;
  final String? coachId;
```

Update constructor — add after `createdAt`:
```dart
    this.assignedByCoach = false,
    this.coachId,
```

Update `toJson()`:
```dart
        'assignedByCoach': assignedByCoach,
        'coachId': coachId,
```

Update `fromJson()`:
```dart
        assignedByCoach: json['assignedByCoach'] as bool? ?? false,
        coachId: json['coachId'] as String?,
```

Update `copyWith()` — add parameters:
```dart
    bool? assignedByCoach,
    String? coachId,
```
And in the return:
```dart
        assignedByCoach: assignedByCoach ?? this.assignedByCoach,
        coachId: coachId ?? this.coachId,
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd GymRatz && flutter test test/coach/coach_models_test.dart`
Expected: All PASS

- [ ] **Step 5: Commit**

```bash
git add lib/shared/models/program.dart test/coach/coach_models_test.dart
git commit -m "feat(coach): add assignedByCoach and coachId to Program model"
```

---

## Task 4: Update Constants with Coach Product IDs

**Files:**
- Modify: `lib/core/constants.dart`

- [ ] **Step 1: Add coach product IDs to AppConstants**

In `lib/core/constants.dart`, add after `productYearly`:

```dart
  // Coach tier product identifiers
  static const String productCoach5 = 'coach_5';
  static const String productCoach10 = 'coach_10';
  static const String productCoach20 = 'coach_20';

  // Max clients per coach tier
  static int maxClientsForTier(String tier) {
    switch (tier) {
      case productCoach5:
        return 5;
      case productCoach10:
        return 10;
      case productCoach20:
        return 20;
      default:
        return 0;
    }
  }
```

- [ ] **Step 2: Verify existing tests still pass**

Run: `cd GymRatz && flutter test`
Expected: All existing tests PASS

- [ ] **Step 3: Commit**

```bash
git add lib/core/constants.dart
git commit -m "feat(coach): add coach tier product IDs to AppConstants"
```

---

## Task 5: Coach Repository (Firestore Data Layer)

**Files:**
- Create: `lib/features/coach/data/coach_repository.dart`
- Create: `test/coach/coach_repository_test.dart`

- [ ] **Step 1: Write failing tests for CoachRepository**

```dart
// test/coach/coach_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/features/coach/data/coach_repository.dart';
import 'package:gymratz/shared/models/coach_profile.dart';
import 'package:gymratz/shared/models/coach_invite.dart';
import 'package:gymratz/shared/models/coach_client.dart';

// CoachRepository depends on FirebaseFirestore — these tests verify the
// public API shape compiles and documents expected method signatures.
// Integration tests with Firestore emulator would live in integration_test/.

void main() {
  group('CoachRepository API surface', () {
    test('class exists and can be referenced', () {
      // Verifies that the import compiles and the class is defined
      expect(CoachRepository, isNotNull);
    });
  });

  group('CoachInvite code generation', () {
    test('generateInviteCode returns 6-char alphanumeric string', () {
      final code = CoachRepository.generateInviteCode();
      expect(code.length, 6);
      expect(RegExp(r'^[A-Z0-9]{6}$').hasMatch(code), true);
    });

    test('generateInviteCode produces unique codes', () {
      final codes = List.generate(100, (_) => CoachRepository.generateInviteCode());
      expect(codes.toSet().length, codes.length);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd GymRatz && flutter test test/coach/coach_repository_test.dart`
Expected: FAIL — CoachRepository not found

- [ ] **Step 3: Create CoachRepository**

```dart
// lib/features/coach/data/coach_repository.dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/coach_client.dart';
import '../../../shared/models/coach_invite.dart';
import '../../../shared/models/coach_profile.dart';

class CoachRepository {
  final FirebaseFirestore _firestore;

  CoachRepository(this._firestore);

  // ─── Collection refs ───

  DocumentReference<Map<String, dynamic>> _coachDoc(String coachUid) =>
      _firestore.collection('coaches').doc(coachUid);

  CollectionReference<Map<String, dynamic>> _clients(String coachUid) =>
      _coachDoc(coachUid).collection('clients');

  CollectionReference<Map<String, dynamic>> _invites(String coachUid) =>
      _coachDoc(coachUid).collection('invites');

  CollectionReference<Map<String, dynamic>> get _inviteCodes =>
      _firestore.collection('invite_codes');

  CollectionReference<Map<String, dynamic>> get _coachApplications =>
      _firestore.collection('coach_applications');

  // ─── Coach Profile ───

  Future<void> createCoachProfile(CoachProfile profile) async {
    await _coachDoc(profile.uid).set(profile.toJson());
  }

  Future<CoachProfile?> getCoachProfile(String coachUid) async {
    final snap = await _coachDoc(coachUid).get();
    if (!snap.exists || snap.data() == null) return null;
    return CoachProfile.fromJson(snap.data()!);
  }

  Stream<CoachProfile?> watchCoachProfile(String coachUid) {
    return _coachDoc(coachUid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return CoachProfile.fromJson(snap.data()!);
    });
  }

  Future<void> updateCoachProfile(
      String coachUid, Map<String, dynamic> fields) async {
    await _coachDoc(coachUid).update(fields);
  }

  // ─── Clients ───

  Stream<List<CoachClient>> watchClients(String coachUid) {
    return _clients(coachUid).snapshots().map((snap) =>
        snap.docs.map((d) => CoachClient.fromJson(d.data())).toList());
  }

  Future<void> addClient(String coachUid, CoachClient client) async {
    await _clients(coachUid).doc(client.clientUid).set(client.toJson());
    await _coachDoc(coachUid).update({
      'clientCount': FieldValue.increment(1),
    });
  }

  Future<void> removeClient(String coachUid, String clientUid) async {
    await _clients(coachUid).doc(clientUid).delete();
    await _coachDoc(coachUid).update({
      'clientCount': FieldValue.increment(-1),
    });
  }

  // ─── Invites ───

  Stream<List<CoachInvite>> watchInvites(String coachUid) {
    return _invites(coachUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CoachInvite.fromJson(d.data())).toList());
  }

  Future<CoachInvite> createInvite(
      String coachUid, {String? clientEmail}) async {
    final code = generateInviteCode();
    final now = DateTime.now();
    final invite = CoachInvite(
      id: code,
      code: code,
      clientEmail: clientEmail,
      status: 'pending',
      createdAt: now,
      expiresAt: now.add(const Duration(days: 7)),
    );

    final batch = _firestore.batch();
    batch.set(_invites(coachUid).doc(invite.id), invite.toJson());
    batch.set(_inviteCodes.doc(code), {
      'coachUid': coachUid,
      'inviteId': invite.id,
      'status': 'pending',
    });
    await batch.commit();

    return invite;
  }

  Future<void> revokeInvite(String coachUid, CoachInvite invite) async {
    final batch = _firestore.batch();
    batch.update(_invites(coachUid).doc(invite.id), {'status': 'expired'});
    batch.update(_inviteCodes.doc(invite.code), {'status': 'expired'});
    await batch.commit();
  }

  /// Look up an invite code. Returns the coachUid or null.
  Future<Map<String, dynamic>?> lookupInviteCode(String code) async {
    final snap = await _inviteCodes.doc(code.toUpperCase()).get();
    if (!snap.exists || snap.data() == null) return null;
    final data = snap.data()!;
    if (data['status'] != 'pending') return null;
    return data;
  }

  /// Accept an invite — links client to coach.
  Future<void> acceptInvite({
    required String code,
    required String coachUid,
    required String inviteId,
    required CoachClient client,
  }) async {
    final batch = _firestore.batch();

    // Update invite status
    batch.update(_invites(coachUid).doc(inviteId), {'status': 'accepted'});
    batch.update(_inviteCodes.doc(code), {'status': 'accepted'});

    // Add client to coach's roster
    batch.set(_clients(coachUid).doc(client.clientUid), client.toJson());

    // Increment coach client count
    batch.update(_coachDoc(coachUid), {
      'clientCount': FieldValue.increment(1),
    });

    // Update client's user doc with coachId
    batch.update(_firestore.collection('users').doc(client.clientUid), {
      'coachId': coachUid,
      'coachLinkedAt': DateTime.now().toIso8601String(),
    });

    await batch.commit();
  }

  /// Remove coach link from client.
  Future<void> unlinkClient(String coachUid, String clientUid) async {
    final batch = _firestore.batch();

    batch.delete(_clients(coachUid).doc(clientUid));
    batch.update(_coachDoc(coachUid), {
      'clientCount': FieldValue.increment(-1),
    });
    batch.update(_firestore.collection('users').doc(clientUid), {
      'coachId': null,
      'coachLinkedAt': null,
    });

    await batch.commit();
  }

  // ─── Coach Applications ───

  Future<void> submitApplication({
    required String uid,
    required String email,
    required String displayName,
    required String reason,
  }) async {
    await _coachApplications.doc(uid).set({
      'email': email,
      'displayName': displayName,
      'reason': reason,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchPendingApplications() {
    return _coachApplications
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['uid'] = d.id;
              return data;
            }).toList());
  }

  Future<void> approveApplication(String uid) async {
    await _coachApplications.doc(uid).update({'status': 'approved'});
    await _firestore.collection('users').doc(uid).update({'role': 'coach'});
  }

  Future<void> rejectApplication(String uid) async {
    await _coachApplications.doc(uid).update({'status': 'rejected'});
  }

  // ─── Client data access (coach reads client data) ───

  Stream<List<Map<String, dynamic>>> watchClientWorkouts(
      String clientUid, {int limit = 20}) {
    return _firestore
        .collection('users')
        .doc(clientUid)
        .collection('workouts')
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> watchClientPrograms(String clientUid) {
    return _firestore
        .collection('users')
        .doc(clientUid)
        .collection('programs')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Assign a program to a client by copying it to their programs subcollection.
  Future<void> assignProgramToClient({
    required String coachUid,
    required String clientUid,
    required Map<String, dynamic> programJson,
    required String programId,
  }) async {
    final batch = _firestore.batch();

    // Deactivate all client programs
    final existing = await _firestore
        .collection('users')
        .doc(clientUid)
        .collection('programs')
        .get();
    for (final doc in existing.docs) {
      batch.update(doc.reference, {'isActive': false});
    }

    // Write the new program as active
    final programData = Map<String, dynamic>.from(programJson);
    programData['id'] = programId;
    programData['isActive'] = true;
    programData['assignedByCoach'] = true;
    programData['coachId'] = coachUid;
    programData['createdAt'] = DateTime.now().toIso8601String();

    batch.set(
      _firestore.collection('users').doc(clientUid).collection('programs').doc(programId),
      programData,
    );

    await batch.commit();
  }

  // ─── Invite code generation ───

  static String generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd GymRatz && flutter test test/coach/coach_repository_test.dart`
Expected: All PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/coach/data/coach_repository.dart test/coach/coach_repository_test.dart
git commit -m "feat(coach): add CoachRepository with Firestore operations"
```

---

## Task 6: Coach Service (Business Logic)

**Files:**
- Create: `lib/features/coach/domain/coach_service.dart`
- Create: `test/coach/coach_service_test.dart`

- [ ] **Step 1: Write failing test for CoachService**

```dart
// test/coach/coach_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/features/coach/domain/coach_service.dart';
import 'package:gymratz/core/constants.dart';

void main() {
  group('CoachService.maxClientsForTier', () {
    test('returns correct max for each tier', () {
      expect(AppConstants.maxClientsForTier('coach_5'), 5);
      expect(AppConstants.maxClientsForTier('coach_10'), 10);
      expect(AppConstants.maxClientsForTier('coach_20'), 20);
      expect(AppConstants.maxClientsForTier('unknown'), 0);
    });
  });

  group('CoachService API surface', () {
    test('class exists and can be referenced', () {
      expect(CoachService, isNotNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd GymRatz && flutter test test/coach/coach_service_test.dart`
Expected: FAIL ��� CoachService not found

- [ ] **Step 3: Create CoachService**

```dart
// lib/features/coach/domain/coach_service.dart
import 'package:uuid/uuid.dart';

import '../../../core/constants.dart';
import '../../../shared/models/coach_client.dart';
import '../../../shared/models/coach_invite.dart';
import '../../../shared/models/coach_profile.dart';
import '../data/coach_repository.dart';

class CoachService {
  final CoachRepository _repo;

  CoachService(this._repo);

  // ─── Coach Profile ───

  Stream<CoachProfile?> watchProfile(String coachUid) =>
      _repo.watchCoachProfile(coachUid);

  Future<CoachProfile?> getProfile(String coachUid) =>
      _repo.getCoachProfile(coachUid);

  Future<void> createProfile({
    required String uid,
    required String displayName,
    required String email,
    required String planTier,
  }) async {
    final profile = CoachProfile(
      uid: uid,
      displayName: displayName,
      email: email,
      planTier: planTier,
      maxClients: AppConstants.maxClientsForTier(planTier),
      createdAt: DateTime.now(),
    );
    await _repo.createCoachProfile(profile);
  }

  // ──��� Client Management ───

  Stream<List<CoachClient>> watchClients(String coachUid) =>
      _repo.watchClients(coachUid);

  Future<void> removeClient(String coachUid, String clientUid) =>
      _repo.unlinkClient(coachUid, clientUid);

  // ─── Invites ───

  Stream<List<CoachInvite>> watchInvites(String coachUid) =>
      _repo.watchInvites(coachUid);

  Future<CoachInvite> createInvite(
    String coachUid, {
    String? clientEmail,
  }) async {
    final profile = await _repo.getCoachProfile(coachUid);
    if (profile == null) throw StateError('Coach profile not found');
    if (profile.isFull) throw StateError('Client roster is full');
    return _repo.createInvite(coachUid, clientEmail: clientEmail);
  }

  Future<void> revokeInvite(String coachUid, CoachInvite invite) =>
      _repo.revokeInvite(coachUid, invite);

  /// Client-side: join a coach by invite code.
  Future<String> joinCoach({
    required String code,
    required String clientUid,
    required String clientName,
    required String clientEmail,
  }) async {
    final lookup = await _repo.lookupInviteCode(code.toUpperCase());
    if (lookup == null) throw StateError('Invalid or expired invite code');

    final coachUid = lookup['coachUid'] as String;
    final inviteId = lookup['inviteId'] as String;

    final coachProfile = await _repo.getCoachProfile(coachUid);
    if (coachProfile == null) throw StateError('Coach not found');
    if (coachProfile.isFull) throw StateError('Coach roster is full');

    final client = CoachClient(
      clientUid: clientUid,
      clientName: clientName,
      clientEmail: clientEmail,
      linkedAt: DateTime.now(),
      inviteMethod: 'code',
    );

    await _repo.acceptInvite(
      code: code.toUpperCase(),
      coachUid: coachUid,
      inviteId: inviteId,
      client: client,
    );

    return coachProfile.displayName;
  }

  // ─── Program Assignment ───

  Future<void> assignProgram({
    required String coachUid,
    required String clientUid,
    required Map<String, dynamic> programJson,
  }) async {
    final programId = const Uuid().v4();
    await _repo.assignProgramToClient(
      coachUid: coachUid,
      clientUid: clientUid,
      programJson: programJson,
      programId: programId,
    );
  }

  // ─── Client Data Access ───

  Stream<List<Map<String, dynamic>>> watchClientWorkouts(
          String clientUid, {int limit = 20}) =>
      _repo.watchClientWorkouts(clientUid, limit: limit);

  Stream<List<Map<String, dynamic>>> watchClientPrograms(String clientUid) =>
      _repo.watchClientPrograms(clientUid);

  // ─── Applications ───

  Future<void> submitApplication({
    required String uid,
    required String email,
    required String displayName,
    required String reason,
  }) =>
      _repo.submitApplication(
        uid: uid,
        email: email,
        displayName: displayName,
        reason: reason,
      );

  Stream<List<Map<String, dynamic>>> watchPendingApplications() =>
      _repo.watchPendingApplications();

  Future<void> approveApplication(String uid) =>
      _repo.approveApplication(uid);

  Future<void> rejectApplication(String uid) =>
      _repo.rejectApplication(uid);
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd GymRatz && flutter test test/coach/coach_service_test.dart`
Expected: All PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/coach/domain/coach_service.dart test/coach/coach_service_test.dart
git commit -m "feat(coach): add CoachService with business logic"
```

---

## Task 7: Update Entitlement System for Coach-Sponsored Pro

**Files:**
- Modify: `lib/features/subscription/data/entitlement_repository.dart`
- Modify: `lib/features/subscription/domain/entitlement_service.dart`
- Modify: `lib/app/providers/subscription_providers.dart`
- Create: `test/coach/entitlement_coach_test.dart`

- [ ] **Step 1: Write failing test for role-based entitlement**

```dart
// test/coach/entitlement_coach_test.dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd GymRatz && flutter test test/coach/entitlement_coach_test.dart`
Expected: FAIL — `isRoleBasedPro` not found

- [ ] **Step 3: Add isRoleBasedPro to EntitlementService**

In `lib/features/subscription/domain/entitlement_service.dart`, add import at top:

```dart
import '../../../shared/models/enums.dart';
```

Add static method to `EntitlementService` class:

```dart
  /// Check if a role grants permanent pro access.
  static bool isRoleBasedPro(UserRole role) => role.isAdmin;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd GymRatz && flutter test test/coach/entitlement_coach_test.dart`
Expected: All PASS

- [ ] **Step 5: Update isProProvider to check role and coach-sponsored**

In `lib/app/providers/subscription_providers.dart`, replace the entire file:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/exceptions.dart';
import '../../features/subscription/data/entitlement_repository.dart';
import '../../features/subscription/domain/entitlement_service.dart';
import '../../shared/models/enums.dart';
import 'auth_providers.dart';
import 'data_providers.dart';

final entitlementRepositoryProvider = Provider<EntitlementRepository>((ref) {
  return EntitlementRepository();
});

final entitlementServiceProvider = Provider<EntitlementService>((ref) {
  return EntitlementService(ref.watch(entitlementRepositoryProvider));
});

/// Resolves pro access: own sub OR admin role OR coach-sponsored.
final isProProvider = StreamProvider<bool>((ref) async* {
  // 1. Check RevenueCat subscription
  final rcStream = ref.watch(entitlementServiceProvider).isProStream();
  await for (final rcPro in rcStream) {
    if (rcPro) {
      yield true;
      continue;
    }

    // 2. Check role-based pro (admin)
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile != null && EntitlementService.isRoleBasedPro(profile.role)) {
      yield true;
      continue;
    }

    // 3. Check coach-sponsored pro
    if (profile != null && profile.coachId != null) {
      final coachHasPlan = await _coachHasActivePlan(
        ref.read(firestoreProvider),
        profile.coachId!,
      );
      if (coachHasPlan) {
        yield true;
        continue;
      }
    }

    yield false;
  }
});

/// Check if a coach has an active plan by reading their profile doc.
Future<bool> _coachHasActivePlan(
    FirebaseFirestore? firestore, String coachUid) async {
  if (firestore == null) return false;
  try {
    final snap = await firestore.collection('coaches').doc(coachUid).get();
    if (!snap.exists || snap.data() == null) return false;
    final tier = snap.data()!['planTier'] as String?;
    return tier != null && tier.isNotEmpty;
  } catch (_) {
    return false;
  }
}

final subscriptionStateProvider = StreamProvider<SubscriptionState>((ref) {
  return ref.watch(entitlementServiceProvider).subscriptionStateStream();
});

/// Call before any write action. Throws [SubscriptionExpiredException] if expired.
final subscriptionGuardProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    // Admin bypass
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile != null && EntitlementService.isRoleBasedPro(profile.role)) {
      return;
    }

    final state = await ref.read(entitlementServiceProvider).getSubscriptionState();
    if (state == SubscriptionState.expired) {
      throw SubscriptionExpiredException();
    }
  };
});
```

- [ ] **Step 6: Run all tests**

Run: `cd GymRatz && flutter test`
Expected: All PASS

- [ ] **Step 7: Commit**

```bash
git add lib/features/subscription/domain/entitlement_service.dart lib/app/providers/subscription_providers.dart test/coach/entitlement_coach_test.dart
git commit -m "feat(coach): add role-based and coach-sponsored pro entitlement"
```

---

## Task 8: Coach Providers

**Files:**
- Create: `lib/app/providers/coach_providers.dart`
- Modify: `lib/app/providers.dart`

- [ ] **Step 1: Create coach_providers.dart**

```dart
// lib/app/providers/coach_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/coach/data/coach_repository.dart';
import '../../features/coach/domain/coach_service.dart';
import '../../shared/models/coach_client.dart';
import '../../shared/models/coach_invite.dart';
import '../../shared/models/coach_profile.dart';
import 'auth_providers.dart';

final coachRepositoryProvider = Provider<CoachRepository>((ref) {
  return CoachRepository(ref.watch(firestoreProvider)!);
});

final coachServiceProvider = Provider<CoachService>((ref) {
  return CoachService(ref.watch(coachRepositoryProvider));
});

/// Current user's coach profile (only valid when role is coach/admin_coach).
final coachProfileProvider = StreamProvider<CoachProfile?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(coachServiceProvider).watchProfile(uid);
});

/// Coach's client list.
final coachClientsProvider = StreamProvider<List<CoachClient>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(coachServiceProvider).watchClients(uid);
});

/// Coach's invites.
final coachInvitesProvider = StreamProvider<List<CoachInvite>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(coachServiceProvider).watchInvites(uid);
});

/// Pending coach applications (admin only).
final pendingApplicationsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(coachServiceProvider).watchPendingApplications();
});
```

- [ ] **Step 2: Export from providers.dart**

In `lib/app/providers.dart`, add after the last export:

```dart
export 'providers/coach_providers.dart';
```

- [ ] **Step 3: Verify compilation**

Run: `cd GymRatz && flutter test`
Expected: All PASS

- [ ] **Step 4: Commit**

```bash
git add lib/app/providers/coach_providers.dart lib/app/providers.dart
git commit -m "feat(coach): add Riverpod providers for coach state"
```

---

## Task 9: Coach Scaffold (Bottom Nav)

**Files:**
- Create: `lib/shared/widgets/coach_scaffold.dart`

- [ ] **Step 1: Create CoachScaffold**

```dart
// lib/shared/widgets/coach_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../utils/extensions.dart';
import '../utils/platform_adapter.dart';

class CoachScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const CoachScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              boxShadow: AppShadows.sm,
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildNavRow(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow(bool isDark) {
    final tabCount = 4;
    final activeIndex = navigationShell.currentIndex;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(tabCount, (index) {
            return Expanded(
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: 20,
                  height: 3,
                  decoration: BoxDecoration(
                    color: index == activeIndex
                        ? (isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _navItem(AppIcons.home, 'Dashboard', activeIndex == 0,
                () => navigationShell.goBranch(0), isDark),
            _navItem(AppIcons.users, 'Clients', activeIndex == 1,
                () => navigationShell.goBranch(1), isDark),
            _navItem(AppIcons.library, 'Programs', activeIndex == 2,
                () => navigationShell.goBranch(2), isDark),
            _navItem(AppIcons.settings, 'Settings', activeIndex == 3,
                () => navigationShell.goBranch(3), isDark),
          ],
        ),
      ],
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive,
      VoidCallback onTap, bool isDark) {
    final activeColor =
        isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final inactiveColor =
        isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          PlatformAdapter.hapticLight();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20,
                  color: isActive ? activeColor : inactiveColor),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? activeColor : inactiveColor,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compilation**

Run: `cd GymRatz && flutter test`
Expected: All PASS

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/coach_scaffold.dart
git commit -m "feat(coach): add CoachScaffold with 4-tab bottom nav"
```

---

## Task 10: Coach Router and Role-Based Routing

**Files:**
- Create: `lib/app/coach_router.dart`
- Modify: `lib/app/router.dart`

- [ ] **Step 1: Create placeholder coach screens**

Create minimal placeholder screens so routes compile. Each will be fleshed out in later tasks.

```dart
// lib/features/coach/presentation/coach_dashboard_screen.dart
import 'package:flutter/material.dart';

class CoachDashboardScreen extends StatelessWidget {
  const CoachDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Coach Dashboard')),
    );
  }
}
```

```dart
// lib/features/coach/presentation/clients_screen.dart
import 'package:flutter/material.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Clients')),
    );
  }
}
```

```dart
// lib/features/coach/presentation/client_detail_screen.dart
import 'package:flutter/material.dart';

class ClientDetailScreen extends StatelessWidget {
  final String clientUid;
  const ClientDetailScreen({super.key, required this.clientUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Client Detail: $clientUid')),
    );
  }
}
```

```dart
// lib/features/coach/presentation/assign_program_screen.dart
import 'package:flutter/material.dart';

class AssignProgramScreen extends StatelessWidget {
  final String clientUid;
  const AssignProgramScreen({super.key, required this.clientUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Assign Program to $clientUid')),
    );
  }
}
```

```dart
// lib/features/coach/presentation/coach_programs_screen.dart
import 'package:flutter/material.dart';

class CoachProgramsScreen extends StatelessWidget {
  const CoachProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Coach Programs')),
    );
  }
}
```

```dart
// lib/features/coach/presentation/invite_management_screen.dart
import 'package:flutter/material.dart';

class InviteManagementScreen extends StatelessWidget {
  const InviteManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Invite Management')),
    );
  }
}
```

```dart
// lib/features/coach/presentation/coach_settings_screen.dart
import 'package:flutter/material.dart';

class CoachSettingsScreen extends StatelessWidget {
  const CoachSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Coach Settings')),
    );
  }
}
```

```dart
// lib/features/coach/presentation/coach_application_screen.dart
import 'package:flutter/material.dart';

class CoachApplicationScreen extends StatelessWidget {
  const CoachApplicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Apply to Become a Coach')),
    );
  }
}
```

```dart
// lib/features/coach/presentation/coach_approval_screen.dart
import 'package:flutter/material.dart';

class CoachApprovalScreen extends StatelessWidget {
  const CoachApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Coach Application Approval')),
    );
  }
}
```

```dart
// lib/features/coach/presentation/join_coach_screen.dart
import 'package:flutter/material.dart';

class JoinCoachScreen extends StatelessWidget {
  const JoinCoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Join a Coach')),
    );
  }
}
```

- [ ] **Step 2: Create coach_router.dart with coach shell routes**

```dart
// lib/app/coach_router.dart
import 'package:go_router/go_router.dart';

import '../features/coach/presentation/assign_program_screen.dart';
import '../features/coach/presentation/client_detail_screen.dart';
import '../features/coach/presentation/clients_screen.dart';
import '../features/coach/presentation/coach_approval_screen.dart';
import '../features/coach/presentation/coach_dashboard_screen.dart';
import '../features/coach/presentation/coach_programs_screen.dart';
import '../features/coach/presentation/coach_settings_screen.dart';
import '../features/coach/presentation/invite_management_screen.dart';
import '../shared/widgets/coach_scaffold.dart';
import 'router.dart';

/// Coach shell route — 4 tabs (Dashboard, Clients, Programs, Settings).
StatefulShellRoute coachShellRoute() {
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) {
      return CoachScaffold(navigationShell: navigationShell);
    },
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/coach/dashboard',
            name: 'coach-dashboard',
            pageBuilder: (context, state) => fadeTransitionPage(
              state: state,
              child: const CoachDashboardScreen(),
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/coach/clients',
            name: 'coach-clients',
            pageBuilder: (context, state) => fadeTransitionPage(
              state: state,
              child: const ClientsScreen(),
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/coach/programs',
            name: 'coach-programs',
            pageBuilder: (context, state) => fadeTransitionPage(
              state: state,
              child: const CoachProgramsScreen(),
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/coach/settings',
            name: 'coach-settings',
            pageBuilder: (context, state) => fadeTransitionPage(
              state: state,
              child: const CoachSettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

/// Standalone coach routes (outside shell).
List<GoRoute> coachStandaloneRoutes() {
  return [
    GoRoute(
      path: '/coach/clients/:clientUid',
      name: 'client-detail',
      pageBuilder: (context, state) => slideTransitionPage(
        state: state,
        child: ClientDetailScreen(
          clientUid: state.pathParameters['clientUid'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/coach/clients/:clientUid/assign',
      name: 'assign-program',
      pageBuilder: (context, state) => slideTransitionPage(
        state: state,
        child: AssignProgramScreen(
          clientUid: state.pathParameters['clientUid'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/coach/invites',
      name: 'coach-invites',
      pageBuilder: (context, state) => slideTransitionPage(
        state: state,
        child: const InviteManagementScreen(),
      ),
    ),
    GoRoute(
      path: '/coach/approvals',
      name: 'coach-approvals',
      pageBuilder: (context, state) => slideTransitionPage(
        state: state,
        child: const CoachApprovalScreen(),
      ),
    ),
  ];
}
```

- [ ] **Step 3: Update router.dart for role-based routing**

In `lib/app/router.dart`, add imports at top:

```dart
import '../shared/models/enums.dart';
import '../features/coach/presentation/coach_application_screen.dart';
import '../features/coach/presentation/join_coach_screen.dart';
import 'coach_router.dart';
import 'providers/data_providers.dart';
```

Replace the `routerProvider` with role-aware version. The key changes:
1. Watch `userProfileProvider` for role
2. Add coach shell route
3. Redirect coach roles to `/coach/dashboard`
4. Add `/join-coach` and `/apply-coach` routes

Replace the redirect logic inside `routerProvider`:

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userProfile = ref.watch(userProfileProvider).valueOrNull;

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final currentPath = state.uri.path;
      final isPublicRoute = _publicPaths.contains(currentPath);

      // Not signed in and trying to access protected route -> onboarding
      if (!isLoggedIn && !isPublicRoute) {
        return '/onboarding';
      }

      // Signed in and on auth/onboarding route -> route by role
      if (isLoggedIn && (currentPath == '/login' || currentPath == '/onboarding')) {
        if (userProfile != null && userProfile.role.isCoachRole) {
          return '/coach/dashboard';
        }
        return '/home';
      }

      // Coach role trying to access user routes -> redirect to coach shell
      if (isLoggedIn && userProfile != null && userProfile.role.isCoachRole) {
        if (!currentPath.startsWith('/coach') &&
            !isPublicRoute &&
            currentPath != '/settings' &&
            currentPath != '/paywall') {
          return '/coach/dashboard';
        }
      }

      // User role trying to access coach routes -> redirect to home
      if (isLoggedIn && userProfile != null && !userProfile.role.isCoachRole) {
        if (currentPath.startsWith('/coach')) {
          return '/home';
        }
      }

      return null; // no redirect
    },
    routes: [
      // ─── Auth ───
      ...// (keep all existing auth routes as-is)

      // ─── Coach Shell ───
      coachShellRoute(),

      // ─── Coach Standalone ───
      ...coachStandaloneRoutes(),

      // ─── Main App (User Shell with Bottom Nav) ───
      ...// (keep existing StatefulShellRoute as-is)

      // ─── Standalone Screens ───
      ...// (keep all existing standalone routes as-is)

      // ─── New: Join Coach + Apply Coach ───
      GoRoute(
        path: '/join-coach',
        name: 'join-coach',
        pageBuilder: (context, state) => slideTransitionPage(
          state: state,
          child: const JoinCoachScreen(),
        ),
      ),
      GoRoute(
        path: '/apply-coach',
        name: 'apply-coach',
        pageBuilder: (context, state) => slideTransitionPage(
          state: state,
          child: const CoachApplicationScreen(),
        ),
      ),
    ],
  );
});
```

**Important:** Keep all existing routes intact. Only add the new imports, watch `userProfileProvider`, add the role-based redirect logic, and add the new routes (coach shell, coach standalone, join-coach, apply-coach).

- [ ] **Step 4: Verify compilation**

Run: `cd GymRatz && flutter test`
Expected: All PASS

- [ ] **Step 5: Commit**

```bash
git add lib/app/coach_router.dart lib/app/router.dart lib/features/coach/presentation/*.dart lib/shared/widgets/coach_scaffold.dart
git commit -m "feat(coach): add coach router with role-based shell switching"
```

---

## Task 11: Client-Side "My Coach" and "Join Coach" in Settings

**Files:**
- Modify: `lib/features/settings/presentation/settings_screen.dart`

- [ ] **Step 1: Add "My Coach" section to settings**

In `lib/features/settings/presentation/settings_screen.dart`, add after the ACCOUNT section (after `SizedBox(height: AppSpacing.sectionGap)` on line 111):

```dart
                  _sectionTitle(context, 'COACH'),
                  _buildCoachSection(context, ref),
                  SizedBox(height: AppSpacing.sectionGap),
```

Add the builder method to `_SettingsScreenState`:

```dart
  Widget _buildCoachSection(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final hasCoach = profile?.coachId != null;

    return CustomCard(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          if (hasCoach) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              child: Row(
                children: [
                  Icon(AppIcons.users, size: 20.r, color: context.primaryColor),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Linked to a Coach', style: AppTextStyles.body.copyWith(color: context.foreground)),
                        if (profile?.coachLinkedAt != null)
                          Text(
                            'Since ${DateFormat.yMMMd().format(profile!.coachLinkedAt!)}',
                            style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            MenuItemWidget(
              icon: AppIcons.userPlus,
              label: 'Join a Coach',
              onTap: () => context.push('/join-coach'),
            ),
          ],
        ],
      ),
    );
  }
```

Add import at top if not present:
```dart
import 'package:intl/intl.dart';
```

- [ ] **Step 2: Verify compilation**

Run: `cd GymRatz && flutter test`
Expected: All PASS

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/presentation/settings_screen.dart
git commit -m "feat(coach): add My Coach section to settings screen"
```

---

## Task 12: "Assigned by Coach" Badge on Programs Screen

**Files:**
- Modify: `lib/features/programs/presentation/programs_screen.dart`

- [ ] **Step 1: Update program cards to show coach badge**

In `lib/features/programs/presentation/programs_screen.dart`, find where program cards are rendered in `_buildMyPrograms`. After the program name text widget, add a conditional badge:

```dart
if (program.assignedByCoach)
  Padding(
    padding: EdgeInsets.only(top: 4.h),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        'Assigned by Coach',
        style: AppTextStyles.caption.copyWith(
          color: context.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ),
```

Also, when user has a `coachId`, disable "Set as Active" for non-coach-assigned programs. In the set-active tap handler, add a guard:

```dart
final userProfile = ref.read(userProfileProvider).valueOrNull;
if (userProfile?.coachId != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Your coach manages your active program')),
  );
  return;
}
```

- [ ] **Step 2: Verify compilation**

Run: `cd GymRatz && flutter test`
Expected: All PASS

- [ ] **Step 3: Commit**

```bash
git add lib/features/programs/presentation/programs_screen.dart
git commit -m "feat(coach): show Assigned by Coach badge on programs screen"
```

---

## Task 13: Firestore Security Rules

**Files:**
- Create: `firestore.rules`

- [ ] **Step 1: Write updated security rules**

```
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isOwner(uid) {
      return request.auth != null && request.auth.uid == uid;
    }

    function isCoachOf(clientUid) {
      return request.auth != null
        && get(/databases/$(database)/documents/users/$(clientUid)).data.coachId == request.auth.uid;
    }

    function isAdmin() {
      return request.auth != null
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin_user', 'admin_coach'];
    }

    match /users/{uid} {
      allow read: if isOwner(uid) || isCoachOf(uid) || isAdmin();
      allow create: if isOwner(uid);
      allow update: if isOwner(uid) || isCoachOf(uid);
      allow delete: if isOwner(uid);

      match /{subcollection}/{docId} {
        allow read: if isOwner(uid) || isCoachOf(uid) || isAdmin();
        allow create, update: if isOwner(uid) || isCoachOf(uid);
        allow delete: if isOwner(uid) || isCoachOf(uid);
      }
    }

    match /coaches/{coachUid} {
      allow read: if isOwner(coachUid) || isAdmin();
      allow create, update: if isOwner(coachUid);

      match /clients/{clientUid} {
        allow read: if isOwner(coachUid) || isAdmin();
        allow create, update, delete: if isOwner(coachUid);
      }

      match /invites/{inviteId} {
        allow read: if isOwner(coachUid) || request.auth != null;
        allow create, update, delete: if isOwner(coachUid);
      }
    }

    match /invite_codes/{code} {
      allow read: if request.auth != null;
      allow create: if request.auth != null
        && request.resource.data.coachUid == request.auth.uid;
      allow update: if request.auth != null;
      allow delete: if request.auth != null
        && get(/databases/$(database)/documents/invite_codes/$(code)).data.coachUid == request.auth.uid;
    }

    match /coach_applications/{uid} {
      allow create: if isOwner(uid);
      allow read, update: if isOwner(uid) || isAdmin();
    }

    match /community_programs/{programId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null
        && request.resource.data.ownerUid == request.auth.uid;
      allow update: if request.auth != null
        && resource.data.ownerUid == request.auth.uid;
    }

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add firestore.rules
git commit -m "feat(coach): add Firestore security rules with coach access patterns"
```

---

## Task 14: Implement Join Coach Screen (Client-Side)

**Files:**
- Modify: `lib/features/coach/presentation/join_coach_screen.dart`

- [ ] **Step 1: Replace placeholder with full implementation**

```dart
// lib/features/coach/presentation/join_coach_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/gradient_header.dart';

class JoinCoachScreen extends ConsumerStatefulWidget {
  const JoinCoachScreen({super.key});

  @override
  ConsumerState<JoinCoachScreen> createState() => _JoinCoachScreenState();
}

class _JoinCoachScreenState extends ConsumerState<JoinCoachScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Please enter a 6-character invite code');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw StateError('Not signed in');

      if (profile.coachId != null) {
        setState(() {
          _error = 'You are already linked to a coach';
          _isLoading = false;
        });
        return;
      }

      final coachService = ref.read(coachServiceProvider);
      final coachName = await coachService.joinCoach(
        code: code,
        clientUid: profile.uid!,
        clientName: profile.name,
        clientEmail: profile.email,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined coach: $coachName')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('StateError: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              showBackButton: true,
              child: Text('Join a Coach',
                  style: AppTextStyles.h1.copyWith(color: Colors.white)),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter the 6-character invite code from your coach.',
                    style: AppTextStyles.body
                        .copyWith(color: context.mutedForeground),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: _controller,
                    maxLength: 6,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    ],
                    style: AppTextStyles.h2.copyWith(
                      letterSpacing: 8,
                      color: context.foreground,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'XXXXXX',
                      hintStyle: AppTextStyles.h2.copyWith(
                        letterSpacing: 8,
                        color: context.mutedForeground.withValues(alpha: 0.3),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    SizedBox(height: AppSpacing.md),
                    Text(_error!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: context.destructiveColor)),
                  ],
                  SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      label: _isLoading ? 'Joining...' : 'Join Coach',
                      onPressed: _isLoading ? null : _handleJoin,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compilation**

Run: `cd GymRatz && flutter test`
Expected: All PASS

- [ ] **Step 3: Commit**

```bash
git add lib/features/coach/presentation/join_coach_screen.dart
git commit -m "feat(coach): implement Join Coach screen with invite code input"
```

---

## Tasks 15-21: Coach Screen Implementations

These tasks implement the full coach screens. Each follows the same pattern — replace placeholder with full implementation. Due to plan length, they are summarized here. Each is an independent task.

### Task 15: Coach Dashboard Screen
**File:** `lib/features/coach/presentation/coach_dashboard_screen.dart`
- Display active clients / max, weekly workout count, clients with missed workouts, recent activity feed
- Uses `coachProfileProvider`, `coachClientsProvider`
- Watch client workouts via `coachServiceProvider.watchClientWorkouts()`

### Task 16: Clients Screen
**File:** `lib/features/coach/presentation/clients_screen.dart`
- Client cards with avatar, name, last active date
- Search/filter
- "Add Client" FAB -> navigate to `/coach/invites`
- Tap card -> navigate to `/coach/clients/:clientUid`

### Task 17: Client Detail Screen
**File:** `lib/features/coach/presentation/client_detail_screen.dart`
- Tabs: Overview, Workouts, Programs, Progress
- Overview: profile summary, current program, streak
- Workouts: chronological list with set data
- Programs: active + personal (read-only)
- Actions: "Assign Program" button, "Remove Client" button

### Task 18: Assign Program Screen
**File:** `lib/features/coach/presentation/assign_program_screen.dart`
- List coach's program templates (from `coaches/{uid}/programs/`)
- Preview days/exercises
- Confirm -> calls `coachService.assignProgram()`

### Task 19: Coach Programs Screen
**File:** `lib/features/coach/presentation/coach_programs_screen.dart`
- Template library stored under `coaches/{uid}/programs/`
- Reuse existing program creation UI (CreateProgramScreen) adapted for coach context
- "Assign to Client" action on each template

### Task 20: Invite Management Screen
**File:** `lib/features/coach/presentation/invite_management_screen.dart`
- List pending/accepted/expired invites via `coachInvitesProvider`
- "Generate Code" button -> calls `coachService.createInvite()`
- "Send Email" option
- "Revoke" on pending invites

### Task 21: Coach Settings Screen
**File:** `lib/features/coach/presentation/coach_settings_screen.dart`
- Profile editing (name, bio, specializations)
- Subscription management (link to RevenueCat customer center)
- Coach application approval section (admin only) -> navigate to `/coach/approvals`
- Sign out

### Task 22: Coach Application Screen
**File:** `lib/features/coach/presentation/coach_application_screen.dart`
- Form: display name, email, reason
- Submit -> calls `coachService.submitApplication()`
- Show status if already applied

### Task 23: Coach Approval Screen (Admin)
**File:** `lib/features/coach/presentation/coach_approval_screen.dart`
- List pending applications via `pendingApplicationsProvider`
- Approve/Reject buttons on each
- Approve -> calls `coachService.approveApplication()`

---

## Task 24: Final Integration Test and Cleanup

**Files:**
- All modified files

- [ ] **Step 1: Run full test suite**

Run: `cd GymRatz && flutter test`
Expected: All PASS

- [ ] **Step 2: Run flutter analyze**

Run: `cd GymRatz && flutter analyze`
Expected: No errors (warnings acceptable)

- [ ] **Step 3: Verify the app compiles**

Run: `cd GymRatz && flutter build apk --debug`
Expected: BUILD SUCCESSFUL

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat(coach): complete coach management feature integration"
```

---

## Implementation Notes

- **Tasks 1-14** are fully specified with complete code.
- **Tasks 15-23** are coach screen implementations. Each follows the established patterns from existing screens (GradientHeader, CustomCard, StaggeredList, etc.) and uses the providers/services created in Tasks 5-8. They should be implemented using the same TDD approach — write minimal test, implement, verify, commit.
- **Task ordering:** Tasks 1-9 must be sequential (each builds on prior). Tasks 10-14 depend on Tasks 1-9. Tasks 15-23 depend on Task 10 but are independent of each other and can be parallelized.
- **Existing AppIcons:** The codebase uses `AppIcons.users` (referenced in coach_scaffold) — verify this icon exists in `lib/theme/app_icons.dart`. If not, add it or use `AppIcons.user` with a group variant.
