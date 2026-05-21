import '../../../shared/models/enums.dart';
import '../../../shared/models/workout_set.dart';

class SessionSummary {
  final int repsMin;
  final double repsAvg;
  final int rirMin;
  final double rirAvg;
  final double maxWeight;
  final RangeStatus rangeStatus;
  final EffortStatus effortStatus;

  const SessionSummary({
    required this.repsMin,
    required this.repsAvg,
    required this.rirMin,
    required this.rirAvg,
    required this.maxWeight,
    required this.rangeStatus,
    required this.effortStatus,
  });
}

class SessionAnalyzer {
  /// Compute per-exercise session summary from working sets only.
  static SessionSummary analyze({
    required List<WorkoutSet> sets,
    required int repMin,
    required int repMax,
    required int targetRir,
  }) {
    final workingSets = sets.where((s) => !s.isWarmup && s.completed).toList();
    if (workingSets.isEmpty) {
      return SessionSummary(
        repsMin: 0,
        repsAvg: 0,
        rirMin: 0,
        rirAvg: 0,
        maxWeight: 0,
        rangeStatus: RangeStatus.belowRange,
        effortStatus: EffortStatus.rirLow,
      );
    }

    final reps = workingSets.map((s) => s.reps).toList();
    // Use effective RIR: default to 2 if null.
    final rirs = workingSets.map((s) => s.rir ?? 2).toList();
    final weights = workingSets.map((s) => s.weight).toList();

    final repsMinVal = reps.reduce((a, b) => a < b ? a : b);
    final repsAvgVal = reps.reduce((a, b) => a + b) / reps.length;
    final rirMinVal = rirs.reduce((a, b) => a < b ? a : b);
    final rirAvgVal = rirs.reduce((a, b) => a + b) / rirs.length;
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);

    // Range status
    RangeStatus rangeStatus;
    if (repsMinVal < repMin) {
      rangeStatus = RangeStatus.belowRange;
    } else if (repsMinVal > repMax) {
      rangeStatus = RangeStatus.aboveRange;
    } else {
      rangeStatus = RangeStatus.inRange;
    }

    // Effort status
    EffortStatus effortStatus;
    if (rirMinVal < targetRir) {
      effortStatus = EffortStatus.rirLow;
    } else if (rirAvgVal > targetRir + 1) {
      effortStatus = EffortStatus.rirHigh;
    } else {
      effortStatus = EffortStatus.rirOnTarget;
    }

    return SessionSummary(
      repsMin: repsMinVal,
      repsAvg: repsAvgVal,
      rirMin: rirMinVal,
      rirAvg: rirAvgVal,
      maxWeight: maxWeight,
      rangeStatus: rangeStatus,
      effortStatus: effortStatus,
    );
  }
}
