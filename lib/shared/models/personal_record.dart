class PersonalRecord {
  final String exerciseId;
  final String exerciseName;
  final double weight;
  final int reps;
  final DateTime date;
  // Unit the weight was recorded in ('lbs' or 'kg'). Empty string for
  // legacy records created before this field existed — display as-is.
  final String unit;

  const PersonalRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.date,
    this.unit = '',
  });

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'weight': weight,
        'reps': reps,
        'date': date.toIso8601String(),
        'unit': unit,
      };

  factory PersonalRecord.fromJson(Map<String, dynamic> json) => PersonalRecord(
        exerciseId: json['exerciseId'] as String,
        exerciseName: json['exerciseName'] as String? ?? '',
        weight: (json['weight'] as num?)?.toDouble() ?? 0,
        reps: json['reps'] as int? ?? 0,
        date: DateTime.parse(json['date'] as String),
        unit: json['unit'] as String? ?? '',
      );

  PersonalRecord copyWith({
    String? exerciseId,
    String? exerciseName,
    double? weight,
    int? reps,
    DateTime? date,
    String? unit,
  }) =>
      PersonalRecord(
        exerciseId: exerciseId ?? this.exerciseId,
        exerciseName: exerciseName ?? this.exerciseName,
        weight: weight ?? this.weight,
        reps: reps ?? this.reps,
        date: date ?? this.date,
        unit: unit ?? this.unit,
      );
}
