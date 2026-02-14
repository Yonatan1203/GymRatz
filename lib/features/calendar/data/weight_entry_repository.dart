import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/weight_entry.dart';

class WeightEntryRepository {
  final FirebaseFirestore _firestore;

  WeightEntryRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _entries(String uid) =>
      _firestore.collection('users').doc(uid).collection('weightEntries');

  Future<void> addWeightEntry(String uid, WeightEntry entry) async {
    await _entries(uid).doc(entry.id).set(entry.toJson());
  }

  Stream<List<WeightEntry>> watchWeightEntries(String uid, {int limit = 30}) {
    return _entries(uid)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => WeightEntry.fromJson(d.data())).toList());
  }
}
