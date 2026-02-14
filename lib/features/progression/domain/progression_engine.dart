import '../../../shared/models/enums.dart';
import '../../../shared/models/workout_set.dart';
import 'progression_rules.dart';
import 'progression_suggestion.dart';
import 'session_analyzer.dart';

class ProgressionEngine {
  static final _rules = <EquipmentType, ProgressionRule>{
    EquipmentType.barbell: BarbellProgression(),
    EquipmentType.dumbbell: DumbbellProgression(),
    EquipmentType.machineStack: MachineStackProgression(),
    EquipmentType.machinePlateLoaded: PlateMachineProgression(),
    EquipmentType.bodyweight: BodyweightProgression(),
  };

  /// Generate a progression suggestion for an exercise.
  ///
  /// [performedSets] - sets the user just logged
  /// [repMin], [repMax], [targetRir] - prescription from ProgramExercise
  /// [equipment] - equipment type
  /// [unit] - 'kg' or 'lbs'
  /// [poorSessionCount] - consecutive sessions below range or rirLow
  ProgressionSuggestion suggest({
    required List<WorkoutSet> performedSets,
    required double currentWeight,
    required int currentSets,
    required int repMin,
    required int repMax,
    required int targetRir,
    required EquipmentType equipment,
    required String unit,
    int poorSessionCount = 0,
  }) {
    final session = SessionAnalyzer.analyze(
      sets: performedSets,
      repMin: repMin,
      repMax: repMax,
      targetRir: targetRir,
    );

    final rule = _rules[equipment] ?? BarbellProgression();

    return rule.suggest(
      session: session,
      currentWeight: currentWeight,
      currentSets: currentSets,
      repMin: repMin,
      repMax: repMax,
      targetRir: targetRir,
      equipment: equipment,
      unit: unit,
      poorSessionCount: poorSessionCount,
    );
  }
}
