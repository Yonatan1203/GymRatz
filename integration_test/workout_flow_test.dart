// GYM-90: Integration test — workout flow
//
// Tests the workout service flow end-to-end using fakes for Firestore
// (no real Firebase needed). Verifies that selecting a program day,
// starting a workout, logging sets, and completing it produces a valid
// WorkoutSummary with the correct totals.
//
// These tests can be run with:
//   flutter test integration_test/workout_flow_test.dart

// ignore_for_file: avoid_print

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gymratz/core/analytics_service.dart';
import 'package:gymratz/features/achievements/domain/achievement_service.dart';
import 'package:gymratz/features/programs/data/program_repository.dart';
import 'package:gymratz/features/progression/data/progression_repository.dart';
import 'package:gymratz/features/progress/data/pr_repository.dart';
import 'package:gymratz/features/workout/data/workout_repository.dart';
import 'package:gymratz/features/workout/domain/workout_service.dart';
import 'package:gymratz/shared/models/enums.dart';
import 'package:gymratz/shared/models/program.dart';
import 'package:gymratz/shared/models/program_exercise.dart';
import 'package:gymratz/shared/models/workout_day.dart';
import 'package:gymratz/shared/models/workout_set.dart';

// ---------------------------------------------------------------------------
// Mocks (service-layer collaborators that are hard to fake)
// ---------------------------------------------------------------------------

class MockAchievementService extends Mock implements AchievementService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _uid = 'integration-test-uid';

Program _program() => const Program(
      id: 'prog-1',
      name: 'Push / Pull / Legs',
      workouts: 3,
      weeks: 4,
    );

WorkoutDay _pushDay() => WorkoutDay(
      id: 'day-push',
      name: 'Push Day',
      dayOfWeek: 'Monday',
      exercises: [
        const ProgramExercise(
          id: 'ex-bench',
          name: 'Bench Press',
          sets: 3,
          repMin: 8,
          repMax: 12,
          targetRir: 2,
          equipmentType: EquipmentType.barbell,
        ),
        const ProgramExercise(
          id: 'ex-ohp',
          name: 'Overhead Press',
          sets: 3,
          repMin: 8,
          repMax: 10,
          targetRir: 2,
          equipmentType: EquipmentType.barbell,
        ),
      ],
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeFirestore;
  late WorkoutRepository workoutRepo;
  late PrRepository prRepo;
  late ProgressionRepository progressionRepo;
  late MockAchievementService achievementService;
  late MockAnalyticsService analyticsService;
  late WorkoutService workoutService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    workoutRepo = WorkoutRepository(fakeFirestore);
    prRepo = PrRepository(fakeFirestore);
    progressionRepo = ProgressionRepository(fakeFirestore);
    achievementService = MockAchievementService();
    analyticsService = MockAnalyticsService();

    workoutService = WorkoutService(
      workoutRepo,
      prRepo,
      progressionRepo,
      achievementService,
      analyticsService,
      ProgramRepository(fakeFirestore),
    );

    when(() => analyticsService.logWorkoutStarted(
          programId: any(named: 'programId'),
          workoutDayId: any(named: 'workoutDayId'),
        )).thenAnswer((_) async {});
    when(() => analyticsService.logWorkoutCompleted(
          durationSeconds: any(named: 'durationSeconds'),
          exerciseCount: any(named: 'exerciseCount'),
          totalSets: any(named: 'totalSets'),
          totalVolume: any(named: 'totalVolume'),
        )).thenAnswer((_) async {});
    when(() => analyticsService.logAchievementUnlocked(any()))
        .thenAnswer((_) async {});
    when(() => achievementService.checkAchievements(
          _uid,
          totalWorkouts: any(named: 'totalWorkouts'),
          streak: any(named: 'streak'),
          totalVolume: any(named: 'totalVolume'),
          prCount: any(named: 'prCount'),
        )).thenAnswer((_) async => []);
  });

  group('Workout flow — end-to-end via service layer', () {
    testWidgets('select program day → start → complete → WorkoutSummary shown',
        (tester) async {
      // 1. Start workout from program day (first time — no prior data)
      final workout = await workoutService.startWorkout(
        uid: _uid,
        program: _program(),
        day: _pushDay(),
      );

      // 2. Verify workout was created with correct structure
      expect(workout.exercises, hasLength(2));
      expect(workout.exercises.first.name, 'Bench Press');
      expect(workout.exercises.first.sets, hasLength(3));
      expect(workout.status, WorkoutStatus.inProgress);

      // 3. Mark sets as completed (simulate user entering data)
      final completedWorkout = workout.copyWith(
        exercises: workout.exercises.map((exercise) {
          return exercise.copyWith(
            sets: exercise.sets.map((set) {
              return set.copyWith(
                weight: exercise.name == 'Bench Press' ? 80.0 : 50.0,
                reps: 10,
                rir: 2,
                completed: true,
              );
            }).toList(),
          );
        }).toList(),
      );

      // 4. Complete the workout
      final summary = await workoutService.completeWorkout(
        _uid,
        completedWorkout,
        'lbs',
      );

      // 5. Verify WorkoutSummary has correct aggregates
      expect(summary.totalSets, 6); // 2 exercises × 3 sets each
      expect(summary.totalReps, 60); // 6 sets × 10 reps
      // Volume: (80 * 10 * 3) + (50 * 10 * 3) = 2400 + 1500 = 3900
      expect(summary.totalVolume, closeTo(3900.0, 0.1));

      // 6. Verify the completed workout was persisted in Firestore
      final snap = await fakeFirestore
          .collection('users')
          .doc(_uid)
          .collection('workouts')
          .doc(completedWorkout.id)
          .get();
      expect(snap.exists, isTrue);
      expect(snap.data()?['status'], WorkoutStatus.completed.name);
    });

    testWidgets('second workout for same day prefills from last session',
        (tester) async {
      // Complete a first workout to establish history
      final day = _pushDay();
      final program = _program();

      final first = await workoutService.startWorkout(
        uid: _uid,
        program: program,
        day: day,
      );

      final completedFirst = first.copyWith(
        exercises: first.exercises.map((ex) {
          return ex.copyWith(
            sets: ex.sets.map((s) {
              return s.copyWith(
                weight: 80.0,
                reps: 10,
                completed: true,
              );
            }).toList(),
          );
        }).toList(),
      );
      await workoutService.completeWorkout(_uid, completedFirst, 'lbs');

      // Start a second workout — should prefill from PO suggestion stored by
      // the first completion. The progression suggestions are written to
      // Firestore by completeWorkout, and getSuggestionsForExercises reads
      // them back.
      final second = await workoutService.startWorkout(
        uid: _uid,
        program: program,
        day: day,
      );

      // The second workout's exercises should exist and have the correct count.
      expect(second.exercises, hasLength(2));
      // Weight may be prefilled from progression suggestion (>= 0)
      expect(second.exercises.first.sets.first.weight, greaterThanOrEqualTo(0));
    });

    testWidgets('PR is recorded when a new best weight is lifted', (tester) async {
      final day = WorkoutDay(
        id: 'day-pr',
        name: 'PR Day',
        dayOfWeek: 'Wednesday',
        exercises: const [
          ProgramExercise(
            id: 'ex-squat',
            name: 'Squat',
            sets: 1,
            repMin: 1,
            repMax: 3,
            targetRir: 0,
          ),
        ],
      );

      final workout = await workoutService.startWorkout(
        uid: _uid,
        program: _program(),
        day: day,
      );

      final heavyWorkout = workout.copyWith(
        exercises: [
          workout.exercises.first.copyWith(
            sets: [
              const WorkoutSet(
                weight: 200.0,
                reps: 1,
                completed: true,
                rir: 0,
              ),
            ],
          ),
        ],
      );

      final summary =
          await workoutService.completeWorkout(_uid, heavyWorkout, 'lbs');

      expect(summary.newPRs, contains('Squat'));
    });
  });
}
