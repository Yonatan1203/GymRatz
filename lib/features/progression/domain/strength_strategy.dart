import 'dart:math';

import '../../../shared/models/enums.dart';
import '../../../shared/models/workout_set.dart';
import 'effort_normalizer.dart';
import 'load_quantizer.dart';
import 'models/progression_history.dart';
import 'models/session_metrics.dart';
import 'progression_strategy.dart';
import 'progression_suggestion.dart';

/// Strength mode progressive overload strategy.
///
/// Goal: Increase load while keeping reps low-moderate and fatigue controlled.
/// Template: 3-6 sets x 1-6 reps, RIR 1-3
/// Metric: smoothed e1RM + rep-quality gate
class StrengthStrategy extends ProgressionStrategy {
  /// Default neutral score when there is no history to compare against.
  static const double _neutralScore = 85.0;

  /// Improvement threshold for plateau detection (0.25%).
  static const double _improvementThresholdPct = 0.25;

  /// Low-score threshold used when appending to history.
  static const double _lowScoreThreshold = 80.0;

  @override
  SessionMetrics computeMetrics({
    required List<WorkoutSet> performedSets,
    required int repMin,
    required int repMax,
    required int targetRir,
    required ProgressionHistory history,
  }) {
    // Normalize effort: fill in nullable RIR via EffortNormalizer.
    final normalized = EffortNormalizer.normalizeSets(performedSets);

    // Filter out warmup and incomplete sets.
    final workingSets =
        normalized.where((s) => s.completed && !s.isWarmup).toList();

    if (workingSets.isEmpty) {
      return const SessionMetrics();
    }

    // Find best reps at each weight for rep-drop inference context.
    final bestRepsAtWeight = <double, int>{};
    for (final s in workingSets) {
      final current = bestRepsAtWeight[s.weight] ?? 0;
      if (s.reps > current) bestRepsAtWeight[s.weight] = s.reps;
    }

    // Compute e1RM for each working set, track the top set.
    double maxE1rm = 0;
    double topWeight = 0;
    int topReps = 0;
    int topRir = 2; // default moderate if nothing found
    int totalReps = 0;
    double totalTonnage = 0;

    for (final s in workingSets) {
      final e1rm = _epleyE1RM(s.weight, s.reps);
      final rir = EffortNormalizer.effectiveRir(
        s,
        bestRepsInSession: bestRepsAtWeight[s.weight],
      );
      if (e1rm > maxE1rm) {
        maxE1rm = e1rm;
        topWeight = s.weight;
        topReps = s.reps;
        topRir = rir;
      }
      totalReps += s.reps;
      totalTonnage += s.weight * s.reps;
    }

    // Smoothing: 0.7 * previous + 0.3 * current
    final prevSmoothed = history.latestSmoothedE1RM;
    final smoothed =
        prevSmoothed > 0 ? 0.7 * prevSmoothed + 0.3 * maxE1rm : maxE1rm;

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
    final e1rmRatio = (metrics.sessionE1RM / baseline).clamp(0.85, 1.10);

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

    // Plateau + avg RIR <= 1 for last 2 sessions.
    // Plateau = no increase in smoothed e1RM for >= 3 exposures
    // (smoothed_t <= max(smoothed_(t-1..t-3)) + 0.25%).
    if (history.isPlateaued && _avgRirLastNSessions(history, 2) <= 1) {
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

    // Update history with this session's data.
    final updatedHistory = history.appendSession(
      sessionE1RM: metrics.sessionE1RM,
      smoothedE1RM: metrics.smoothedE1RM,
      score: score,
      lowScoreThreshold: _lowScoreThreshold,
      improvementThreshold: _improvementThresholdPct,
    );

    // Check deload first.
    if (shouldDeload(
        score: score, metrics: metrics, history: updatedHistory)) {
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

    // Rule D: Score < 80 OR RIR_top == 0 -> -5% load OR -1 set.
    if (score < 80 || rirTop == 0) {
      return _ruleD(
        currentWeight: currentWeight,
        sets: sets,
        repMax: repMax,
        rirTop: rirTop,
        equipment: equipment,
        unit: unit,
        score: score,
        metrics: metrics,
      );
    }

    // Rule A-high: Score >= 97 AND RIR_top >= 2 -> +2%.
    if (score >= 97 && rirTop >= 2) {
      final increased = currentWeight * 1.02;
      final snapped = LoadQuantizer.snap(increased, equipment, unit);
      final clamped = LoadQuantizer.clampToWeeklyCap(
          currentWeight, snapped, equipment, unit);
      final backoff = _backoffLoad(clamped, rirTop, equipment, unit);
      return ProgressionSuggestion(
        suggestedWeight: clamped,
        suggestedReps: repMin,
        suggestedSets: sets,
        reasoning:
            'Increase load +2% (score ${score.toStringAsFixed(0)}, RIR $rirTop)',
        backoffWeight: backoff,
        score: score,
        metrics: metrics,
      );
    }

    // Rule A-low: Score >= 94 AND RIR_top >= 1 -> +1%.
    if (score >= 94 && rirTop >= 1) {
      final increased = currentWeight * 1.01;
      final snapped = LoadQuantizer.snap(increased, equipment, unit);
      final clamped = LoadQuantizer.clampToWeeklyCap(
          currentWeight, snapped, equipment, unit);
      final backoff = _backoffLoad(clamped, rirTop, equipment, unit);
      return ProgressionSuggestion(
        suggestedWeight: clamped,
        suggestedReps: repMin,
        suggestedSets: sets,
        reasoning:
            'Increase load +1% (score ${score.toStringAsFixed(0)}, RIR $rirTop)',
        backoffWeight: backoff,
        score: score,
        metrics: metrics,
      );
    }

    // Rule B: 88 <= score < 94 AND RIR_top >= 1 -> keep load, +1 rep (cap 6).
    if (score >= 88 && score < 94 && rirTop >= 1) {
      final suggestedReps = min(metrics.topSetReps + 1, 6);
      final backoff = _backoffLoad(currentWeight, rirTop, equipment, unit);
      return ProgressionSuggestion(
        suggestedWeight: currentWeight,
        suggestedReps: suggestedReps,
        suggestedSets: sets,
        reasoning:
            'Micro-progression: +1 rep (score ${score.toStringAsFixed(0)})',
        backoffWeight: backoff,
        score: score,
        metrics: metrics,
      );
    }

    // Rule C: 80 <= score < 88 -> hold/repeat.
    final backoff = _backoffLoad(currentWeight, rirTop, equipment, unit);
    return ProgressionSuggestion(
      suggestedWeight: currentWeight,
      suggestedReps: repMax,
      suggestedSets: sets,
      reasoning:
          'Hold: repeat same prescription (score ${score.toStringAsFixed(0)})',
      backoffWeight: backoff,
      score: score,
      metrics: metrics,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Epley e1RM with reps capped at 12.
  static double _epleyE1RM(double load, int reps) {
    final repsCapped = min(reps, 12);
    if (repsCapped == 0) return load;
    return load * (1 + repsCapped / 30);
  }

  /// Back-off load: top * 0.90, or top * 0.87 if RIR == 0.
  static double _backoffLoad(
    double topLoad,
    int rirTop,
    EquipmentType equipment,
    String unit,
  ) {
    final factor = rirTop == 0 ? 0.87 : 0.90;
    return LoadQuantizer.snap(topLoad * factor, equipment, unit);
  }

  /// Rule D: score < 80 OR RIR_top == 0 -> -5% load OR -1 set.
  ProgressionSuggestion _ruleD({
    required double currentWeight,
    required int sets,
    required int repMax,
    required int rirTop,
    required EquipmentType equipment,
    required String unit,
    required double score,
    required SessionMetrics metrics,
  }) {
    // Prefer -5% load. If load can't drop further (already at minimum),
    // fall back to -1 set instead.
    final reduced = currentWeight * 0.95;
    final snapped = LoadQuantizer.snap(reduced, equipment, unit);
    final backoff = _backoffLoad(snapped, rirTop, equipment, unit);

    if (snapped < currentWeight) {
      // -5% load path.
      return ProgressionSuggestion(
        suggestedWeight: snapped,
        suggestedReps: repMax,
        suggestedSets: sets,
        reasoning:
            'Reduce load -5% (score ${score.toStringAsFixed(0)}, RIR $rirTop)',
        isDeload: false,
        backoffWeight: backoff,
        score: score,
        metrics: metrics,
      );
    }

    // -1 set path (floor at 2 sets).
    final reducedSets = max(sets - 1, 2);
    return ProgressionSuggestion(
      suggestedWeight: currentWeight,
      suggestedReps: repMax,
      suggestedSets: reducedSets,
      reasoning:
          'Reduce sets -1 (score ${score.toStringAsFixed(0)}, RIR $rirTop)',
      isDeload: false,
      backoffWeight: _backoffLoad(currentWeight, rirTop, equipment, unit),
      score: score,
      metrics: metrics,
    );
  }

  /// Deload prescription: sets *= 0.6 (min 2), load *= 0.90, target RIR 3-5.
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
      reasoning: 'Deload: -10% load, reduced volume (target RIR 3-5)',
      isDeload: true,
      score: score,
      metrics: metrics,
    );
  }

  /// Estimate average top-set RIR over the last [n] sessions from score history.
  ///
  /// Uses a heuristic: if a session scored below 80, RIR was likely 0;
  /// if the effort component (lower 15%) was missing, RIR < 1.
  /// For a more precise check we look at the current metrics plus
  /// the score pattern. A score below ~85 with baseline present
  /// suggests low RIR.
  ///
  /// In practice the caller checks [ProgressionHistory.isPlateaued] first,
  /// and this helper backs it up with a coarse RIR estimate.
  double _avgRirLastNSessions(ProgressionHistory history, int n) {
    // Best-effort: use the top-set RIR from score decomposition.
    // effort_ok contributes 15 points when RIR >= 1.
    // A score near or below (100 * 0.85 * ratio) means effort_ok = 0 -> RIR 0.
    final scores = history.scoreHistory;
    if (scores.isEmpty) return 2.0; // no data, assume moderate

    final lookback = scores.length < n ? scores.length : n;
    double rirSum = 0;
    for (int i = scores.length - lookback; i < scores.length; i++) {
      // With effort_ok = 1 the minimum score at ratio=0.85 is
      // 100*(0.85*0.85+0.15) = 87.25. If score < 87 it's likely RIR 0.
      // Between 87-90 ~ RIR 1. Above 90 ~ RIR 2+.
      final s = scores[i];
      if (s < 87) {
        rirSum += 0;
      } else if (s < 91) {
        rirSum += 1;
      } else {
        rirSum += 2;
      }
    }
    return rirSum / lookback;
  }

  static double _round2(double v) => (v * 100).roundToDouble() / 100;
}
