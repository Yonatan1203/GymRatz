import 'enums.dart';
import 'workout_exercise.dart';

class Workout {
  final String id;
  final String? programId;
  final String? workoutDayId;
  final DateTime date;
  final WorkoutStatus status;
  final List<WorkoutExercise> exercises;
  final double totalVolume;
  final int duration; // seconds
  final String? notes;
  final DateTime? completedAt;

  const Workout({
    required this.id,
    this.programId,
    this.workoutDayId,
    required this.date,
    this.status = WorkoutStatus.scheduled,
    this.exercises = const [],
    this.totalVolume = 0,
    this.duration = 0,
    this.notes,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'programId': programId,
        'workoutDayId': workoutDayId,
        'date': date.toIso8601String(),
        'status': status.name,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'totalVolume': totalVolume,
        'duration': duration,
        'notes': notes,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
        id: json['id'] as String,
        programId: json['programId'] as String?,
        workoutDayId: json['workoutDayId'] as String?,
        date: DateTime.parse(json['date'] as String),
        status: WorkoutStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => WorkoutStatus.scheduled,
        ),
        exercises: (json['exercises'] as List<dynamic>?)
                ?.map((e) =>
                    WorkoutExercise.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        totalVolume: (json['totalVolume'] as num?)?.toDouble() ?? 0,
        duration: json['duration'] as int? ?? 0,
        notes: json['notes'] as String?,
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'] as String)
            : null,
      );

  Workout copyWith({
    String? id,
    String? programId,
    String? workoutDayId,
    DateTime? date,
    WorkoutStatus? status,
    List<WorkoutExercise>? exercises,
    double? totalVolume,
    int? duration,
    String? notes,
    DateTime? completedAt,
  }) =>
      Workout(
        id: id ?? this.id,
        programId: programId ?? this.programId,
        workoutDayId: workoutDayId ?? this.workoutDayId,
        date: date ?? this.date,
        status: status ?? this.status,
        exercises: exercises ?? this.exercises,
        totalVolume: totalVolume ?? this.totalVolume,
        duration: duration ?? this.duration,
        notes: notes ?? this.notes,
        completedAt: completedAt ?? this.completedAt,
      );
}
