import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/features/progression/domain/load_quantizer.dart';
import 'package:gymratz/features/progression/domain/effort_normalizer.dart';
import 'package:gymratz/shared/models/enums.dart';
import 'package:gymratz/shared/models/workout_set.dart';

void main() {
  // ──────────────────────────────────────────────────────────
  // LoadQuantizer
  // ──────────────────────────────────────────────────────────

  group('LoadQuantizer.snap', () {
    test('nearest rounding for barbell kg', () {
      // 102.1 → nearest 2.5 = 102.5
      expect(LoadQuantizer.snap(102.1, EquipmentType.barbell, 'kg'),
          closeTo(102.5, 0.001));
    });

    test('RoundMode.down floors to increment', () {
      // 102.1 → floor to 2.5 = 100.0
      expect(
          LoadQuantizer.snap(102.1, EquipmentType.barbell, 'kg',
              mode: RoundMode.down),
          closeTo(100.0, 0.001));
    });

    test('RoundMode.up ceils to increment', () {
      // 102.1 → ceil to 2.5 = 102.5
      expect(
          LoadQuantizer.snap(102.1, EquipmentType.barbell, 'kg',
              mode: RoundMode.up),
          closeTo(102.5, 0.001));
    });
  });

  group('LoadQuantizer.minIncrement', () {
    test('barbell kg returns 2.5', () {
      expect(LoadQuantizer.minIncrement(EquipmentType.barbell, 'kg'), 2.5);
    });

    test('barbell lbs returns 5.0', () {
      expect(LoadQuantizer.minIncrement(EquipmentType.barbell, 'lbs'), 5.0);
    });

    test('dumbbell kg returns 2.0', () {
      expect(LoadQuantizer.minIncrement(EquipmentType.dumbbell, 'kg'), 2.0);
    });

    test('machineStack kg returns 5.0', () {
      expect(LoadQuantizer.minIncrement(EquipmentType.machineStack, 'kg'), 5.0);
    });

    test('machineStack lbs returns 10.0', () {
      expect(
          LoadQuantizer.minIncrement(EquipmentType.machineStack, 'lbs'), 10.0);
    });
  });

  group('LoadQuantizer.exceedsWeeklyCap', () {
    test('exactly 10% increase returns false', () {
      expect(LoadQuantizer.exceedsWeeklyCap(100, 110), isFalse);
    });

    test('10.01% increase returns true', () {
      expect(LoadQuantizer.exceedsWeeklyCap(100, 110.01), isTrue);
    });

    test('decrease returns false', () {
      expect(LoadQuantizer.exceedsWeeklyCap(100, 90), isFalse);
    });

    test('currentWeight zero returns false', () {
      expect(LoadQuantizer.exceedsWeeklyCap(0, 100), isFalse);
    });
  });

  group('LoadQuantizer.clampToWeeklyCap', () {
    test('proposed below current returns proposed unchanged', () {
      final result = LoadQuantizer.clampToWeeklyCap(
          100, 90, EquipmentType.barbell, 'kg');
      expect(result, closeTo(90.0, 0.001));
    });

    test('proposed exceeding cap is clamped to snapped max', () {
      // max = 100 * 1.10 = 110; snap(110) for barbell kg = 110.0
      final result = LoadQuantizer.clampToWeeklyCap(
          100, 120, EquipmentType.barbell, 'kg');
      expect(result, closeTo(110.0, 0.1));
    });
  });

  // ──────────────────────────────────────────────────────────
  // EffortNormalizer
  // ──────────────────────────────────────────────────────────

  group('EffortNormalizer.effectiveRir', () {
    test('returns explicit rir when set', () {
      const s = WorkoutSet(weight: 80, reps: 8, rir: 3, completed: true);
      expect(EffortNormalizer.effectiveRir(s), 3);
    });

    test('returns 2 when rir is null and bestRepsInSession is null', () {
      const s = WorkoutSet(weight: 80, reps: 8, rir: null, completed: true);
      expect(EffortNormalizer.effectiveRir(s), 2);
    });

    test('drop == 0 infers RIR 1', () {
      const s = WorkoutSet(weight: 80, reps: 8, rir: null, completed: true);
      expect(EffortNormalizer.effectiveRir(s, bestRepsInSession: 8), 1);
    });

    test('drop == 1 infers RIR 1', () {
      const s = WorkoutSet(weight: 80, reps: 7, rir: null, completed: true);
      expect(EffortNormalizer.effectiveRir(s, bestRepsInSession: 8), 1);
    });

    test('drop == 2 infers RIR 2', () {
      const s = WorkoutSet(weight: 80, reps: 6, rir: null, completed: true);
      expect(EffortNormalizer.effectiveRir(s, bestRepsInSession: 8), 2);
    });

    test('drop >= 3 infers RIR 3', () {
      const s = WorkoutSet(weight: 80, reps: 5, rir: null, completed: true);
      expect(EffortNormalizer.effectiveRir(s, bestRepsInSession: 8), 3);
    });
  });

  group('EffortNormalizer.normalizeSets', () {
    test('empty input returns empty list', () {
      expect(EffortNormalizer.normalizeSets(const []), isEmpty);
    });

    test('warmup sets are left unchanged', () {
      const warmup = WorkoutSet(
          weight: 40, reps: 12, rir: null, completed: true, isWarmup: true);
      final result = EffortNormalizer.normalizeSets(const [warmup]);
      expect(result.first.rir, isNull);
    });

    test('incomplete sets are left unchanged', () {
      const incomplete =
          WorkoutSet(weight: 80, reps: 8, rir: null, completed: false);
      final result = EffortNormalizer.normalizeSets(const [incomplete]);
      expect(result.first.rir, isNull);
    });

    test('working sets with null rir get inferred rir', () {
      const s = WorkoutSet(weight: 80, reps: 8, rir: null, completed: true);
      final result = EffortNormalizer.normalizeSets(const [s]);
      expect(result.first.rir, isNotNull);
    });

    test('sets with explicit rir are not mutated', () {
      const s = WorkoutSet(weight: 80, reps: 8, rir: 3, completed: true);
      final result = EffortNormalizer.normalizeSets(const [s]);
      expect(result.first.rir, 3);
    });
  });
}
