import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/auth_service.dart';
import '../../features/subscription/domain/entitlement_service.dart';
import '../../features/subscription/data/entitlement_repository.dart';

/// Returns null when Firebase hasn't been initialized (no google-services.json yet).
final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) {
  if (Firebase.apps.isEmpty) return null;
  return FirebaseAuth.instance;
});

/// Returns null when Firebase hasn't been initialized.
/// Only accessed by repositories when uid != null (i.e. Firebase IS available).
final firestoreProvider = Provider<FirebaseFirestore?>((ref) {
  if (Firebase.apps.isEmpty) return null;
  return FirebaseFirestore.instance;
});

final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  if (auth == null) return null;
  return AuthRepository(auth);
});

/// Only read by button handlers (login, signup, signout) — never eagerly evaluated.
/// Throws if Firebase isn't initialized, which is correct since those actions
/// require Firebase.
final authServiceProvider = Provider<AuthService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  if (auth == null || firestore == null) {
    throw StateError('Firebase not initialized — cannot create AuthService');
  }
  final service = AuthService(AuthRepository(auth), firestore);
  service.setEntitlementService(
    EntitlementService(EntitlementRepository()),
  );
  return service;
});

/// Emits null (not logged in) when Firebase isn't available.
final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  if (repo == null) return Stream.value(null);
  return repo.authStateChanges();
});

final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});
