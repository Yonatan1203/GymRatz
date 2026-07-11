// GYM-201: WorkoutRepository.getWorkoutById unit tests

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gymratz/features/workout/data/workout_repository.dart';
import 'package:gymratz/shared/models/enums.dart';
import 'package:gymratz/shared/models/workout.dart';

const _uid = 'uid';

Workout _workout({String id = 'w1'}) => Workout(
      id: id,
      date: DateTime(2026, 1, 1),
      status: WorkoutStatus.completed,
    );

void main() {
  group('WorkoutRepository.getWorkoutById', () {
    test('returns the workout when it exists', () async {
      final repo = WorkoutRepository(FakeFirebaseFirestore());
      await repo.createWorkout(_uid, _workout(id: 'w1'));

      final result = await repo.getWorkoutById(_uid, 'w1');

      expect(result, isNotNull);
      expect(result!.id, 'w1');
    });

    test('returns null when the workout does not exist', () async {
      final repo = WorkoutRepository(FakeFirebaseFirestore());

      final result = await repo.getWorkoutById(_uid, 'missing');

      expect(result, isNull);
    });
  });
}
