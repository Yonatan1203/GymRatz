import 'enums.dart';
import 'workout_day.dart';

class Program {
  final String id;
  final String name;
  final int workouts;
  final int? weeks;
  final int progress;
  final String? difficulty;
  final String? description;
  final List<WorkoutDay> days;
  final bool isActive;
  final bool prefillWeights;
  final DateTime? createdAt;
  final DateTime? activatedAt;
  final bool assignedByCoach;
  final String? coachId;
  /// Controls whether the PO engine's weight suggestions are applied when
  /// an athlete starts a workout from this program.
  ///
  /// Only meaningful for coach-assigned programs ([assignedByCoach] == true).
  /// Defaults to [WeightAutofillMode.systemSuggested] for backwards
  /// compatibility with existing programs.
  final WeightAutofillMode weightAutofillMode;

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
    this.activatedAt,
    this.assignedByCoach = false,
    this.coachId,
    this.weightAutofillMode = WeightAutofillMode.systemSuggested,
  });

  /// Date (time-truncated) from which this program counts for schedule/missed
  /// calculations: explicit [activatedAt], else [createdAt] for legacy programs.
  /// Null only when both are absent — callers should then skip "missed" marking.
  DateTime? get activationFloor {
    final raw = activatedAt ?? createdAt;
    return raw == null ? null : DateTime(raw.year, raw.month, raw.day);
  }

  /// Display label for the program's duration: "N weeks" for a fixed-length
  /// program, or "Ongoing" when [weeks] is null.
  String get weeksLabel => weeks != null ? '$weeks weeks' : 'Ongoing';

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
        'activatedAt': activatedAt?.toIso8601String(),
        'assignedByCoach': assignedByCoach,
        'coachId': coachId,
        'weightAutofillMode': weightAutofillMode.name,
      };

  factory Program.fromJson(Map<String, dynamic> json) => Program(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        workouts: json['workouts'] as int? ?? 0,
        weeks: json['weeks'] as int?,
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
        activatedAt: json['activatedAt'] != null
            ? DateTime.tryParse(json['activatedAt'] as String)
            : null,
        assignedByCoach: json['assignedByCoach'] as bool? ?? false,
        coachId: json['coachId'] as String?,
        weightAutofillMode: WeightAutofillMode.values.byName(
          json['weightAutofillMode'] as String? ?? 'systemSuggested',
        ),
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
    DateTime? activatedAt,
    bool? assignedByCoach,
    String? coachId,
    WeightAutofillMode? weightAutofillMode,
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
        activatedAt: activatedAt ?? this.activatedAt,
        assignedByCoach: assignedByCoach ?? this.assignedByCoach,
        coachId: coachId ?? this.coachId,
        weightAutofillMode: weightAutofillMode ?? this.weightAutofillMode,
      );
}
