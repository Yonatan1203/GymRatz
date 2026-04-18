class SessionMetrics {
  final double sessionE1RM;
  final double smoothedE1RM;
  final int hardSetCount;
  final int totalReps;
  final int targetTotalReps;
  final double totalTonnage;
  final double density;
  final int totalTimeSeconds;
  final double topSetWeight;
  final int topSetReps;
  final int topSetRir;

  const SessionMetrics({
    this.sessionE1RM = 0,
    this.smoothedE1RM = 0,
    this.hardSetCount = 0,
    this.totalReps = 0,
    this.targetTotalReps = 0,
    this.totalTonnage = 0,
    this.density = 0,
    this.totalTimeSeconds = 0,
    this.topSetWeight = 0,
    this.topSetReps = 0,
    this.topSetRir = 0,
  });

  Map<String, dynamic> toJson() => {
    'sessionE1RM': sessionE1RM,
    'smoothedE1RM': smoothedE1RM,
    'hardSetCount': hardSetCount,
    'totalReps': totalReps,
    'targetTotalReps': targetTotalReps,
    'totalTonnage': totalTonnage,
    'density': density,
    'totalTimeSeconds': totalTimeSeconds,
    'topSetWeight': topSetWeight,
    'topSetReps': topSetReps,
    'topSetRir': topSetRir,
  };

  factory SessionMetrics.fromJson(Map<String, dynamic> json) => SessionMetrics(
    sessionE1RM: (json['sessionE1RM'] ?? 0).toDouble(),
    smoothedE1RM: (json['smoothedE1RM'] ?? 0).toDouble(),
    hardSetCount: json['hardSetCount'] ?? 0,
    totalReps: json['totalReps'] ?? 0,
    targetTotalReps: json['targetTotalReps'] ?? 0,
    totalTonnage: (json['totalTonnage'] ?? 0).toDouble(),
    density: (json['density'] ?? 0).toDouble(),
    totalTimeSeconds: json['totalTimeSeconds'] ?? 0,
    topSetWeight: (json['topSetWeight'] ?? 0).toDouble(),
    topSetReps: json['topSetReps'] ?? 0,
    topSetRir: json['topSetRir'] ?? 0,
  );
}
