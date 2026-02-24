import 'enums.dart';
import 'workout_set.dart';

class WorkoutExercise {
  final String name;
  final String equipment;
  final EquipmentType equipmentType;
  final String repRange;
  final int targetRir;
  final int restSeconds;
  final List<WorkoutSet> sets;

  const WorkoutExercise({
    required this.name,
    required this.equipment,
    this.equipmentType = EquipmentType.barbell,
    required this.repRange,
    required this.targetRir,
    this.restSeconds = 120,
    required this.sets,
  });

  int get completedSets => sets.where((s) => s.completed).length;

  Map<String, dynamic> toJson() => {
        'name': name,
        'equipment': equipment,
        'equipmentType': equipmentType.name,
        'repRange': repRange,
        'targetRir': targetRir,
        'restSeconds': restSeconds,
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
        repRange: json['repRange'] as String? ?? '',
        targetRir: json['targetRir'] as int? ?? 2,
        restSeconds: json['restSeconds'] as int? ?? 120,
        sets: (json['sets'] as List<dynamic>?)
                ?.map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
      );

  WorkoutExercise copyWith({
    String? name,
    String? equipment,
    EquipmentType? equipmentType,
    String? repRange,
    int? targetRir,
    int? restSeconds,
    List<WorkoutSet>? sets,
  }) =>
      WorkoutExercise(
        name: name ?? this.name,
        equipment: equipment ?? this.equipment,
        equipmentType: equipmentType ?? this.equipmentType,
        repRange: repRange ?? this.repRange,
        targetRir: targetRir ?? this.targetRir,
        restSeconds: restSeconds ?? this.restSeconds,
        sets: sets ?? this.sets,
      );
}
