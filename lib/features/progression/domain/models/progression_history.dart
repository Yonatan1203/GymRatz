class ProgressionHistory {
  final List<double> e1rmHistory;
  final List<double> smoothedE1rmHistory;
  final List<double> scoreHistory;
  final List<double> densityHistory;
  final List<int> weeklyHardSets;
  final int consecutiveLowScores;
  final int exposuresSinceImprovement;

  const ProgressionHistory({
    this.e1rmHistory = const [],
    this.smoothedE1rmHistory = const [],
    this.scoreHistory = const [],
    this.densityHistory = const [],
    this.weeklyHardSets = const [],
    this.consecutiveLowScores = 0,
    this.exposuresSinceImprovement = 0,
  });

  /// Median of last 3 session e1RMs, or last value, or 0.
  double get baselineE1RM {
    if (e1rmHistory.length < 3) {
      return e1rmHistory.isNotEmpty ? e1rmHistory.last : 0;
    }
    final last3 = e1rmHistory.sublist(e1rmHistory.length - 3).toList();
    last3.sort();
    return last3[1];
  }

  double get latestSmoothedE1RM =>
      smoothedE1rmHistory.isNotEmpty ? smoothedE1rmHistory.last : 0;

  double get latestDensity =>
      densityHistory.isNotEmpty ? densityHistory.last : 0;

  /// Plateau: no improvement for >= 3 exposures.
  bool get isPlateaued => exposuresSinceImprovement >= 3;

  /// Density plateau: density hasn't improved > 1% for 3 exposures.
  bool get isDensityPlateaued {
    if (densityHistory.length < 4) return false;
    final recent = densityHistory.sublist(densityHistory.length - 3);
    final peak = densityHistory
        .sublist(0, densityHistory.length - 3)
        .fold<double>(0, (a, b) => a > b ? a : b);
    return recent.every((d) => d <= peak * 1.01);
  }

  /// Create a new history with an additional session appended.
  ProgressionHistory appendSession({
    required double sessionE1RM,
    required double smoothedE1RM,
    required double score,
    double? density,
    required double lowScoreThreshold,
    required double improvementThreshold,
  }) {
    final newE1rm = [...e1rmHistory, sessionE1RM];
    final newSmoothed = [...smoothedE1rmHistory, smoothedE1RM];
    final newScores = [...scoreHistory, score];
    final newDensity = density != null
        ? [...densityHistory, density]
        : densityHistory;

    // Count consecutive low scores.
    int newConsecutiveLow = 0;
    for (int i = newScores.length - 1; i >= 0; i--) {
      if (newScores[i] < lowScoreThreshold) {
        newConsecutiveLow++;
      } else {
        break;
      }
    }

    // Count exposures since improvement.
    int newExposures = exposuresSinceImprovement;
    if (newSmoothed.length >= 2) {
      final prev = newSmoothed[newSmoothed.length - 2];
      if (prev > 0 && smoothedE1RM > prev * (1 + improvementThreshold / 100)) {
        newExposures = 0;
      } else {
        newExposures++;
      }
    }

    // Keep last 20 entries max.
    List<T> trim<T>(List<T> list) =>
        list.length > 20 ? list.sublist(list.length - 20) : list;

    return ProgressionHistory(
      e1rmHistory: trim(newE1rm),
      smoothedE1rmHistory: trim(newSmoothed),
      scoreHistory: trim(newScores),
      densityHistory: trim(newDensity),
      weeklyHardSets: weeklyHardSets,
      consecutiveLowScores: newConsecutiveLow,
      exposuresSinceImprovement: newExposures,
    );
  }

  Map<String, dynamic> toJson() => {
    'e1rmHistory': e1rmHistory,
    'smoothedE1rmHistory': smoothedE1rmHistory,
    'scoreHistory': scoreHistory,
    'densityHistory': densityHistory,
    'weeklyHardSets': weeklyHardSets,
    'consecutiveLowScores': consecutiveLowScores,
    'exposuresSinceImprovement': exposuresSinceImprovement,
  };

  factory ProgressionHistory.fromJson(Map<String, dynamic> json) =>
      ProgressionHistory(
        e1rmHistory: List<double>.from(
            (json['e1rmHistory'] ?? []).map((e) => (e as num).toDouble())),
        smoothedE1rmHistory: List<double>.from(
            (json['smoothedE1rmHistory'] ?? []).map((e) => (e as num).toDouble())),
        scoreHistory: List<double>.from(
            (json['scoreHistory'] ?? []).map((e) => (e as num).toDouble())),
        densityHistory: List<double>.from(
            (json['densityHistory'] ?? []).map((e) => (e as num).toDouble())),
        weeklyHardSets: List<int>.from(json['weeklyHardSets'] ?? []),
        consecutiveLowScores: json['consecutiveLowScores'] ?? 0,
        exposuresSinceImprovement: json['exposuresSinceImprovement'] ?? 0,
      );

  ProgressionHistory copyWith({
    List<double>? e1rmHistory,
    List<double>? smoothedE1rmHistory,
    List<double>? scoreHistory,
    List<double>? densityHistory,
    List<int>? weeklyHardSets,
    int? consecutiveLowScores,
    int? exposuresSinceImprovement,
  }) =>
      ProgressionHistory(
        e1rmHistory: e1rmHistory ?? this.e1rmHistory,
        smoothedE1rmHistory: smoothedE1rmHistory ?? this.smoothedE1rmHistory,
        scoreHistory: scoreHistory ?? this.scoreHistory,
        densityHistory: densityHistory ?? this.densityHistory,
        weeklyHardSets: weeklyHardSets ?? this.weeklyHardSets,
        consecutiveLowScores: consecutiveLowScores ?? this.consecutiveLowScores,
        exposuresSinceImprovement: exposuresSinceImprovement ?? this.exposuresSinceImprovement,
      );
}
