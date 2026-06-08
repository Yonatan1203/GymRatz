import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/program.dart';

class ProgramRepository {
  final FirebaseFirestore _firestore;

  ProgramRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _programs(String uid) =>
      _firestore.collection('users').doc(uid).collection('programs');

  Future<void> createProgram(String uid, Program program) async {
    await _programs(uid).doc(program.id).set(program.toJson());
  }

  Stream<List<Program>> watchPrograms(String uid) {
    return _programs(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Program.fromJson({...d.data(), 'id': d.id})).toList());
  }

  Stream<Program?> watchActiveProgram(String uid) {
    return _programs(uid)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return Program.fromJson({...snap.docs.first.data(), 'id': snap.docs.first.id});
    });
  }

  Future<void> setActiveProgram(String uid, String programId) async {
    final batch = _firestore.batch();

    // Deactivate all programs
    final allProgs = await _programs(uid).get();
    for (final doc in allProgs.docs) {
      batch.update(doc.reference, {'isActive': false});
    }

    // Activate the selected one
    batch.update(_programs(uid).doc(programId), {
      'isActive': true,
      'activatedAt': DateTime.now().toIso8601String(),
    });
    await batch.commit();
  }

  Future<void> updateProgram(
      String uid, String programId, Map<String, dynamic> fields) async {
    await _programs(uid).doc(programId).update(fields);
  }

  Future<void> deleteProgram(String uid, String programId) async {
    await _programs(uid).doc(programId).delete();
  }

  Future<Program?> getProgram(String uid, String programId) async {
    final snap = await _programs(uid).doc(programId).get();
    if (!snap.exists || snap.data() == null) return null;
    return Program.fromJson(snap.data()!);
  }

  Stream<List<Program>> watchCommunityPrograms() {
    return _firestore
        .collection('community_programs')
        .orderBy('name')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Program.fromJson({...d.data(), 'id': d.id})).toList());
  }

  Future<Program?> getCommunityProgram(String programId) async {
    final snap = await _firestore
        .collection('community_programs')
        .doc(programId)
        .get();
    if (!snap.exists || snap.data() == null) return null;
    return Program.fromJson({...snap.data()!, 'id': snap.id});
  }
}
