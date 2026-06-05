import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/body_measurement.dart';

/// Firestore repository for body measurements (GYM-114).
/// Collection path: users/{uid}/bodyMeasurements
class BodyMeasurementRepository {
  final FirebaseFirestore _firestore;

  BodyMeasurementRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('bodyMeasurements');

  Future<void> addMeasurement(String uid, BodyMeasurement measurement) async {
    await _col(uid).doc(measurement.id).set(measurement.toJson());
  }

  Future<void> deleteMeasurement(String uid, String id) async {
    await _col(uid).doc(id).delete();
  }

  Stream<List<BodyMeasurement>> watchMeasurements(String uid, {int limit = 60}) {
    return _col(uid)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => BodyMeasurement.fromJson(d.data())).toList());
  }
}
