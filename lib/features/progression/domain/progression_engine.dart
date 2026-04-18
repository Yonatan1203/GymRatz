import '../../../shared/models/enums.dart';
import '../../../shared/models/workout_set.dart';
import 'progression_strategy.dart';
import 'progression_suggestion.dart';
import 'strength_strategy.dart';
import 'hypertrophy_strategy.dart';
import 'endurance_strategy.dart';
import 'models/progression_history.dart';

class ProgressionEngine {
  static final Map<ProgressionMode, ProgressionStrategy> _strategies = {
    ProgressionMode.strength: StrengthStrategy(),
    ProgressionMode.hypertrophy: HypertrophyStrategy(),
    ProgressionMode.endurance: EnduranceStrategy(),
  };

  static ProgressionStrategy getStrategy(ProgressionMode mode) {
    return _strategies[mode] ?? HypertrophyStrategy();
  }

  static ProgressionSuggestion suggest({
    required List<WorkoutSet> performedSets,
    required double currentWeight,
    required int repMin,
    required int repMax,
    required int targetRir,
    required EquipmentType equipment,
    required String unit,
    required ProgressionMode mode,
    ProgressionHistory history = const ProgressionHistory(),
  }) {
    final strategy = getStrategy(mode);
    return strategy.suggest(
      performedSets: performedSets,
      currentWeight: currentWeight,
      repMin: repMin,
      repMax: repMax,
      targetRir: targetRir,
      equipment: equipment,
      unit: unit,
      history: history,
    );
  }
}
