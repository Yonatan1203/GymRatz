import 'dart:math';

import 'models/session_metrics.dart';
import 'models/progression_history.dart';
import 'progression_strategy.dart';
import 'progression_suggestion.dart';
import 'load_quantizer.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/workout_set.dart';

/// Endurance mode progressive overload strategy.
///
/// Goal: Increase reps, density (work per time), or reduce rest at submaximal loads.
/// Template: 2-4 sets × 12-25 reps, RIR 2-4
///
/// Primary metric — Density: total_tonnage / total_time_min
/// Approximate time: (20sec per set * num_sets) + total_rest_seconds
///
/// Uses reps-first progression at fixed load:
/// A) If min(reps) >= r_max AND RIR_last >= 2 → increase load or add 1 set (cap 4)
/// B) If min(reps) >= r_min AND RIR_last >= 2 → add +1-2 reps to lowest set
/// C) Else → reduce load 2.5-5% or increase rest
class EnduranceStrategy extends ProgressionStrategy {
  /// Seconds assumed per working set for density calculation.
  static const int _secondsPerSet = 20;

  /// Maximum number of sets allowed.
  static const int _maxSets = 4;

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
    int hardSets = 0;
    int totalRestSeconds = 0;

    for (final s in workingSets) {
      totalReps += s.reps;
      totalTonnage += s.weight * s.reps;
      totalRestSeconds += s.restSeconds;

      if (s.rir <= 3) hardSets++;

      if (s.weight > topWeight ||
          (s.weight == topWeight && s.reps > topReps)) {
        topWeight = s.weight;
        topReps = s.reps;
      }
    }

    // Last set RIR for effort tracking.
    final lastSetRir = workingSets.last.rir;

    // Density: total_tonnage / total_time_min
    // Time = (20sec * num_sets) + total_rest_seconds
    final totalTimeSeconds =
        (_secondsPerSet * workingSets.length) + totalRestSeconds;
    final totalTimeMin = totalTimeSeconds / 60.0;
    final density = totalTimeMin > 0 ? totalTonnage / totalTimeMin : 0.0;

    // Target total reps = number of working sets × repMax.
    final targetTotalReps = workingSets.length * repMax;

    // e1RM smoothing (less relevant for endurance but kept for interface).
    final sessionE1rm = _epleyE1RM(topWeight, topReps);
    final prevSmoothed = history.latestSmoothedE1RM;
    final smoothed =
        prevSmoothed > 0 ? 0.7 * prevSmoothed + 0.3 * sessionE1rm : sessionE1rm;

    return SessionMetrics(
      sessionE1RM: _round2(sessionE1rm),
      smoothedE1RM: _round2(smoothed),
      hardSetCount: hardSets,
      totalReps: totalReps,
      targetTotalReps: targetTotalReps,
      totalTonnage: _round2(totalTonnage),
      density: _round2(density),
      totalTimeSeconds: totalTimeSeconds,
      topSetWeight: topWeight,
      topSetReps: topReps,
      topSetRir: lastSetRir,
    );
  }

  @override
  double computeScore({
    required SessionMetrics metrics,
    required ProgressionHistory history,
  }) {
    final target = metrics.targetTotalReps;
    if (target <= 0) return 0;

    // rep_ratio = clamp(total_reps / target_total_reps, 0.6, 1.2)
    final repRatio = (metrics.totalReps / target).clamp(0.6, 1.2);

    // effort_factor = clamp((RIR_last - 1) / 4, 0, 1)
    final effortFactor = ((metrics.topSetRir - 1) / 4).clamp(0.0, 1.0);

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
    // Plateau: density doesn't improve for 3 exposures.
    return history.isPlateaued;
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

    // Extract per-set reps for reps-first logic.
    final repsPerSet = workingSets.map((s) => s.reps).toList();
    final minReps = repsPerSet.isNotEmpty ? repsPerSet.reduce(min) : 0;
    final lastSetRir = workingSets.isNotEmpty ? workingSets.last.rir : 0;

    // Rule C: Reduce — if min(reps) < r_min OR RIR_last < 2
    if (minReps < repMin || lastSetRir < 2) {
      final reduced = currentWeight * 0.95;
      final snapped = LoadQuantizer.snap(reduced, equipment, unit);
      return ProgressionSuggestion(
        suggestedWeight: snapped,
        suggestedReps: repMax,
        suggestedSets: sets,
        reasoning:
            'Reduce load ~5% (min reps $minReps, RIR $lastSetRir)',
        backoffWeight:
            LoadQuantizer.snap(snapped * 0.90, equipment, unit),
        score: score,
        metrics: metrics,
      );
    }

    // Rule A: Increase — if min(reps) >= r_max AND RIR_last >= 2
    if (minReps >= repMax && lastSetRir >= 2) {
      // Prefer adding a set if below cap.
      if (sets < _maxSets) {
        return ProgressionSuggestion(
          suggestedWeight: currentWeight,
          suggestedReps: repMax,
          suggestedSets: sets + 1,
          reasoning:
              'Add 1 set ($sets → ${sets + 1}) — all sets at top of range',
          backoffWeight:
              LoadQuantizer.snap(currentWeight * 0.90, equipment, unit),
          score: score,
          metrics: metrics,
        );
      }

      // Already at max sets → increase load.
      final increment = LoadQuantizer.minIncrement(equipment, unit);
      final increased = currentWeight + increment;
      final snapped = LoadQuantizer.snap(increased, equipment, unit);
      return ProgressionSuggestion(
        suggestedWeight: snapped,
        suggestedReps: repMin,
        suggestedSets: sets,
        reasoning:
            'Increase load +${increment.toStringAsFixed(1)} $unit (all sets at top, max sets reached)',
        backoffWeight:
            LoadQuantizer.snap(snapped * 0.90, equipment, unit),
        score: score,
        metrics: metrics,
      );
    }

    // Rule B: Add reps — if min(reps) >= r_min AND RIR_last >= 2
    if (minReps >= repMin && lastSetRir >= 2) {
      final targetRep = minReps + 1;
      return ProgressionSuggestion(
        suggestedWeight: currentWeight,
        suggestedReps: targetRep,
        suggestedSets: sets,
        reasoning:
            'Add reps: target $targetRep on lowest set (reps-first progression)',
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
    // Deload: sets *= 0.6 (min 2), keep load or *0.9, RIR 3-5.
    final deloadSets = max((sets * 0.6).round(), 2);
    final deloadWeight = currentWeight * 0.90;
    final snapped = LoadQuantizer.snap(deloadWeight, equipment, unit);

    return ProgressionSuggestion(
      suggestedWeight: snapped,
      suggestedReps: repMax,
      suggestedSets: deloadSets,
      reasoning: 'Deload: -10% load, reduced volume (RIR 3-5)',
      isDeload: true,
      score: score,
      metrics: metrics,
    );
  }

  static double _round2(double v) => (v * 100).roundToDouble() / 100;
}
