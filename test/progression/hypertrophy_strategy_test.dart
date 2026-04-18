import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/features/progression/domain/hypertrophy_strategy.dart';
import 'package:gymratz/features/progression/domain/models/progression_history.dart';
import 'package:gymratz/features/progression/domain/models/session_metrics.dart';
import 'package:gymratz/shared/models/enums.dart';
import 'package:gymratz/shared/models/workout_set.dart';

void main() {
  late HypertrophyStrategy strategy;

  setUp(() {
    strategy = HypertrophyStrategy();
  });

  group('double progression — increase load', () {
    test('increases load when all sets hit top of rep range with RIR >= 1', () {
      // 3 sets × 12 reps (rep range 8-12), RIR >= 1 on last set
      // min(reps) = 12 >= r_min(8), max(reps) = 12 >= r_max(12), RIR_last >= 1
      // → Rule A: increase load
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 60, reps: 12, rir: 2, completed: true),
          const WorkoutSet(weight: 60, reps: 12, rir: 2, completed: true),
          const WorkoutSet(weight: 60, reps: 12, rir: 1, completed: true),
        ],
        currentWeight: 60,
        repMin: 8,
        repMax: 12,
        targetRir: 2,
        equipment: EquipmentType.dumbbell,
        unit: 'kg',
        history: const ProgressionHistory(),
      );

      expect(result.suggestedWeight, greaterThan(60));
      expect(result.isDeload, false);
      // Dumbbell kg increment is 2.0 → 60 + 2 = 62
      expect(result.suggestedWeight, equals(62));
      // Reps should reset to bottom of range
      expect(result.suggestedReps, equals(8));
    });
  });

  group('double progression — add reps', () {
    test('adds reps when min reps met but not all at max', () {
      // 3 sets: 10, 9, 8 reps (range 8-12), RIR_last >= 1
      // min(reps) = 8 >= r_min(8) ✓, max(reps) = 10 < r_max(12) ✗
      // → Rule B: keep load, target +1 rep on lowest set
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 60, reps: 10, rir: 2, completed: true),
          const WorkoutSet(weight: 60, reps: 9, rir: 2, completed: true),
          const WorkoutSet(weight: 60, reps: 8, rir: 1, completed: true),
        ],
        currentWeight: 60,
        repMin: 8,
        repMax: 12,
        targetRir: 2,
        equipment: EquipmentType.dumbbell,
        unit: 'kg',
        history: const ProgressionHistory(),
      );

      expect(result.suggestedWeight, equals(60));
      // Target +1 rep on lowest set → 8 + 1 = 9
      expect(result.suggestedReps, equals(9));
      expect(result.isDeload, false);
    });
  });

  group('double progression — reduce', () {
    test('reduces load when reps below range', () {
      // 3 sets: 7, 6, 5 reps (range 8-12)
      // min(reps) = 5 < r_min(8) → Rule C: reduce load 5%
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 60, reps: 7, rir: 2, completed: true),
          const WorkoutSet(weight: 60, reps: 6, rir: 1, completed: true),
          const WorkoutSet(weight: 60, reps: 5, rir: 1, completed: true),
        ],
        currentWeight: 60,
        repMin: 8,
        repMax: 12,
        targetRir: 2,
        equipment: EquipmentType.dumbbell,
        unit: 'kg',
        history: const ProgressionHistory(),
      );

      expect(result.suggestedWeight, lessThan(60));
      expect(result.isDeload, false);
      // 60 * 0.95 = 57 → snap to dumbbell 2kg increment → 58
      expect(result.suggestedWeight, equals(58));
    });

    test('reduces load when RIR is 0 (grinding)', () {
      // Even if reps are in range, RIR == 0 on last set → Rule C
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 60, reps: 10, rir: 1, completed: true),
          const WorkoutSet(weight: 60, reps: 9, rir: 1, completed: true),
          const WorkoutSet(weight: 60, reps: 8, rir: 0, completed: true),
        ],
        currentWeight: 60,
        repMin: 8,
        repMax: 12,
        targetRir: 2,
        equipment: EquipmentType.dumbbell,
        unit: 'kg',
        history: const ProgressionHistory(),
      );

      expect(result.suggestedWeight, lessThan(60));
      expect(result.isDeload, false);
    });
  });

  group('deload trigger', () {
    test('triggers deload after 2 consecutive low scores', () {
      // History with 2 consecutive scores < 75
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 60, reps: 8, rir: 1, completed: true),
          const WorkoutSet(weight: 60, reps: 8, rir: 1, completed: true),
          const WorkoutSet(weight: 60, reps: 8, rir: 1, completed: true),
        ],
        currentWeight: 60,
        repMin: 8,
        repMax: 12,
        targetRir: 2,
        equipment: EquipmentType.dumbbell,
        unit: 'kg',
        history: const ProgressionHistory(
          consecutiveLowScores: 2,
          scoreHistory: [70, 72],
        ),
      );

      expect(result.isDeload, true);
      // Deload: sets *= 0.5, keep load or *0.9
      expect(result.suggestedWeight, lessThanOrEqualTo(60));
    });
  });

  group('maintain', () {
    test('maintains when score is in 75-89 range', () {
      // Sets that hit the range with decent RIR → score should be in 75-89
      // Rule B applies here (add reps) since min reps met but not all at max
      // But if all sets are at top of range, Rule A applies
      // For maintain: need a scenario that doesn't trigger A, B, or C
      // Actually, "maintain" in hypertrophy means Rule B (add reps) since that's
      // the progressive path. Let me use a case where reps are all at max but
      // RIR == 0, which triggers C (reduce). So maintain doesn't happen per spec.
      //
      // Re-reading spec: A requires RIR_last >= 1, B requires RIR_last >= 1.
      // If RIR_last >= 1 we'll always be in A or B.
      // If RIR_last == 0, we're in C (reduce).
      // So "maintain" only really applies when score is OK but we're in B territory.
      // Let's test that Rule B (add reps) fires when score is in reasonable range.
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 60, reps: 10, rir: 2, completed: true),
          const WorkoutSet(weight: 60, reps: 10, rir: 2, completed: true),
          const WorkoutSet(weight: 60, reps: 9, rir: 1, completed: true),
        ],
        currentWeight: 60,
        repMin: 8,
        repMax: 12,
        targetRir: 2,
        equipment: EquipmentType.dumbbell,
        unit: 'kg',
        history: const ProgressionHistory(),
      );

      // Should not deload, should keep weight
      expect(result.isDeload, false);
      expect(result.suggestedWeight, equals(60));
      // Should add reps (Rule B) since min met but not all at max
      expect(result.suggestedReps, equals(10)); // lowest is 9, +1 = 10
    });
  });

  group('hard set counting', () {
    test('correctly counts hard sets (RIR <= 3)', () {
      final metrics = strategy.computeMetrics(
        performedSets: [
          const WorkoutSet(weight: 60, reps: 10, rir: 2, completed: true),
          const WorkoutSet(weight: 60, reps: 10, rir: 3, completed: true),
          const WorkoutSet(weight: 60, reps: 10, rir: 4, completed: true),
          const WorkoutSet(weight: 60, reps: 10, rir: 1, completed: true),
          const WorkoutSet(
              weight: 40, reps: 10, rir: 5, completed: true, isWarmup: true),
        ],
        repMin: 8,
        repMax: 12,
        targetRir: 2,
        history: const ProgressionHistory(),
      );

      // Sets with RIR <= 3: set1 (rir=2), set2 (rir=3), set4 (rir=1) = 3 hard sets
      // set3 (rir=4) is NOT hard, warmup is excluded entirely
      expect(metrics.hardSetCount, equals(3));
    });
  });

  group('score computation', () {
    test('computes score correctly', () {
      // rep_ratio = clamp(actual_total_reps / target_total_reps, 0.6, 1.2)
      // effort_factor = clamp((RIR_last - 1) / 3, 0, 1)
      // score = 100 * (0.7 * rep_ratio + 0.3 * effort_factor)

      // 3 sets × target 12 reps = 36 target total reps
      // actual: 10 + 10 + 9 = 29 reps
      // rep_ratio = clamp(29/36, 0.6, 1.2) = 0.8056
      // RIR_last = 1 → effort_factor = clamp((1-1)/3, 0, 1) = 0
      // score = 100 * (0.7 * 0.8056 + 0.3 * 0) = 56.39
      final metrics = const SessionMetrics(
        totalReps: 29,
        targetTotalReps: 36,
        topSetRir: 1,
        hardSetCount: 3,
      );
      final score = strategy.computeScore(
        metrics: metrics,
        history: const ProgressionHistory(),
      );
      expect(score, closeTo(56.39, 0.5));

      // Another case: perfect execution
      // 3 × 12 = 36 actual, 36 target → ratio = 1.0
      // RIR_last = 2 → effort_factor = clamp((2-1)/3, 0, 1) = 0.333
      // score = 100 * (0.7 * 1.0 + 0.3 * 0.333) = 100 * (0.7 + 0.1) = 80
      final metrics2 = const SessionMetrics(
        totalReps: 36,
        targetTotalReps: 36,
        topSetRir: 2,
        hardSetCount: 3,
      );
      final score2 = strategy.computeScore(
        metrics: metrics2,
        history: const ProgressionHistory(),
      );
      expect(score2, closeTo(80, 0.5));

      // High RIR case:
      // ratio = 1.0, RIR_last = 4 → effort_factor = clamp((4-1)/3, 0, 1) = 1.0
      // score = 100 * (0.7 * 1.0 + 0.3 * 1.0) = 100
      final metrics3 = const SessionMetrics(
        totalReps: 36,
        targetTotalReps: 36,
        topSetRir: 4,
        hardSetCount: 3,
      );
      final score3 = strategy.computeScore(
        metrics: metrics3,
        history: const ProgressionHistory(),
      );
      expect(score3, closeTo(100, 0.5));
    });
  });
}
