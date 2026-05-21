import 'enums.dart';

class Exercise {
  final String id;
  final String name;
  final String category;
  final String type;
  final String muscle;
  final String equipment;
  final EquipmentType equipmentType;
  final String difficulty;
  final bool isFavorite;
  final List<String> muscleGroups;
  final String? instructions;
  final bool isDefault;
  final bool isCardio;

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.muscle,
    required this.equipment,
    this.equipmentType = EquipmentType.barbell,
    required this.difficulty,
    this.isFavorite = false,
    this.muscleGroups = const [],
    this.instructions,
    this.isDefault = true,
    this.isCardio = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'type': type,
        'muscle': muscle,
        'equipment': equipment,
        'equipmentType': equipmentType.name,
        'difficulty': difficulty,
        'isFavorite': isFavorite,
        'muscleGroups': muscleGroups,
        'instructions': instructions,
        'isDefault': isDefault,
        if (isCardio) 'isCardio': true,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        category: json['category'] as String? ?? '',
        type: json['type'] as String? ?? '',
        muscle: json['muscle'] as String? ?? '',
        equipment: json['equipment'] as String? ?? '',
        equipmentType: EquipmentType.values.firstWhere(
          (e) => e.name == json['equipmentType'],
          orElse: () => EquipmentType.barbell,
        ),
        difficulty: json['difficulty'] as String? ?? '',
        isFavorite: json['isFavorite'] as bool? ?? false,
        muscleGroups: (json['muscleGroups'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        instructions: json['instructions'] as String?,
        isDefault: json['isDefault'] as bool? ?? true,
        isCardio: json['isCardio'] as bool? ?? false,
      );

  Exercise copyWith({
    String? id,
    String? name,
    String? category,
    String? type,
    String? muscle,
    String? equipment,
    EquipmentType? equipmentType,
    String? difficulty,
    bool? isFavorite,
    List<String>? muscleGroups,
    String? instructions,
    bool? isDefault,
    bool? isCardio,
  }) =>
      Exercise(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        type: type ?? this.type,
        muscle: muscle ?? this.muscle,
        equipment: equipment ?? this.equipment,
        equipmentType: equipmentType ?? this.equipmentType,
        difficulty: difficulty ?? this.difficulty,
        isFavorite: isFavorite ?? this.isFavorite,
        muscleGroups: muscleGroups ?? this.muscleGroups,
        instructions: instructions ?? this.instructions,
        isDefault: isDefault ?? this.isDefault,
        isCardio: isCardio ?? this.isCardio,
      );
}
