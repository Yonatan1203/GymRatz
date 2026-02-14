/// Base exception for the GymRatz app.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException($code): $message';
}

/// Exception thrown by auth operations.
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'AuthException($code): $message';
}

/// Exception thrown by Firestore operations.
class FirestoreException extends AppException {
  const FirestoreException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'FirestoreException($code): $message';
}
