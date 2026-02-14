import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/user_profile.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  Future<void> createUser(String uid, UserProfile profile) async {
    await _userDoc(uid).set(profile.toJson());
  }

  Future<UserProfile?> getUser(String uid) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return UserProfile.fromJson(snap.data()!);
  }

  Stream<UserProfile?> watchUser(String uid) {
    return _userDoc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserProfile.fromJson(snap.data()!);
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {
    fields['updatedAt'] = DateTime.now().toIso8601String();
    await _userDoc(uid).update(fields);
  }

  Future<void> deleteUser(String uid) async {
    await _userDoc(uid).delete();
  }

  Future<void> toggleFavoriteExercise(String uid, String exerciseId) async {
    final doc = await _userDoc(uid).get();
    final data = doc.data();
    if (data == null) return;

    final favorites =
        List<String>.from(data['favoriteExerciseIds'] as List? ?? []);
    if (favorites.contains(exerciseId)) {
      favorites.remove(exerciseId);
    } else {
      favorites.add(exerciseId);
    }

    await updateUser(uid, {'favoriteExerciseIds': favorites});
  }
}
