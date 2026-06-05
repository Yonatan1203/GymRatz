import 'enums.dart';

class ProgramExercise {
  final String id;
  final String name;
  final int sets;
  final int repMin;
  final int repMax;
  final int targetRir;
  final int restSeconds;
  final ProgressionMode progressionMode;
  final String category;
  final String? equipment;
  final EquipmentType equipmentType;
  /// Duration in minutes for cardio exercises (null for strength exercises).
  final int? durationMinutes;
  /// When true, sets are logged by duration (seconds) rather than reps.
  final bool isTimeBased;

  const ProgramExercise({
    required this.id,
    required this.name,
    this.sets = 3,
    this.repMin = 8,
    this.repMax = 12,
    this.targetRir = 2,
    this.restSeconds = 120,
    this.progressionMode = ProgressionMode.hypertrophy,
    this.category = 'Chest',
    this.equipment,
    this.equipmentType = EquipmentType.barbell,
    this.durationMinutes,
    this.isTimeBased = false,
  });

  bool get isCardio => durationMinutes != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sets': sets,
        'repMin': repMin,
        'repMax': repMax,
        'targetRir': targetRir,
        'restSeconds': restSeconds,
        'progressionMode': progressionMode.name,
        'category': category,
        'equipment': equipment,
        'equipmentType': equipmentType.name,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        'isTimeBased': isTimeBased,
      };

  factory ProgramExercise.fromJson(Map<String, dynamic> json) {
    ProgressionMode mode;
    if (json['progressionMode'] != null) {
      mode = ProgressionMode.values.firstWhere(
        (e) => e.name == json['progressionMode'],
        orElse: () => ProgressionMode.hypertrophy,
      );
    } else {
      // Legacy migration from old progressionType string
      mode = ProgressionMode.fromLegacy(json['progressionType'] as String?);
    }

    return ProgramExercise(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      sets: json['sets'] as int? ?? 3,
      repMin: json['repMin'] as int? ?? 8,
      repMax: json['repMax'] as int? ?? 12,
      targetRir: json['targetRir'] as int? ?? 2,
      restSeconds: json['restSeconds'] as int? ?? 120,
      progressionMode: mode,
      category: json['category'] as String? ?? '',
      equipment: json['equipment'] as String?,
      equipmentType: EquipmentType.values.firstWhere(
        (e) => e.name == json['equipmentType'],
        orElse: () => EquipmentType.barbell,
      ),
      durationMinutes: json['durationMinutes'] as int?,
      isTimeBased: json['isTimeBased'] as bool? ?? false,
    );
  }

  ProgramExercise copyWith({
    String? id,
    String? name,
    int? sets,
    int? repMin,
    int? repMax,
    int? targetRir,
    int? restSeconds,
    ProgressionMode? progressionMode,
    String? category,
    String? equipment,
    EquipmentType? equipmentType,
    int? durationMinutes,
    bool? isTimeBased,
  }) =>
      ProgramExercise(
        id: id ?? this.id,
        name: name ?? this.name,
        sets: sets ?? this.sets,
        repMin: repMin ?? this.repMin,
        repMax: repMax ?? this.repMax,
        targetRir: targetRir ?? this.targetRir,
        restSeconds: restSeconds ?? this.restSeconds,
        progressionMode: progressionMode ?? this.progressionMode,
        category: category ?? this.category,
        equipment: equipment ?? this.equipment,
        equipmentType: equipmentType ?? this.equipmentType,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        isTimeBased: isTimeBased ?? this.isTimeBased,
      );
}
