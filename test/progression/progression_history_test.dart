import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/features/progression/domain/models/progression_history.dart';

void main() {
  const lowThreshold = 75.0;
  const improvementThreshold = 0.25;

  group('ProgressionHistory.appendSession — basic counters', () {
    test('on empty history initialises all counters to zero', () {
      final result = const ProgressionHistory().appendSession(
        sessionE1RM: 100,
        smoothedE1RM: 100,
        score: 80,
        lowScoreThreshold: lowThreshold,
        improvementThreshold: improvementThreshold,
      );
      expect(result.consecutiveLowScores, 0);
      expect(result.exposuresSinceImprovement, 0);
      expect(result.e1rmHistory, [100.0]);
    });

    test('score improvement resets exposuresSinceImprovement to 0', () {
      // First session establishes baseline smoothedE1RM = 100.
      final first = const ProgressionHistory().appendSession(
        sessionE1RM: 100,
        smoothedE1RM: 100,
        score: 80,
        lowScoreThreshold: lowThreshold,
        improvementThreshold: improvementThreshold,
      );
      // Second session: smoothedE1RM > 100 * (1 + 0.25/100) → improvement.
      final second = first.appendSession(
        sessionE1RM: 102,
        smoothedE1RM: 100.3,
        score: 85,
        lowScoreThreshold: lowThreshold,
        improvementThreshold: improvementThreshold,
      );
      expect(second.exposuresSinceImprovement, 0);
    });

    test('no improvement increments exposuresSinceImprovement', () {
      final first = const ProgressionHistory().appendSession(
        sessionE1RM: 100,
        smoothedE1RM: 100,
        score: 80,
        lowScoreThreshold: lowThreshold,
        improvementThreshold: improvementThreshold,
      );
      final second = first.appendSession(
        sessionE1RM: 100,
        smoothedE1RM: 100,
        score: 80,
        lowScoreThreshold: lowThreshold,
        improvementThreshold: improvementThreshold,
      );
      expect(second.exposuresSinceImprovement, 1);
    });
  });

  group('ProgressionHistory.appendSession — improvement threshold boundary', () {
    test('strictly above 0.25% threshold resets exposures', () {
      final first = const ProgressionHistory().appendSession(
        sessionE1RM: 100,
        smoothedE1RM: 100,
        score: 80,
        lowScoreThreshold: lowThreshold,
        improvementThreshold: improvementThreshold,
      );
      // Threshold = 100.25; pass 100.26 (strictly above) → reset.
      final second = first.appendSession(
        sessionE1RM: 100.26,
        smoothedE1RM: 100.26,
        score: 80,
        lowScoreThreshold: lowThreshold,
        improvementThreshold: improvementThreshold,
      );
      expect(second.exposuresSinceImprovement, 0);
    });

    test('exactly at threshold (100.25) does NOT reset — strict > boundary', () {
      final first = const ProgressionHistory().appendSession(
        sessionE1RM: 100,
        smoothedE1RM: 100,
        score: 80,
        lowScoreThreshold: lowThreshold,
        improvementThreshold: improvementThreshold,
      );
      // 100 * (1 + 0.25/100) = 100.25 — strict >, so exactly equal does not reset.
      final second = first.appendSession(
        sessionE1RM: 100.25,
        smoothedE1RM: 100.25,
        score: 80,
        lowScoreThreshold: lowThreshold,
        improvementThreshold: improvementThreshold,
      );
      expect(second.exposuresSinceImprovement, 1);
    });

    test('exactly at previous smoothed (no improvement) increments', () {
      final first = const ProgressionHistory().appendSession(
        sessionE1RM: 100,
        smoothedE1RM: 100,
        score: 80,
        lowScoreThreshold: lowThreshold,
        improvementThreshold: improvementThreshold,
      );
      final second = first.appendSession(
        sessionE1RM: 100,
        smoothedE1RM: 100,
        score: 80,
        lowScoreThreshold: lowThreshold,
        improvementThreshold: improvementThreshold,
      );
      expect(second.exposuresSinceImprovement, 1);
    });
  });

  group('ProgressionHistory.appendSession — trimming at 20 entries', () {
    test('list is trimmed to 20 entries after 21 appends', () {
      ProgressionHistory h = const ProgressionHistory();
      for (int i = 0; i < 21; i++) {
        h = h.appendSession(
          sessionE1RM: i.toDouble(),
          smoothedE1RM: i.toDouble(),
          score: 80,
          lowScoreThreshold: lowThreshold,
          improvementThreshold: improvementThreshold,
        );
      }
      expect(h.e1rmHistory.length, 20);
      expect(h.scoreHistory.length, 20);
      expect(h.smoothedE1rmHistory.length, 20);
    });

    test('list of exactly 20 entries is not trimmed further', () {
      ProgressionHistory h = const ProgressionHistory();
      for (int i = 0; i < 20; i++) {
        h = h.appendSession(
          sessionE1RM: i.toDouble(),
          smoothedE1RM: i.toDouble(),
          score: 80,
          lowScoreThreshold: lowThreshold,
          improvementThreshold: improvementThreshold,
        );
      }
      expect(h.e1rmHistory.length, 20);
    });
  });

  group('ProgressionHistory fromJson/toJson round-trip', () {
    test('round-trip preserves all seven fields', () {
      final original = const ProgressionHistory(
        e1rmHistory: [100.0, 102.5],
        smoothedE1rmHistory: [99.0, 101.0],
        scoreHistory: [80.0, 85.0],
        densityHistory: [1.2, 1.3],
        weeklyHardSets: [12, 15],
        consecutiveLowScores: 1,
        exposuresSinceImprovement: 2,
      );
      final restored = ProgressionHistory.fromJson(original.toJson());
      expect(restored.e1rmHistory, original.e1rmHistory);
      expect(restored.smoothedE1rmHistory, original.smoothedE1rmHistory);
      expect(restored.scoreHistory, original.scoreHistory);
      expect(restored.densityHistory, original.densityHistory);
      expect(restored.weeklyHardSets, original.weeklyHardSets);
      expect(restored.consecutiveLowScores, original.consecutiveLowScores);
      expect(
          restored.exposuresSinceImprovement, original.exposuresSinceImprovement);
    });

    test('fromJson with missing optional fields uses correct defaults', () {
      final h = ProgressionHistory.fromJson({});
      expect(h.e1rmHistory, isEmpty);
      expect(h.consecutiveLowScores, 0);
      expect(h.exposuresSinceImprovement, 0);
    });
  });
}
