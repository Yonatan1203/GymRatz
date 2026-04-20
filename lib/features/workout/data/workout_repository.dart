import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/workout.dart';
import '../../../shared/models/enums.dart';

class WorkoutRepository {
  final FirebaseFirestore _firestore;

  WorkoutRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _workouts(String uid) =>
      _firestore.collection('users').doc(uid).collection('workouts');

  Future<void> createWorkout(String uid, Workout workout) async {
    await _workouts(uid).doc(workout.id).set(workout.toJson());
  }

  Stream<List<Workout>> watchWorkouts(
      String uid, DateTime from, DateTime to) {
    return _workouts(uid)
        .where('date', isGreaterThanOrEqualTo: from.toIso8601String())
        .where('date', isLessThanOrEqualTo: to.toIso8601String())
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Workout.fromJson(d.data())).toList());
  }

  Stream<List<Workout>> watchRecentWorkouts(String uid, {int limit = 10}) {
    return _workouts(uid)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Workout.fromJson(d.data())).toList());
  }

  Future<void> completeWorkout(String uid, Workout workout) async {
    final updated = workout.copyWith(
      status: WorkoutStatus.completed,
      completedAt: DateTime.now(),
    );
    await _workouts(uid).doc(workout.id).set(updated.toJson());
  }

  Future<List<Workout>> getWorkoutsForMonth(
      String uid, int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);

    final snap = await _workouts(uid)
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThanOrEqualTo: end.toIso8601String())
        .orderBy('date')
        .get();

    return snap.docs.map((d) => Workout.fromJson(d.data())).toList();
  }

  /// Get most recent completed workouts for a specific program day.
  Future<List<Workout>> getRecentWorkoutsForDay(
      String uid, String programId, String workoutDayId,
      {int limit = 1}) async {
    final snap = await _workouts(uid)
        .where('programId', isEqualTo: programId)
        .where('workoutDayId', isEqualTo: workoutDayId)
        .where('status', isEqualTo: WorkoutStatus.completed.name)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();

    return snap.docs.map((d) => Workout.fromJson(d.data())).toList();
  }

  Future<List<Workout>> getRecentWorkoutsForExercise(
      String uid, String exerciseName,
      {int limit = 5}) async {
    final snap = await _workouts(uid)
        .where('status', isEqualTo: WorkoutStatus.completed.name)
        .orderBy('date', descending: true)
        .limit(20)
        .get();

    final workouts =
        snap.docs.map((d) => Workout.fromJson(d.data())).toList();

    return workouts
        .where(
            (w) => w.exercises.any((e) => e.name == exerciseName))
        .take(limit)
        .toList();
  }
}
