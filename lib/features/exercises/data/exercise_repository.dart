import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/exercise.dart';

class ExerciseRepository {
  final FirebaseFirestore _firestore;

  ExerciseRepository(this._firestore);

  Future<List<Exercise>> loadBundledExercises() async {
    final jsonStr = await rootBundle.loadString('assets/data/exercises.json');
    final List<dynamic> jsonList = json.decode(jsonStr);
    return jsonList
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Stream<List<Exercise>> watchUserExercises(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('exercises')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                Exercise.fromJson(doc.data()).copyWith(isDefault: false))
            .toList());
  }

  Future<void> createExercise(String uid, Exercise exercise) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('exercises')
        .doc(exercise.id)
        .set(exercise.copyWith(isDefault: false).toJson());
  }

  Future<void> deleteExercise(String uid, String exerciseId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('exercises')
        .doc(exerciseId)
        .delete();
  }
}
