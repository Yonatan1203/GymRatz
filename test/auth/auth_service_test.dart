// GYM-88: AuthService unit tests
// ignore_for_file: avoid_print

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gymratz/features/auth/data/auth_repository.dart';
import 'package:gymratz/features/auth/domain/auth_service.dart';
import 'package:gymratz/features/achievements/domain/achievement_service.dart';
import 'package:gymratz/features/subscription/domain/entitlement_service.dart';
import 'package:gymratz/features/user/data/user_repository.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockEntitlementService extends Mock implements EntitlementService {}

class MockAchievementService extends Mock implements AchievementService {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

MockUser _makeUser({String uid = 'test-uid'}) {
  final user = MockUser();
  when(() => user.uid).thenReturn(uid);
  when(() => user.email).thenReturn('test@example.com');
  when(() => user.displayName).thenReturn(null);
  return user;
}

MockUserCredential _makeCredential(MockUser user) {
  final cred = MockUserCredential();
  when(() => cred.user).thenReturn(user);
  return cred;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockAuthRepository authRepo;
  late FakeFirebaseFirestore firestore;
  late MockUserRepository userRepo;
  late MockEntitlementService entitlementService;
  late MockAchievementService achievementService;
  late AuthService sut;

  setUp(() {
    authRepo = MockAuthRepository();
    firestore = FakeFirebaseFirestore();
    userRepo = MockUserRepository();
    entitlementService = MockEntitlementService();
    achievementService = MockAchievementService();

    sut = AuthService(authRepo, firestore, userRepo);
    sut.setEntitlementService(entitlementService);
    sut.setAchievementService(achievementService);

    // Default stubs for non-fatal services
    when(() => achievementService.initForNewUser(any()))
        .thenAnswer((_) async {});
    when(() => entitlementService.loginUser(any()))
        .thenAnswer((_) async {});
    when(() => entitlementService.logoutUser()).thenAnswer((_) async {});
    when(() => userRepo.deleteAllUserData(any())).thenAnswer((_) async {});
    when(() => authRepo.deleteAccount()).thenAnswer((_) async {});
  });

  // -------------------------------------------------------------------------
  // signUp: initials derivation
  // -------------------------------------------------------------------------

  group('signUp — initials derivation', () {
    test('single name produces one-letter initials', () async {
      final user = _makeUser();
      final cred = _makeCredential(user);
      when(() => authRepo.signUpWithEmail(any(), any()))
          .thenAnswer((_) async => cred);

      await sut.signUp(
        email: 'test@example.com',
        password: 'password123',
        onboardingData: {'name': 'Alice'},
      );

      final snap = await firestore
          .collection('users')
          .doc('test-uid')
          .get();
      expect(snap.data()?['initials'], 'A');
    });

    test('two-part name produces two-letter initials', () async {
      final user = _makeUser();
      final cred = _makeCredential(user);
      when(() => authRepo.signUpWithEmail(any(), any()))
          .thenAnswer((_) async => cred);

      await sut.signUp(
        email: 'test@example.com',
        password: 'password123',
        onboardingData: {'name': 'Alice Bob'},
      );

      final snap = await firestore
          .collection('users')
          .doc('test-uid')
          .get();
      expect(snap.data()?['initials'], 'AB');
    });

    test('empty name produces empty initials', () async {
      final user = _makeUser();
      final cred = _makeCredential(user);
      when(() => authRepo.signUpWithEmail(any(), any()))
          .thenAnswer((_) async => cred);

      await sut.signUp(
        email: 'test@example.com',
        password: 'password123',
        onboardingData: {'name': ''},
      );

      final snap = await firestore
          .collection('users')
          .doc('test-uid')
          .get();
      expect(snap.data()?['initials'], '');
    });

    test('missing name falls back to email prefix', () async {
      final user = _makeUser();
      final cred = _makeCredential(user);
      when(() => authRepo.signUpWithEmail(any(), any()))
          .thenAnswer((_) async => cred);

      await sut.signUp(
        email: 'gymuser@example.com',
        password: 'password123',
        onboardingData: {},
      );

      final snap = await firestore
          .collection('users')
          .doc('test-uid')
          .get();
      // Name is email prefix "gymuser" → initials "G"
      expect(snap.data()?['name'], 'gymuser');
    });
  });

  // -------------------------------------------------------------------------
  // social sign-in: skip profile creation for returning users
  // -------------------------------------------------------------------------

  group('social sign-in — returning user', () {
    test('signInWithGoogle skips profile creation when profile exists', () async {
      const uid = 'existing-uid';
      final user = _makeUser(uid: uid);
      user.displayName; // already stubbed as null above

      // Pre-seed a profile so hasProfile returns true
      await firestore.collection('users').doc(uid).set({'uid': uid});

      final cred = _makeCredential(user);
      when(() => authRepo.signInWithGoogle())
          .thenAnswer((_) async => cred);

      await sut.signInWithGoogle();

      // Profile doc should still have only the pre-seeded fields (not overwritten)
      final snap = await firestore.collection('users').doc(uid).get();
      expect(snap.data()?.containsKey('initials'), isFalse);
    });

    test('signInWithGoogle creates profile for new user', () async {
      const uid = 'new-google-uid';
      final user = MockUser();
      when(() => user.uid).thenReturn(uid);
      when(() => user.email).thenReturn('newgoogle@example.com');
      when(() => user.displayName).thenReturn('John Doe');

      final cred = MockUserCredential();
      when(() => cred.user).thenReturn(user);
      when(() => authRepo.signInWithGoogle())
          .thenAnswer((_) async => cred);

      await sut.signInWithGoogle();

      final snap = await firestore.collection('users').doc(uid).get();
      expect(snap.exists, isTrue);
      expect(snap.data()?['initials'], 'JD');
    });
  });

  // -------------------------------------------------------------------------
  // deleteAccount: data deleted BEFORE auth account
  // -------------------------------------------------------------------------

  group('deleteAccount', () {
    test('deleteAllUserData is called before deleteAccount', () async {
      final callOrder = <String>[];

      when(() => authRepo.currentUser).thenReturn(_makeUser());
      when(() => userRepo.deleteAllUserData(any())).thenAnswer((_) async {
        callOrder.add('deleteData');
      });
      when(() => authRepo.deleteAccount()).thenAnswer((_) async {
        callOrder.add('deleteAuth');
      });

      await sut.deleteAccount();

      expect(callOrder, ['deleteData', 'deleteAuth']);
    });

    test('throws when no user is signed in', () async {
      when(() => authRepo.currentUser).thenReturn(null);

      await expectLater(sut.deleteAccount(), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  // sendPasswordReset
  // -------------------------------------------------------------------------

  group('sendPasswordReset', () {
    test('delegates to repository', () async {
      when(() => authRepo.sendPasswordReset(any())).thenAnswer((_) async {});

      await sut.sendPasswordReset('user@example.com');

      verify(() => authRepo.sendPasswordReset('user@example.com')).called(1);
    });
  });
}
