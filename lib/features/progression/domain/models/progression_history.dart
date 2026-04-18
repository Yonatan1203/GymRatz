class ProgressionHistory {
  final List<double> e1rmHistory;
  final List<double> smoothedE1rmHistory;
  final List<double> scoreHistory;
  final List<int> weeklyHardSets;
  final int consecutiveLowScores;
  final int exposuresSinceImprovement;

  const ProgressionHistory({
    this.e1rmHistory = const [],
    this.smoothedE1rmHistory = const [],
    this.scoreHistory = const [],
    this.weeklyHardSets = const [],
    this.consecutiveLowScores = 0,
    this.exposuresSinceImprovement = 0,
  });

  double get baselineE1RM {
    if (e1rmHistory.length < 3) {
      return e1rmHistory.isNotEmpty ? e1rmHistory.last : 0;
    }
    final last3 = e1rmHistory.sublist(e1rmHistory.length - 3);
    last3.sort();
    return last3[1];
  }

  double get latestSmoothedE1RM =>
      smoothedE1rmHistory.isNotEmpty ? smoothedE1rmHistory.last : 0;

  bool get isPlateaued => exposuresSinceImprovement >= 3;

  Map<String, dynamic> toJson() => {
    'e1rmHistory': e1rmHistory,
    'smoothedE1rmHistory': smoothedE1rmHistory,
    'scoreHistory': scoreHistory,
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
        weeklyHardSets: List<int>.from(json['weeklyHardSets'] ?? []),
        consecutiveLowScores: json['consecutiveLowScores'] ?? 0,
        exposuresSinceImprovement: json['exposuresSinceImprovement'] ?? 0,
      );

  ProgressionHistory copyWith({
    List<double>? e1rmHistory,
    List<double>? smoothedE1rmHistory,
    List<double>? scoreHistory,
    List<int>? weeklyHardSets,
    int? consecutiveLowScores,
    int? exposuresSinceImprovement,
  }) =>
      ProgressionHistory(
        e1rmHistory: e1rmHistory ?? this.e1rmHistory,
        smoothedE1rmHistory: smoothedE1rmHistory ?? this.smoothedE1rmHistory,
        scoreHistory: scoreHistory ?? this.scoreHistory,
        weeklyHardSets: weeklyHardSets ?? this.weeklyHardSets,
        consecutiveLowScores: consecutiveLowScores ?? this.consecutiveLowScores,
        exposuresSinceImprovement: exposuresSinceImprovement ?? this.exposuresSinceImprovement,
      );
}
