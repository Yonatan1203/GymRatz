import 'dart:math';

import '../../../shared/models/enums.dart';
import '../../../shared/models/workout_set.dart';
import 'effort_normalizer.dart';
import 'load_quantizer.dart';
import 'models/progression_history.dart';
import 'models/session_metrics.dart';
import 'progression_strategy.dart';
import 'progression_suggestion.dart';

/// Endurance progression style selector.
///
/// A) repsFirst  — increase reps at fixed load (default)
/// B) restReduction — hold load/reps, reduce rest for density
/// C) timedDensity — fixed time block, track total reps
enum EnduranceProgressionStyle {
  repsFirst,
  restReduction,
  timedDensity,
}

/// Endurance mode progressive overload strategy.
///
/// Goal: Increase reps, density (work per time), or reduce rest at submaximal
/// loads.
///
/// Template: 2-4 sets x 12-25 reps, RIR 2-4
/// Primary metric: Density = total_tonnage / total_time_min
///
/// Three progression styles:
///
/// A) Reps-first at fixed load (default):
///    - min(reps) >= r_max AND RIR >= 2: increase load or add set (cap 4)
///    - min(reps) >= r_min AND RIR >= 2: add +1-2 reps to lowest set
///    - Else: reduce load 2.5-5% or increase rest +15-30s
///
/// B) Rest-reduction (density):
///    - Hold load and reps constant, reduce rest each session
///    - All sets achieved with RIR >= 2: next_rest = max(rest - 15, floor)
///    - rest_floor: 30s accessories, 60s compounds
///
/// C) Timed density block:
///    - Fixed time (e.g. 8 min), same load each week
///    - total_reps >= last + 2 AND RIR_end >= 2: aim +2 reps next
///    - total_reps >= last + 6 across 2 sessions: increase load, reset target
class EnduranceStrategy extends ProgressionStrategy {
  /// Seconds assumed per working set for density calculation.
  static const int _secondsPerSet = 20;

  /// Maximum number of sets allowed.
  static const int _maxSets = 4;

  /// Rest floor for compound exercises (seconds).
  static const int _restFloorCompound = 60;

  /// Rest floor for accessory exercises (seconds).
  static const int _restFloorAccessory = 30;

  /// The active progression style. Defaults to reps-first.
  final EnduranceProgressionStyle style;

  /// Whether the exercise is a compound movement (affects rest floor).
  final bool isCompound;

  /// Fixed block duration in minutes for timed density mode.
  final int timedBlockMinutes;

  /// Previous total reps for timed density comparison.
  final int? previousTotalReps;

  /// Total reps two sessions ago for timed density 2-session check.
  final int? previousTotalReps2;

  /// Current rest between sets in seconds (for rest-reduction mode).
  final int? currentRestSeconds;

  EnduranceStrategy({
    this.style = EnduranceProgressionStyle.repsFirst,
    this.isCompound = true,
    this.timedBlockMinutes = 8,
    this.previousTotalReps,
    this.previousTotalReps2,
    this.currentRestSeconds,
  });

  @override
  SessionMetrics computeMetrics({
    required List<WorkoutSet> performedSets,
    required int repMin,
    required int repMax,
    required int targetRir,
    required ProgressionHistory history,
  }) {
    // Normalize effort so nullable RIR is filled in.
    final normalized = EffortNormalizer.normalizeSets(performedSets);
    final workingSets =
        normalized.where((s) => s.completed && !s.isWarmup).toList();

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

      final rir = EffortNormalizer.effectiveRir(s);
      if (rir <= 3) hardSets++;

      if (s.weight > topWeight ||
          (s.weight == topWeight && s.reps > topReps)) {
        topWeight = s.weight;
        topReps = s.reps;
      }
    }

    // Last set RIR for effort tracking (via EffortNormalizer).
    final lastSetRir = EffortNormalizer.effectiveRir(workingSets.last);

    // Density: total_tonnage / total_time_min
    // Time = (20sec * num_sets) + total_rest_seconds
    final totalTimeSeconds =
        (_secondsPerSet * workingSets.length) + totalRestSeconds;
    final totalTimeMin = totalTimeSeconds / 60.0;
    final density = totalTimeMin > 0 ? totalTonnage / totalTimeMin : 0.0;

    // Target total reps = number of working sets x repMax.
    final targetTotalReps = workingSets.length * repMax;

    // e1RM smoothing (less relevant for endurance but kept for interface).
    final sessionE1rm = _epleyE1RM(topWeight, topReps);
    final prevSmoothed = history.latestSmoothedE1RM;
    final smoothed = prevSmoothed > 0
        ? 0.7 * prevSmoothed + 0.3 * sessionE1rm
        : sessionE1rm;

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
    // density_t <= max(density_(t-1..t-3)) + 1%
    return history.isDensityPlateaued;
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

    // Normalize sets for consistent RIR access.
    final normalized = EffortNormalizer.normalizeSets(performedSets);
    final workingSets =
        normalized.where((s) => s.completed && !s.isWarmup).toList();
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

    // Dispatch to the active progression style.
    switch (style) {
      case EnduranceProgressionStyle.repsFirst:
        return _suggestRepsFirst(
          workingSets: workingSets,
          currentWeight: currentWeight,
          sets: sets,
          repMin: repMin,
          repMax: repMax,
          equipment: equipment,
          unit: unit,
          score: score,
          metrics: metrics,
        );

      case EnduranceProgressionStyle.restReduction:
        return _suggestRestReduction(
          workingSets: workingSets,
          currentWeight: currentWeight,
          sets: sets,
          repMin: repMin,
          repMax: repMax,
          equipment: equipment,
          unit: unit,
          score: score,
          metrics: metrics,
        );

      case EnduranceProgressionStyle.timedDensity:
        return _suggestTimedDensity(
          workingSets: workingSets,
          currentWeight: currentWeight,
          sets: sets,
          repMin: repMin,
          repMax: repMax,
          equipment: equipment,
          unit: unit,
          score: score,
          metrics: metrics,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Style A: Reps-first at fixed load
  // ---------------------------------------------------------------------------

  ProgressionSuggestion _suggestRepsFirst({
    required List<WorkoutSet> workingSets,
    required double currentWeight,
    required int sets,
    required int repMin,
    required int repMax,
    required EquipmentType equipment,
    required String unit,
    required double score,
    required SessionMetrics metrics,
  }) {
    final repsPerSet = workingSets.map((s) => s.reps).toList();
    final minReps = repsPerSet.isNotEmpty ? repsPerSet.reduce(min) : 0;
    final lastSetRir =
        workingSets.isNotEmpty ? EffortNormalizer.effectiveRir(workingSets.last) : 0;

    // Rule C: Reduce -- min(reps) < r_min OR RIR_last < 2
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

    // Rule A: Increase -- min(reps) >= r_max AND RIR_last >= 2
    if (minReps >= repMax && lastSetRir >= 2) {
      // Prefer adding a set if below cap.
      if (sets < _maxSets) {
        return ProgressionSuggestion(
          suggestedWeight: currentWeight,
          suggestedReps: repMax,
          suggestedSets: sets + 1,
          reasoning:
              'Add 1 set ($sets -> ${sets + 1}) -- all sets at top of range',
          backoffWeight:
              LoadQuantizer.snap(currentWeight * 0.90, equipment, unit),
          score: score,
          metrics: metrics,
        );
      }

      // Already at max sets -- increase load by smallest increment.
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

    // Rule B: Add reps -- min(reps) >= r_min AND RIR_last >= 2
    if (minReps >= repMin && lastSetRir >= 2) {
      final targetRep = min(minReps + 2, repMax);
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
      reasoning:
          'Hold: repeat same prescription (score ${score.toStringAsFixed(0)})',
      backoffWeight:
          LoadQuantizer.snap(currentWeight * 0.90, equipment, unit),
      score: score,
      metrics: metrics,
    );
  }

  // ---------------------------------------------------------------------------
  // Style B: Rest-reduction (density)
  // ---------------------------------------------------------------------------

  ProgressionSuggestion _suggestRestReduction({
    required List<WorkoutSet> workingSets,
    required double currentWeight,
    required int sets,
    required int repMin,
    required int repMax,
    required EquipmentType equipment,
    required String unit,
    required double score,
    required SessionMetrics metrics,
  }) {
    final lastSetRir =
        workingSets.isNotEmpty ? EffortNormalizer.effectiveRir(workingSets.last) : 0;
    final repsPerSet = workingSets.map((s) => s.reps).toList();
    final minReps = repsPerSet.isNotEmpty ? repsPerSet.reduce(min) : 0;
    final restFloor = isCompound ? _restFloorCompound : _restFloorAccessory;
    final currentRest = currentRestSeconds ??
        (workingSets.isNotEmpty ? workingSets.first.restSeconds : 90);

    // All sets achieved (min reps >= target) and RIR >= 2: reduce rest.
    if (minReps >= repMin && lastSetRir >= 2) {
      final nextRest = max(currentRest - 15, restFloor);
      final didReduce = nextRest < currentRest;
      return ProgressionSuggestion(
        suggestedWeight: currentWeight,
        suggestedReps: repMax,
        suggestedSets: sets,
        suggestedRestSeconds: nextRest,
        reasoning: didReduce
            ? 'Reduce rest ${currentRest}s -> ${nextRest}s (density progression)'
            : 'Rest at floor (${restFloor}s) -- consider switching to reps-first or increasing load',
        backoffWeight:
            LoadQuantizer.snap(currentWeight * 0.90, equipment, unit),
        score: score,
        metrics: metrics,
      );
    }

    // Not all sets achieved or RIR too low: increase rest +15-30s.
    final addedRest = min(currentRest + 15, currentRest + 30);
    return ProgressionSuggestion(
      suggestedWeight: currentWeight,
      suggestedReps: repMax,
      suggestedSets: sets,
      suggestedRestSeconds: addedRest,
      reasoning:
          'Increase rest ${currentRest}s -> ${addedRest}s (min reps $minReps, RIR $lastSetRir)',
      backoffWeight:
          LoadQuantizer.snap(currentWeight * 0.90, equipment, unit),
      score: score,
      metrics: metrics,
    );
  }

  // ---------------------------------------------------------------------------
  // Style C: Timed density block
  // ---------------------------------------------------------------------------

  ProgressionSuggestion _suggestTimedDensity({
    required List<WorkoutSet> workingSets,
    required double currentWeight,
    required int sets,
    required int repMin,
    required int repMax,
    required EquipmentType equipment,
    required String unit,
    required double score,
    required SessionMetrics metrics,
  }) {
    final totalReps = metrics.totalReps;
    final lastSetRir =
        workingSets.isNotEmpty ? EffortNormalizer.effectiveRir(workingSets.last) : 0;
    final prevReps = previousTotalReps ?? 0;
    final prevReps2 = previousTotalReps2 ?? 0;
    final blockDurationSec = timedBlockMinutes * 60;

    // Check 2-session cumulative improvement: increase load, reset target.
    if (prevReps > 0 && prevReps2 > 0) {
      final cumulativeGain = totalReps - prevReps2;
      if (cumulativeGain >= 6 && lastSetRir >= 2) {
        final increment = LoadQuantizer.minIncrement(equipment, unit);
        final increased = currentWeight + increment;
        final snapped = LoadQuantizer.snap(increased, equipment, unit);
        return ProgressionSuggestion(
          suggestedWeight: snapped,
          suggestedReps: repMin,
          suggestedSets: sets,
          suggestedDuration: blockDurationSec,
          reasoning:
              'Timed block: +$cumulativeGain reps over 2 sessions (>=6) -- increase load +${increment.toStringAsFixed(1)} $unit, reset target',
          backoffWeight:
              LoadQuantizer.snap(snapped * 0.90, equipment, unit),
          score: score,
          metrics: metrics,
        );
      }
    }

    // Single-session check: total_reps >= last + 2 AND RIR_end >= 2.
    if (prevReps > 0 && totalReps >= prevReps + 2 && lastSetRir >= 2) {
      final nextTarget = totalReps + 2;
      return ProgressionSuggestion(
        suggestedWeight: currentWeight,
        suggestedReps: nextTarget,
        suggestedSets: sets,
        suggestedDuration: blockDurationSec,
        reasoning:
            'Timed block: $totalReps reps (prev $prevReps, +${totalReps - prevReps}) -- aim $nextTarget next session',
        backoffWeight:
            LoadQuantizer.snap(currentWeight * 0.90, equipment, unit),
        score: score,
        metrics: metrics,
      );
    }

    // No improvement or first session: hold and aim for +2 next time.
    final nextTarget = prevReps > 0 ? prevReps + 2 : totalReps + 2;
    return ProgressionSuggestion(
      suggestedWeight: currentWeight,
      suggestedReps: nextTarget,
      suggestedSets: sets,
      suggestedDuration: blockDurationSec,
      reasoning: prevReps > 0
          ? 'Timed block: $totalReps reps (target was ${prevReps + 2}) -- aim $nextTarget next'
          : 'Timed block: $totalReps reps -- aim $nextTarget next session',
      backoffWeight:
          LoadQuantizer.snap(currentWeight * 0.90, equipment, unit),
      score: score,
      metrics: metrics,
    );
  }

  // ---------------------------------------------------------------------------
  // Deload
  // ---------------------------------------------------------------------------

  /// Deload: sets *= 0.6, increase rest +15-30s, keep load or *0.9, RIR 3-5.
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

    // Increase rest +15-30s for deload.
    final currentRest = currentRestSeconds ?? 90;
    final deloadRest = currentRest + 30;

    return ProgressionSuggestion(
      suggestedWeight: snapped,
      suggestedReps: repMax,
      suggestedSets: deloadSets,
      suggestedRestSeconds: deloadRest,
      reasoning:
          'Deload: -10% load, $deloadSets sets, rest ${deloadRest}s (RIR 3-5)',
      isDeload: true,
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

  static double _round2(double v) => (v * 100).roundToDouble() / 100;
}
