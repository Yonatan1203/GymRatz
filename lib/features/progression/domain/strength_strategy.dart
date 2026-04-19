import 'dart:math';

import 'models/session_metrics.dart';
import 'models/progression_history.dart';
import 'progression_strategy.dart';
import 'progression_suggestion.dart';
import 'load_quantizer.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/workout_set.dart';

/// Strength mode progressive overload strategy.
///
/// Goal: Increase load while keeping reps low-moderate and fatigue controlled.
/// Template: 3-6 sets x 1-6 reps, RIR 1-3
class StrengthStrategy extends ProgressionStrategy {
  /// Default neutral score when there is no history to compare against.
  static const double _neutralScore = 85.0;

  @override
  SessionMetrics computeMetrics({
    required List<WorkoutSet> performedSets,
    required int repMin,
    required int repMax,
    required int targetRir,
    required ProgressionHistory history,
  }) {
    // Filter out warmup and incomplete sets.
    final workingSets =
        performedSets.where((s) => s.completed && !s.isWarmup).toList();

    if (workingSets.isEmpty) {
      return const SessionMetrics();
    }

    // Compute e1RM for each working set, take the max.
    double maxE1rm = 0;
    double topWeight = 0;
    int topReps = 0;
    int topRir = 0;
    int totalReps = 0;
    double totalTonnage = 0;

    for (final s in workingSets) {
      final e1rm = _epleyE1RM(s.weight, s.reps);
      if (e1rm > maxE1rm) {
        maxE1rm = e1rm;
        topWeight = s.weight;
        topReps = s.reps;
        topRir = s.rir;
      }
      totalReps += s.reps;
      totalTonnage += s.weight * s.reps;
    }

    // Smoothing: 0.7 * previous + 0.3 * current
    final prevSmoothed = history.latestSmoothedE1RM;
    final smoothed = prevSmoothed > 0
        ? 0.7 * prevSmoothed + 0.3 * maxE1rm
        : maxE1rm;

    return SessionMetrics(
      sessionE1RM: _round2(maxE1rm),
      smoothedE1RM: _round2(smoothed),
      hardSetCount: workingSets.length,
      totalReps: totalReps,
      targetTotalReps: workingSets.length * repMax,
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
    final baseline = history.baselineE1RM;
    if (baseline <= 0) return _neutralScore;

    // e1rm_ratio = clamp(session_e1RM / baseline_e1RM, 0.85, 1.10)
    final e1rmRatio =
        (metrics.sessionE1RM / baseline).clamp(0.85, 1.10);

    // effort_ok = 1 if RIR >= 1, else 0
    final effortOk = metrics.topSetRir >= 1 ? 1.0 : 0.0;

    // score = 100 * (0.85 * e1rm_ratio + 0.15 * effort_ok)
    final score = 100 * (0.85 * e1rmRatio + 0.15 * effortOk);
    return _round2(score);
  }

  @override
  bool shouldDeload({
    required double score,
    required SessionMetrics metrics,
    required ProgressionHistory history,
  }) {
    final baseline = history.baselineE1RM;

    // Plateau + avg RIR <= 1
    if (history.isPlateaued && metrics.topSetRir <= 1) {
      return true;
    }

    // session_e1RM < baseline * 0.97
    if (baseline > 0 && metrics.sessionE1RM < baseline * 0.97) {
      return true;
    }

    return false;
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
    final rirTop = metrics.topSetRir;
    final sets = metrics.hardSetCount > 0 ? metrics.hardSetCount : 3;

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

    // Rule D: Score < 80 OR RIR_top == 0 → reduce load -5%
    if (score < 80 || rirTop == 0) {
      final reduced = currentWeight * 0.95;
      final snapped = LoadQuantizer.snap(reduced, equipment, unit);
      final backoff = snapped * (rirTop == 0 ? 0.87 : 0.90);
      return ProgressionSuggestion(
        suggestedWeight: snapped,
        suggestedReps: repMax,
        suggestedSets: sets,
        reasoning: 'Reduce load -5% (score ${score.toStringAsFixed(0)}, RIR $rirTop)',
        isDeload: false,
        backoffWeight: LoadQuantizer.snap(backoff, equipment, unit),
        score: score,
        metrics: metrics,
      );
    }

    // Rule A-high: Score >= 97 AND RIR_top >= 2 → +2%
    if (score >= 97 && rirTop >= 2) {
      final increased = currentWeight * 1.02;
      final snapped = LoadQuantizer.snap(increased, equipment, unit);
      final clamped =
          LoadQuantizer.clampToWeeklyCap(currentWeight, snapped, equipment, unit);
      return ProgressionSuggestion(
        suggestedWeight: clamped,
        suggestedReps: repMin,
        suggestedSets: sets,
        reasoning: 'Increase load +2% (score ${score.toStringAsFixed(0)}, RIR $rirTop)',
        backoffWeight: LoadQuantizer.snap(clamped * 0.90, equipment, unit),
        score: score,
        metrics: metrics,
      );
    }

    // Rule A-low: Score >= 94 AND RIR_top >= 1 → +1%
    if (score >= 94 && rirTop >= 1) {
      final increased = currentWeight * 1.01;
      final snapped = LoadQuantizer.snap(increased, equipment, unit);
      final clamped =
          LoadQuantizer.clampToWeeklyCap(currentWeight, snapped, equipment, unit);
      return ProgressionSuggestion(
        suggestedWeight: clamped,
        suggestedReps: repMin,
        suggestedSets: sets,
        reasoning: 'Increase load +1% (score ${score.toStringAsFixed(0)}, RIR $rirTop)',
        backoffWeight: LoadQuantizer.snap(clamped * 0.90, equipment, unit),
        score: score,
        metrics: metrics,
      );
    }

    // Rule B: Score 88-93 AND RIR_top >= 1 → micro-progression (+1 rep, cap 6)
    if (score >= 88 && score <= 93 && rirTop >= 1) {
      final suggestedReps = min(metrics.topSetReps + 1, 6);
      return ProgressionSuggestion(
        suggestedWeight: currentWeight,
        suggestedReps: suggestedReps,
        suggestedSets: sets,
        reasoning: 'Micro-progression: +1 rep (score ${score.toStringAsFixed(0)})',
        backoffWeight: LoadQuantizer.snap(currentWeight * 0.90, equipment, unit),
        score: score,
        metrics: metrics,
      );
    }

    // Rule C: Score 80-87 → hold
    return ProgressionSuggestion(
      suggestedWeight: currentWeight,
      suggestedReps: repMax,
      suggestedSets: sets,
      reasoning: 'Hold: repeat same prescription (score ${score.toStringAsFixed(0)})',
      backoffWeight: LoadQuantizer.snap(currentWeight * 0.90, equipment, unit),
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

  static double _round2(double v) =>
      (v * 100).roundToDouble() / 100;
}
