/// Whether an exercise is measured by reps or by time.
enum ExerciseType {
  reps,
  timed;

  String get label {
    switch (this) {
      case reps:
        return 'Reps';
      case timed:
        return 'Timed';
    }
  }
}

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
  strength,
  hypertrophy,
  endurance;

  String get label {
    switch (this) {
      case ProgressionMode.strength:
        return 'Strength';
      case ProgressionMode.hypertrophy:
        return 'Hypertrophy';
      case ProgressionMode.endurance:
        return 'Endurance';
    }
  }

  /// Migration from old values
  static ProgressionMode fromLegacy(String? value) {
    switch (value?.toLowerCase()) {
      case 'loadfirst':
      case 'load first':
        return ProgressionMode.strength;
      case 'repsfirst':
      case 'reps first':
        return ProgressionMode.endurance;
      case 'mixed':
        return ProgressionMode.hypertrophy;
      default:
        return ProgressionMode.hypertrophy;
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

/// User role within the app.
enum UserRole {
  user('user'),
  coach('coach'),
  adminUser('admin_user'),
  adminCoach('admin_coach');

  final String value;
  const UserRole(this.value);

  bool get isAdmin => this == adminUser || this == adminCoach;
  bool get isCoachRole => this == coach || this == adminCoach;

  static UserRole fromString(String? value) {
    switch (value) {
      case 'user':
        return UserRole.user;
      case 'coach':
        return UserRole.coach;
      case 'admin_user':
        return UserRole.adminUser;
      case 'admin_coach':
        return UserRole.adminCoach;
      default:
        return UserRole.user;
    }
  }
}
