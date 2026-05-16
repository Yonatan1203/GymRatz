# Coach Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add coach management layer allowing coaches to pay for client bundles (5/10/20), manage client programs, and monitor workout data.

**Architecture:** Firestore-only approach — new `coaches/`, `invite_codes/`, `coach_applications/` collections with role-based routing. Coach-sponsored pro access resolved via `coachId` field on user profile. Separate navigation shell for coach accounts.

**Tech Stack:** Flutter/Dart, Riverpod, Cloud Firestore, RevenueCat, go_router

---

## File Structure

### New Files
```
lib/shared/models/coach_profile.dart          — Coach profile model
lib/shared/models/coach_client.dart           — Coach-client link model
lib/shared/models/coach_invite.dart           — Invite model
lib/shared/models/coach_application.dart      — Application model
lib/features/coach/data/coach_repository.dart — Firestore CRUD for coach data
lib/features/coach/domain/coach_service.dart  — Coach business logic
lib/app/providers/coach_providers.dart        — Riverpod providers for coach
lib/app/coach_router.dart                     — Coach shell routes
lib/shared/widgets/coach_scaffold.dart        — Coach bottom nav shell
lib/features/coach/presentation/coach_dashboard_screen.dart
lib/features/coach/presentation/clients_screen.dart
lib/features/coach/presentation/client_detail_screen.dart
lib/features/coach/presentation/assign_program_screen.dart
lib/features/coach/presentation/coach_programs_screen.dart
lib/features/coach/presentation/coach_program_editor_screen.dart
lib/features/coach/presentation/invite_management_screen.dart
lib/features/coach/presentation/coach_settings_screen.dart
lib/features/coach/presentation/coach_approval_screen.dart
lib/features/coach/presentation/join_coach_screen.dart  — Client-side join flow
test/models/coach_profile_test.dart
test/models/coach_invite_test.dart
test/services/coach_service_test.dart
test/services/entitlement_service_test.dart
```

### Modified Files
```
lib/shared/models/user_profile.dart           — Add role, coachId, coachLinkedAt
lib/shared/models/program.dart                — Add assignedByCoach, coachId
lib/core/constants.dart                       — Add coach product IDs
lib/features/subscription/domain/entitlement_service.dart — Coach-sponsored pro
lib/features/subscription/data/entitlement_repository.dart — Role-based bypass
lib/app/providers/subscription_providers.dart — Updated isProProvider
lib/app/providers/data_providers.dart         — Add userRoleProvider
lib/app/router.dart                           — Role-based shell switching
lib/shared/widgets/custom_scaffold.dart       — (no change, used as-is for user shell)
lib/app/providers.dart                        — Export coach_providers
lib/features/user/data/user_repository.dart   — Add getCoachId helper
firestore.rules                               — Full rewrite with coach rules
```

---

## Task 1: Models — UserProfile & Program Extensions

**Files:**
- Modify: `lib/shared/models/user_profile.dart`
- Modify: `lib/shared/models/program.dart`
- Test: `test/models/user_profile_test.dart`

- [ ] **Step 1: Write test for UserProfile with new fields**

```dart
// test/models/user_profile_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/shared/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('fromJson parses role and coachId', () {
      final json = {
        'uid': 'u1',
        'name': 'Test',
        'initials': 'TE',
        'email': 'test@test.com',
        'role': 'coach',
        'coachId': 'coach123',
        'coachLinkedAt': '2026-01-01T00:00:00.000',
      };
      final profile = UserProfile.fromJson(json);
      expect(profile.role, 'coach');
      expect(profile.coachId, 'coach123');
      expect(profile.coachLinkedAt, isNotNull);
    });

    test('fromJson defaults role to user when missing', () {
      final json = {
        'uid': 'u1',
        'name': 'Test',
        'initials': 'TE',
        'email': 'test@test.com',
      };
      final profile = UserProfile.fromJson(json);
      expect(profile.role, 'user');
      expect(profile.coachId, isNull);
      expect(profile.coachLinkedAt, isNull);
    });

    test('toJson includes role and coachId', () {
      final profile = UserProfile(
        uid: 'u1',
        name: 'Test',
        initials: 'TE',
        email: 'test@test.com',
        role: 'admin_user',
        coachId: 'c1',
        coachLinkedAt: DateTime(2026, 1, 1),
      );
      final json = profile.toJson();
      expect(json['role'], 'admin_user');
      expect(json['coachId'], 'c1');
      expect(json['coachLinkedAt'], isNotNull);
    });

    test('copyWith updates role', () {
      final profile = UserProfile(
        name: 'Test',
        initials: 'TE',
        email: 'test@test.com',
      );
      final updated = profile.copyWith(role: 'coach');
      expect(updated.role, 'coach');
    });

    test('isCoach and isAdmin helpers', () {
      final coach = UserProfile(name: 'C', initials: 'C', email: 'c@c.com', role: 'coach');
      final adminUser = UserProfile(name: 'A', initials: 'A', email: 'a@a.com', role: 'admin_user');
      final adminCoach = UserProfile(name: 'AC', initials: 'AC', email: 'ac@ac.com', role: 'admin_coach');
      final user = UserProfile(name: 'U', initials: 'U', email: 'u@u.com');

      expect(coach.isCoach, true);
      expect(coach.isAdmin, false);
      expect(adminUser.isAdmin, true);
      expect(adminUser.isCoach, false);
      expect(adminCoach.isCoach, true);
      expect(adminCoach.isAdmin, true);
      expect(user.isCoach, false);
      expect(user.isAdmin, false);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd "C:\Personal_Projects\GymRatz\Development\Version_0\GymRatz" && flutter test test/models/user_profile_test.dart`
Expected: FAIL — `role`, `coachId`, `coachLinkedAt` fields don't exist

- [ ] **Step 3: Update UserProfile model**

```dart
// lib/shared/models/user_profile.dart
class UserProfile {
  final String? uid;
  final String name;
  final String initials;
  final String email;
  final int age;
  final String height;
  final double weight;
  final String unit;
  final String experienceLevel;
  final String primaryGoal;
  final Set<String> injuries;
  final String? style;
  final bool notificationsEnabled;
  final bool healthEnabled;
  final String? discovery;
  final List<String> favoriteExerciseIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String role;
  final String? coachId;
  final DateTime? coachLinkedAt;

  const UserProfile({
    this.uid,
    required this.name,
    required this.initials,
    required this.email,
    this.age = 25,
    this.height = '5\'10"',
    this.weight = 175.2,
    this.unit = 'lbs',
    this.experienceLevel = 'Intermediate',
    this.primaryGoal = 'Build Muscle',
    this.injuries = const {},
    this.style,
    this.notificationsEnabled = true,
    this.healthEnabled = false,
    this.discovery,
    this.favoriteExerciseIds = const [],
    this.createdAt,
    this.updatedAt,
    this.role = 'user',
    this.coachId,
    this.coachLinkedAt,
  });

  bool get isCoach => role == 'coach' || role == 'admin_coach';
  bool get isAdmin => role == 'admin_user' || role == 'admin_coach';
  bool get hasCoach => coachId != null;

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'initials': initials,
        'email': email,
        'age': age,
        'height': height,
        'weight': weight,
        'unit': unit,
        'experienceLevel': experienceLevel,
        'primaryGoal': primaryGoal,
        'injuries': injuries.toList(),
        'style': style,
        'notificationsEnabled': notificationsEnabled,
        'healthEnabled': healthEnabled,
        'discovery': discovery,
        'favoriteExerciseIds': favoriteExerciseIds,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'role': role,
        'coachId': coachId,
        'coachLinkedAt': coachLinkedAt?.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        uid: json['uid'] as String?,
        name: json['name'] as String? ?? '',
        initials: json['initials'] as String? ?? '',
        email: json['email'] as String? ?? '',
        age: json['age'] as int? ?? 25,
        height: json['height'] as String? ?? '5\'10"',
        weight: (json['weight'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] as String? ?? 'lbs',
        experienceLevel: json['experienceLevel'] as String? ?? 'Intermediate',
        primaryGoal: json['primaryGoal'] as String? ?? 'Build Muscle',
        injuries: (json['injuries'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toSet() ??
            {},
        style: json['style'] as String?,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        healthEnabled: json['healthEnabled'] as bool? ?? false,
        discovery: json['discovery'] as String?,
        favoriteExerciseIds: (json['favoriteExerciseIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
        role: json['role'] as String? ?? 'user',
        coachId: json['coachId'] as String?,
        coachLinkedAt: json['coachLinkedAt'] != null
            ? DateTime.tryParse(json['coachLinkedAt'] as String)
            : null,
      );

  UserProfile copyWith({
    String? uid,
    String? name,
    String? initials,
    String? email,
    int? age,
    String? height,
    double? weight,
    String? unit,
    String? experienceLevel,
    String? primaryGoal,
    Set<String>? injuries,
    String? style,
    bool? notificationsEnabled,
    bool? healthEnabled,
    String? discovery,
    List<String>? favoriteExerciseIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? role,
    String? coachId,
    DateTime? coachLinkedAt,
  }) =>
      UserProfile(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        initials: initials ?? this.initials,
        email: email ?? this.email,
        age: age ?? this.age,
        height: height ?? this.height,
        weight: weight ?? this.weight,
        unit: unit ?? this.unit,
        experienceLevel: experienceLevel ?? this.experienceLevel,
        primaryGoal: primaryGoal ?? this.primaryGoal,
        injuries: injuries ?? this.injuries,
        style: style ?? this.style,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        healthEnabled: healthEnabled ?? this.healthEnabled,
        discovery: discovery ?? this.discovery,
        favoriteExerciseIds: favoriteExerciseIds ?? this.favoriteExerciseIds,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        role: role ?? this.role,
        coachId: coachId ?? this.coachId,
        coachLinkedAt: coachLinkedAt ?? this.coachLinkedAt,
      );
}
```

- [ ] **Step 4: Update Program model with coach fields**

```dart
// lib/shared/models/program.dart — add two fields
import 'workout_day.dart';

class Program {
  final String id;
  final String name;
  final int workouts;
  final int weeks;
  final int progress;
  final String? difficulty;
  final String? description;
  final List<WorkoutDay> days;
  final bool isActive;
  final bool prefillWeights;
  final DateTime? createdAt;
  final bool assignedByCoach;
  final String? coachId;

  const Program({
    required this.id,
    required this.name,
    required this.workouts,
    required this.weeks,
    this.progress = 0,
    this.difficulty,
    this.description,
    this.days = const [],
    this.isActive = false,
    this.prefillWeights = true,
    this.createdAt,
    this.assignedByCoach = false,
    this.coachId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'workouts': workouts,
        'weeks': weeks,
        'progress': progress,
        'difficulty': difficulty,
        'description': description,
        'days': days.map((d) => d.toJson()).toList(),
        'isActive': isActive,
        'prefillWeights': prefillWeights,
        'createdAt': createdAt?.toIso8601String(),
        'assignedByCoach': assignedByCoach,
        'coachId': coachId,
      };

  factory Program.fromJson(Map<String, dynamic> json) => Program(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        workouts: json['workouts'] as int? ?? 0,
        weeks: json['weeks'] as int? ?? 0,
        progress: json['progress'] as int? ?? 0,
        difficulty: json['difficulty'] as String?,
        description: json['description'] as String?,
        days: (json['days'] as List<dynamic>?)
                ?.map((e) => WorkoutDay.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        isActive: json['isActive'] as bool? ?? false,
        prefillWeights: json['prefillWeights'] as bool? ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        assignedByCoach: json['assignedByCoach'] as bool? ?? false,
        coachId: json['coachId'] as String?,
      );

  Program copyWith({
    String? id,
    String? name,
    int? workouts,
    int? weeks,
    int? progress,
    String? difficulty,
    String? description,
    List<WorkoutDay>? days,
    bool? isActive,
    bool? prefillWeights,
    DateTime? createdAt,
    bool? assignedByCoach,
    String? coachId,
  }) =>
      Program(
        id: id ?? this.id,
        name: name ?? this.name,
        workouts: workouts ?? this.workouts,
        weeks: weeks ?? this.weeks,
        progress: progress ?? this.progress,
        difficulty: difficulty ?? this.difficulty,
        description: description ?? this.description,
        days: days ?? this.days,
        isActive: isActive ?? this.isActive,
        prefillWeights: prefillWeights ?? this.prefillWeights,
        createdAt: createdAt ?? this.createdAt,
        assignedByCoach: assignedByCoach ?? this.assignedByCoach,
        coachId: coachId ?? this.coachId,
      );
}
```

- [ ] **Step 5: Run tests**

Run: `cd "C:\Personal_Projects\GymRatz\Development\Version_0\GymRatz" && flutter test test/models/user_profile_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/shared/models/user_profile.dart lib/shared/models/program.dart test/models/user_profile_test.dart
git commit -m "feat(models): add role, coachId to UserProfile and assignedByCoach to Program"
```

---

## Task 2: Coach Models — CoachProfile, CoachClient, CoachInvite, CoachApplication

**Files:**
- Create: `lib/shared/models/coach_profile.dart`
- Create: `lib/shared/models/coach_client.dart`
- Create: `lib/shared/models/coach_invite.dart`
- Create: `lib/shared/models/coach_application.dart`
- Test: `test/models/coach_models_test.dart`

- [ ] **Step 1: Write tests for coach models**

```dart
// test/models/coach_models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/shared/models/coach_profile.dart';
import 'package:gymratz/shared/models/coach_client.dart';
import 'package:gymratz/shared/models/coach_invite.dart';
import 'package:gymratz/shared/models/coach_application.dart';

void main() {
  group('CoachProfile', () {
    test('fromJson and toJson roundtrip', () {
      final json = {
        'displayName': 'Coach Dan',
        'email': 'dan@coach.com',
        'bio': 'Strength coach',
        'specializations': ['Powerlifting', 'Bodybuilding'],
        'planTier': 'coach_10',
        'clientCount': 5,
        'maxClients': 10,
        'approvedAt': '2026-01-01T00:00:00.000',
        'createdAt': '2026-01-01T00:00:00.000',
      };
      final profile = CoachProfile.fromJson(json);
      expect(profile.displayName, 'Coach Dan');
      expect(profile.planTier, 'coach_10');
      expect(profile.maxClients, 10);
      expect(profile.clientCount, 5);
      expect(profile.canAddClient, true);

      final output = profile.toJson();
      expect(output['planTier'], 'coach_10');
    });

    test('canAddClient returns false when at capacity', () {
      final profile = CoachProfile(
        displayName: 'Full',
        email: 'f@f.com',
        planTier: 'coach_5',
        clientCount: 5,
        maxClients: 5,
      );
      expect(profile.canAddClient, false);
    });
  });

  group('CoachClient', () {
    test('fromJson parses correctly', () {
      final json = {
        'clientName': 'Alice',
        'clientEmail': 'alice@test.com',
        'linkedAt': '2026-03-01T00:00:00.000',
        'inviteMethod': 'code',
      };
      final client = CoachClient.fromJson(json);
      expect(client.clientName, 'Alice');
      expect(client.inviteMethod, 'code');
    });
  });

  group('CoachInvite', () {
    test('isExpired returns true for past expiry', () {
      final invite = CoachInvite(
        id: 'inv1',
        code: 'ABC123',
        status: 'pending',
        createdAt: DateTime(2026, 1, 1),
        expiresAt: DateTime(2026, 1, 2),
      );
      expect(invite.isExpired, true);
    });

    test('isExpired returns false for future expiry', () {
      final invite = CoachInvite(
        id: 'inv1',
        code: 'ABC123',
        status: 'pending',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );
      expect(invite.isExpired, false);
    });
  });

  group('CoachApplication', () {
    test('fromJson parses correctly', () {
      final json = {
        'email': 'new@coach.com',
        'displayName': 'New Coach',
        'reason': 'I train clients',
        'status': 'pending',
        'createdAt': '2026-04-01T00:00:00.000',
      };
      final app = CoachApplication.fromJson(json);
      expect(app.status, 'pending');
      expect(app.isPending, true);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models/coach_models_test.dart`
Expected: FAIL — models don't exist

- [ ] **Step 3: Create CoachProfile model**

```dart
// lib/shared/models/coach_profile.dart
class CoachProfile {
  final String? uid;
  final String displayName;
  final String email;
  final String? bio;
  final List<String> specializations;
  final String? planTier;
  final int clientCount;
  final int maxClients;
  final DateTime? approvedAt;
  final DateTime? createdAt;

  const CoachProfile({
    this.uid,
    required this.displayName,
    required this.email,
    this.bio,
    this.specializations = const [],
    this.planTier,
    this.clientCount = 0,
    this.maxClients = 0,
    this.approvedAt,
    this.createdAt,
  });

  bool get canAddClient => clientCount < maxClients;

  Map<String, dynamic> toJson() => {
        if (uid != null) 'uid': uid,
        'displayName': displayName,
        'email': email,
        'bio': bio,
        'specializations': specializations,
        'planTier': planTier,
        'clientCount': clientCount,
        'maxClients': maxClients,
        'approvedAt': approvedAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };

  factory CoachProfile.fromJson(Map<String, dynamic> json) => CoachProfile(
        uid: json['uid'] as String?,
        displayName: json['displayName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        bio: json['bio'] as String?,
        specializations: (json['specializations'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        planTier: json['planTier'] as String?,
        clientCount: json['clientCount'] as int? ?? 0,
        maxClients: json['maxClients'] as int? ?? 0,
        approvedAt: json['approvedAt'] != null
            ? DateTime.tryParse(json['approvedAt'] as String)
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
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

- [ ] **Step 4: Create CoachClient model**

```dart
// lib/shared/models/coach_client.dart
class CoachClient {
  final String? uid;
  final String clientName;
  final String clientEmail;
  final DateTime? linkedAt;
  final String inviteMethod;

  const CoachClient({
    this.uid,
    required this.clientName,
    required this.clientEmail,
    this.linkedAt,
    this.inviteMethod = 'code',
  });

  Map<String, dynamic> toJson() => {
        if (uid != null) 'uid': uid,
        'clientName': clientName,
        'clientEmail': clientEmail,
        'linkedAt': linkedAt?.toIso8601String(),
        'inviteMethod': inviteMethod,
      };

  factory CoachClient.fromJson(Map<String, dynamic> json) => CoachClient(
        uid: json['uid'] as String?,
        clientName: json['clientName'] as String? ?? '',
        clientEmail: json['clientEmail'] as String? ?? '',
        linkedAt: json['linkedAt'] != null
            ? DateTime.tryParse(json['linkedAt'] as String)
            : null,
        inviteMethod: json['inviteMethod'] as String? ?? 'code',
      );
}
```

- [ ] **Step 5: Create CoachInvite model**

```dart
// lib/shared/models/coach_invite.dart
class CoachInvite {
  final String id;
  final String code;
  final String? clientEmail;
  final String status; // pending, accepted, expired
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
        id: json['id'] as String? ?? '',
        code: json['code'] as String? ?? '',
        clientEmail: json['clientEmail'] as String?,
        status: json['status'] as String? ?? 'pending',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
```

- [ ] **Step 6: Create CoachApplication model**

```dart
// lib/shared/models/coach_application.dart
class CoachApplication {
  final String? uid;
  final String email;
  final String displayName;
  final String reason;
  final String status; // pending, approved, rejected
  final DateTime? createdAt;

  const CoachApplication({
    this.uid,
    required this.email,
    required this.displayName,
    required this.reason,
    this.status = 'pending',
    this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';

  Map<String, dynamic> toJson() => {
        if (uid != null) 'uid': uid,
        'email': email,
        'displayName': displayName,
        'reason': reason,
        'status': status,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory CoachApplication.fromJson(Map<String, dynamic> json) =>
      CoachApplication(
        uid: json['uid'] as String?,
        email: json['email'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}
```

- [ ] **Step 7: Run tests**

Run: `flutter test test/models/coach_models_test.dart`
Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add lib/shared/models/coach_profile.dart lib/shared/models/coach_client.dart lib/shared/models/coach_invite.dart lib/shared/models/coach_application.dart test/models/coach_models_test.dart
git commit -m "feat(models): add CoachProfile, CoachClient, CoachInvite, CoachApplication models"
```

---

## Task 3: Constants & UserRepository Updates

**Files:**
- Modify: `lib/core/constants.dart`
- Modify: `lib/features/user/data/user_repository.dart`

- [ ] **Step 1: Add coach product IDs to constants**

```dart
// lib/core/constants.dart
class AppConstants {
  AppConstants._();

  static const String revenueCatAppleApiKey =
      String.fromEnvironment('RC_APPLE_KEY', defaultValue: 'appl_REPLACE_ME');
  static const String revenueCatGoogleApiKey =
      String.fromEnvironment('RC_GOOGLE_KEY',
          defaultValue: 'test_QPrCcBDWPprQOPWibhFNchqaTPB');

  static const String entitlementId = 'GymRatz';

  static const String productMonthly = 'monthly';
  static const String productYearly = 'yearly';

  // Coach subscription products
  static const String productCoach5 = 'coach_5';
  static const String productCoach10 = 'coach_10';
  static const String productCoach20 = 'coach_20';

  // Coach plan tier -> max clients mapping
  static const Map<String, int> coachTierLimits = {
    'coach_5': 5,
    'coach_10': 10,
    'coach_20': 20,
  };

  static const String appVersion = '1.0.0';
  static const String privacyPolicyUrl = 'https://gymratz-app.github.io/privacy';
  static const String termsOfServiceUrl = 'https://gymratz-app.github.io/terms';
}
```

- [ ] **Step 2: Add getCoachId method to UserRepository**

```dart
// Add to lib/features/user/data/user_repository.dart — append after toggleFavoriteExercise

  /// Get the coachId for a user (used for entitlement check).
  Future<String?> getCoachId(String uid) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return snap.data()!['coachId'] as String?;
  }

  /// Get the role for a user.
  Future<String> getRole(String uid) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists || snap.data() == null) return 'user';
    return snap.data()!['role'] as String? ?? 'user';
  }
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/constants.dart lib/features/user/data/user_repository.dart
git commit -m "feat: add coach product constants and UserRepository helper methods"
```

---

## Task 4: Coach Repository

**Files:**
- Create: `lib/features/coach/data/coach_repository.dart`

- [ ] **Step 1: Create coach repository**

```dart
// lib/features/coach/data/coach_repository.dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/coach_application.dart';
import '../../../shared/models/coach_client.dart';
import '../../../shared/models/coach_invite.dart';
import '../../../shared/models/coach_profile.dart';
import '../../../shared/models/program.dart';

class CoachRepository {
  final FirebaseFirestore _firestore;

  CoachRepository(this._firestore);

  // ─── Coach Profile ───

  DocumentReference<Map<String, dynamic>> _coachDoc(String coachUid) =>
      _firestore.collection('coaches').doc(coachUid);

  Future<void> createCoachProfile(String coachUid, CoachProfile profile) async {
    await _coachDoc(coachUid).set(profile.toJson());
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

  CollectionReference<Map<String, dynamic>> _clientsCol(String coachUid) =>
      _coachDoc(coachUid).collection('clients');

  Stream<List<CoachClient>> watchClients(String coachUid) {
    return _clientsCol(coachUid).snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return CoachClient.fromJson(data);
      }).toList();
    });
  }

  Future<void> addClient(String coachUid, String clientUid, CoachClient client) async {
    await _clientsCol(coachUid).doc(clientUid).set(client.toJson());
  }

  Future<void> removeClient(String coachUid, String clientUid) async {
    await _clientsCol(coachUid).doc(clientUid).delete();
  }

  // ─── Invites ───

  CollectionReference<Map<String, dynamic>> _invitesCol(String coachUid) =>
      _coachDoc(coachUid).collection('invites');

  Stream<List<CoachInvite>> watchInvites(String coachUid) {
    return _invitesCol(coachUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CoachInvite.fromJson(data);
      }).toList();
    });
  }

  Future<CoachInvite> createInvite(String coachUid, {String? clientEmail}) async {
    final code = _generateCode();
    final now = DateTime.now();
    final invite = CoachInvite(
      id: '',
      code: code,
      clientEmail: clientEmail,
      status: 'pending',
      createdAt: now,
      expiresAt: now.add(const Duration(days: 7)),
    );

    final batch = _firestore.batch();

    // Create invite in coach's subcollection
    final inviteRef = _invitesCol(coachUid).doc();
    batch.set(inviteRef, invite.toJson());

    // Create lookup doc
    final lookupRef = _firestore.collection('invite_codes').doc(code);
    batch.set(lookupRef, {
      'coachUid': coachUid,
      'inviteId': inviteRef.id,
      'status': 'pending',
    });

    await batch.commit();

    return CoachInvite(
      id: inviteRef.id,
      code: code,
      clientEmail: clientEmail,
      status: 'pending',
      createdAt: now,
      expiresAt: now.add(const Duration(days: 7)),
    );
  }

  Future<void> revokeInvite(String coachUid, String inviteId, String code) async {
    final batch = _firestore.batch();
    batch.update(_invitesCol(coachUid).doc(inviteId), {'status': 'expired'});
    batch.update(_firestore.collection('invite_codes').doc(code), {'status': 'expired'});
    await batch.commit();
  }

  // ─── Invite Lookup (client-side) ───

  Future<Map<String, dynamic>?> lookupInviteCode(String code) async {
    final snap = await _firestore.collection('invite_codes').doc(code).get();
    if (!snap.exists || snap.data() == null) return null;
    return snap.data();
  }

  // ─── Coach Programs (templates) ───

  CollectionReference<Map<String, dynamic>> _coachProgramsCol(String coachUid) =>
      _coachDoc(coachUid).collection('programs');

  Stream<List<Program>> watchCoachPrograms(String coachUid) {
    return _coachProgramsCol(coachUid).snapshots().map((snap) {
      return snap.docs.map((doc) {
        return Program.fromJson(doc.data());
      }).toList();
    });
  }

  Future<void> saveCoachProgram(String coachUid, Program program) async {
    await _coachProgramsCol(coachUid).doc(program.id).set(program.toJson());
  }

  Future<void> deleteCoachProgram(String coachUid, String programId) async {
    await _coachProgramsCol(coachUid).doc(programId).delete();
  }

  // ─── Coach Applications ───

  Future<void> submitApplication(String uid, CoachApplication application) async {
    await _firestore.collection('coach_applications').doc(uid).set(application.toJson());
  }

  Future<CoachApplication?> getApplication(String uid) async {
    final snap = await _firestore.collection('coach_applications').doc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return CoachApplication.fromJson(snap.data()!);
  }

  Stream<List<CoachApplication>> watchPendingApplications() {
    return _firestore
        .collection('coach_applications')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return CoachApplication.fromJson(data);
      }).toList();
    });
  }

  Future<void> approveApplication(String uid) async {
    await _firestore.collection('coach_applications').doc(uid).update({
      'status': 'approved',
    });
  }

  Future<void> rejectApplication(String uid) async {
    await _firestore.collection('coach_applications').doc(uid).update({
      'status': 'rejected',
    });
  }

  // ─── Helpers ───

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/coach/data/coach_repository.dart
git commit -m "feat: add CoachRepository with Firestore CRUD for coach data"
```

---

## Task 5: Coach Service

**Files:**
- Create: `lib/features/coach/domain/coach_service.dart`
- Test: `test/services/coach_service_test.dart`

- [ ] **Step 1: Create coach service**

```dart
// lib/features/coach/domain/coach_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/models/coach_application.dart';
import '../../../shared/models/coach_client.dart';
import '../../../shared/models/coach_invite.dart';
import '../../../shared/models/coach_profile.dart';
import '../../../shared/models/program.dart';
import '../../user/data/user_repository.dart';
import '../data/coach_repository.dart';

class CoachService {
  final CoachRepository _coachRepo;
  final UserRepository _userRepo;
  final FirebaseFirestore _firestore;

  CoachService(this._coachRepo, this._userRepo, this._firestore);

  // ─── Invite Flow ───

  Future<CoachInvite> generateInvite(String coachUid, {String? clientEmail}) async {
    final profile = await _coachRepo.getCoachProfile(coachUid);
    if (profile == null) throw Exception('Coach profile not found');
    if (!profile.canAddClient) throw Exception('Client roster is full');
    return _coachRepo.createInvite(coachUid, clientEmail: clientEmail);
  }

  /// Client accepts invite code. Returns coach display name on success.
  Future<String> acceptInvite(String clientUid, String code) async {
    // 1. Lookup code
    final lookup = await _coachRepo.lookupInviteCode(code.toUpperCase());
    if (lookup == null) throw Exception('Invalid invite code');
    if (lookup['status'] != 'pending') throw Exception('Invite is no longer valid');

    final coachUid = lookup['coachUid'] as String;
    final inviteId = lookup['inviteId'] as String;

    // 2. Validate coach has room
    final coachProfile = await _coachRepo.getCoachProfile(coachUid);
    if (coachProfile == null) throw Exception('Coach not found');
    if (!coachProfile.canAddClient) throw Exception('Coach roster is full');

    // 3. Check client doesn't already have a coach
    final clientProfile = await _userRepo.getUser(clientUid);
    if (clientProfile == null) throw Exception('User profile not found');
    if (clientProfile.coachId != null) {
      throw Exception('Already linked to a coach');
    }

    // 4. Atomic batch write
    final batch = _firestore.batch();

    // Update user with coachId
    batch.update(_firestore.collection('users').doc(clientUid), {
      'coachId': coachUid,
      'coachLinkedAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Add to coach's clients
    final clientDoc = CoachClient(
      uid: clientUid,
      clientName: clientProfile.name,
      clientEmail: clientProfile.email,
      linkedAt: DateTime.now(),
      inviteMethod: 'code',
    );
    batch.set(
      _firestore.collection('coaches').doc(coachUid).collection('clients').doc(clientUid),
      clientDoc.toJson(),
    );

    // Update invite status
    batch.update(
      _firestore.collection('coaches').doc(coachUid).collection('invites').doc(inviteId),
      {'status': 'accepted'},
    );
    batch.update(
      _firestore.collection('invite_codes').doc(code.toUpperCase()),
      {'status': 'accepted'},
    );

    // Increment client count
    batch.update(
      _firestore.collection('coaches').doc(coachUid),
      {'clientCount': FieldValue.increment(1)},
    );

    await batch.commit();

    return coachProfile.displayName;
  }

  // ─── Remove Client ───

  Future<void> removeClient(String coachUid, String clientUid) async {
    final batch = _firestore.batch();

    // Remove coachId from user
    batch.update(_firestore.collection('users').doc(clientUid), {
      'coachId': null,
      'coachLinkedAt': null,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Remove from coach's clients subcollection
    batch.delete(
      _firestore.collection('coaches').doc(coachUid).collection('clients').doc(clientUid),
    );

    // Decrement client count
    batch.update(
      _firestore.collection('coaches').doc(coachUid),
      {'clientCount': FieldValue.increment(-1)},
    );

    // Unmark coach-assigned programs (keep them but remove coach flag)
    final programs = await _firestore
        .collection('users')
        .doc(clientUid)
        .collection('programs')
        .where('coachId', isEqualTo: coachUid)
        .get();

    for (final doc in programs.docs) {
      batch.update(doc.reference, {
        'assignedByCoach': false,
        'coachId': null,
      });
    }

    await batch.commit();
  }

  // ─── Assign Program ───

  Future<void> assignProgram(String coachUid, String clientUid, Program template) async {
    final programId = const Uuid().v4();
    final program = template.copyWith(
      id: programId,
      isActive: true,
      assignedByCoach: true,
      coachId: coachUid,
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();

    // Deactivate current active program
    final activePrograms = await _firestore
        .collection('users')
        .doc(clientUid)
        .collection('programs')
        .where('isActive', isEqualTo: true)
        .get();

    for (final doc in activePrograms.docs) {
      batch.update(doc.reference, {'isActive': false});
    }

    // Write new program
    batch.set(
      _firestore.collection('users').doc(clientUid).collection('programs').doc(programId),
      program.toJson(),
    );

    await batch.commit();
  }

  // ─── Coach Application ───

  Future<void> submitApplication(String uid, String email, String name, String reason) async {
    final application = CoachApplication(
      uid: uid,
      email: email,
      displayName: name,
      reason: reason,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    await _coachRepo.submitApplication(uid, application);
  }

  Future<void> approveCoach(String applicantUid) async {
    // 1. Update application status
    await _coachRepo.approveApplication(applicantUid);

    // 2. Set user role to coach
    await _userRepo.updateUser(applicantUid, {'role': 'coach'});

    // 3. Create coach profile
    final userProfile = await _userRepo.getUser(applicantUid);
    final coachProfile = CoachProfile(
      uid: applicantUid,
      displayName: userProfile?.name ?? 'Coach',
      email: userProfile?.email ?? '',
      planTier: null, // Coach needs to subscribe
      clientCount: 0,
      maxClients: 0,
      approvedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
    await _coachRepo.createCoachProfile(applicantUid, coachProfile);
  }

  Future<void> rejectCoach(String applicantUid) async {
    await _coachRepo.rejectApplication(applicantUid);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/coach/domain/coach_service.dart
git commit -m "feat: add CoachService with invite, client management, and program assignment logic"
```

---

## Task 6: Coach Providers

**Files:**
- Create: `lib/app/providers/coach_providers.dart`
- Modify: `lib/app/providers.dart`
- Modify: `lib/app/providers/data_providers.dart`

- [ ] **Step 1: Create coach providers**

```dart
// lib/app/providers/coach_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/coach/data/coach_repository.dart';
import '../../features/coach/domain/coach_service.dart';
import '../../shared/models/coach_application.dart';
import '../../shared/models/coach_client.dart';
import '../../shared/models/coach_invite.dart';
import '../../shared/models/coach_profile.dart';
import '../../shared/models/program.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

// ─── Repository ───
final coachRepositoryProvider = Provider<CoachRepository>((ref) {
  final firestore = ref.watch(firestoreProvider)!;
  return CoachRepository(firestore);
});

// ─── Service ───
final coachServiceProvider = Provider<CoachService>((ref) {
  final coachRepo = ref.watch(coachRepositoryProvider);
  final userRepo = ref.watch(userRepositoryProvider);
  final firestore = ref.watch(firestoreProvider)!;
  return CoachService(coachRepo, userRepo, firestore);
});

// ─── Coach Profile (for logged-in coach) ───
final coachProfileProvider = StreamProvider<CoachProfile?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(coachRepositoryProvider).watchCoachProfile(uid);
});

// ─── Coach Clients ───
final coachClientsProvider = StreamProvider<List<CoachClient>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(coachRepositoryProvider).watchClients(uid);
});

// ─── Coach Invites ───
final coachInvitesProvider = StreamProvider<List<CoachInvite>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(coachRepositoryProvider).watchInvites(uid);
});

// ─── Coach Program Templates ───
final coachProgramsProvider = StreamProvider<List<Program>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(coachRepositoryProvider).watchCoachPrograms(uid);
});

// ─── Pending Applications (admin only) ───
final pendingApplicationsProvider = StreamProvider<List<CoachApplication>>((ref) {
  return ref.watch(coachRepositoryProvider).watchPendingApplications();
});
```

- [ ] **Step 2: Add userRoleProvider to data_providers.dart**

Append to `lib/app/providers/data_providers.dart`:

```dart
// ─── User Role ───
final userRoleProvider = Provider<String>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  return profile?.role ?? 'user';
});
```

- [ ] **Step 3: Add export to providers.dart**

Add to `lib/app/providers.dart`:

```dart
export 'providers/coach_providers.dart';
```

- [ ] **Step 4: Commit**

```bash
git add lib/app/providers/coach_providers.dart lib/app/providers/data_providers.dart lib/app/providers.dart
git commit -m "feat: add coach Riverpod providers and userRoleProvider"
```

---

## Task 7: Updated Entitlement Service (Coach-Sponsored Pro)

**Files:**
- Modify: `lib/features/subscription/domain/entitlement_service.dart`
- Modify: `lib/features/subscription/data/entitlement_repository.dart`
- Modify: `lib/app/providers/subscription_providers.dart`

- [ ] **Step 1: Update EntitlementService to accept UserRepository and CoachRepository**

```dart
// lib/features/subscription/domain/entitlement_service.dart
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/exceptions.dart';
import '../../../features/coach/data/coach_repository.dart';
import '../../../features/user/data/user_repository.dart';
import '../data/entitlement_repository.dart';

class EntitlementService {
  final EntitlementRepository _repo;
  final UserRepository? _userRepo;
  final CoachRepository? _coachRepo;

  EntitlementService(this._repo, {UserRepository? userRepo, CoachRepository? coachRepo})
      : _userRepo = userRepo,
        _coachRepo = coachRepo;

  Future<void> initialize() => _repo.initialize();

  Future<void> loginUser(String uid) async {
    await _repo.initialize();
    await _repo.login(uid);
  }

  Future<void> logoutUser() async {
    await _repo.logout();
  }

  /// Check if user has pro access from any source:
  /// 1. Admin role bypass
  /// 2. Own RevenueCat subscription
  /// 3. Coach-sponsored (coach has active plan)
  Future<bool> isPro(String? uid) async {
    // Admin bypass via role
    if (uid != null && _userRepo != null) {
      final role = await _userRepo!.getRole(uid);
      if (role == 'admin_user' || role == 'admin_coach') return true;
    }

    // Own subscription
    if (await _repo.isPro()) return true;

    // Coach-sponsored
    if (uid != null && _userRepo != null && _coachRepo != null) {
      final coachId = await _userRepo!.getCoachId(uid);
      if (coachId != null) {
        final coachProfile = await _coachRepo!.getCoachProfile(coachId);
        if (coachProfile != null && coachProfile.planTier != null) {
          return true;
        }
      }
    }

    return false;
  }

  Stream<bool> isProStream() => _repo.isProStream();

  Future<Offerings> getOfferings() => _repo.getOfferings();

  Future<bool> purchase(Package package) => _repo.purchase(package);

  Future<bool> restorePurchases() => _repo.restorePurchases();

  Future<SubscriptionState> getSubscriptionState() => _repo.getSubscriptionState();
  Stream<SubscriptionState> subscriptionStateStream() => _repo.subscriptionStateStream();

  Future<void> requireActiveSubscription(String? uid) async {
    if (uid != null && await isPro(uid)) return;
    final state = await getSubscriptionState();
    if (state == SubscriptionState.expired) {
      throw SubscriptionExpiredException();
    }
  }
}
```

- [ ] **Step 2: Update subscription_providers.dart**

```dart
// lib/app/providers/subscription_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/exceptions.dart';
import '../../features/subscription/data/entitlement_repository.dart';
import '../../features/subscription/domain/entitlement_service.dart';
import 'auth_providers.dart';
import 'coach_providers.dart';
import 'repository_providers.dart';

final entitlementRepositoryProvider = Provider<EntitlementRepository>((ref) {
  return EntitlementRepository();
});

final entitlementServiceProvider = Provider<EntitlementService>((ref) {
  return EntitlementService(
    ref.watch(entitlementRepositoryProvider),
    userRepo: ref.watch(userRepositoryProvider),
    coachRepo: ref.watch(coachRepositoryProvider),
  );
});

final isProProvider = FutureProvider<bool>((ref) async {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(entitlementServiceProvider).isPro(uid);
});

final subscriptionStateProvider = StreamProvider<SubscriptionState>((ref) {
  return ref.watch(entitlementServiceProvider).subscriptionStateStream();
});

final subscriptionGuardProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final uid = ref.read(currentUidProvider);
    await ref.read(entitlementServiceProvider).requireActiveSubscription(uid);
  };
});
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/subscription/domain/entitlement_service.dart lib/app/providers/subscription_providers.dart
git commit -m "feat: update EntitlementService with coach-sponsored pro and admin role bypass"
```

---

## Task 8: Router — Role-Based Shell Switching

**Files:**
- Create: `lib/shared/widgets/coach_scaffold.dart`
- Modify: `lib/app/router.dart`

- [ ] **Step 1: Create CoachScaffold (coach bottom nav)**

```dart
// lib/shared/widgets/coach_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_shadows.dart';
import '../utils/platform_adapter.dart';

class CoachScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const CoachScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _navItem(Icons.dashboard_outlined, 'Dashboard', activeIndex == 0, () => navigationShell.goBranch(0), isDark),
                _navItem(Icons.people_outlined, 'Clients', activeIndex == 1, () => navigationShell.goBranch(1), isDark),
                _navItem(AppIcons.library, 'Programs', activeIndex == 2, () => navigationShell.goBranch(2), isDark),
                _navItem(Icons.settings_outlined, 'Settings', activeIndex == 3, () => navigationShell.goBranch(3), isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive, VoidCallback onTap, bool isDark) {
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final inactiveColor = isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          PlatformAdapter.hapticLight();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: isActive ? activeColor : inactiveColor),
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
    );
  }
}
```

- [ ] **Step 2: Update router.dart with role-based routing**

Add to the imports in `lib/app/router.dart`:

```dart
import '../features/coach/presentation/coach_dashboard_screen.dart';
import '../features/coach/presentation/clients_screen.dart';
import '../features/coach/presentation/coach_programs_screen.dart';
import '../features/coach/presentation/coach_settings_screen.dart';
import '../features/coach/presentation/client_detail_screen.dart';
import '../features/coach/presentation/assign_program_screen.dart';
import '../features/coach/presentation/invite_management_screen.dart';
import '../features/coach/presentation/coach_approval_screen.dart';
import '../features/coach/presentation/join_coach_screen.dart';
import '../shared/widgets/coach_scaffold.dart';
import 'providers/data_providers.dart';
```

Update `routerProvider` redirect logic to handle coach role:

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userRole = ref.watch(userRoleProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final currentPath = state.uri.path;
      final isPublicRoute = _publicPaths.contains(currentPath);

      if (!isLoggedIn && !isPublicRoute) return '/onboarding';
      if (isLoggedIn && (currentPath == '/login' || currentPath == '/onboarding')) {
        // Route based on role
        if (userRole == 'coach' || userRole == 'admin_coach') {
          return '/coach/dashboard';
        }
        return '/home';
      }

      // Prevent user from accessing coach routes
      if (isLoggedIn && currentPath.startsWith('/coach/') &&
          userRole != 'coach' && userRole != 'admin_coach') {
        return '/home';
      }

      // Prevent coach from accessing user routes
      if (isLoggedIn && !currentPath.startsWith('/coach/') &&
          !isPublicRoute &&
          currentPath != '/paywall' &&
          currentPath != '/settings' &&
          currentPath != '/join-coach' &&
          (userRole == 'coach' || userRole == 'admin_coach')) {
        return '/coach/dashboard';
      }

      return null;
    },
    routes: [
      // ... existing auth + onboarding routes stay the same ...

      // ─── Coach Shell ───
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return CoachScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/coach/dashboard',
              name: 'coach-dashboard',
              pageBuilder: (context, state) => fadeTransitionPage(
                state: state, child: const CoachDashboardScreen(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/coach/clients',
              name: 'coach-clients',
              pageBuilder: (context, state) => fadeTransitionPage(
                state: state, child: const ClientsScreen(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/coach/programs',
              name: 'coach-programs',
              pageBuilder: (context, state) => fadeTransitionPage(
                state: state, child: const CoachProgramsScreen(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/coach/settings',
              name: 'coach-settings',
              pageBuilder: (context, state) => fadeTransitionPage(
                state: state, child: const CoachSettingsScreen(),
              ),
            ),
          ]),
        ],
      ),

      // ─── Coach Standalone Screens ───
      GoRoute(
        path: '/coach/clients/:clientUid',
        name: 'client-detail',
        pageBuilder: (context, state) => slideTransitionPage(
          state: state,
          child: ClientDetailScreen(clientUid: state.pathParameters['clientUid'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/coach/clients/:clientUid/assign',
        name: 'assign-program',
        pageBuilder: (context, state) => slideTransitionPage(
          state: state,
          child: AssignProgramScreen(clientUid: state.pathParameters['clientUid'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/coach/invites',
        name: 'coach-invites',
        pageBuilder: (context, state) => slideTransitionPage(
          state: state, child: const InviteManagementScreen(),
        ),
      ),
      GoRoute(
        path: '/coach/approvals',
        name: 'coach-approvals',
        pageBuilder: (context, state) => slideTransitionPage(
          state: state, child: const CoachApprovalScreen(),
        ),
      ),

      // ─── Client: Join Coach ───
      GoRoute(
        path: '/join-coach',
        name: 'join-coach',
        pageBuilder: (context, state) => slideTransitionPage(
          state: state, child: const JoinCoachScreen(),
        ),
      ),

      // ... existing main app shell + standalone routes stay the same ...
    ],
  );
});
```

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/coach_scaffold.dart lib/app/router.dart
git commit -m "feat: add role-based routing with coach shell and CoachScaffold"
```

---

## Task 9: Coach Dashboard Screen

**Files:**
- Create: `lib/features/coach/presentation/coach_dashboard_screen.dart`

- [ ] **Step 1: Create dashboard screen**

```dart
// lib/features/coach/presentation/coach_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/coach_providers.dart';
import '../../../theme/app_colors.dart';

class CoachDashboardScreen extends ConsumerWidget {
  const CoachDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coachProfile = ref.watch(coachProfileProvider);
    final clients = ref.watch(coachClientsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Coach Dashboard',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                ),
              ),
              SizedBox(height: 16.h),

              // Stats cards
              coachProfile.when(
                data: (profile) {
                  if (profile == null) {
                    return const Text('Coach profile not found. Please subscribe to a coach plan.');
                  }
                  return Column(
                    children: [
                      _StatCard(
                        title: 'Active Clients',
                        value: '${profile.clientCount} / ${profile.maxClients}',
                        isDark: isDark,
                      ),
                      SizedBox(height: 12.h),
                      if (profile.planTier == null)
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              children: [
                                const Text('Subscribe to a coach plan to start adding clients.'),
                                SizedBox(height: 8.h),
                                ElevatedButton(
                                  onPressed: () => context.push('/paywall'),
                                  child: const Text('View Plans'),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),

              SizedBox(height: 24.h),

              // Recent client activity
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                ),
              ),
              SizedBox(height: 12.h),

              Expanded(
                child: clients.when(
                  data: (clientList) {
                    if (clientList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 48.sp, color: Colors.grey),
                            SizedBox(height: 8.h),
                            const Text('No clients yet'),
                            SizedBox(height: 8.h),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/coach/invites'),
                              icon: const Icon(Icons.add),
                              label: const Text('Invite Client'),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: clientList.length,
                      itemBuilder: (context, index) {
                        final client = clientList[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(client.clientName.isNotEmpty
                                ? client.clientName[0].toUpperCase()
                                : '?'),
                          ),
                          title: Text(client.clientName),
                          subtitle: Text(client.clientEmail),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/coach/clients/${client.uid}'),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isDark;

  const _StatCard({required this.title, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
          SizedBox(height: 4.h),
          Text(value, style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/coach/presentation/coach_dashboard_screen.dart
git commit -m "feat: add CoachDashboardScreen with stats and client list"
```

---

## Task 10: Clients Screen & Client Detail Screen

**Files:**
- Create: `lib/features/coach/presentation/clients_screen.dart`
- Create: `lib/features/coach/presentation/client_detail_screen.dart`

- [ ] **Step 1: Create ClientsScreen**

```dart
// lib/features/coach/presentation/clients_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/coach_providers.dart';
import '../../../theme/app_colors.dart';

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(coachClientsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clients',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                ),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: clients.when(
                  data: (clientList) {
                    if (clientList.isEmpty) {
                      return const Center(child: Text('No clients yet. Send an invite to get started.'));
                    }
                    return ListView.separated(
                      itemCount: clientList.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final client = clientList[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(client.clientName.isNotEmpty
                                ? client.clientName[0].toUpperCase()
                                : '?'),
                          ),
                          title: Text(client.clientName),
                          subtitle: Text(client.clientEmail),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/coach/clients/${client.uid}'),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/coach/invites'),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Client'),
      ),
    );
  }
}
```

- [ ] **Step 2: Create ClientDetailScreen**

```dart
// lib/features/coach/presentation/client_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/auth_providers.dart';
import '../../../app/providers/coach_providers.dart';
import '../../../shared/models/program.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/models/workout.dart';
import '../../../theme/app_colors.dart';
import '../../user/data/user_repository.dart';

// Providers scoped to a specific client
final clientProfileProvider =
    FutureProvider.family<UserProfile?, String>((ref, clientUid) async {
  final firestore = ref.watch(firestoreProvider)!;
  final repo = UserRepository(firestore);
  return repo.getUser(clientUid);
});

final clientProgramsProvider =
    StreamProvider.family<List<Program>, String>((ref, clientUid) {
  final firestore = ref.watch(firestoreProvider)!;
  return firestore
      .collection('users')
      .doc(clientUid)
      .collection('programs')
      .snapshots()
      .map((snap) => snap.docs.map((d) => Program.fromJson(d.data())).toList());
});

final clientWorkoutsProvider =
    StreamProvider.family<List<Workout>, String>((ref, clientUid) {
  final firestore = ref.watch(firestoreProvider)!;
  return firestore
      .collection('users')
      .doc(clientUid)
      .collection('workouts')
      .orderBy('date', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs.map((d) => Workout.fromJson(d.data())).toList());
});

class ClientDetailScreen extends ConsumerWidget {
  final String clientUid;

  const ClientDetailScreen({super.key, required this.clientUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientProfile = ref.watch(clientProfileProvider(clientUid));
    final clientPrograms = ref.watch(clientProgramsProvider(clientUid));
    final clientWorkouts = ref.watch(clientWorkoutsProvider(clientUid));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: clientProfile.when(
          data: (p) => Text(p?.name ?? 'Client'),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Client'),
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'assign', child: Text('Assign Program')),
              const PopupMenuItem(value: 'remove', child: Text('Remove Client')),
            ],
            onSelected: (value) async {
              if (value == 'assign') {
                context.push('/coach/clients/$clientUid/assign');
              } else if (value == 'remove') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Remove Client'),
                    content: const Text('This will disconnect the client from your roster. They will lose coach-sponsored pro access.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  final coachUid = ref.read(currentUidProvider)!;
                  await ref.read(coachServiceProvider).removeClient(coachUid, clientUid);
                  if (context.mounted) context.pop();
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile overview
            clientProfile.when(
              data: (profile) {
                if (profile == null) return const Text('Profile not found');
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.name, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4.h),
                        Text('${profile.experienceLevel} | ${profile.primaryGoal}'),
                        Text('${profile.weight} ${profile.unit} | ${profile.height}'),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),

            SizedBox(height: 24.h),

            // Programs section
            Text('Programs', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 8.h),
            clientPrograms.when(
              data: (programs) {
                if (programs.isEmpty) return const Text('No programs assigned');
                return Column(
                  children: programs.map((p) => ListTile(
                    title: Text(p.name),
                    subtitle: Text(p.isActive ? 'Active' : 'Inactive'),
                    trailing: p.assignedByCoach
                        ? const Chip(label: Text('Coach'))
                        : null,
                  )).toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),

            SizedBox(height: 24.h),

            // Recent workouts
            Text('Recent Workouts', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 8.h),
            clientWorkouts.when(
              data: (workouts) {
                if (workouts.isEmpty) return const Text('No workouts logged yet');
                return Column(
                  children: workouts.take(10).map((w) => ListTile(
                    title: Text('${w.exercises.length} exercises'),
                    subtitle: Text('${w.date.day}/${w.date.month}/${w.date.year}'),
                    trailing: Text('${w.totalVolume.toStringAsFixed(0)} ${w.status.name}'),
                  )).toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/coach/presentation/clients_screen.dart lib/features/coach/presentation/client_detail_screen.dart
git commit -m "feat: add ClientsScreen and ClientDetailScreen for coach"
```

---

## Task 11: Coach Programs Screen & Assign Program Screen

**Files:**
- Create: `lib/features/coach/presentation/coach_programs_screen.dart`
- Create: `lib/features/coach/presentation/assign_program_screen.dart`

- [ ] **Step 1: Create CoachProgramsScreen**

```dart
// lib/features/coach/presentation/coach_programs_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/auth_providers.dart';
import '../../../app/providers/coach_providers.dart';
import '../../../theme/app_colors.dart';

class CoachProgramsScreen extends ConsumerWidget {
  const CoachProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programs = ref.watch(coachProgramsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Program Templates',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Create templates to assign to your clients.',
                style: TextStyle(color: Colors.grey, fontSize: 14.sp),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: programs.when(
                  data: (programList) {
                    if (programList.isEmpty) {
                      return const Center(child: Text('No program templates yet.'));
                    }
                    return ListView.builder(
                      itemCount: programList.length,
                      itemBuilder: (context, index) {
                        final p = programList[index];
                        return Card(
                          child: ListTile(
                            title: Text(p.name),
                            subtitle: Text('${p.workouts} workouts/week | ${p.weeks} weeks'),
                            trailing: PopupMenuButton(
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                              onSelected: (value) async {
                                if (value == 'delete') {
                                  final uid = ref.read(currentUidProvider)!;
                                  await ref.read(coachRepositoryProvider).deleteCoachProgram(uid, p.id);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/programs/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Template'),
      ),
    );
  }
}
```

- [ ] **Step 2: Create AssignProgramScreen**

```dart
// lib/features/coach/presentation/assign_program_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/auth_providers.dart';
import '../../../app/providers/coach_providers.dart';
import '../../../shared/models/program.dart';

class AssignProgramScreen extends ConsumerWidget {
  final String clientUid;

  const AssignProgramScreen({super.key, required this.clientUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programs = ref.watch(coachProgramsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Assign Program')),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a program template to assign:',
              style: TextStyle(fontSize: 16.sp),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: programs.when(
                data: (programList) {
                  if (programList.isEmpty) {
                    return const Center(
                      child: Text('No templates available. Create one first.'),
                    );
                  }
                  return ListView.builder(
                    itemCount: programList.length,
                    itemBuilder: (context, index) {
                      final p = programList[index];
                      return Card(
                        child: ListTile(
                          title: Text(p.name),
                          subtitle: Text('${p.workouts} workouts/week | ${p.weeks} weeks'),
                          trailing: ElevatedButton(
                            onPressed: () => _assignProgram(context, ref, p),
                            child: const Text('Assign'),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignProgram(BuildContext context, WidgetRef ref, Program template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Program'),
        content: Text('Assign "${template.name}" as the active program? This will deactivate their current program.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Assign')),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final coachUid = ref.read(currentUidProvider)!;
      await ref.read(coachServiceProvider).assignProgram(coachUid, clientUid, template);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${template.name} assigned successfully')),
        );
        context.pop();
      }
    }
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/coach/presentation/coach_programs_screen.dart lib/features/coach/presentation/assign_program_screen.dart
git commit -m "feat: add CoachProgramsScreen and AssignProgramScreen"
```

---

## Task 12: Invite Management & Coach Settings Screens

**Files:**
- Create: `lib/features/coach/presentation/invite_management_screen.dart`
- Create: `lib/features/coach/presentation/coach_settings_screen.dart`

- [ ] **Step 1: Create InviteManagementScreen**

```dart
// lib/features/coach/presentation/invite_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/providers/auth_providers.dart';
import '../../../app/providers/coach_providers.dart';

class InviteManagementScreen extends ConsumerWidget {
  const InviteManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invites = ref.watch(coachInvitesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Invites')),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Generate new invite
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _generateInvite(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Generate Code'),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _generateEmailInvite(context, ref),
                    icon: const Icon(Icons.email),
                    label: const Text('Email Invite'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Invite list
            Expanded(
              child: invites.when(
                data: (inviteList) {
                  if (inviteList.isEmpty) {
                    return const Center(child: Text('No invites yet.'));
                  }
                  return ListView.builder(
                    itemCount: inviteList.length,
                    itemBuilder: (context, index) {
                      final invite = inviteList[index];
                      final isActive = invite.isPending;
                      return Card(
                        child: ListTile(
                          title: Text(
                            invite.code,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: isActive ? null : Colors.grey,
                            ),
                          ),
                          subtitle: Text(
                            isActive
                                ? 'Pending | Expires ${invite.expiresAt.day}/${invite.expiresAt.month}'
                                : invite.status.toUpperCase(),
                          ),
                          trailing: isActive
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.copy),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: invite.code));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Code copied')),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => _revokeInvite(ref, invite.id, invite.code),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateInvite(BuildContext context, WidgetRef ref) async {
    final coachUid = ref.read(currentUidProvider)!;
    try {
      final invite = await ref.read(coachServiceProvider).generateInvite(coachUid);
      if (context.mounted) {
        Clipboard.setData(ClipboardData(text: invite.code));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Code ${invite.code} copied to clipboard')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _generateEmailInvite(BuildContext context, WidgetRef ref) async {
    final emailController = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Email Invite'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(hintText: 'Client email'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, emailController.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (email != null && email.isNotEmpty && context.mounted) {
      final coachUid = ref.read(currentUidProvider)!;
      try {
        await ref.read(coachServiceProvider).generateInvite(coachUid, clientEmail: email);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invite created for $email')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _revokeInvite(WidgetRef ref, String inviteId, String code) {
    final coachUid = ref.read(currentUidProvider)!;
    ref.read(coachRepositoryProvider).revokeInvite(coachUid, inviteId, code);
  }
}
```

- [ ] **Step 2: Create CoachSettingsScreen**

```dart
// lib/features/coach/presentation/coach_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/auth_providers.dart';
import '../../../app/providers/coach_providers.dart';
import '../../../app/providers/data_providers.dart';
import '../../../features/auth/domain/auth_service.dart';
import '../../../theme/app_colors.dart';

class CoachSettingsScreen extends ConsumerWidget {
  const CoachSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coachProfile = ref.watch(coachProfileProvider);
    final userRole = ref.watch(userRoleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                ),
              ),
              SizedBox(height: 24.h),

              // Coach profile info
              coachProfile.when(
                data: (profile) {
                  if (profile == null) return const SizedBox.shrink();
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.displayName, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                          if (profile.bio != null) Text(profile.bio!),
                          SizedBox(height: 8.h),
                          Text('Plan: ${profile.planTier ?? "None"}'),
                          Text('Clients: ${profile.clientCount} / ${profile.maxClients}'),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              SizedBox(height: 16.h),

              // Menu items
              ListTile(
                leading: const Icon(Icons.send),
                title: const Text('Manage Invites'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/coach/invites'),
              ),

              ListTile(
                leading: const Icon(Icons.payment),
                title: const Text('Subscription'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/paywall'),
              ),

              // Admin only: approve coaches
              if (userRole == 'admin_coach' || userRole == 'admin_user')
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('Coach Applications'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/coach/approvals'),
                ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go('/onboarding');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/coach/presentation/invite_management_screen.dart lib/features/coach/presentation/coach_settings_screen.dart
git commit -m "feat: add InviteManagementScreen and CoachSettingsScreen"
```

---

## Task 13: Coach Approval Screen (Admin)

**Files:**
- Create: `lib/features/coach/presentation/coach_approval_screen.dart`

- [ ] **Step 1: Create CoachApprovalScreen**

```dart
// lib/features/coach/presentation/coach_approval_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/providers/coach_providers.dart';

class CoachApprovalScreen extends ConsumerWidget {
  const CoachApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(pendingApplicationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Coach Applications')),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: applications.when(
          data: (apps) {
            if (apps.isEmpty) {
              return const Center(child: Text('No pending applications.'));
            }
            return ListView.builder(
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.displayName, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                        Text(app.email),
                        SizedBox(height: 8.h),
                        Text('Reason: ${app.reason}'),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                await ref.read(coachServiceProvider).approveCoach(app.uid!);
                              },
                              child: const Text('Approve'),
                            ),
                            SizedBox(width: 8.w),
                            OutlinedButton(
                              onPressed: () async {
                                await ref.read(coachServiceProvider).rejectCoach(app.uid!);
                              },
                              child: const Text('Reject'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/coach/presentation/coach_approval_screen.dart
git commit -m "feat: add CoachApprovalScreen for admin to approve/reject coach applications"
```

---

## Task 14: Client-Side — Join Coach Screen

**Files:**
- Create: `lib/features/coach/presentation/join_coach_screen.dart`

- [ ] **Step 1: Create JoinCoachScreen**

```dart
// lib/features/coach/presentation/join_coach_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/auth_providers.dart';
import '../../../app/providers/coach_providers.dart';

class JoinCoachScreen extends ConsumerStatefulWidget {
  const JoinCoachScreen({super.key});

  @override
  ConsumerState<JoinCoachScreen> createState() => _JoinCoachScreenState();
}

class _JoinCoachScreenState extends ConsumerState<JoinCoachScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join a Coach')),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your coach\'s invite code:',
              style: TextStyle(fontSize: 16.sp),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: TextStyle(fontSize: 24.sp, fontFamily: 'monospace', letterSpacing: 4),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'ABC123',
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (_error != null) ...[
              SizedBox(height: 8.h),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Join'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Code must be 6 characters');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uid = ref.read(currentUidProvider)!;
      final coachName = await ref.read(coachServiceProvider).acceptInvite(uid, code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined $coachName\'s roster!')),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/coach/presentation/join_coach_screen.dart
git commit -m "feat: add JoinCoachScreen for clients to enter invite code"
```

---

## Task 15: Firestore Security Rules Update

**Files:**
- Modify: `firestore.rules`

- [ ] **Step 1: Update firestore.rules**

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isOwner(uid) {
      return request.auth != null && request.auth.uid == uid;
    }

    function isCoachOf(clientUid) {
      return request.auth != null
        && exists(/databases/$(database)/documents/users/$(clientUid))
        && get(/databases/$(database)/documents/users/$(clientUid)).data.coachId == request.auth.uid;
    }

    function isAdmin() {
      return request.auth != null
        && exists(/databases/$(database)/documents/users/$(request.auth.uid))
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin_user', 'admin_coach'];
    }

    // User profiles
    match /users/{uid} {
      allow read: if isOwner(uid) || isCoachOf(uid) || isAdmin();
      allow create: if isOwner(uid)
        && request.resource.data.email == request.auth.token.email
        && request.resource.data.uid == uid;
      allow update: if isOwner(uid) || isCoachOf(uid);
      allow delete: if isOwner(uid);

      // Subcollections
      match /workouts/{docId} {
        allow read: if isOwner(uid) || isCoachOf(uid) || isAdmin();
        allow create, update: if isOwner(uid) || isCoachOf(uid);
        allow delete: if isOwner(uid) || isCoachOf(uid);
      }
      match /programs/{docId} {
        allow read: if isOwner(uid) || isCoachOf(uid) || isAdmin();
        allow create, update: if isOwner(uid) || isCoachOf(uid);
        allow delete: if isOwner(uid) || isCoachOf(uid);
      }
      match /prs/{docId} {
        allow read: if isOwner(uid) || isCoachOf(uid) || isAdmin();
        allow create, update: if isOwner(uid) || isCoachOf(uid);
        allow delete: if isOwner(uid);
      }
      match /achievements/{docId} {
        allow read: if isOwner(uid) || isCoachOf(uid) || isAdmin();
        allow create, update: if isOwner(uid);
        allow delete: if isOwner(uid);
      }
      match /weightEntries/{docId} {
        allow read: if isOwner(uid) || isCoachOf(uid) || isAdmin();
        allow create, update: if isOwner(uid);
        allow delete: if isOwner(uid);
      }
      match /exercises/{docId} {
        allow read: if isOwner(uid) || isCoachOf(uid) || isAdmin();
        allow create, update, delete: if isOwner(uid);
      }
    }

    // Coach profiles & subcollections
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

      match /programs/{programId} {
        allow read: if isOwner(coachUid) || isAdmin();
        allow create, update, delete: if isOwner(coachUid);
      }
    }

    // Invite code lookup (top-level for fast queries)
    match /invite_codes/{code} {
      allow read: if request.auth != null;
      allow create: if request.auth != null
        && request.resource.data.coachUid == request.auth.uid;
      allow update: if request.auth != null;
      allow delete: if request.auth != null
        && resource.data.coachUid == request.auth.uid;
    }

    // Coach applications
    match /coach_applications/{uid} {
      allow create: if isOwner(uid);
      allow read: if isOwner(uid) || isAdmin();
      allow update: if isAdmin();
    }

    // Deny everything else
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add firestore.rules
git commit -m "feat: update Firestore security rules with coach access and admin roles"
```

---

## Task 16: Client-Side Program Screen Modifications

**Files:**
- Modify: `lib/features/programs/presentation/programs_screen.dart` (add coach badge, disable "Set Active" when coached)
- Modify: `lib/features/settings/presentation/settings_screen.dart` (add "My Coach" and "Become a Coach" options)

- [ ] **Step 1: Read current programs_screen.dart and settings_screen.dart**

Read the files to understand their current structure before modifying.

- [ ] **Step 2: Modify programs_screen.dart**

Add logic to check `userProfileProvider` for `coachId`. When a program has `assignedByCoach == true`, show a "Coach" chip. When user has a `coachId`, hide/disable the "Set as Active" button on all programs.

- [ ] **Step 3: Modify settings_screen.dart**

Add two new menu items:
- "My Coach" — visible when `profile.coachId != null`, shows coach name
- "Join a Coach" — visible when `profile.coachId == null`, navigates to `/join-coach`
- "Become a Coach" — visible when role is `user`, navigates to coach application flow

- [ ] **Step 4: Commit**

```bash
git add lib/features/programs/presentation/programs_screen.dart lib/features/settings/presentation/settings_screen.dart
git commit -m "feat: add coach badges to programs, My Coach section in settings"
```

---

## Task 17: Seed Script for Admin Accounts

**Files:**
- Create: `scripts/seed_admin_accounts.dart`

- [ ] **Step 1: Create seed script**

```dart
// scripts/seed_admin_accounts.dart
// Run with: dart run scripts/seed_admin_accounts.dart
//
// NOTE: This script requires the firebase_admin package or
// manual execution via Firebase Console.
//
// Instructions for manual seeding:
//
// 1. Sign up admin-user@gymratz.app via the app, note the UID
// 2. Sign up admin-coach@gymratz.app via the app, note the UID
// 3. In Firebase Console > Firestore, update:
//
//    users/{admin_user_uid}:
//      role: "admin_user"
//
//    users/{admin_coach_uid}:
//      role: "admin_coach"
//
//    coaches/{admin_coach_uid}:
//      displayName: "Admin Coach"
//      email: "admin-coach@gymratz.app"
//      planTier: "coach_20"
//      clientCount: 0
//      maxClients: 999
//      approvedAt: <current timestamp>
//      createdAt: <current timestamp>
//
// The admin accounts will then have full access without subscription checks.

void main() {
  print('=== GymRatz Admin Account Seed Instructions ===');
  print('');
  print('1. Create two Firebase Auth accounts:');
  print('   - admin-user@gymratz.app (User Admin)');
  print('   - admin-coach@gymratz.app (Coach Admin)');
  print('');
  print('2. Note the UIDs from Firebase Console > Authentication');
  print('');
  print('3. In Firestore, set the following:');
  print('');
  print('   users/{admin_user_uid}.role = "admin_user"');
  print('');
  print('   users/{admin_coach_uid}.role = "admin_coach"');
  print('');
  print('   coaches/{admin_coach_uid} = {');
  print('     displayName: "Admin Coach",');
  print('     email: "admin-coach@gymratz.app",');
  print('     planTier: "coach_20",');
  print('     clientCount: 0,');
  print('     maxClients: 999,');
  print('     approvedAt: <timestamp>,');
  print('     createdAt: <timestamp>,');
  print('   }');
  print('');
  print('Done! Both accounts bypass all subscription checks.');
}
```

- [ ] **Step 2: Commit**

```bash
git add scripts/seed_admin_accounts.dart
git commit -m "feat: add admin account seed instructions script"
```

---

## Task 18: Integration — Wire Everything Together & Verify Build

- [ ] **Step 1: Verify all imports resolve**

Run: `flutter analyze`
Fix any missing imports or type errors.

- [ ] **Step 2: Verify app builds**

Run: `flutter build apk --debug` (Android) or `flutter run` if emulator available.
Expected: Build succeeds with no errors.

- [ ] **Step 3: Run all tests**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat: wire coach management feature together, fix any build issues"
```

---

## Summary of Commits

1. `feat(models): add role, coachId to UserProfile and assignedByCoach to Program`
2. `feat(models): add CoachProfile, CoachClient, CoachInvite, CoachApplication models`
3. `feat: add coach product constants and UserRepository helper methods`
4. `feat: add CoachRepository with Firestore CRUD for coach data`
5. `feat: add CoachService with invite, client management, and program assignment logic`
6. `feat: add coach Riverpod providers and userRoleProvider`
7. `feat: update EntitlementService with coach-sponsored pro and admin role bypass`
8. `feat: add role-based routing with coach shell and CoachScaffold`
9. `feat: add CoachDashboardScreen with stats and client list`
10. `feat: add ClientsScreen and ClientDetailScreen for coach`
11. `feat: add CoachProgramsScreen and AssignProgramScreen`
12. `feat: add InviteManagementScreen and CoachSettingsScreen`
13. `feat: add CoachApprovalScreen for admin to approve/reject coach applications`
14. `feat: add JoinCoachScreen for clients to enter invite code`
15. `feat: update Firestore security rules with coach access and admin roles`
16. `feat: add coach badges to programs, My Coach section in settings`
17. `feat: add admin account seed instructions script`
18. `feat: wire coach management feature together, fix any build issues`
