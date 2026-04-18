import 'dart:math';

import 'models/session_metrics.dart';
import 'models/progression_history.dart';
import 'progression_strategy.dart';
import 'progression_suggestion.dart';
import 'load_quantizer.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/workout_set.dart';

/// Hypertrophy mode progressive overload strategy.
///
/// Goal: Accumulate effective reps near failure with controlled volume progression.
/// Template: 2-5 sets × 6-15 reps, RIR 1-3
///
/// Uses double progression (rep range): increase reps within a range, then
/// bump load and reset to the bottom of the range.
class HypertrophyStrategy extends ProgressionStrategy {
  @override
  SessionMetrics computeMetrics({
    required List<WorkoutSet> performedSets,
    required int repMin,
    required int repMax,
    required int targetRir,
    required ProgressionHistory history,
  }) {
    final workingSets =
        performedSets.where((s) => s.completed && !s.isWarmup).toList();

    if (workingSets.isEmpty) {
      return const SessionMetrics();
    }

    int totalReps = 0;
    double totalTonnage = 0;
    double topWeight = 0;
    int topReps = 0;
    int topRir = 0;
    double maxE1rm = 0;

    // Count hard sets (RIR <= 3).
    int hardSets = 0;

    for (final s in workingSets) {
      totalReps += s.reps;
      totalTonnage += s.weight * s.reps;

      if (s.rir <= 3) hardSets++;

      final e1rm = _epleyE1RM(s.weight, s.reps);
      if (e1rm > maxE1rm) {
        maxE1rm = e1rm;
        topWeight = s.weight;
        topReps = s.reps;
        topRir = s.rir;
      }
    }

    // Smoothing: 0.7 * previous + 0.3 * current.
    final prevSmoothed = history.latestSmoothedE1RM;
    final smoothed =
        prevSmoothed > 0 ? 0.7 * prevSmoothed + 0.3 * maxE1rm : maxE1rm;

    // Target total reps = number of working sets × repMax.
    final targetTotalReps = workingSets.length * repMax;

    return SessionMetrics(
      sessionE1RM: _round2(maxE1rm),
      smoothedE1RM: _round2(smoothed),
      hardSetCount: hardSets,
      totalReps: totalReps,
      targetTotalReps: targetTotalReps,
      totalTonnage: _round2(totalTonnage),
      topSetWeight: topWeight,
      topSetReps: topReps,
      topSetRir: topRir,
    );
  }

  @override
  double computeScore({
    required SessionMetrics metrics,
    required ProgressionHistory history,
  }) {
    final target = metrics.targetTotalReps;
    if (target <= 0) return 0;

    // rep_ratio = clamp(actual_total_reps / target_total_reps, 0.6, 1.2)
    final repRatio = (metrics.totalReps / target).clamp(0.6, 1.2);

    // effort_factor = clamp((RIR_last - 1) / 3, 0, 1)
    final effortFactor = ((metrics.topSetRir - 1) / 3).clamp(0.0, 1.0);

    // score = 100 * (0.7 * rep_ratio + 0.3 * effort_factor)
    final score = 100 * (0.7 * repRatio + 0.3 * effortFactor);
    return _round2(score);
  }

  @override
  bool shouldDeload({
    required double score,
    required SessionMetrics metrics,
    required ProgressionHistory history,
  }) {
    // Deload trigger: 2 consecutive sessions < 75 score.
    return history.consecutiveLowScores >= 2;
  }

  @override
  ProgressionSuggestion suggest({
    required List<WorkoutSet> performedSets,
    required double currentWeight,
    required int repMin,
    required int repMax,
    required int targetRir,
    required EquipmentType equipment,
    required String unit,
    required ProgressionHistory history,
  }) {
    final metrics = computeMetrics(
      performedSets: performedSets,
      repMin: repMin,
      repMax: repMax,
      targetRir: targetRir,
      history: history,
    );

    final score = computeScore(metrics: metrics, history: history);
    final workingSets =
        performedSets.where((s) => s.completed && !s.isWarmup).toList();
    final sets = workingSets.isNotEmpty ? workingSets.length : 3;

    // Check deload first.
    if (shouldDeload(score: score, metrics: metrics, history: history)) {
      return _deloadPrescription(
        currentWeight: currentWeight,
        sets: sets,
        repMax: repMax,
        equipment: equipment,
        unit: unit,
        score: score,
        metrics: metrics,
      );
    }

    // Extract per-set reps for double-progression logic.
    final repsPerSet = workingSets.map((s) => s.reps).toList();
    final minReps = repsPerSet.isNotEmpty ? repsPerSet.reduce(min) : 0;
    final maxReps = repsPerSet.isNotEmpty ? repsPerSet.reduce(max) : 0;
    final lastSetRir = workingSets.isNotEmpty ? workingSets.last.rir : 0;

    // Rule C: Reduce — if min(reps) < r_min OR RIR_last == 0
    if (minReps < repMin || lastSetRir == 0) {
      final reduced = currentWeight * 0.95;
      final snapped = LoadQuantizer.snap(reduced, equipment, unit);
      return ProgressionSuggestion(
        suggestedWeight: snapped,
        suggestedReps: repMax,
        suggestedSets: sets,
        reasoning:
            'Reduce load -5% (min reps $minReps, RIR $lastSetRir)',
        backoffWeight:
            LoadQuantizer.snap(snapped * 0.90, equipment, unit),
        score: score,
        metrics: metrics,
      );
    }

    // Rule A: Increase load — if min(reps) >= r_min AND max(reps) >= r_max
    //         AND RIR_last >= 1
    if (minReps >= repMin && maxReps >= repMax && lastSetRir >= 1) {
      final increment = LoadQuantizer.minIncrement(equipment, unit);
      final increased = currentWeight + increment;
      final snapped = LoadQuantizer.snap(increased, equipment, unit);
      return ProgressionSuggestion(
        suggestedWeight: snapped,
        suggestedReps: repMin,
        suggestedSets: sets,
        reasoning:
            'Increase load +${increment.toStringAsFixed(1)} $unit (all sets hit top of range)',
        backoffWeight:
            LoadQuantizer.snap(snapped * 0.90, equipment, unit),
        score: score,
        metrics: metrics,
      );
    }

    // Rule B: Add reps — if min(reps) >= r_min AND RIR_last >= 1
    if (minReps >= repMin && lastSetRir >= 1) {
      final targetRep = minReps + 1;
      return ProgressionSuggestion(
        suggestedWeight: currentWeight,
        suggestedReps: targetRep,
        suggestedSets: sets,
        reasoning:
            'Add reps: target $targetRep on lowest set (double progression)',
        backoffWeight:
            LoadQuantizer.snap(currentWeight * 0.90, equipment, unit),
        score: score,
        metrics: metrics,
      );
    }

    // Fallback: hold.
    return ProgressionSuggestion(
      suggestedWeight: currentWeight,
      suggestedReps: repMax,
      suggestedSets: sets,
      reasoning: 'Hold: repeat same prescription (score ${score.toStringAsFixed(0)})',
      backoffWeight:
          LoadQuantizer.snap(currentWeight * 0.90, equipment, unit),
      score: score,
      metrics: metrics,
    );
  }

  // --- Private helpers ---

  /// Epley e1RM with reps capped at 12.
  static double _epleyE1RM(double load, int reps) {
    final repsCapped = min(reps, 12);
    if (repsCapped == 0) return load;
    return load * (1 + repsCapped / 30);
  }

  ProgressionSuggestion _deloadPrescription({
    required double currentWeight,
    required int sets,
    required int repMax,
    required EquipmentType equipment,
    required String unit,
    required double score,
    required SessionMetrics metrics,
  }) {
    // Deload: sets *= 0.5, keep load or *0.9, RIR 3-5.
    final deloadSets = max((sets * 0.5).round(), 1);
    final deloadWeight = currentWeight * 0.90;
    final snapped = LoadQuantizer.snap(deloadWeight, equipment, unit);

    return ProgressionSuggestion(
      suggestedWeight: snapped,
      suggestedReps: repMax,
      suggestedSets: deloadSets,
      reasoning: 'Deload: -10% load, halved volume (RIR 3-5)',
      isDeload: true,
      score: score,
      metrics: metrics,
    );
  }

  static double _round2(double v) => (v * 100).roundToDouble() / 100;
}
