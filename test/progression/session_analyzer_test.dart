import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/features/progression/domain/session_analyzer.dart';
import 'package:gymratz/shared/models/enums.dart';
import 'package:gymratz/shared/models/workout_set.dart';

void main() {
  group('SessionAnalyzer.analyze — empty / filtered sets', () {
    test('empty sets returns belowRange + rirLow without throwing', () {
      final result = SessionAnalyzer.analyze(
        sets: const [],
        repMin: 6,
        repMax: 10,
        targetRir: 2,
      );
      expect(result.rangeStatus, RangeStatus.belowRange);
      expect(result.effortStatus, EffortStatus.rirLow);
    });

    test('only warmup sets are excluded — treated as empty', () {
      const warmup = WorkoutSet(
          weight: 40, reps: 12, rir: 5, completed: true, isWarmup: true);
      final result = SessionAnalyzer.analyze(
        sets: const [warmup],
        repMin: 6,
        repMax: 10,
        targetRir: 2,
      );
      expect(result.rangeStatus, RangeStatus.belowRange);
    });

    test('incomplete sets are excluded', () {
      const incomplete =
          WorkoutSet(weight: 80, reps: 8, rir: 2, completed: false);
      final result = SessionAnalyzer.analyze(
        sets: const [incomplete],
        repMin: 6,
        repMax: 10,
        targetRir: 2,
      );
      expect(result.rangeStatus, RangeStatus.belowRange);
    });
  });

  group('SessionAnalyzer.analyze — range status', () {
    test('repsMin exactly equal to repMin returns inRange', () {
      final result = SessionAnalyzer.analyze(
        sets: const [
          WorkoutSet(weight: 80, reps: 6, rir: 2, completed: true),
          WorkoutSet(weight: 80, reps: 8, rir: 2, completed: true),
        ],
        repMin: 6,
        repMax: 10,
        targetRir: 2,
      );
      expect(result.rangeStatus, RangeStatus.inRange);
    });

    test('repsMin exactly equal to repMax returns inRange', () {
      final result = SessionAnalyzer.analyze(
        sets: const [
          WorkoutSet(weight: 80, reps: 10, rir: 2, completed: true),
          WorkoutSet(weight: 80, reps: 10, rir: 2, completed: true),
        ],
        repMin: 6,
        repMax: 10,
        targetRir: 2,
      );
      expect(result.rangeStatus, RangeStatus.inRange);
    });

    test('repsMin below repMin returns belowRange', () {
      final result = SessionAnalyzer.analyze(
        sets: const [
          WorkoutSet(weight: 80, reps: 5, rir: 2, completed: true),
        ],
        repMin: 6,
        repMax: 10,
        targetRir: 2,
      );
      expect(result.rangeStatus, RangeStatus.belowRange);
    });

    test('repsMin above repMax returns aboveRange', () {
      final result = SessionAnalyzer.analyze(
        sets: const [
          WorkoutSet(weight: 80, reps: 12, rir: 2, completed: true),
        ],
        repMin: 6,
        repMax: 10,
        targetRir: 2,
      );
      expect(result.rangeStatus, RangeStatus.aboveRange);
    });
  });

  group('SessionAnalyzer.analyze — effort status', () {
    test('rirMin below targetRir returns rirLow even when rirAvg is on target',
        () {
      // rirMin = 1, rirAvg = (1+3)/2 = 2 = targetRir
      final result = SessionAnalyzer.analyze(
        sets: const [
          WorkoutSet(weight: 80, reps: 8, rir: 1, completed: true),
          WorkoutSet(weight: 80, reps: 8, rir: 3, completed: true),
        ],
        repMin: 6,
        repMax: 10,
        targetRir: 2,
      );
      expect(result.effortStatus, EffortStatus.rirLow);
    });

    test('rirAvg more than 1 above targetRir returns rirHigh', () {
      // rirAvg = 5, targetRir = 2 → 5 > 2+1 → rirHigh
      final result = SessionAnalyzer.analyze(
        sets: const [
          WorkoutSet(weight: 60, reps: 8, rir: 5, completed: true),
          WorkoutSet(weight: 60, reps: 8, rir: 5, completed: true),
        ],
        repMin: 6,
        repMax: 10,
        targetRir: 2,
      );
      expect(result.effortStatus, EffortStatus.rirHigh);
    });

    test('rirMin on target and rirAvg within 1 returns rirOnTarget', () {
      final result = SessionAnalyzer.analyze(
        sets: const [
          WorkoutSet(weight: 80, reps: 8, rir: 2, completed: true),
          WorkoutSet(weight: 80, reps: 8, rir: 3, completed: true),
        ],
        repMin: 6,
        repMax: 10,
        targetRir: 2,
      );
      expect(result.effortStatus, EffortStatus.rirOnTarget);
    });
  });
}
