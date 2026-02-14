/// Equipment categories that drive progression rules and load snapping.
enum EquipmentType {
  barbell,
  dumbbell,
  machineStack,
  machinePlateLoaded,
  bodyweight;

  String get label {
    switch (this) {
      case barbell:
        return 'Barbell';
      case dumbbell:
        return 'Dumbbell';
      case machineStack:
        return 'Machine (Stack)';
      case machinePlateLoaded:
        return 'Machine (Plate Loaded)';
      case bodyweight:
        return 'Bodyweight';
    }
  }
}

/// How the PO engine prioritises load vs reps.
enum ProgressionMode {
  loadFirst,
  repsFirst,
  mixed;

  String get label {
    switch (this) {
      case loadFirst:
        return 'Load First';
      case repsFirst:
        return 'Reps First';
      case mixed:
        return 'Mixed';
    }
  }
}

/// Lifecycle state of a workout.
enum WorkoutStatus {
  scheduled,
  inProgress,
  completed,
  missed;
}

/// Whether performed reps fell inside the prescribed range.
enum RangeStatus {
  belowRange,
  inRange,
  aboveRange;
}

/// Whether RIR matched the target.
enum EffortStatus {
  rirLow,
  rirOnTarget,
  rirHigh;
}

/// Quick-select templates that auto-fill rep/RIR ranges.
enum GoalPreset {
  strength,
  hypertrophy,
  repsBased;

  String get label {
    switch (this) {
      case strength:
        return 'Strength';
      case hypertrophy:
        return 'Hypertrophy';
      case repsBased:
        return 'Reps Based';
    }
  }
}
