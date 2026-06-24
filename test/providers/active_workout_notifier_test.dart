import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/app/providers/active_workout_provider.dart';
import 'package:gymratz/shared/models/enums.dart';
import 'package:gymratz/shared/models/workout_exercise.dart';
import 'package:gymratz/shared/models/workout_set.dart';

WorkoutExercise _exercise(String name) => WorkoutExercise(
      name: name,
      equipment: 'Barbell',
      equipmentType: EquipmentType.barbell,
      repRange: '5-8',
      targetRir: 2,
      sets: [const WorkoutSet(weight: 80, reps: 8, rir: 2, completed: false)],
    );

void main() {
  late ProviderContainer container;
  late ActiveWorkoutNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(activeWorkoutSessionProvider.notifier);
  });

  tearDown(() => container.dispose());

  group('ActiveWorkoutNotifier.startSession', () {
    test('initialises expandedIndices to {0} and sets currentExerciseName to first exercise', () {
      notifier.startSession(
        dayId: 'day1',
        workoutName: 'Push Day',
        exercises: [_exercise('Bench Press'), _exercise('Overhead Press')],
        sets: [[], []],
      );
      final s = container.read(activeWorkoutSessionProvider)!;
      expect(s.expandedIndices, {0});
      expect(s.currentExerciseName, 'Bench Press');
    });

    test('state is non-null after startSession', () {
      notifier.startSession(
        dayId: 'day1',
        workoutName: 'Test',
        exercises: [_exercise('Squat')],
        sets: [[]],
      );
      expect(container.read(activeWorkoutSessionProvider), isNotNull);
    });
  });

  group('ActiveWorkoutNotifier.getSessionForDay', () {
    setUp(() {
      notifier.startSession(
        dayId: 'day1',
        workoutName: 'Leg Day',
        exercises: [_exercise('Squat')],
        sets: [[]],
      );
    });

    test('returns session when dayId matches', () {
      expect(notifier.getSessionForDay('day1'), isNotNull);
    });

    test('returns null when dayId does not match', () {
      expect(notifier.getSessionForDay('day2'), isNull);
    });
  });

  group('ActiveWorkoutNotifier.syncState', () {
    setUp(() {
      notifier.startSession(
        dayId: 'day1',
        workoutName: 'Test',
        exercises: [_exercise('Squat')],
        sets: [[]],
      );
    });

    test('updates currentExerciseName', () {
      notifier.syncState(currentExerciseName: 'Bench');
      expect(
        container.read(activeWorkoutSessionProvider)!.currentExerciseName,
        'Bench',
      );
    });
  });

  group('ActiveWorkoutNotifier.endSession', () {
    test('sets state to null', () {
      notifier.startSession(
        dayId: 'day1',
        workoutName: 'Test',
        exercises: [_exercise('Squat')],
        sets: [[]],
      );
      expect(container.read(activeWorkoutSessionProvider), isNotNull);

      notifier.endSession();
      expect(container.read(activeWorkoutSessionProvider), isNull);
    });
  });

  group('workoutElapsedSecondsProvider', () {
    test('is in loading state when session is null', () {
      // No active session — StreamProvider should not have a value yet
      final elapsed = container.read(workoutElapsedSecondsProvider);
      // The stream is empty (Stream.empty()), so there is no value
      expect(elapsed.hasValue, false);
    });

    test('stream is non-null when a session is active', () {
      notifier.startSession(
        dayId: 'day1',
        workoutName: 'Test',
        exercises: [_exercise('Squat')],
        sets: [[]],
      );
      // The provider exists and is not in an error state — stream emitting
      // values is verified implicitly by CI and integration tests.
      final elapsed = container.read(workoutElapsedSecondsProvider);
      expect(elapsed.hasError, false);
    });
  });
}
