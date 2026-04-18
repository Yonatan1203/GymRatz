import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/features/progression/domain/strength_strategy.dart';
import 'package:gymratz/features/progression/domain/models/progression_history.dart';
import 'package:gymratz/features/progression/domain/models/session_metrics.dart';
import 'package:gymratz/shared/models/enums.dart';
import 'package:gymratz/shared/models/workout_set.dart';

void main() {
  late StrengthStrategy strategy;

  setUp(() {
    strategy = StrengthStrategy();
  });

  group('e1RM calculation', () {
    test('computes e1RM using Epley formula', () {
      // 100kg x 5 reps → e1RM = 100 * (1 + 5/30) = 116.67
      final metrics = strategy.computeMetrics(
        performedSets: [
          const WorkoutSet(weight: 100, reps: 5, rir: 2, completed: true),
          const WorkoutSet(weight: 100, reps: 5, rir: 2, completed: true),
          const WorkoutSet(weight: 100, reps: 4, rir: 1, completed: true),
        ],
        repMin: 3,
        repMax: 5,
        targetRir: 2,
        history: const ProgressionHistory(),
      );
      expect(metrics.sessionE1RM, closeTo(116.67, 0.1));
    });

    test('caps reps at 12 for e1RM', () {
      // 60kg x 15 reps → capped to 12 → e1RM = 60 * (1 + 12/30) = 84
      final metrics = strategy.computeMetrics(
        performedSets: [
          const WorkoutSet(weight: 60, reps: 15, rir: 3, completed: true),
        ],
        repMin: 1,
        repMax: 6,
        targetRir: 2,
        history: const ProgressionHistory(),
      );
      expect(metrics.sessionE1RM, closeTo(84, 0.1));
    });

    test('ignores warmup sets', () {
      final metrics = strategy.computeMetrics(
        performedSets: [
          const WorkoutSet(
              weight: 60, reps: 10, rir: 5, completed: true, isWarmup: true),
          const WorkoutSet(weight: 100, reps: 5, rir: 2, completed: true),
        ],
        repMin: 3,
        repMax: 5,
        targetRir: 2,
        history: const ProgressionHistory(),
      );
      expect(metrics.sessionE1RM, closeTo(116.67, 0.1));
    });

    test('ignores incomplete sets', () {
      final metrics = strategy.computeMetrics(
        performedSets: [
          const WorkoutSet(weight: 120, reps: 3, rir: 1, completed: false),
          const WorkoutSet(weight: 100, reps: 5, rir: 2, completed: true),
        ],
        repMin: 3,
        repMax: 5,
        targetRir: 2,
        history: const ProgressionHistory(),
      );
      expect(metrics.sessionE1RM, closeTo(116.67, 0.1));
    });

    test('applies smoothing with history', () {
      final metrics = strategy.computeMetrics(
        performedSets: [
          const WorkoutSet(weight: 100, reps: 5, rir: 2, completed: true),
        ],
        repMin: 3,
        repMax: 5,
        targetRir: 2,
        history: const ProgressionHistory(smoothedE1rmHistory: [110.0]),
      );
      // smoothed = 0.7 * 110 + 0.3 * 116.67 = 77 + 35 = 112
      expect(metrics.smoothedE1RM, closeTo(112, 0.1));
    });

    test('no smoothing when no previous smoothed value', () {
      final metrics = strategy.computeMetrics(
        performedSets: [
          const WorkoutSet(weight: 100, reps: 5, rir: 2, completed: true),
        ],
        repMin: 3,
        repMax: 5,
        targetRir: 2,
        history: const ProgressionHistory(),
      );
      // No previous → smoothed = session e1RM
      expect(metrics.smoothedE1RM, closeTo(116.67, 0.1));
    });

    test('returns empty metrics when no working sets', () {
      final metrics = strategy.computeMetrics(
        performedSets: [
          const WorkoutSet(
              weight: 60, reps: 10, rir: 5, completed: true, isWarmup: true),
        ],
        repMin: 3,
        repMax: 5,
        targetRir: 2,
        history: const ProgressionHistory(),
      );
      expect(metrics.sessionE1RM, 0);
    });

    test('tracks top set metrics correctly', () {
      final metrics = strategy.computeMetrics(
        performedSets: [
          const WorkoutSet(weight: 80, reps: 5, rir: 2, completed: true),
          const WorkoutSet(weight: 100, reps: 3, rir: 1, completed: true),
          const WorkoutSet(weight: 90, reps: 4, rir: 2, completed: true),
        ],
        repMin: 3,
        repMax: 5,
        targetRir: 2,
        history: const ProgressionHistory(),
      );
      // 80*(1+5/30)=93.33, 100*(1+3/30)=110, 90*(1+4/30)=102
      expect(metrics.sessionE1RM, closeTo(110, 0.1));
      expect(metrics.topSetWeight, 100);
      expect(metrics.topSetReps, 3);
      expect(metrics.topSetRir, 1);
    });
  });

  group('score calculation', () {
    test('high score when e1RM exceeds baseline', () {
      final metrics = const SessionMetrics(sessionE1RM: 120, topSetRir: 2);
      final history = const ProgressionHistory(e1rmHistory: [115, 116, 117]);
      final score = strategy.computeScore(metrics: metrics, history: history);
      // baseline = median(115,116,117) = 116
      // ratio = clamp(120/116, 0.85, 1.10) = clamp(1.034, ...) = 1.034
      // effort_ok = 1
      // score = 100 * (0.85*1.034 + 0.15*1) = 100*(0.879 + 0.15) = 102.9
      expect(score, greaterThan(90));
    });

    test('low score when e1RM drops significantly', () {
      final metrics = const SessionMetrics(sessionE1RM: 95, topSetRir: 0);
      final history = const ProgressionHistory(e1rmHistory: [115, 116, 117]);
      // baseline = 116
      // ratio = clamp(95/116, 0.85, 1.10) = clamp(0.819, ...) = 0.85
      // effort_ok = 0
      // score = 100 * (0.85*0.85 + 0.15*0) = 72.25
      final score = strategy.computeScore(metrics: metrics, history: history);
      expect(score, lessThan(80));
    });

    test('neutral score with no history', () {
      final metrics = const SessionMetrics(sessionE1RM: 100, topSetRir: 2);
      final history = const ProgressionHistory();
      final score = strategy.computeScore(metrics: metrics, history: history);
      expect(score, equals(85)); // default neutral
    });

    test('penalises RIR of 0', () {
      final metrics1 = const SessionMetrics(sessionE1RM: 116, topSetRir: 2);
      final metrics2 = const SessionMetrics(sessionE1RM: 116, topSetRir: 0);
      final history = const ProgressionHistory(e1rmHistory: [115, 116, 117]);

      final score1 = strategy.computeScore(metrics: metrics1, history: history);
      final score2 = strategy.computeScore(metrics: metrics2, history: history);
      expect(score1, greaterThan(score2));
    });

    test('clamps e1rm ratio to range 0.85-1.10', () {
      // Very high session should be clamped at 1.10
      final metricsHigh = const SessionMetrics(sessionE1RM: 200, topSetRir: 2);
      final history = const ProgressionHistory(e1rmHistory: [100, 100, 100]);
      final scoreHigh =
          strategy.computeScore(metrics: metricsHigh, history: history);
      // ratio clamped at 1.10 → score = 100*(0.85*1.10 + 0.15*1) = 108.5
      expect(scoreHigh, closeTo(108.5, 0.1));
    });
  });

  group('progression rules', () {
    test('increases load when score is high and RIR comfortable', () {
      // Need score >= 94 AND RIR >= 1
      // Using e1rm that gives high ratio vs baseline
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 100, reps: 5, rir: 3, completed: true),
          const WorkoutSet(weight: 100, reps: 5, rir: 3, completed: true),
          const WorkoutSet(weight: 100, reps: 5, rir: 2, completed: true),
        ],
        currentWeight: 100,
        repMin: 3,
        repMax: 5,
        targetRir: 2,
        equipment: EquipmentType.barbell,
        unit: 'kg',
        history: const ProgressionHistory(e1rmHistory: [115, 115.5, 116]),
      );
      expect(result.suggestedWeight, greaterThan(100));
      expect(result.isDeload, false);
    });

    test('holds when score is moderate', () {
      // session e1RM = 100*(1+3/30) = 110
      // baseline = 116 → ratio = 110/116 = 0.948
      // But we want score 80-87, so we need RIR 0 to drop effort penalty
      // Actually for hold we need score 80-87 AND RIR >= 1
      // ratio needs to be ~0.85-0.90 range
      // Use baseline ~128 → ratio = 110/128 = 0.859
      // score = 100*(0.85*0.859 + 0.15*1) = 100*(0.73+0.15) = 88
      // That's in 88-93 → micro-prog. Need higher baseline.
      // Use baseline ~130 → ratio = 110/130 = 0.846 → clamped to 0.85
      // score = 100*(0.85*0.85 + 0.15*1) = 87.25
      // And session e1RM = 110 vs baseline 130 → 110/130*0.97 = not < 0.97*130=126.1
      // Actually 110 < 126.1 → deload triggers!
      // To avoid deload: need session_e1RM >= baseline * 0.97
      // So we need baseline where ratio is low but e1RM >= baseline*0.97
      // baseline*0.97 <= 110 → baseline <= 113.4
      // ratio = 110/113 = 0.973 → score = 100*(0.85*0.973 + 0.15*0) = 82.7 (with RIR 0)
      // But RIR 0 triggers rule D. Need RIR >= 1 for hold.
      // With RIR >= 1: score = 100*(0.85*0.973 + 0.15*1) = 97.7 → too high
      // The only way to get score 80-87 with RIR >= 1 is ratio ~0.85
      // But that means e1RM/baseline = 0.85 → e1RM < baseline*0.97 → deload
      // So hold with RIR >= 1 can only occur when no deload trigger
      // Need exposuresSinceImprovement < 3 to avoid plateau deload
      // AND session_e1RM >= baseline * 0.97
      // Actually, let's set history with only 1-2 entries so baseline = last entry
      // baseline = 113, session = 110 → 110 >= 113*0.97=109.6 ✓
      // ratio = 110/113 = 0.973, effort_ok = 1
      // score = 100*(0.85*0.973 + 0.15*1) = 97.7 → still too high for hold

      // The math means hold zone (80-87) with effort_ok=1 needs ratio 0.765-0.847
      // which always means session << baseline → deload. So hold mainly happens with RIR=0.
      // But RIR=0 triggers rule D. Hmm.
      // Actually rule D is "Score < 80 OR RIR_top == 0". So score 80-87 with RIR 0 → rule D.
      // Score 80-87 with RIR >= 1 → need ratio = (score/100 - 0.15)/0.85 = ~0.765-0.847
      // That means session/baseline < 0.85 → clamped to 0.85 → min score with effort=1 is 87.25
      // So hold range with RIR>=1 is score ~87.25 (when ratio clamped at 0.85)
      // Let's test exactly at the boundary: score ~87, verify it holds
      final result = strategy.suggest(
        performedSets: [
          // Use weight that gives e1RM just at baseline*0.97
          const WorkoutSet(weight: 95, reps: 3, rir: 1, completed: true),
          const WorkoutSet(weight: 95, reps: 3, rir: 1, completed: true),
          const WorkoutSet(weight: 95, reps: 3, rir: 1, completed: true),
        ],
        currentWeight: 100,
        repMin: 3,
        repMax: 5,
        targetRir: 2,
        equipment: EquipmentType.barbell,
        unit: 'kg',
        // session e1RM = 95*(1+3/30) = 104.5
        // baseline with 2 entries = last = 107
        // 104.5 >= 107*0.97 = 103.79 ✓ no perf drop deload
        // ratio = 104.5/107 = 0.977 → score = 100*(0.85*0.977+0.15*1) = 98.0 → too high
        // Need baseline higher. Use 3 entries, median.
        // history: [119, 120, 121] → baseline = 120
        // 104.5 < 120*0.97 = 116.4 → deload! Can't avoid it.
        // The math shows hold is very narrow. Let's just test with no history (neutral=85).
        history: const ProgressionHistory(),
      );
      // No history → score = 85 (neutral) → hold zone, no deload (no baseline)
      expect(result.isDeload, false);
      expect(result.suggestedWeight, equals(100)); // hold = same weight
      expect(result.reasoning, contains('Hold'));
    });

    test('reduces load when RIR is 0 (rule D)', () {
      // RIR == 0 triggers rule D regardless of score
      // Use no history to avoid deload trigger (no baseline for perf drop check)
      // But we need e1rmHistory for score != neutral...
      // Actually with RIR=0 and any score, rule D fires.
      // Use history where session e1RM >= baseline*0.97 to avoid deload.
      final result = strategy.suggest(
        performedSets: [
          // e1RM = 100*(1+5/30) = 116.67
          const WorkoutSet(weight: 100, reps: 5, rir: 0, completed: true),
          const WorkoutSet(weight: 100, reps: 5, rir: 0, completed: true),
        ],
        currentWeight: 100,
        repMin: 3,
        repMax: 5,
        targetRir: 2,
        equipment: EquipmentType.barbell,
        unit: 'kg',
        // baseline = 116, session = 116.67 >= 116*0.97=112.5 ✓
        // ratio = 116.67/116 = 1.006, effort_ok = 0
        // score = 100*(0.85*1.006 + 0) = 85.5
        // RIR == 0 → rule D: reduce -5%
        history: const ProgressionHistory(e1rmHistory: [115, 116, 117]),
      );
      expect(result.suggestedWeight, lessThan(100));
      expect(result.isDeload, false);
    });

    test('deloads when plateau detected with low RIR', () {
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 100, reps: 3, rir: 0, completed: true),
          const WorkoutSet(weight: 100, reps: 3, rir: 0, completed: true),
        ],
        currentWeight: 100,
        repMin: 3,
        repMax: 5,
        targetRir: 2,
        equipment: EquipmentType.barbell,
        unit: 'kg',
        history: ProgressionHistory(
          e1rmHistory: [110, 110, 110, 110],
          exposuresSinceImprovement: 4,
          scoreHistory: [75, 72],
        ),
      );
      expect(result.isDeload, true);
      expect(result.suggestedWeight, lessThan(100));
    });

    test('snaps weight to equipment increment', () {
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 100, reps: 5, rir: 3, completed: true),
          const WorkoutSet(weight: 100, reps: 5, rir: 3, completed: true),
          const WorkoutSet(weight: 100, reps: 5, rir: 3, completed: true),
        ],
        currentWeight: 100,
        repMin: 3,
        repMax: 5,
        targetRir: 2,
        equipment: EquipmentType.barbell,
        unit: 'kg',
        history: const ProgressionHistory(e1rmHistory: [115, 115.5, 116]),
      );
      // Weight should be snapped to 2.5kg increments for barbell
      expect(result.suggestedWeight % 2.5, equals(0));
    });
  });

  group('deload detection', () {
    test('triggers deload on plateau with low RIR', () {
      final deload = strategy.shouldDeload(
        score: 80,
        metrics: const SessionMetrics(topSetRir: 1, sessionE1RM: 110),
        history: const ProgressionHistory(
          exposuresSinceImprovement: 4,
          e1rmHistory: [110, 110, 110],
        ),
      );
      expect(deload, true);
    });

    test('triggers deload on performance drop', () {
      final deload = strategy.shouldDeload(
        score: 70,
        metrics: const SessionMetrics(topSetRir: 2, sessionE1RM: 105),
        history: const ProgressionHistory(e1rmHistory: [115, 116, 117]),
      );
      // baseline = 116, session = 105, 105 < 116*0.97 = 112.52 → deload
      expect(deload, true);
    });

    test('no deload when performing well', () {
      final deload = strategy.shouldDeload(
        score: 95,
        metrics: const SessionMetrics(topSetRir: 2, sessionE1RM: 120),
        history: const ProgressionHistory(e1rmHistory: [115, 116, 117]),
      );
      expect(deload, false);
    });

    test('no deload on plateau with comfortable RIR', () {
      final deload = strategy.shouldDeload(
        score: 85,
        metrics: const SessionMetrics(topSetRir: 3, sessionE1RM: 110),
        history: const ProgressionHistory(
          exposuresSinceImprovement: 4,
          e1rmHistory: [110, 110, 110],
        ),
      );
      // Plateaued but RIR > 1 → no deload
      expect(deload, false);
    });
  });

  group('deload prescription', () {
    test('reduces sets and load', () {
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 100, reps: 3, rir: 1, completed: true),
          const WorkoutSet(weight: 100, reps: 3, rir: 1, completed: true),
          const WorkoutSet(weight: 100, reps: 3, rir: 1, completed: true),
          const WorkoutSet(weight: 100, reps: 3, rir: 1, completed: true),
          const WorkoutSet(weight: 100, reps: 3, rir: 0, completed: true),
        ],
        currentWeight: 100,
        repMin: 3,
        repMax: 5,
        targetRir: 2,
        equipment: EquipmentType.barbell,
        unit: 'kg',
        history: const ProgressionHistory(
          e1rmHistory: [110, 110, 110],
          exposuresSinceImprovement: 4,
        ),
      );
      // top RIR across sets: the set with highest e1RM is one with rir=1 or 0
      // All sets: 100*(1+3/30)=110. topRir will be from the first set found with max e1RM
      // Plateau + RIR <= 1 → deload
      expect(result.isDeload, true);
      expect(result.suggestedWeight, closeTo(90, 1)); // 100 * 0.90
      // sets * 0.6 = 5 * 0.6 = 3, min 2
      expect(result.suggestedSets, equals(3));
    });
  });

  group('backoff sets', () {
    test('backoff weight is 90% of top load normally', () {
      final result = strategy.suggest(
        performedSets: [
          const WorkoutSet(weight: 100, reps: 5, rir: 2, completed: true),
          const WorkoutSet(weight: 100, reps: 5, rir: 2, completed: true),
        ],
        currentWeight: 100,
        repMin: 3,
        repMax: 5,
        targetRir: 2,
        equipment: EquipmentType.barbell,
        unit: 'kg',
        history: const ProgressionHistory(),
      );
      // No history → neutral score 85 → hold
      // backoff = 100 * 0.90 = 90
      expect(result.backoffWeight, closeTo(90, 1));
    });

    test('backoff weight is 87% when RIR was 0', () {
      // Use data where session e1RM >= baseline*0.97 to avoid deload
      // but RIR == 0 triggers rule D (reduce -5%)
      final result = strategy.suggest(
        performedSets: [
          // e1RM = 100*(1+5/30) = 116.67
          const WorkoutSet(weight: 100, reps: 5, rir: 0, completed: true),
          const WorkoutSet(weight: 100, reps: 5, rir: 0, completed: true),
        ],
        currentWeight: 100,
        repMin: 3,
        repMax: 5,
        targetRir: 2,
        equipment: EquipmentType.barbell,
        unit: 'kg',
        // baseline = 116, session = 116.67 >= 112.52 ✓ no deload
        history: const ProgressionHistory(e1rmHistory: [115, 116, 117]),
      );
      // RIR == 0 → rule D: reduce -5% → suggestedWeight = snap(95) = 95
      // backoff = 95 * 0.87 = 82.65 → snap to 82.5
      expect(result.isDeload, false);
      expect(result.backoffWeight, isNotNull);
      expect(result.backoffWeight!, lessThan(90));
    });
  });
}
