import '../../../features/progression/domain/progression_suggestion.dart';

class WorkoutSummary {
  final int totalSets;
  final int totalReps;
  final double totalVolume;
  final int duration; // seconds
  final List<String> newPRs;
  final List<ProgressionSuggestion> suggestions;

  const WorkoutSummary({
    required this.totalSets,
    required this.totalReps,
    required this.totalVolume,
    required this.duration,
    this.newPRs = const [],
    this.suggestions = const [],
  });
}
