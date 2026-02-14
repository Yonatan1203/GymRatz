import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/personal_record.dart';

class PrRepository {
  final FirebaseFirestore _firestore;

  PrRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _prs(String uid) =>
      _firestore.collection('users').doc(uid).collection('prs');

  Future<void> setPR(String uid, PersonalRecord pr) async {
    await _prs(uid).doc(pr.exerciseId).set(pr.toJson());
  }

  Future<PersonalRecord?> getPR(String uid, String exerciseId) async {
    final snap = await _prs(uid).doc(exerciseId).get();
    if (!snap.exists || snap.data() == null) return null;
    return PersonalRecord.fromJson(snap.data()!);
  }

  Stream<List<PersonalRecord>> watchPRs(String uid) {
    return _prs(uid).snapshots().map((snap) =>
        snap.docs.map((d) => PersonalRecord.fromJson(d.data())).toList());
  }

  /// Check if the new weight beats the existing PR and update if so.
  /// Returns true if a new PR was set.
  Future<bool> checkAndUpdatePR(
    String uid, {
    required String exerciseId,
    required String exerciseName,
    required double weight,
    required int reps,
  }) async {
    final existing = await getPR(uid, exerciseId);
    if (existing == null || weight > existing.weight) {
      await setPR(
        uid,
        PersonalRecord(
          exerciseId: exerciseId,
          exerciseName: exerciseName,
          weight: weight,
          reps: reps,
          date: DateTime.now(),
        ),
      );
      return true;
    }
    return false;
  }
}
