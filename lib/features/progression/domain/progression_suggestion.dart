class ProgressionSuggestion {
  final double suggestedWeight;
  final int suggestedReps;
  final int suggestedSets;
  final String reasoning;
  final bool isDeload;

  const ProgressionSuggestion({
    required this.suggestedWeight,
    required this.suggestedReps,
    required this.suggestedSets,
    required this.reasoning,
    this.isDeload = false,
  });
}
