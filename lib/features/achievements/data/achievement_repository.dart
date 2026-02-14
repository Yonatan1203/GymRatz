import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/achievement.dart';

class AchievementRepository {
  final FirebaseFirestore _firestore;

  AchievementRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _achievements(String uid) =>
      _firestore.collection('users').doc(uid).collection('achievements');

  Future<void> initializeAchievements(
      String uid, List<Achievement> defaults) async {
    final batch = _firestore.batch();
    for (final a in defaults) {
      batch.set(_achievements(uid).doc(a.id), a.toJson());
    }
    await batch.commit();
  }

  Stream<List<Achievement>> watchAchievements(String uid) {
    return _achievements(uid).snapshots().map((snap) =>
        snap.docs.map((d) => Achievement.fromJson(d.data())).toList());
  }

  Future<void> updateProgress(
      String uid, String achievementId, int progress) async {
    await _achievements(uid).doc(achievementId).update({
      'progress': progress,
    });
  }

  Future<void> unlock(String uid, String achievementId) async {
    await _achievements(uid).doc(achievementId).update({
      'unlocked': true,
      'unlockedDate': DateTime.now().toIso8601String(),
    });
  }
}
