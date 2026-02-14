import '../../../shared/models/enums.dart';
import 'load_quantizer.dart';
import 'progression_suggestion.dart';
import 'session_analyzer.dart';

/// Base class for equipment-specific progression rules.
abstract class ProgressionRule {
  ProgressionSuggestion suggest({
    required SessionSummary session,
    required double currentWeight,
    required int currentSets,
    required int repMin,
    required int repMax,
    required int targetRir,
    required EquipmentType equipment,
    required String unit,
    required int poorSessionCount,
  });
}

/// Barbell: LoadFirst progression.
class BarbellProgression extends ProgressionRule {
  static const double bigJumpMultiplier = 2.0;

  @override
  ProgressionSuggestion suggest({
    required SessionSummary session,
    required double currentWeight,
    required int currentSets,
    required int repMin,
    required int repMax,
    required int targetRir,
    required EquipmentType equipment,
    required String unit,
    required int poorSessionCount,
  }) {
    final increment = LoadQuantizer.minIncrement(equipment, unit);

    // Below range or too hard -> maintain or deload
    if (session.rangeStatus == RangeStatus.belowRange ||
        session.effortStatus == EffortStatus.rirLow) {
      if (poorSessionCount >= 2) {
        final deloaded = LoadQuantizer.snap(
            currentWeight - increment, equipment, unit);
        return ProgressionSuggestion(
          suggestedWeight: deloaded,
          suggestedReps: repMin,
          suggestedSets: currentSets,
          reasoning: 'Deload: struggled for $poorSessionCount sessions',
          isDeload: true,
        );
      }
      return ProgressionSuggestion(
        suggestedWeight: currentWeight,
        suggestedReps: repMin,
        suggestedSets: currentSets,
        reasoning: 'Maintain weight — build consistency at this load',
      );
    }

    // In range with easy effort or above range -> big jump
    if ((session.rangeStatus == RangeStatus.inRange &&
            session.effortStatus == EffortStatus.rirHigh) ||
        session.rangeStatus == RangeStatus.aboveRange) {
      final jump = increment * bigJumpMultiplier;
      final proposed = LoadQuantizer.snap(currentWeight + jump, equipment, unit);
      final clamped = LoadQuantizer.clampToWeeklyCap(
          currentWeight, proposed, equipment, unit);
      return ProgressionSuggestion(
        suggestedWeight: clamped,
        suggestedReps: repMin,
        suggestedSets: currentSets,
        reasoning: 'Strong session — bigger weight jump',
      );
    }

    // In range and on target -> standard increment
    final proposed =
        LoadQuantizer.snap(currentWeight + increment, equipment, unit);
    final clamped = LoadQuantizer.clampToWeeklyCap(
        currentWeight, proposed, equipment, unit);
    return ProgressionSuggestion(
      suggestedWeight: clamped,
      suggestedReps: repMin,
      suggestedSets: currentSets,
      reasoning: 'Good session — add ${increment.toStringAsFixed(1)} $unit',
    );
  }
}

/// Dumbbell: Mixed progression (reps -> load).
class DumbbellProgression extends ProgressionRule {
  @override
  ProgressionSuggestion suggest({
    required SessionSummary session,
    required double currentWeight,
    required int currentSets,
    required int repMin,
    required int repMax,
    required int targetRir,
    required EquipmentType equipment,
    required String unit,
    required int poorSessionCount,
  }) {
    final increment = LoadQuantizer.minIncrement(equipment, unit);

    if (session.rangeStatus == RangeStatus.belowRange ||
        session.effortStatus == EffortStatus.rirLow) {
      if (poorSessionCount >= 3) {
        final deloaded = LoadQuantizer.snap(
            currentWeight - increment, equipment, unit);
        return ProgressionSuggestion(
          suggestedWeight: deloaded,
          suggestedReps: repMin,
          suggestedSets: currentSets,
          reasoning: 'Deload: reduce by 1 DB increment',
          isDeload: true,
        );
      }
      return ProgressionSuggestion(
        suggestedWeight: currentWeight,
        suggestedReps: repMin,
        suggestedSets: currentSets,
        reasoning: 'Maintain — focus on hitting the rep range',
      );
    }

    // Top of rep range + on target effort -> increase load
    if (session.rangeStatus == RangeStatus.inRange &&
        session.effortStatus == EffortStatus.rirOnTarget &&
        session.repsAvg >= repMax - 1) {
      final proposed = LoadQuantizer.snap(
          currentWeight + increment, equipment, unit);
      return ProgressionSuggestion(
        suggestedWeight: proposed,
        suggestedReps: repMin,
        suggestedSets: currentSets,
        reasoning: 'Hit top of range — increase weight per hand',
      );
    }

    // In range but not at top -> keep weight, aim for more reps
    return ProgressionSuggestion(
      suggestedWeight: currentWeight,
      suggestedReps: (session.repsAvg + 1).clamp(repMin, repMax).toInt(),
      suggestedSets: currentSets,
      reasoning: 'Keep weight — add reps toward top of range',
    );
  }
}

/// Machine (selectorized stack): RepsFirst -> small load step.
class MachineStackProgression extends ProgressionRule {
  @override
  ProgressionSuggestion suggest({
    required SessionSummary session,
    required double currentWeight,
    required int currentSets,
    required int repMin,
    required int repMax,
    required int targetRir,
    required EquipmentType equipment,
    required String unit,
    required int poorSessionCount,
  }) {
    final increment = LoadQuantizer.minIncrement(equipment, unit);

    if (session.rangeStatus == RangeStatus.belowRange ||
        session.effortStatus == EffortStatus.rirLow) {
      if (poorSessionCount >= 2) {
        final deloaded = LoadQuantizer.snap(
            currentWeight - increment, equipment, unit);
        return ProgressionSuggestion(
          suggestedWeight: deloaded,
          suggestedReps: repMin,
          suggestedSets: currentSets,
          reasoning: 'Deload: drop 1 stack plate',
          isDeload: true,
        );
      }
      return ProgressionSuggestion(
        suggestedWeight: currentWeight,
        suggestedReps: repMin,
        suggestedSets: currentSets,
        reasoning: 'Maintain — build endurance at this stack setting',
      );
    }

    // Hit top of range -> increase stack
    if (session.repsAvg >= repMax &&
        session.effortStatus == EffortStatus.rirOnTarget) {
      final proposed = LoadQuantizer.snap(
          currentWeight + increment, equipment, unit);
      return ProgressionSuggestion(
        suggestedWeight: proposed,
        suggestedReps: repMin,
        suggestedSets: currentSets,
        reasoning: 'Max reps reached — move up the stack',
      );
    }

    // Keep adding reps
    return ProgressionSuggestion(
      suggestedWeight: currentWeight,
      suggestedReps: (session.repsAvg + 1).clamp(repMin, repMax).toInt(),
      suggestedSets: currentSets,
      reasoning: 'Keep load — add reps',
    );
  }
}

/// Plate-loaded machine: barbell snapping with mixed progression.
class PlateMachineProgression extends BarbellProgression {}

/// Bodyweight: RepsFirst -> Sets -> Variation -> Load.
class BodyweightProgression extends ProgressionRule {
  @override
  ProgressionSuggestion suggest({
    required SessionSummary session,
    required double currentWeight,
    required int currentSets,
    required int repMin,
    required int repMax,
    required int targetRir,
    required EquipmentType equipment,
    required String unit,
    required int poorSessionCount,
  }) {
    if (session.rangeStatus == RangeStatus.belowRange ||
        session.effortStatus == EffortStatus.rirLow) {
      return ProgressionSuggestion(
        suggestedWeight: currentWeight,
        suggestedReps: (repMin - 1).clamp(1, repMax),
        suggestedSets: currentSets,
        reasoning: 'Reduce target reps slightly',
      );
    }

    // Above range and easy -> add set or add load
    if (session.rangeStatus == RangeStatus.aboveRange &&
        session.effortStatus == EffortStatus.rirHigh) {
      if (currentSets < 5) {
        return ProgressionSuggestion(
          suggestedWeight: currentWeight,
          suggestedReps: repMax,
          suggestedSets: currentSets + 1,
          reasoning: 'Too easy — add a set',
        );
      }
      final increment = LoadQuantizer.minIncrement(equipment, unit);
      return ProgressionSuggestion(
        suggestedWeight: currentWeight + increment,
        suggestedReps: repMin,
        suggestedSets: currentSets,
        reasoning: 'Max sets reached — add external load',
      );
    }

    // In range -> add reps
    return ProgressionSuggestion(
      suggestedWeight: currentWeight,
      suggestedReps: (session.repsAvg + 1).clamp(repMin, repMax).toInt(),
      suggestedSets: currentSets,
      reasoning: 'Keep going — add reps',
    );
  }
}
