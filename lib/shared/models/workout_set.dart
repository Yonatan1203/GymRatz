import 'enums.dart';

class WorkoutSet {
  final int reps;
  final double weight;
  final int rir;
  final bool completed;
  final bool isWarmup;
  final EquipmentType equipmentType;

  const WorkoutSet({
    this.reps = 0,
    this.weight = 0,
    this.rir = 0,
    this.completed = false,
    this.isWarmup = false,
    this.equipmentType = EquipmentType.barbell,
  });

  Map<String, dynamic> toJson() => {
        'reps': reps,
        'weight': weight,
        'rir': rir,
        'completed': completed,
        'isWarmup': isWarmup,
        'equipmentType': equipmentType.name,
      };

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
        reps: json['reps'] as int? ?? 0,
        weight: (json['weight'] as num?)?.toDouble() ?? 0,
        rir: json['rir'] as int? ?? 0,
        completed: json['completed'] as bool? ?? false,
        isWarmup: json['isWarmup'] as bool? ?? false,
        equipmentType: EquipmentType.values.firstWhere(
          (e) => e.name == json['equipmentType'],
          orElse: () => EquipmentType.barbell,
        ),
      );

  WorkoutSet copyWith({
    int? reps,
    double? weight,
    int? rir,
    bool? completed,
    bool? isWarmup,
    EquipmentType? equipmentType,
  }) =>
      WorkoutSet(
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
        rir: rir ?? this.rir,
        completed: completed ?? this.completed,
        isWarmup: isWarmup ?? this.isWarmup,
        equipmentType: equipmentType ?? this.equipmentType,
      );
}
