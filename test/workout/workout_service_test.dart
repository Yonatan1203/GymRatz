// GYM-89: WorkoutService unit tests
// ignore_for_file: avoid_print

import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gymratz/core/analytics_service.dart';
import 'package:gymratz/features/achievements/domain/achievement_service.dart';
import 'package:gymratz/features/progression/data/progression_repository.dart';
import 'package:gymratz/features/progression/domain/progression_suggestion.dart';
import 'package:gymratz/features/progression/domain/models/progression_history.dart';
import 'package:gymratz/features/progress/data/pr_repository.dart';
import 'package:gymratz/features/workout/data/workout_repository.dart';
import 'package:gymratz/features/workout/domain/workout_service.dart';
import 'package:gymratz/shared/models/enums.dart';
import 'package:gymratz/shared/models/program.dart';
import 'package:gymratz/shared/models/program_exercise.dart';
import 'package:gymratz/shared/models/workout.dart';
import 'package:gymratz/shared/models/workout_day.dart';
import 'package:gymratz/shared/models/workout_exercise.dart';
import 'package:gymratz/shared/models/workout_set.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

class MockPrRepository extends Mock implements PrRepository {}

class MockProgressionRepository extends Mock
    implements ProgressionRepository {}

class MockAchievementService extends Mock implements AchievementService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _uid = 'test-uid';

/// A minimal program exercise for tests.
ProgramExercise _pe({
  String name = 'Bench Press',
  int sets = 3,
  int repMin = 8,
  int repMax = 12,
  int targetRir = 2,
  EquipmentType equipmentType = EquipmentType.barbell,
}) =>
    ProgramExercise(
      id: 'ex-1',
      name: name,
      sets: sets,
      repMin: repMin,
      repMax: repMax,
      targetRir: targetRir,
      equipmentType: equipmentType,
    );

WorkoutDay _day({List<ProgramExercise>? exercises}) => WorkoutDay(
      id: 'day-1',
      name: 'Day A',
      dayOfWeek: 'Monday',
      exercises: exercises ?? [_pe()],
    );

Program _program({
  WeightAutofillMode mode = WeightAutofillMode.systemSuggested,
}) =>
    Program(
      id: 'program-1',
      name: 'Test Program',
      workouts: 3,
      weeks: 4,
      weightAutofillMode: mode,
    );

ProgressionSuggestion _suggestion({
  double weight = 80.0,
  int reps = 10,
  int sets = 3,
}) =>
    ProgressionSuggestion(
      exerciseName: 'Bench Press',
      suggestedWeight: weight,
      suggestedReps: reps,
      suggestedSets: sets,
      reasoning: 'test',
    );

WorkoutExercise _lastExercise({double weight = 70.0, int reps = 8}) =>
    WorkoutExercise(
      name: 'Bench Press',
      equipment: 'Barbell',
      repRange: '8-12',
      targetRir: 2,
      sets: [
        WorkoutSet(weight: weight, reps: reps, completed: true),
      ],
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockWorkoutRepository workoutRepo;
  late MockPrRepository prRepo;
  late MockProgressionRepository progressionRepo;
  late MockAchievementService achievementService;
  late MockAnalyticsService analyticsService;
  late WorkoutService sut;

  setUpAll(() {
    registerFallbackValue(Workout(id: 'fb', programId: '', workoutDayId: '', date: DateTime(2026), status: WorkoutStatus.completed, exercises: []));
    registerFallbackValue(const ProgressionHistory());
    registerFallbackValue(const ProgressionSuggestion(suggestedWeight: 0, suggestedReps: 0, suggestedSets: 0, reasoning: ''));
  });

  setUp(() {
    workoutRepo = MockWorkoutRepository();
    prRepo = MockPrRepository();
    progressionRepo = MockProgressionRepository();
    achievementService = MockAchievementService();
    analyticsService = MockAnalyticsService();

    sut = WorkoutService(
      workoutRepo,
      prRepo,
      progressionRepo,
      achievementService,
      analyticsService,
    );

    // Default analytics stubs (non-fatal fire-and-forget)
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
  });

  // -------------------------------------------------------------------------
  // startWorkout
  // -------------------------------------------------------------------------

  group('startWorkout', () {
    test('prefills from PO suggestion when available', () async {
      final suggestion = _suggestion(weight: 80.0, reps: 10, sets: 3);
      when(() => progressionRepo.getSuggestionsForExercises(_uid, any()))
          .thenAnswer((_) async => {'bench_press': suggestion});
      when(() => workoutRepo.getRecentWorkoutsForDay(_uid, any(), any()))
          .thenAnswer((_) async => []);

      final workout = await sut.startWorkout(
        uid: _uid,
        program: _program(),
        day: _day(),
      );

      expect(workout.exercises, hasLength(1));
      final sets = workout.exercises.first.sets;
      expect(sets.first.weight, 80.0);
      expect(sets.first.reps, 10);
    });

    test('falls back to last session when no PO suggestion', () async {
      when(() => progressionRepo.getSuggestionsForExercises(_uid, any()))
          .thenAnswer((_) async => {});
      final last = _lastExercise(weight: 70.0, reps: 8);
      final lastWorkout = Workout(
        id: 'w1',
        date: DateTime.now(),
        status: WorkoutStatus.completed,
        exercises: [last],
      );
      when(() => workoutRepo.getRecentWorkoutsForDay(_uid, any(), any()))
          .thenAnswer((_) async => [lastWorkout]);

      final workout = await sut.startWorkout(
        uid: _uid,
        program: _program(),
        day: _day(),
      );

      final sets = workout.exercises.first.sets;
      expect(sets.first.weight, 70.0);
    });

    test('uses weight=0 and reps from template when neither exists', () async {
      when(() => progressionRepo.getSuggestionsForExercises(_uid, any()))
          .thenAnswer((_) async => {});
      when(() => workoutRepo.getRecentWorkoutsForDay(_uid, any(), any()))
          .thenAnswer((_) async => []);

      final workout = await sut.startWorkout(
        uid: _uid,
        program: _program(),
        day: _day(exercises: [_pe(repMax: 12)]),
      );

      final sets = workout.exercises.first.sets;
      expect(sets.first.weight, 0.0);
      expect(sets.first.reps, 12);
    });

    test('manual mode discards PO suggestion and uses weight=0', () async {
      final suggestion = _suggestion(weight: 100.0, reps: 5, sets: 5);
      when(() => progressionRepo.getSuggestionsForExercises(_uid, any()))
          .thenAnswer((_) async => {'bench_press': suggestion});
      when(() => workoutRepo.getRecentWorkoutsForDay(_uid, any(), any()))
          .thenAnswer((_) async => []);

      final workout = await sut.startWorkout(
        uid: _uid,
        program: _program(mode: WeightAutofillMode.manual),
        day: _day(),
      );

      final sets = workout.exercises.first.sets;
      expect(sets.first.weight, 0.0);
    });
  });

  // -------------------------------------------------------------------------
  // completeWorkout
  // -------------------------------------------------------------------------

  group('completeWorkout', () {
    test('does not crash when exercise has zero completed sets', () async {
      // Exercise with sets that are all incomplete (not completed)
      final exercise = WorkoutExercise(
        name: 'Squat',
        equipment: 'Barbell',
        repRange: '5-5',
        targetRir: 1,
        sets: [
          const WorkoutSet(weight: 100.0, reps: 5, completed: false),
        ],
      );

      final workout = Workout(
        id: 'w-zero',
        date: DateTime.now(),
        status: WorkoutStatus.inProgress,
        exercises: [exercise],
      );

      when(() => workoutRepo.completeWorkout(_uid, any()))
          .thenAnswer((_) async {});
      when(() => workoutRepo.getWorkoutsForMonth(_uid, any(), any()))
          .thenAnswer((_) async => []);
      when(() => achievementService.checkAchievements(
            _uid,
            totalWorkouts: any(named: 'totalWorkouts'),
            streak: any(named: 'streak'),
            totalVolume: any(named: 'totalVolume'),
            prCount: any(named: 'prCount'),
          )).thenAnswer((_) async => []);

      final summary = await sut.completeWorkout(_uid, workout, 'lbs');

      expect(summary.totalSets, 0);
      expect(summary.totalVolume, 0.0);
    });

    test('Firestore write failure is non-fatal and still returns summary',
        () async {
      final exercise = WorkoutExercise(
        name: 'Bench Press',
        equipment: 'Barbell',
        repRange: '8-12',
        targetRir: 2,
        sets: [
          const WorkoutSet(
              weight: 80.0, reps: 10, completed: true, rir: 2),
        ],
      );

      final workout = Workout(
        id: 'w-fail',
        date: DateTime.now(),
        status: WorkoutStatus.inProgress,
        exercises: [exercise],
      );

      // PR check succeeds
      when(() => prRepo.checkAndUpdatePR(
            _uid,
            exerciseId: any(named: 'exerciseId'),
            exerciseName: any(named: 'exerciseName'),
            weight: any(named: 'weight'),
            reps: any(named: 'reps'),
            unit: any(named: 'unit'),
          )).thenAnswer((_) async => false);

      // Progression history load succeeds
      when(() => progressionRepo.getHistory(_uid, any()))
          .thenAnswer((_) async => const ProgressionHistory());

      // Progression save FAILS — should be non-fatal
      when(() => progressionRepo.saveProgressionData(
            uid: any(named: 'uid'),
            exerciseName: any(named: 'exerciseName'),
            history: any(named: 'history'),
            suggestion: any(named: 'suggestion'),
          )).thenThrow(Exception('Firestore write failed'));

      // completeWorkout itself succeeds
      when(() => workoutRepo.completeWorkout(_uid, any()))
          .thenAnswer((_) async {});
      when(() => workoutRepo.getWorkoutsForMonth(_uid, any(), any()))
          .thenAnswer((_) async => []);
      when(() => achievementService.checkAchievements(
            _uid,
            totalWorkouts: any(named: 'totalWorkouts'),
            streak: any(named: 'streak'),
            totalVolume: any(named: 'totalVolume'),
            prCount: any(named: 'prCount'),
          )).thenAnswer((_) async => []);

      // Should not throw even though progression save threw
      final summary = await sut.completeWorkout(_uid, workout, 'lbs');

      expect(summary.totalSets, 1);
      expect(summary.totalVolume, 800.0); // 80 * 10
    });
  });
}
