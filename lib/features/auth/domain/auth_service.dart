import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/analytics_service.dart';
import '../../../shared/models/user_profile.dart';
import '../../achievements/domain/achievement_service.dart';
import '../../subscription/domain/entitlement_service.dart';
import '../../user/data/user_repository.dart';
import '../data/auth_repository.dart';

class AuthService {
  final AuthRepository _authRepo;
  final FirebaseFirestore _firestore;
  final UserRepository _userRepository;
  EntitlementService? _entitlementService;
  AchievementService? _achievementService;
  AnalyticsService? _analyticsService;

  AuthService(this._authRepo, this._firestore, this._userRepository);

  /// Set the entitlement service for RevenueCat integration.
  void setEntitlementService(EntitlementService service) {
    _entitlementService = service;
  }

  /// Set the achievement service for initializing achievements on sign-up.
  void setAchievementService(AchievementService service) {
    _achievementService = service;
  }

  /// Set the analytics service for logging auth events.
  void setAnalyticsService(AnalyticsService service) {
    _analyticsService = service;
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

    // Link with RevenueCat (non-fatal — don't block signup if it fails/hangs)
    try {
      await _entitlementService?.loginUser(user.uid).timeout(
        const Duration(seconds: 5),
        onTimeout: () => debugPrint('AUTH: RevenueCat login timed out'),
      );
    } catch (e) {
      debugPrint('AUTH: RevenueCat login failed: $e');
    }

    _analyticsService?.logSignUp('email').ignore();

    return user;
  }

  /// Sign in with email/password.
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _authRepo.signInWithEmail(email, password);
    final user = credential.user!;

    // Link with RevenueCat (non-fatal)
    try {
      await _entitlementService?.loginUser(user.uid).timeout(
        const Duration(seconds: 5),
        onTimeout: () => debugPrint('AUTH: RevenueCat login timed out'),
      );
    } catch (e) {
      debugPrint('AUTH: RevenueCat login failed: $e');
    }

    _analyticsService?.logLogin('email').ignore();

    return user;
  }

  /// Sign in with Google and create profile if first time.
  Future<void> signInWithGoogle() async {
    final credential = await _authRepo.signInWithGoogle();
    final uid = credential.user!.uid;

    // Link with RevenueCat (non-fatal)
    try {
      await _entitlementService?.loginUser(uid).timeout(
        const Duration(seconds: 5),
        onTimeout: () => debugPrint('AUTH: RevenueCat login timed out'),
      );
    } catch (e) {
      debugPrint('AUTH: RevenueCat login failed: $e');
    }

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

      _analyticsService?.logSignUp('google').ignore();
    } else {
      _analyticsService?.logLogin('google').ignore();
    }
  }

  /// Sign in with Apple and create profile if first time.
  Future<void> signInWithApple() async {
    final credential = await _authRepo.signInWithApple();
    final uid = credential.user!.uid;

    // Link with RevenueCat (non-fatal)
    try {
      await _entitlementService?.loginUser(uid).timeout(
        const Duration(seconds: 5),
        onTimeout: () => debugPrint('AUTH: RevenueCat login timed out'),
      );
    } catch (e) {
      debugPrint('AUTH: RevenueCat login failed: $e');
    }

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
        debugPrint('AUTH: Failed to init achievements for Apple user: $e');
      }

      _analyticsService?.logSignUp('apple').ignore();
    } else {
      _analyticsService?.logLogin('apple').ignore();
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
    try {
      await _entitlementService?.logoutUser();
    } catch (e) {
      debugPrint('AUTH: RevenueCat logout failed: $e');
    }
    await _authRepo.signOut();
  }

  /// Delete account and all associated data.
  Future<void> deleteAccount() async {
    final uid = _authRepo.currentUser?.uid;
    if (uid == null) throw Exception('No user signed in');

    // 1. Delete all Firestore data (user doc + subcollections)
    await _userRepository.deleteAllUserData(uid);

    // 2. Delete coach document and subcollections if user is a coach
    try {
      final coachDoc = await FirebaseFirestore.instance.collection('coaches').doc(uid).get();
      if (coachDoc.exists) {
        final clients = await FirebaseFirestore.instance.collection('coaches').doc(uid).collection('clients').get();
        for (final c in clients.docs) { await c.reference.delete(); }
        await coachDoc.reference.delete();
      }
    } catch (_) {}

    // 3. Delete RevenueCat customer record.
    // purchases_flutter v8.x does not expose deleteCustomerInfo(); logoutUser()
    // anonymises the session which is the closest available equivalent.
    try { await _entitlementService?.logoutUser(); } catch (_) {}

    // 4. Delete Firebase Auth account
    await _authRepo.deleteAccount();
  }

  /// Send password reset email.
  Future<void> sendPasswordReset(String email) async {
    await _authRepo.sendPasswordReset(email);
  }
}
