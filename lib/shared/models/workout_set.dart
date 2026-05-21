import 'enums.dart';

class WorkoutSet {
  final int reps;
  final double weight;
  /// Reps in Reserve. Null means the user did not enter RIR/RPE.
  final int? rir;
  final bool completed;
  final bool isWarmup;
  final bool isTopSet;
  final bool isAmrap;
  final int restSeconds;
  /// Actual duration held/performed in seconds (for timed exercises).
  final int durationSeconds;
  final EquipmentType equipmentType;

  const WorkoutSet({
    this.reps = 0,
    this.weight = 0,
    this.rir,
    this.completed = false,
    this.isWarmup = false,
    this.isTopSet = false,
    this.isAmrap = false,
    this.restSeconds = 0,
    this.durationSeconds = 0,
    this.equipmentType = EquipmentType.barbell,
  });

  Map<String, dynamic> toJson() => {
        'reps': reps,
        'weight': weight,
        'rir': rir,
        'completed': completed,
        'isWarmup': isWarmup,
        'isTopSet': isTopSet,
        if (isAmrap) 'isAmrap': true,
        'restSeconds': restSeconds,
        if (durationSeconds > 0) 'durationSeconds': durationSeconds,
        'equipmentType': equipmentType.name,
      };

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
        reps: json['reps'] as int? ?? 0,
        weight: (json['weight'] as num?)?.toDouble() ?? 0,
        rir: json['rir'] as int?,
        completed: json['completed'] as bool? ?? false,
        isWarmup: json['isWarmup'] as bool? ?? false,
        isTopSet: json['isTopSet'] as bool? ?? false,
        isAmrap: json['isAmrap'] as bool? ?? false,
        restSeconds: json['restSeconds'] as int? ?? 0,
        durationSeconds: json['durationSeconds'] as int? ?? 0,
        equipmentType: EquipmentType.values.firstWhere(
          (e) => e.name == json['equipmentType'],
          orElse: () => EquipmentType.barbell,
        ),
      );

  WorkoutSet copyWith({
    int? reps,
    double? weight,
    int? rir,
    bool clearRir = false,
    bool? completed,
    bool? isWarmup,
    bool? isTopSet,
    bool? isAmrap,
    int? restSeconds,
    int? durationSeconds,
    EquipmentType? equipmentType,
  }) =>
      WorkoutSet(
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
        rir: clearRir ? null : (rir ?? this.rir),
        completed: completed ?? this.completed,
        isWarmup: isWarmup ?? this.isWarmup,
        isTopSet: isTopSet ?? this.isTopSet,
        isAmrap: isAmrap ?? this.isAmrap,
        restSeconds: restSeconds ?? this.restSeconds,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        equipmentType: equipmentType ?? this.equipmentType,
      );

  /// Effective RIR: uses stored value, or infers from context.
  /// Returns null if no RIR data available.
  int? get effectiveRir => rir;

  /// Convert RPE (6-10 scale) to RIR.
  static int rpeToRir(double rpe) => (10 - rpe).round().clamp(0, 6);
}
