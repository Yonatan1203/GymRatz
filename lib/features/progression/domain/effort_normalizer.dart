import '../../../shared/models/workout_set.dart';

/// Normalizes effort data across different input methods.
///
/// Blueprint rules:
/// - If only RPE given: RIR = clamp(10 - RPE, 0, 6)
/// - If neither RIR nor RPE: infer effort by rep drop from best set
class EffortNormalizer {
  /// Get the effective RIR for a set, applying inference if needed.
  ///
  /// [bestRepsInSession] is the highest reps achieved at this weight
  /// in the current session (used for rep-drop inference).
  static int effectiveRir(WorkoutSet set, {int? bestRepsInSession}) {
    // If RIR is explicitly set, use it.
    if (set.rir != null) return set.rir!;

    // If we have rep-drop data, infer: hard = drop <= 2.
    if (bestRepsInSession != null && bestRepsInSession > 0) {
      final drop = bestRepsInSession - set.reps;
      // Coarse inference: drop 0-1 = RIR 1, drop 2 = RIR 2, drop 3+ = RIR 3
      if (drop <= 1) return 1;
      if (drop == 2) return 2;
      return 3;
    }

    // Default: assume moderate effort (RIR 2).
    return 2;
  }

  /// Apply effort normalization to a list of sets.
  /// Returns a new list with RIR filled in where it was null.
  static List<WorkoutSet> normalizeSets(List<WorkoutSet> sets) {
    if (sets.isEmpty) return sets;

    // Find best reps at each weight level.
    final bestRepsAtWeight = <double, int>{};
    for (final s in sets) {
      if (!s.completed || s.isWarmup) continue;
      final current = bestRepsAtWeight[s.weight] ?? 0;
      if (s.reps > current) bestRepsAtWeight[s.weight] = s.reps;
    }

    return sets.map((s) {
      if (s.rir != null || s.isWarmup || !s.completed) return s;
      final bestReps = bestRepsAtWeight[s.weight];
      final inferred = effectiveRir(s, bestRepsInSession: bestReps);
      return s.copyWith(rir: inferred);
    }).toList();
  }
}
