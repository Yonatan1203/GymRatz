import 'models/session_metrics.dart';

class ProgressionSuggestion {
  final String? exerciseName;
  final double suggestedWeight;
  final int suggestedReps;
  final int suggestedSets;
  /// Suggested duration per set in seconds (for timed exercises).
  final int suggestedDuration;
  /// Suggested rest between sets in seconds (for endurance rest-reduction).
  final int? suggestedRestSeconds;
  final String reasoning;
  final bool isDeload;
  final double? backoffWeight;
  final int? backoffSets;
  final double score;
  final SessionMetrics? metrics;

  const ProgressionSuggestion({
    this.exerciseName,
    required this.suggestedWeight,
    required this.suggestedReps,
    required this.suggestedSets,
    this.suggestedDuration = 0,
    this.suggestedRestSeconds,
    required this.reasoning,
    this.isDeload = false,
    this.backoffWeight,
    this.backoffSets,
    this.score = 0,
    this.metrics,
  });

  Map<String, dynamic> toJson() => {
        if (exerciseName != null) 'exerciseName': exerciseName,
        'suggestedWeight': suggestedWeight,
        'suggestedReps': suggestedReps,
        'suggestedSets': suggestedSets,
        if (suggestedDuration > 0) 'suggestedDuration': suggestedDuration,
        if (suggestedRestSeconds != null)
          'suggestedRestSeconds': suggestedRestSeconds,
        'reasoning': reasoning,
        'isDeload': isDeload,
        if (backoffWeight != null) 'backoffWeight': backoffWeight,
        if (backoffSets != null) 'backoffSets': backoffSets,
        'score': score,
      };

  factory ProgressionSuggestion.fromJson(Map<String, dynamic> json) =>
      ProgressionSuggestion(
        exerciseName: json['exerciseName'] as String?,
        suggestedWeight: (json['suggestedWeight'] as num?)?.toDouble() ?? 0,
        suggestedReps: json['suggestedReps'] as int? ?? 0,
        suggestedSets: json['suggestedSets'] as int? ?? 3,
        suggestedDuration: json['suggestedDuration'] as int? ?? 0,
        suggestedRestSeconds: json['suggestedRestSeconds'] as int?,
        reasoning: json['reasoning'] as String? ?? '',
        isDeload: json['isDeload'] as bool? ?? false,
        backoffWeight: (json['backoffWeight'] as num?)?.toDouble(),
        backoffSets: json['backoffSets'] as int?,
        score: (json['score'] as num?)?.toDouble() ?? 0,
      );
}
