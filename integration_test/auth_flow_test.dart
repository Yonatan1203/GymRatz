// GYM-91: Integration test — auth flow
//
// Tests sign-up, sign-in, sign-out, and wrong-password error at the
// AuthService level, using MockFirebaseAuth (firebase_auth_mocks) and
// FakeFirebaseFirestore (fake_cloud_firestore) so no real Firebase is needed.
//
// Run with:
//   flutter test integration_test/auth_flow_test.dart

// ignore_for_file: avoid_print

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gymratz/features/achievements/domain/achievement_service.dart';
import 'package:gymratz/features/auth/data/auth_repository.dart';
import 'package:gymratz/features/auth/domain/auth_service.dart';
import 'package:gymratz/features/subscription/domain/entitlement_service.dart';
import 'package:gymratz/features/user/data/user_repository.dart';
import 'package:gymratz/core/exceptions.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAuthRepository extends Mock implements AuthRepository {}

class MockEntitlementService extends Mock implements EntitlementService {}

class MockAchievementService extends Mock implements AchievementService {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates an AuthService wired to a [MockAuthRepository] so we can control
/// sign-in / sign-up results without touching real Firebase.
AuthService _makeService({
  required MockAuthRepository authRepo,
  required FakeFirebaseFirestore firestore,
  MockEntitlementService? entitlement,
  MockAchievementService? achievement,
}) {
  final userRepo = UserRepository(firestore);
  final service = AuthService(authRepo, firestore, userRepo);
  if (entitlement != null) service.setEntitlementService(entitlement);
  if (achievement != null) service.setAchievementService(achievement);
  return service;
}

MockUser _fakeUser({String uid = 'uid-test', String email = 'test@example.com'}) {
  final user = MockUser();
  when(() => user.uid).thenReturn(uid);
  when(() => user.email).thenReturn(email);
  when(() => user.displayName).thenReturn(null);
  return user;
}

MockUserCredential _fakeCred(MockUser user) {
  final cred = MockUserCredential();
  when(() => cred.user).thenReturn(user);
  return cred;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository authRepo;
  late FakeFirebaseFirestore firestore;
  late MockEntitlementService entitlement;
  late MockAchievementService achievement;
  late AuthService sut;

  setUp(() {
    authRepo = MockAuthRepository();
    firestore = FakeFirebaseFirestore();
    entitlement = MockEntitlementService();
    achievement = MockAchievementService();

    sut = _makeService(
      authRepo: authRepo,
      firestore: firestore,
      entitlement: entitlement,
      achievement: achievement,
    );

    // Non-fatal side-effects
    when(() => achievement.initForNewUser(any())).thenAnswer((_) async {});
    when(() => entitlement.loginUser(any())).thenAnswer((_) async {});
    when(() => entitlement.logoutUser()).thenAnswer((_) async {});
  });

  group('Auth flow — service layer', () {
    testWidgets('sign-up creates a Firestore profile', (tester) async {
      final user = _fakeUser(uid: 'new-user-uid');
      final cred = _fakeCred(user);

      when(() => authRepo.signUpWithEmail('test@example.com', 'password123'))
          .thenAnswer((_) async => cred);

      await sut.signUp(
        email: 'test@example.com',
        password: 'password123',
        onboardingData: {'name': 'Test User'},
      );

      final doc = await firestore
          .collection('users')
          .doc('new-user-uid')
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['name'], 'Test User');
      expect(doc.data()?['initials'], 'TU');
    });

    testWidgets('sign-in with correct credentials returns the user',
        (tester) async {
      final user = _fakeUser(uid: 'existing-uid');
      final cred = _fakeCred(user);

      when(() => authRepo.signInWithEmail('test@example.com', 'password123'))
          .thenAnswer((_) async => cred);

      final returned = await sut.signIn(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(returned.uid, 'existing-uid');
    });

    testWidgets('sign-up then sign-in same credentials works without error',
        (tester) async {
      const email = 'roundtrip@example.com';
      const password = 'SecurePass1';
      const uid = 'roundtrip-uid';

      final user = _fakeUser(uid: uid, email: email);
      final cred = _fakeCred(user);

      // Both sign-up and sign-in return same credential
      when(() => authRepo.signUpWithEmail(email, password))
          .thenAnswer((_) async => cred);
      when(() => authRepo.signInWithEmail(email, password))
          .thenAnswer((_) async => cred);

      await sut.signUp(
        email: email,
        password: password,
        onboardingData: {'name': 'Round Trip'},
      );

      final signedIn = await sut.signIn(email: email, password: password);
      expect(signedIn.uid, uid);
    });

    testWidgets('sign-out calls entitlement logout and repository signOut',
        (tester) async {
      when(() => authRepo.signOut()).thenAnswer((_) async {});

      await sut.signOut();

      verify(() => entitlement.logoutUser()).called(1);
      verify(() => authRepo.signOut()).called(1);
    });

    testWidgets(
        'sign-in with wrong password propagates AuthException to caller',
        (tester) async {
      when(() => authRepo.signInWithEmail('test@example.com', 'wrongpassword'))
          .thenThrow(const AuthException(
        'Invalid email or password.',
        code: 'invalid-credential',
      ));

      expect(
        () => sut.signIn(
          email: 'test@example.com',
          password: 'wrongpassword',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            'invalid-credential',
          ),
        ),
      );
    });
  });
}
