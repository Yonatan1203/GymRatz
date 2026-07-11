// GYM-201: workoutByIdProvider — the fallback-fetch path WorkoutDetailScreen
// uses when it wasn't handed a Workout via route extra (cold start/deep link).

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gymratz/app/providers/auth_providers.dart';
import 'package:gymratz/app/providers/data_providers.dart';
import 'package:gymratz/app/providers/repository_providers.dart';
import 'package:gymratz/features/workout/data/workout_repository.dart';
import 'package:gymratz/shared/models/enums.dart';
import 'package:gymratz/shared/models/workout.dart';

const _uid = 'uid';

void main() {
  group('workoutByIdProvider', () {
    test('resolves to the workout for a known id', () async {
      final repo = WorkoutRepository(FakeFirebaseFirestore());
      await repo.createWorkout(
        _uid,
        Workout(id: 'w1', date: DateTime(2026, 1, 1), status: WorkoutStatus.completed),
      );

      final container = ProviderContainer(overrides: [
        workoutRepositoryProvider.overrideWithValue(repo),
        currentUidProvider.overrideWithValue(_uid),
      ]);
      addTearDown(container.dispose);

      final result = await container.read(workoutByIdProvider('w1').future);

      expect(result, isNotNull);
      expect(result!.id, 'w1');
    });

    test('resolves to null for an unknown id', () async {
      final repo = WorkoutRepository(FakeFirebaseFirestore());

      final container = ProviderContainer(overrides: [
        workoutRepositoryProvider.overrideWithValue(repo),
        currentUidProvider.overrideWithValue(_uid),
      ]);
      addTearDown(container.dispose);

      final result = await container.read(workoutByIdProvider('missing').future);

      expect(result, isNull);
    });
  });
}
