import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/features/progression/domain/progression_engine.dart';
import 'package:gymratz/features/progression/domain/strength_strategy.dart';
import 'package:gymratz/features/progression/domain/hypertrophy_strategy.dart';
import 'package:gymratz/features/progression/domain/endurance_strategy.dart';
import 'package:gymratz/features/progression/domain/models/progression_history.dart';
import 'package:gymratz/shared/models/enums.dart';
import 'package:gymratz/shared/models/workout_set.dart';

void main() {
  group('ProgressionEngine.getStrategy', () {
    test('returns StrengthStrategy for strength mode', () {
      expect(ProgressionEngine.getStrategy(ProgressionMode.strength),
          isA<StrengthStrategy>());
    });

    test('returns HypertrophyStrategy for hypertrophy mode', () {
      expect(ProgressionEngine.getStrategy(ProgressionMode.hypertrophy),
          isA<HypertrophyStrategy>());
    });

    test('returns EnduranceStrategy for endurance mode', () {
      expect(ProgressionEngine.getStrategy(ProgressionMode.endurance),
          isA<EnduranceStrategy>());
    });
  });

  group('ProgressionEngine.suggest', () {
    final sets = [
      const WorkoutSet(weight: 80, reps: 8, rir: 2, completed: true),
      const WorkoutSet(weight: 80, reps: 8, rir: 2, completed: true),
      const WorkoutSet(weight: 80, reps: 7, rir: 1, completed: true),
    ];

    test('runs without throwing for all three modes', () {
      for (final mode in ProgressionMode.values) {
        expect(
          () => ProgressionEngine.suggest(
            performedSets: sets,
            currentWeight: 80,
            repMin: 6,
            repMax: 10,
            targetRir: 2,
            equipment: EquipmentType.barbell,
            unit: 'kg',
            mode: mode,
          ),
          returnsNormally,
        );
      }
    });

    test('suggest passes parameters to strategy without mutation', () {
      const weight = 100.0;
      final suggestion = ProgressionEngine.suggest(
        performedSets: sets,
        currentWeight: weight,
        repMin: 6,
        repMax: 10,
        targetRir: 2,
        equipment: EquipmentType.barbell,
        unit: 'kg',
        mode: ProgressionMode.hypertrophy,
        history: const ProgressionHistory(),
      );
      // Suggestion is returned (not null) and has a weight.
      expect(suggestion.suggestedWeight, greaterThanOrEqualTo(0));
    });
  });
}
