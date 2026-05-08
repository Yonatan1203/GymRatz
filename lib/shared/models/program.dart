import 'workout_day.dart';

class Program {
  final String id;
  final String name;
  final int workouts;
  final int weeks;
  final int progress;
  final String? difficulty;
  final String? description;
  final List<WorkoutDay> days;
  final bool isActive;
  final bool prefillWeights;
  final DateTime? createdAt;
  final bool assignedByCoach;
  final String? coachId;

  const Program({
    required this.id,
    required this.name,
    required this.workouts,
    required this.weeks,
    this.progress = 0,
    this.difficulty,
    this.description,
    this.days = const [],
    this.isActive = false,
    this.prefillWeights = true,
    this.createdAt,
    this.assignedByCoach = false,
    this.coachId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'workouts': workouts,
        'weeks': weeks,
        'progress': progress,
        'difficulty': difficulty,
        'description': description,
        'days': days.map((d) => d.toJson()).toList(),
        'isActive': isActive,
        'prefillWeights': prefillWeights,
        'createdAt': createdAt?.toIso8601String(),
        'assignedByCoach': assignedByCoach,
        'coachId': coachId,
      };

  factory Program.fromJson(Map<String, dynamic> json) => Program(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        workouts: json['workouts'] as int? ?? 0,
        weeks: json['weeks'] as int? ?? 0,
        progress: json['progress'] as int? ?? 0,
        difficulty: json['difficulty'] as String?,
        description: json['description'] as String?,
        days: (json['days'] as List<dynamic>?)
                ?.map((e) => WorkoutDay.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        isActive: json['isActive'] as bool? ?? false,
        prefillWeights: json['prefillWeights'] as bool? ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        assignedByCoach: json['assignedByCoach'] as bool? ?? false,
        coachId: json['coachId'] as String?,
      );

  Program copyWith({
    String? id,
    String? name,
    int? workouts,
    int? weeks,
    int? progress,
    String? difficulty,
    String? description,
    List<WorkoutDay>? days,
    bool? isActive,
    bool? prefillWeights,
    DateTime? createdAt,
    bool? assignedByCoach,
    String? coachId,
  }) =>
      Program(
        id: id ?? this.id,
        name: name ?? this.name,
        workouts: workouts ?? this.workouts,
        weeks: weeks ?? this.weeks,
        progress: progress ?? this.progress,
        difficulty: difficulty ?? this.difficulty,
        description: description ?? this.description,
        days: days ?? this.days,
        isActive: isActive ?? this.isActive,
        prefillWeights: prefillWeights ?? this.prefillWeights,
        createdAt: createdAt ?? this.createdAt,
        assignedByCoach: assignedByCoach ?? this.assignedByCoach,
        coachId: coachId ?? this.coachId,
      );
}
