import 'enums.dart';
import 'workout_set.dart';

class WorkoutExercise {
  final String name;
  final String equipment;
  final EquipmentType equipmentType;
  final ExerciseType exerciseType;
  final String repRange;
  /// Target duration per set in seconds (for timed exercises).
  final int targetDuration;
  final int targetRir;
  final int restSeconds;
  final ProgressionMode progressionMode;
  final List<WorkoutSet> sets;

  // Transient — not serialized. Populated during startWorkout via
  // _buildExerciseFromTemplate so the UI can show last-session context and
  // the PO suggestion. copyWith cannot clear poSuggestedWeight back to null
  // (Dart nullable-copyWith limitation) — acceptable since these fields are
  // written once at construction and never mutated.
  final List<WorkoutSet> previousSets;
  final double? poSuggestedWeight;

  const WorkoutExercise({
    required this.name,
    required this.equipment,
    this.equipmentType = EquipmentType.barbell,
    this.exerciseType = ExerciseType.reps,
    required this.repRange,
    this.targetDuration = 0,
    required this.targetRir,
    this.restSeconds = 120,
    this.progressionMode = ProgressionMode.hypertrophy,
    required this.sets,
    this.previousSets = const [],
    this.poSuggestedWeight,
  });

  int get completedSets => sets.where((s) => s.completed).length;

  /// Parse repRange into min/max. Supports "8" (exact) and "8-12" (range).
  int get repMin {
    final parts = repRange.split('-');
    return int.tryParse(parts.first.trim()) ?? 8;
  }

  int get repMax {
    final parts = repRange.split('-');
    return parts.length > 1
        ? (int.tryParse(parts.last.trim()) ?? repMin)
        : repMin;
  }

  bool get isTimed => exerciseType == ExerciseType.timed;

  Map<String, dynamic> toJson() => {
        'name': name,
        'equipment': equipment,
        'equipmentType': equipmentType.name,
        if (exerciseType != ExerciseType.reps) 'exerciseType': exerciseType.name,
        'repRange': repRange,
        if (targetDuration > 0) 'targetDuration': targetDuration,
        'targetRir': targetRir,
        'restSeconds': restSeconds,
        'progressionMode': progressionMode.name,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      WorkoutExercise(
        name: json['name'] as String? ?? '',
        equipment: json['equipment'] as String? ?? '',
        equipmentType: EquipmentType.values.firstWhere(
          (e) => e.name == json['equipmentType'],
          orElse: () => EquipmentType.barbell,
        ),
        exerciseType: ExerciseType.values.firstWhere(
          (e) => e.name == json['exerciseType'],
          orElse: () => ExerciseType.reps,
        ),
        repRange: json['repRange'] as String? ?? '',
        targetDuration: json['targetDuration'] as int? ?? 0,
        targetRir: json['targetRir'] as int? ?? 2,
        restSeconds: json['restSeconds'] as int? ?? 120,
        progressionMode: ProgressionMode.values.firstWhere(
          (e) => e.name == json['progressionMode'],
          orElse: () => ProgressionMode.hypertrophy,
        ),
        sets: (json['sets'] as List<dynamic>?)
                ?.map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
      );

  WorkoutExercise copyWith({
    String? name,
    String? equipment,
    EquipmentType? equipmentType,
    ExerciseType? exerciseType,
    String? repRange,
    int? targetDuration,
    int? targetRir,
    int? restSeconds,
    ProgressionMode? progressionMode,
    List<WorkoutSet>? sets,
    List<WorkoutSet>? previousSets,
    double? poSuggestedWeight,
  }) =>
      WorkoutExercise(
        name: name ?? this.name,
        equipment: equipment ?? this.equipment,
        equipmentType: equipmentType ?? this.equipmentType,
        exerciseType: exerciseType ?? this.exerciseType,
        repRange: repRange ?? this.repRange,
        targetDuration: targetDuration ?? this.targetDuration,
        targetRir: targetRir ?? this.targetRir,
        restSeconds: restSeconds ?? this.restSeconds,
        progressionMode: progressionMode ?? this.progressionMode,
        sets: sets ?? this.sets,
        previousSets: previousSets ?? this.previousSets,
        poSuggestedWeight: poSuggestedWeight ?? this.poSuggestedWeight,
      );
}
