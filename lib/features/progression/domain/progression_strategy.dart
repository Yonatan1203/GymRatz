import 'models/session_metrics.dart';
import 'models/progression_history.dart';
import 'progression_suggestion.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/workout_set.dart';

abstract class ProgressionStrategy {
  ProgressionSuggestion suggest({
    required List<WorkoutSet> performedSets,
    required double currentWeight,
    required int repMin,
    required int repMax,
    required int targetRir,
    required EquipmentType equipment,
    required String unit,
    required ProgressionHistory history,
  });

  SessionMetrics computeMetrics({
    required List<WorkoutSet> performedSets,
    required int repMin,
    required int repMax,
    required int targetRir,
    required ProgressionHistory history,
  });

  double computeScore({
    required SessionMetrics metrics,
    required ProgressionHistory history,
  });

  bool shouldDeload({
    required double score,
    required SessionMetrics metrics,
    required ProgressionHistory history,
  });
}
