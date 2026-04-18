import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/models/user_profile.dart';
import '../../achievements/domain/achievement_service.dart';
import '../../subscription/domain/entitlement_service.dart';
import '../data/auth_repository.dart';

class AuthService {
  final AuthRepository _authRepo;
  final FirebaseFirestore _firestore;
  EntitlementService? _entitlementService;
  AchievementService? _achievementService;

  AuthService(this._authRepo, this._firestore);

  /// Set the entitlement service for RevenueCat integration.
  void setEntitlementService(EntitlementService service) {
    _entitlementService = service;
  }

  /// Set the achievement service for initializing achievements on sign-up.
  void setAchievementService(AchievementService service) {
    _achievementService = service;
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

    // Initialize default achievements for the new user
    try {
      await _achievementService?.initForNewUser(user.uid);
    } catch (e) {
      // Non-fatal: onUserCreate Cloud Function will retry as a safety net
      debugPrint('AUTH: Failed to init achievements client-side: $e');
    }

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

  /// Sign in with Google and create profile if first time.
  Future<void> signInWithGoogle() async {
    final credential = await _authRepo.signInWithGoogle();
    final uid = credential.user!.uid;

    // Link with RevenueCat
    await _entitlementService?.loginUser(uid);

    // Create profile if first time
    final hasExistingProfile = await hasProfile(uid);
    if (!hasExistingProfile) {
      final user = credential.user!;
      final displayName = user.displayName ?? 'User';
      final parts = displayName.trim().split(' ');
      final initials = parts.length >= 2
          ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
          : displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

      final now = DateTime.now();
      final profile = UserProfile(
        uid: uid,
        name: displayName,
        initials: initials,
        email: user.email ?? '',
        createdAt: now,
        updatedAt: now,
      );
      await _firestore.collection('users').doc(uid).set(profile.toJson());

      // Initialize default achievements for the new user
      try {
        await _achievementService?.initForNewUser(uid);
      } catch (e) {
        debugPrint('AUTH: Failed to init achievements for Google user: $e');
      }
    }
  }

  /// Check if the user's Firestore profile exists.
  /// Returns true if the profile doc exists, false otherwise.
  Future<bool> hasProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  /// Sign out.
  Future<void> signOut() async {
    await _entitlementService?.logoutUser();
    await _authRepo.signOut();
  }

  /// Delete account and Firestore data.
  /// The user doc is deleted here; subcollections are cascade-deleted
  /// by the onUserDelete Cloud Function when the auth user is removed.
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
