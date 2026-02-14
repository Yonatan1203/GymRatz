import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/models/user_profile.dart';
import '../../subscription/domain/entitlement_service.dart';
import '../data/auth_repository.dart';

class AuthService {
  final AuthRepository _authRepo;
  final FirebaseFirestore _firestore;
  EntitlementService? _entitlementService;

  AuthService(this._authRepo, this._firestore);

  /// Set the entitlement service for RevenueCat integration.
  void setEntitlementService(EntitlementService service) {
    _entitlementService = service;
  }

  Stream<User?> authStateChanges() => _authRepo.authStateChanges();

  User? get currentUser => _authRepo.currentUser;

  /// Sign up with email/password and create the Firestore user profile doc.
  Future<User> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> onboardingData,
  }) async {
    final credential = await _authRepo.signUpWithEmail(email, password);
    final user = credential.user!;

    final now = DateTime.now();
    final name = onboardingData['name'] as String? ?? email.split('@').first;
    final initials = name.isNotEmpty
        ? name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '';

    final profile = UserProfile(
      uid: user.uid,
      name: name,
      initials: initials,
      email: email,
      age: onboardingData['age'] as int? ?? 25,
      height: onboardingData['height'] as String? ?? '5\'10"',
      weight: (onboardingData['weight'] as num?)?.toDouble() ?? 75,
      unit: onboardingData['unit'] as String? ?? 'lbs',
      experienceLevel: onboardingData['experienceLevel'] as String? ?? 'Intermediate',
      primaryGoal: onboardingData['primaryGoal'] as String? ?? 'Build Muscle',
      injuries: (onboardingData['injuries'] as Set<String>?) ?? {},
      style: onboardingData['style'] as String?,
      notificationsEnabled: onboardingData['notificationsEnabled'] as bool? ?? true,
      healthEnabled: onboardingData['healthEnabled'] as bool? ?? false,
      discovery: onboardingData['discovery'] as String?,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore.collection('users').doc(user.uid).set(profile.toJson());

    // Link with RevenueCat
    await _entitlementService?.loginUser(user.uid);

    return user;
  }

  /// Sign in with email/password.
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _authRepo.signInWithEmail(email, password);
    final user = credential.user!;

    // Link with RevenueCat
    await _entitlementService?.loginUser(user.uid);

    return user;
  }

  /// Sign out.
  Future<void> signOut() async {
    await _entitlementService?.logoutUser();
    await _authRepo.signOut();
  }

  /// Delete account and Firestore data.
  Future<void> deleteAccount() async {
    final uid = _authRepo.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).delete();
    }
    await _authRepo.deleteAccount();
  }

  /// Send password reset email.
  Future<void> sendPasswordReset(String email) async {
    await _authRepo.sendPasswordReset(email);
  }
}
