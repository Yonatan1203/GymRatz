import 'enums.dart';

class ProgramExercise {
  final String id;
  final String name;
  final int sets;
  final int repMin;
  final int repMax;
  final int targetRir;
  final int restSeconds;
  final String progressionType;
  final String category;
  final String? equipment;
  final EquipmentType equipmentType;

  const ProgramExercise({
    required this.id,
    required this.name,
    this.sets = 3,
    this.repMin = 8,
    this.repMax = 12,
    this.targetRir = 2,
    this.restSeconds = 120,
    this.progressionType = 'Load First',
    this.category = 'Chest',
    this.equipment,
    this.equipmentType = EquipmentType.barbell,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sets': sets,
        'repMin': repMin,
        'repMax': repMax,
        'targetRir': targetRir,
        'restSeconds': restSeconds,
        'progressionType': progressionType,
        'category': category,
        'equipment': equipment,
        'equipmentType': equipmentType.name,
      };

  factory ProgramExercise.fromJson(Map<String, dynamic> json) =>
      ProgramExercise(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        sets: json['sets'] as int? ?? 3,
        repMin: json['repMin'] as int? ?? 8,
        repMax: json['repMax'] as int? ?? 12,
        targetRir: json['targetRir'] as int? ?? 2,
        restSeconds: json['restSeconds'] as int? ?? 120,
        progressionType: json['progressionType'] as String? ?? 'Load First',
        category: json['category'] as String? ?? '',
        equipment: json['equipment'] as String?,
        equipmentType: EquipmentType.values.firstWhere(
          (e) => e.name == json['equipmentType'],
          orElse: () => EquipmentType.barbell,
        ),
      );

  ProgramExercise copyWith({
    String? id,
    String? name,
    int? sets,
    int? repMin,
    int? repMax,
    int? targetRir,
    int? restSeconds,
    String? progressionType,
    String? category,
    String? equipment,
    EquipmentType? equipmentType,
  }) =>
      ProgramExercise(
        id: id ?? this.id,
        name: name ?? this.name,
        sets: sets ?? this.sets,
        repMin: repMin ?? this.repMin,
        repMax: repMax ?? this.repMax,
        targetRir: targetRir ?? this.targetRir,
        restSeconds: restSeconds ?? this.restSeconds,
        progressionType: progressionType ?? this.progressionType,
        category: category ?? this.category,
        equipment: equipment ?? this.equipment,
        equipmentType: equipmentType ?? this.equipmentType,
      );
}
