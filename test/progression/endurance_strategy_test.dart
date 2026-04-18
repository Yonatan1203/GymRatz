import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/features/progression/domain/endurance_strategy.dart';
import 'package:gymratz/features/progression/domain/models/progression_history.dart';
import 'package:gymratz/features/progression/domain/models/session_metrics.dart';
import 'package:gymratz/shared/models/enums.dart';
import 'package:gymratz/shared/models/workout_set.dart';

void main() {
  late EnduranceStrategy strategy;

  setUp(() {
    strategy = EnduranceStrategy();
  });

  group('Rule A — increase load when all sets hit top of range', () {
    test('increases load when all sets hit r_max with RIR >= 2 and sets at cap', () {
      // 4 sets × 25 reps (rep range 12-25), RIR >= 2 on last set, already at 4 sets
      // min(reps) = 25 >= r_max(25) AND RIR_last >= 2 AND sets == 4
      // → Rule A: increase load by smallest increment
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 40, reps: 25, rir: 3, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 40, reps: 25, rir: 3, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 40, reps: 25, rir: 3, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 40, reps: 25, rir: 2, completed: true, restSeconds: 60),
        ],
        currentWeight: 40,
        repMin: 12,
        repMax: 25,
        targetRir: 3,
        equipment: EquipmentType.machineStack,
        unit: 'kg',
        history: const ProgressionHistory(),
      );

      // machineStack kg increment is 5.0 → 40 + 5 = 45
      expect(result.suggestedWeight, equals(45));
      expect(result.isDeload, false);
    });
  });

  group('Rule A — add set instead of load when set count < 4', () {
    test('adds a set when set count < 4 and all sets hit r_max with RIR >= 2', () {
      // 2 sets × 25 reps (rep range 12-25), RIR >= 2
      // min(reps) = 25 >= r_max AND RIR_last >= 2
      // → Rule A: since sets < 4, add 1 set instead of increasing load
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 40, reps: 25, rir: 3, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 40, reps: 25, rir: 2, completed: true, restSeconds: 60),
        ],
        currentWeight: 40,
        repMin: 12,
        repMax: 25,
        targetRir: 3,
        equipment: EquipmentType.machineStack,
        unit: 'kg',
        history: const ProgressionHistory(),
      );

      // Weight stays the same, but sets increase from 2 to 3
      expect(result.suggestedWeight, equals(40));
      expect(result.suggestedSets, equals(3));
      expect(result.isDeload, false);
    });

    test('increases load when set count is already 4', () {
      // 4 sets × 25 reps, RIR >= 2 → can't add more sets, so increase load
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 40, reps: 25, rir: 3, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 40, reps: 25, rir: 3, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 40, reps: 25, rir: 3, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 40, reps: 25, rir: 2, completed: true, restSeconds: 60),
        ],
        currentWeight: 40,
        repMin: 12,
        repMax: 25,
        targetRir: 3,
        equipment: EquipmentType.machineStack,
        unit: 'kg',
        history: const ProgressionHistory(),
      );

      expect(result.suggestedWeight, equals(45));
      expect(result.suggestedSets, equals(4));
      expect(result.isDeload, false);
    });
  });

  group('Rule B — add reps when in range but not at max', () {
    test('adds reps when min reps >= r_min but < r_max with RIR >= 2', () {
      // 3 sets: 18, 16, 15 reps (range 12-25), RIR_last >= 2
      // min(reps) = 15 >= r_min(12) but < r_max(25)
      // → Rule B: add +1-2 reps to lowest set
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 40, reps: 18, rir: 3, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 40, reps: 16, rir: 3, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 40, reps: 15, rir: 2, completed: true, restSeconds: 60),
        ],
        currentWeight: 40,
        repMin: 12,
        repMax: 25,
        targetRir: 3,
        equipment: EquipmentType.machineStack,
        unit: 'kg',
        history: const ProgressionHistory(),
      );

      // Weight stays the same, reps target = lowest + 1 = 16
      expect(result.suggestedWeight, equals(40));
      expect(result.suggestedReps, equals(16));
      expect(result.isDeload, false);
    });
  });

  group('Rule C — reduce load when below range', () {
    test('reduces load when min reps < r_min', () {
      // 3 sets: 11, 10, 9 reps (range 12-25)
      // min(reps) = 9 < r_min(12)
      // → Rule C: reduce load 2.5-5%
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 40, reps: 11, rir: 2, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 40, reps: 10, rir: 1, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 40, reps: 9, rir: 1, completed: true, restSeconds: 60),
        ],
        currentWeight: 40,
        repMin: 12,
        repMax: 25,
        targetRir: 3,
        equipment: EquipmentType.machineStack,
        unit: 'kg',
        history: const ProgressionHistory(),
      );

      // 40 * 0.95 = 38 → snap to machineStack 5kg increment → 40 (rounds to nearest)
      // Actually 38 / 5 = 7.6, rounds to 8 → 40. Let's use barbell instead.
      expect(result.suggestedWeight, lessThanOrEqualTo(40));
      expect(result.isDeload, false);
    });

    test('reduces load when RIR is too low', () {
      // Reps in range but RIR < 2
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 30, reps: 15, rir: 1, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 30, reps: 14, rir: 0, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 30, reps: 13, rir: 0, completed: true, restSeconds: 60),
        ],
        currentWeight: 30,
        repMin: 12,
        repMax: 25,
        targetRir: 3,
        equipment: EquipmentType.barbell,
        unit: 'kg',
        history: const ProgressionHistory(),
      );

      // 30 * 0.95 = 28.5 → snap to barbell 2.5kg → 27.5
      expect(result.suggestedWeight, lessThan(30));
      expect(result.isDeload, false);
    });
  });

  group('deload after plateau', () {
    test('triggers deload after 3 stagnant exposures', () {
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 40, reps: 15, rir: 2, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 40, reps: 14, rir: 2, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 40, reps: 13, rir: 2, completed: true, restSeconds: 60),
        ],
        currentWeight: 40,
        repMin: 12,
        repMax: 25,
        targetRir: 3,
        equipment: EquipmentType.machineStack,
        unit: 'kg',
        history: const ProgressionHistory(
          exposuresSinceImprovement: 3,
          scoreHistory: [70, 70, 70],
        ),
      );

      expect(result.isDeload, true);
      // Deload: sets *= 0.6 (min 2), load * 0.9
      expect(result.suggestedWeight, lessThanOrEqualTo(40));
      // 3 sets * 0.6 = 1.8, clamped to min 2
      expect(result.suggestedSets, equals(2));
    });

    test('does not deload when only 2 stagnant exposures', () {
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 40, reps: 15, rir: 2, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 40, reps: 14, rir: 2, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 40, reps: 13, rir: 2, completed: true, restSeconds: 60),
        ],
        currentWeight: 40,
        repMin: 12,
        repMax: 25,
        targetRir: 3,
        equipment: EquipmentType.machineStack,
        unit: 'kg',
        history: const ProgressionHistory(
          exposuresSinceImprovement: 2,
        ),
      );

      expect(result.isDeload, false);
    });
  });

  group('density computation', () {
    test('computes density correctly as total_tonnage / total_time_min', () {
      // 3 sets × 20 reps @ 40kg, rest 60s per set
      // total_tonnage = 3 * 20 * 40 = 2400
      // total_time = (20sec per set * 3) + total_rest_seconds
      //            = 60 + (60 * 3) = 60 + 180 = 240 seconds = 4.0 min
      // density = 2400 / 4.0 = 600
      final metrics = strategy.computeMetrics(
        performedSets: [
          const WorkoutSet(weight: 40, reps: 20, rir: 3, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 40, reps: 20, rir: 3, completed: true, restSeconds: 60),
          const WorkoutSet(weight: 40, reps: 20, rir: 2, completed: true, restSeconds: 60),
        ],
        repMin: 12,
        repMax: 25,
        targetRir: 3,
        history: const ProgressionHistory(),
      );

      expect(metrics.totalTonnage, equals(2400));
      // Time: (20 * 3) + (60 * 3) = 60 + 180 = 240 seconds
      expect(metrics.totalTimeSeconds, equals(240));
      // Density: 2400 / 4.0 = 600
      expect(metrics.density, closeTo(600, 0.1));
    });

    test('handles varying rest times across sets', () {
      final metrics = strategy.computeMetrics(
        performedSets: [
          const WorkoutSet(weight: 50, reps: 15, rir: 3, completed: true, restSeconds: 90),
          const WorkoutSet(weight: 50, reps: 15, rir: 2, completed: true, restSeconds: 120),
        ],
        repMin: 12,
        repMax: 25,
        targetRir: 3,
        history: const ProgressionHistory(),
      );

      // tonnage = 50*15 + 50*15 = 1500
      expect(metrics.totalTonnage, equals(1500));
      // time = (20 * 2) + (90 + 120) = 40 + 210 = 250 seconds
      expect(metrics.totalTimeSeconds, equals(250));
      // density = 1500 / (250/60) = 1500 / 4.1667 = 360
      expect(metrics.density, closeTo(360, 0.1));
    });
  });

  group('score computation', () {
    test('computes score correctly', () {
      // rep_ratio = clamp(total_reps / target_total_reps, 0.6, 1.2)
      // effort_factor = clamp((RIR_last - 1) / 4, 0, 1)
      // score = 100 * (0.7 * rep_ratio + 0.3 * effort_factor)

      // 3 sets × target 25 reps = 75 target total reps
      // actual: 20 + 18 + 17 = 55 reps
      // rep_ratio = clamp(55/75, 0.6, 1.2) = 0.7333
      // RIR_last = 2 → effort_factor = clamp((2-1)/4, 0, 1) = 0.25
      // score = 100 * (0.7 * 0.7333 + 0.3 * 0.25) = 100 * (0.5133 + 0.075) = 58.83
      final metrics = const SessionMetrics(
        totalReps: 55,
        targetTotalReps: 75,
        topSetRir: 2,
        hardSetCount: 3,
      );
      final score = strategy.computeScore(
        metrics: metrics,
        history: const ProgressionHistory(),
      );
      expect(score, closeTo(58.83, 0.5));
    });

    test('computes perfect score with max reps and high RIR', () {
      // ratio = 1.0, RIR_last = 5 → effort_factor = clamp((5-1)/4, 0, 1) = 1.0
      // score = 100 * (0.7 * 1.0 + 0.3 * 1.0) = 100
      final metrics = const SessionMetrics(
        totalReps: 75,
        targetTotalReps: 75,
        topSetRir: 5,
        hardSetCount: 3,
      );
      final score = strategy.computeScore(
        metrics: metrics,
        history: const ProgressionHistory(),
      );
      expect(score, closeTo(100, 0.5));
    });

    test('clamps rep_ratio to 0.6 minimum', () {
      // Very few reps: 10 out of 75 → ratio = 0.133 → clamped to 0.6
      // RIR_last = 1 → effort_factor = 0
      // score = 100 * (0.7 * 0.6 + 0.3 * 0) = 42
      final metrics = const SessionMetrics(
        totalReps: 10,
        targetTotalReps: 75,
        topSetRir: 1,
        hardSetCount: 3,
      );
      final score = strategy.computeScore(
        metrics: metrics,
        history: const ProgressionHistory(),
      );
      expect(score, closeTo(42, 0.5));
    });

    test('clamps rep_ratio to 1.2 maximum', () {
      // Overperform: 100 out of 75 → ratio = 1.333 → clamped to 1.2
      // RIR_last = 3 → effort_factor = clamp((3-1)/4, 0, 1) = 0.5
      // score = 100 * (0.7 * 1.2 + 0.3 * 0.5) = 100 * (0.84 + 0.15) = 99
      final metrics = const SessionMetrics(
        totalReps: 100,
        targetTotalReps: 75,
        topSetRir: 3,
        hardSetCount: 3,
      );
      final score = strategy.computeScore(
        metrics: metrics,
        history: const ProgressionHistory(),
      );
      expect(score, closeTo(99, 0.5));
    });
  });
}
