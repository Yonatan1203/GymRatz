class PersonalRecord {
  final String exerciseId;
  final String exerciseName;
  final double weight;
  final int reps;
  final DateTime date;

  const PersonalRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'weight': weight,
        'reps': reps,
        'date': date.toIso8601String(),
      };

  factory PersonalRecord.fromJson(Map<String, dynamic> json) => PersonalRecord(
        exerciseId: json['exerciseId'] as String,
        exerciseName: json['exerciseName'] as String? ?? '',
        weight: (json['weight'] as num?)?.toDouble() ?? 0,
        reps: json['reps'] as int? ?? 0,
        date: DateTime.parse(json['date'] as String),
      );

  PersonalRecord copyWith({
    String? exerciseId,
    String? exerciseName,
    double? weight,
    int? reps,
    DateTime? date,
  }) =>
      PersonalRecord(
        exerciseId: exerciseId ?? this.exerciseId,
        exerciseName: exerciseName ?? this.exerciseName,
        weight: weight ?? this.weight,
        reps: reps ?? this.reps,
        date: date ?? this.date,
      );
}
