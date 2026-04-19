import 'models/session_metrics.dart';

class ProgressionSuggestion {
  final double suggestedWeight;
  final int suggestedReps;
  final int suggestedSets;
  final String reasoning;
  final bool isDeload;
  final double? backoffWeight;
  final int? backoffSets;
  final double score;
  final SessionMetrics? metrics;

  const ProgressionSuggestion({
    required this.suggestedWeight,
    required this.suggestedReps,
    required this.suggestedSets,
    required this.reasoning,
    this.isDeload = false,
    this.backoffWeight,
    this.backoffSets,
    this.score = 0,
    this.metrics,
  });
}
