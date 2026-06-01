import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/core/analytics_service.dart';
import 'package:gymratz/features/achievements/data/achievement_repository.dart';
import 'package:gymratz/features/achievements/domain/achievement_service.dart';

import 'package:gymratz/features/progression/data/progression_repository.dart';
import 'package:gymratz/features/progression/domain/models/progression_history.dart';
import 'package:gymratz/features/progression/domain/progression_suggestion.dart';
import 'package:gymratz/features/progress/data/pr_repository.dart';
import 'package:gymratz/features/workout/data/workout_repository.dart';
import 'package:gymratz/features/workout/domain/workout_service.dart';
import 'package:gymratz/shared/models/enums.dart';
import 'package:gymratz/shared/models/workout.dart';
import 'package:gymratz/shared/models/workout_exercise.dart';
import 'package:gymratz/shared/models/workout_set.dart';

// AnalyticsService() with no args: Firebase errors are wrapped in async
// Futures and discarded by .ignore() callers — safe for unit tests.

/// Repo subclass whose completeWorkout always throws.
class _ThrowingWorkoutRepository extends WorkoutRepository {
  _ThrowingWorkoutRepository(super.firestore);

  @override
  Future<void> completeWorkout(String uid, Workout workout) async {
    throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
  }

  @override
  Future<List<Workout>> getWorkoutsForMonth(String uid, int year, int month) async => [];
}

/// Repo subclass whose saveProgressionData always throws.
class _ThrowingProgressionRepository extends ProgressionRepository {
  _ThrowingProgressionRepository(super.firestore);

  @override
  Future<void> saveProgressionData({
    required String uid,
    required String exerciseName,
    required ProgressionHistory history,
    required ProgressionSuggestion suggestion,
  }) async {
    throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
  }
}

Workout _workout({String id = 'w1'}) => Workout(
      id: id,
      programId: 'prog1',
      date: DateTime(2026, 1, 1, 10),
      status: WorkoutStatus.inProgress,
      exercises: [
        WorkoutExercise(
          name: 'Squat',
          equipment: 'Barbell',
          equipmentType: EquipmentType.barbell,
          repRange: '5-8',
          targetRir: 2,
          sets: [
            const WorkoutSet(weight: 100, reps: 5, rir: 2, completed: true),
          ],
        ),
      ],
    );

void main() {
  group('WorkoutService.completeWorkout — network failure', () {
    test('exception from completeWorkout propagates to caller', () async {
      final fakeFs = FakeFirebaseFirestore();
      final service = WorkoutService(
        _ThrowingWorkoutRepository(fakeFs),
        PrRepository(fakeFs),
        ProgressionRepository(fakeFs),
        AchievementService(AchievementRepository(fakeFs)),
        AnalyticsService(), // Firebase errors discarded via async+.ignore()
      );

      await expectLater(
        service.completeWorkout('uid', _workout(), 'kg'),
        throwsA(isA<FirebaseException>()),
      );
    });

    test('progression-repo write failure does NOT prevent workout save', () async {
      final fakeFs = FakeFirebaseFirestore();
      final workoutRepo = WorkoutRepository(fakeFs);

      // Create the workout first so completeWorkout can find it
      await workoutRepo.createWorkout('uid', _workout());

      final service = WorkoutService(
        workoutRepo,
        PrRepository(fakeFs),
        _ThrowingProgressionRepository(fakeFs),
        AchievementService(AchievementRepository(fakeFs)),
        AnalyticsService(),
      );

      // Should complete without throwing even if progression write fails
      final summary = await service.completeWorkout('uid', _workout(), 'kg');
      expect(summary.totalSets, greaterThanOrEqualTo(0));

      // Workout should be saved as completed
      final saved = await fakeFs
          .collection('users')
          .doc('uid')
          .collection('workouts')
          .doc('w1')
          .get();
      expect(saved.exists, true);
      expect(saved.data()?['status'], 'completed');
    });
  });
}
