import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../core/exceptions.dart';

class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository(this._auth);

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('AUTH: FirebaseAuthException code=${e.code} message=${e.message}');
      throw AuthException(
        _mapAuthErrorMessage(e.code),
        code: e.code,
        originalError: e,
      );
    } on FirebaseException catch (e) {
      debugPrint('AUTH: FirebaseException code=${e.code} message=${e.message}');
      throw AuthException(
        _mapAuthErrorMessage(e.code),
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      debugPrint('AUTH: Unexpected exception type=${e.runtimeType} error=$e');
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        _mapAuthErrorMessage(e.code),
        code: e.code,
        originalError: e,
      );
    } on FirebaseException catch (e) {
      throw AuthException(
        _mapAuthErrorMessage(e.code),
        code: e.code,
        originalError: e,
      );
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        _mapAuthErrorMessage(e.code),
        code: e.code,
        originalError: e,
      );
    }
  }

  String _mapAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
