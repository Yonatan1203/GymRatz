import 'program_exercise.dart';

class WorkoutDay {
  final String id;
  final String name;
  final String dayOfWeek;
  final List<ProgramExercise> exercises;

  const WorkoutDay({
    required this.id,
    required this.name,
    required this.dayOfWeek,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dayOfWeek': dayOfWeek,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutDay.fromJson(Map<String, dynamic> json) => WorkoutDay(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        dayOfWeek: json['dayOfWeek'] as String? ?? '',
        exercises: (json['exercises'] as List<dynamic>?)
                ?.map(
                    (e) => ProgramExercise.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  WorkoutDay copyWith({
    String? id,
    String? name,
    String? dayOfWeek,
    List<ProgramExercise>? exercises,
  }) =>
      WorkoutDay(
        id: id ?? this.id,
        name: name ?? this.name,
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
        exercises: exercises ?? this.exercises,
      );
}
