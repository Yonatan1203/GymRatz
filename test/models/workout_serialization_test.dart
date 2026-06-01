import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/shared/models/achievement.dart';
import 'package:gymratz/shared/models/enums.dart';
import 'package:gymratz/shared/models/workout.dart';
import 'package:gymratz/shared/models/workout_exercise.dart';
import 'package:gymratz/shared/models/workout_set.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────
  // Workout
  // ──────────────────────────────────────────────────────────────────
  group('Workout.fromJson', () {
    test('null completedAt does not throw', () {
      final json = {
        'id': 'w1',
        'date': '2026-01-01T10:00:00.000Z',
        'status': 'completed',
        'completedAt': null,
      };
      expect(() => Workout.fromJson(json), returnsNormally);
      expect(Workout.fromJson(json).completedAt, isNull);
    });

    test('unknown status falls back to scheduled', () {
      final json = {
        'id': 'w1',
        'date': '2026-01-01T10:00:00.000Z',
        'status': 'UNKNOWN_VALUE',
      };
      expect(Workout.fromJson(json).status, WorkoutStatus.scheduled);
    });
  });

  group('Workout round-trip', () {
    test('nested WorkoutExercise + WorkoutSet survives toJson/fromJson', () {
      final original = Workout(
        id: 'w1',
        programId: 'p1',
        date: DateTime(2026, 1, 15, 9),
        status: WorkoutStatus.completed,
        totalVolume: 1500.5,
        duration: 3600,
        completedAt: DateTime(2026, 1, 15, 10),
        exercises: [
          WorkoutExercise(
            name: 'Squat',
            equipment: 'Barbell',
            equipmentType: EquipmentType.barbell,
            sets: [
              const WorkoutSet(weight: 100, reps: 5, rir: 2, completed: true),
              const WorkoutSet(weight: 100, reps: 5, rir: 2, completed: true),
            ],
          ),
        ],
      );

      final restored = Workout.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.programId, original.programId);
      expect(restored.status, original.status);
      expect(restored.totalVolume, original.totalVolume);
      expect(restored.exercises.length, 1);
      expect(restored.exercises.first.name, 'Squat');
      expect(restored.exercises.first.sets.length, 2);
      expect(restored.exercises.first.sets.first.weight, 100.0);
      expect(restored.completedAt?.toUtc(), original.completedAt?.toUtc());
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // WorkoutSet
  // ──────────────────────────────────────────────────────────────────
  group('WorkoutSet.copyWith', () {
    const original = WorkoutSet(weight: 80, reps: 8, rir: 2, completed: true);

    test('unspecified fields are preserved', () {
      final copy = original.copyWith(reps: 10);
      expect(copy.weight, 80.0);
      expect(copy.reps, 10);
      expect(copy.rir, 2);
      expect(copy.completed, true);
    });

    test('specified fields are updated', () {
      final copy = original.copyWith(weight: 90, completed: false);
      expect(copy.weight, 90.0);
      expect(copy.completed, false);
      expect(copy.reps, 8); // unchanged
    });
  });

  group('WorkoutSet fromJson/toJson', () {
    test('round-trip preserves all fields', () {
      const s = WorkoutSet(
        weight: 75.5,
        reps: 8,
        rir: 2,
        completed: true,
        isWarmup: false,
      );
      final restored = WorkoutSet.fromJson(s.toJson());
      expect(restored.weight, s.weight);
      expect(restored.reps, s.reps);
      expect(restored.rir, s.rir);
      expect(restored.completed, s.completed);
      expect(restored.isWarmup, s.isWarmup);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // Achievement
  // ──────────────────────────────────────────────────────────────────
  group('Achievement.fromJson', () {
    test('missing optional fields use correct defaults', () {
      final a = Achievement.fromJson({
        'id': 'first_workout',
        'title': 'First Workout',
        'description': 'desc',
        'iconName': 'trophy',
        'progress': 0,
        'total': 1,
        'rarity': 'Common',
      });
      expect(a.unlocked, false);
      expect(a.points, 0);
      expect(a.unlockedDate, isNull);
    });

    test('unlocked=true and points round-trip correctly', () {
      const original = Achievement(
        id: 'century_club',
        title: 'Century Club',
        description: 'desc',
        iconName: 'star',
        progress: 100,
        total: 100,
        rarity: 'Epic',
        points: 150,
        unlocked: true,
      );
      final restored = Achievement.fromJson(original.toJson());
      expect(restored.unlocked, true);
      expect(restored.points, 150);
    });
  });
}
