import '../models/achievement.dart';
import '../models/enums.dart';
import '../models/exercise.dart';
import '../models/program.dart';
import '../models/program_exercise.dart';
import '../models/user_profile.dart';
import '../models/workout_day.dart';
import '../models/workout_exercise.dart';
import '../models/workout_set.dart';
import 'exercise_seed_data.dart';

class SampleData {
  SampleData._();

  static const user = UserProfile(
    name: 'GymRatz User',
    initials: 'GR',
    email: 'user@example.com',
    age: 0,
    height: '0 cm',
    weight: 0,
    unit: 'lbs',
    experienceLevel: 'Intermediate',
    primaryGoal: 'Build Muscle',
  );

  // ─── Exercises ───
  /// Exercise library now backed by the comprehensive seed data (~55 exercises).
  static List<Exercise> get exercises => ExerciseSeedData.allExercises;

  // ─── Programs ───
  static const myPrograms = [
    Program(id: '1', name: 'PPL Split', workouts: 6, weeks: 8, progress: 65),
    Program(id: '2', name: 'Upper/Lower', workouts: 4, weeks: 6, progress: 30),
    Program(id: '3', name: 'Full Body', workouts: 3, weeks: 4, progress: 90),
  ];

  static const explorePrograms = [
    Program(id: '4', name: 'Stronglifts 5x5', workouts: 3, weeks: 12, difficulty: 'Beginner'),
    Program(id: '5', name: 'PHUL', workouts: 4, weeks: 8, difficulty: 'Intermediate'),
    Program(id: '6', name: 'nSuns 5/3/1', workouts: 5, weeks: 16, difficulty: 'Advanced'),
  ];

  // ─── Today's Workout Exercises ───
  static const todayExercises = [
    WorkoutExercise(
      name: 'Bench Press',
      equipment: 'Barbell',
      equipmentType: EquipmentType.barbell,
      repRange: '8-10',
      targetRir: 2,
      sets: [
        WorkoutSet(reps: 10, weight: 135, rir: 3, completed: true),
        WorkoutSet(reps: 8, weight: 155, rir: 2, completed: true),
        WorkoutSet(reps: 8, weight: 155, rir: 1),
      ],
    ),
    WorkoutExercise(
      name: 'Incline DB Press',
      equipment: 'Dumbbell',
      equipmentType: EquipmentType.dumbbell,
      repRange: '10-12',
      targetRir: 2,
      sets: [
        WorkoutSet(reps: 12, weight: 50, rir: 2),
        WorkoutSet(reps: 10, weight: 50, rir: 1),
        WorkoutSet(reps: 10, weight: 50, rir: 1),
      ],
    ),
    WorkoutExercise(
      name: 'Cable Flyes',
      equipment: 'Machine',
      equipmentType: EquipmentType.machineStack,
      repRange: '12-15',
      targetRir: 1,
      sets: [
        WorkoutSet(reps: 15, weight: 25, rir: 2),
        WorkoutSet(reps: 12, weight: 25, rir: 1),
        WorkoutSet(reps: 12, weight: 25, rir: 0),
      ],
    ),
  ];

  // ─── Achievements ───
  static const achievements = [
    Achievement(id: '1', title: 'First Workout', description: 'Complete your first workout', iconName: 'trophy', progress: 1, total: 1, unlocked: true, unlockedDate: null, rarity: 'Common', points: 10),
    Achievement(id: '2', title: 'Week Warrior', description: 'Work out 5 days in a week', iconName: 'flame', progress: 5, total: 5, unlocked: true, unlockedDate: null, rarity: 'Common', points: 25),
    Achievement(id: '3', title: 'PR Machine', description: 'Set 10 personal records', iconName: 'award', progress: 10, total: 10, unlocked: true, unlockedDate: null, rarity: 'Rare', points: 50),
    Achievement(id: '4', title: 'Iron Will', description: 'Maintain a 30-day streak', iconName: 'target', progress: 12, total: 30, rarity: 'Epic', points: 100),
    Achievement(id: '5', title: 'Century Club', description: 'Complete 100 workouts', iconName: 'star', progress: 24, total: 100, rarity: 'Epic', points: 150),
    Achievement(id: '6', title: 'Volume King', description: 'Log 100,000 lbs total volume', iconName: 'crown', progress: 45000, total: 100000, rarity: 'Legendary', points: 200),
    Achievement(id: '7', title: 'Consistency', description: 'Work out for 4 consecutive weeks', iconName: 'calendar', progress: 4, total: 4, unlocked: true, unlockedDate: null, rarity: 'Rare', points: 50),
    Achievement(id: '8', title: 'Early Bird', description: 'Complete 5 workouts before 8am', iconName: 'sunrise', progress: 2, total: 5, rarity: 'Common', points: 25),
    Achievement(id: '9', title: 'Program Complete', description: 'Finish an entire program', iconName: 'checkCircle', progress: 0, total: 1, rarity: 'Rare', points: 75),
    Achievement(id: '10', title: 'Legend', description: 'Reach 1000 total points', iconName: 'crown', progress: 310, total: 1000, rarity: 'Legendary', points: 500),
  ];

  // ─── Personal Records ───
  static const personalRecords = [
    {'exercise': 'Bench Press', 'weight': 225, 'unit': 'lbs', 'date': 'Feb 1, 2026'},
    {'exercise': 'Squat', 'weight': 315, 'unit': 'lbs', 'date': 'Jan 28, 2026'},
    {'exercise': 'Deadlift', 'weight': 405, 'unit': 'lbs', 'date': 'Jan 20, 2026'},
    {'exercise': 'Overhead Press', 'weight': 155, 'unit': 'lbs', 'date': 'Feb 8, 2026'},
  ];

  // ─── Calendar Data ───
  // 0 = empty, 1 = completed, 2 = scheduled, 3 = missed
  static const calendarDays = [
    0, 0, 0, 0, 0, 1, 2,
    1, 3, 1, 1, 2, 1, 2,
    1, 1, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0,
  ];

  static const weightEntries = [
    {'date': 'Feb 12, 2026', 'weight': 175.2},
    {'date': 'Feb 5, 2026', 'weight': 176.8},
    {'date': 'Jan 29, 2026', 'weight': 177.5},
  ];

  // ─── Progress Chart Data ───
  static const volumeData = [
    {'week': 'W1', 'value': 8500.0},
    {'week': 'W2', 'value': 9200.0},
    {'week': 'W3', 'value': 9800.0},
    {'week': 'W4', 'value': 10500.0},
    {'week': 'W5', 'value': 11200.0},
    {'week': 'W6', 'value': 12500.0},
  ];

  // ─── Program Detail ───
  static const programDetailDays = [
    WorkoutDay(
      id: '1',
      name: 'Push Day A',
      dayOfWeek: 'Monday',
      exercises: [
        ProgramExercise(id: '1', name: 'Bench Press', sets: 3, repMin: 8, repMax: 10, targetRir: 2, restSeconds: 120, progressionMode: ProgressionMode.strength, category: 'Chest', equipment: 'Barbell', equipmentType: EquipmentType.barbell),
        ProgramExercise(id: '2', name: 'Incline DB Press', sets: 3, repMin: 10, repMax: 12, targetRir: 2, restSeconds: 90, progressionMode: ProgressionMode.strength, category: 'Chest', equipment: 'Dumbbell', equipmentType: EquipmentType.dumbbell),
        ProgramExercise(id: '3', name: 'Overhead Press', sets: 3, repMin: 8, repMax: 10, targetRir: 2, restSeconds: 120, progressionMode: ProgressionMode.strength, category: 'Shoulders', equipment: 'Barbell', equipmentType: EquipmentType.barbell),
      ],
    ),
    WorkoutDay(
      id: '2',
      name: 'Pull Day A',
      dayOfWeek: 'Wednesday',
      exercises: [
        ProgramExercise(id: '4', name: 'Barbell Row', sets: 3, repMin: 8, repMax: 10, targetRir: 2, restSeconds: 120, progressionMode: ProgressionMode.strength, category: 'Back', equipment: 'Barbell', equipmentType: EquipmentType.barbell),
        ProgramExercise(id: '5', name: 'Pull-ups', sets: 3, repMin: 6, repMax: 10, targetRir: 2, restSeconds: 120, progressionMode: ProgressionMode.endurance, category: 'Back', equipment: 'Body Weight', equipmentType: EquipmentType.bodyweight),
        ProgramExercise(id: '6', name: 'Barbell Curl', sets: 3, repMin: 10, repMax: 12, targetRir: 1, restSeconds: 60, progressionMode: ProgressionMode.endurance, category: 'Arms', equipment: 'Barbell', equipmentType: EquipmentType.barbell),
      ],
    ),
    WorkoutDay(
      id: '3',
      name: 'Leg Day',
      dayOfWeek: 'Friday',
      exercises: [
        ProgramExercise(id: '7', name: 'Squat', sets: 4, repMin: 6, repMax: 8, targetRir: 2, restSeconds: 180, progressionMode: ProgressionMode.strength, category: 'Legs', equipment: 'Barbell', equipmentType: EquipmentType.barbell),
        ProgramExercise(id: '8', name: 'Romanian Deadlift', sets: 3, repMin: 8, repMax: 10, targetRir: 2, restSeconds: 120, progressionMode: ProgressionMode.strength, category: 'Legs', equipment: 'Barbell', equipmentType: EquipmentType.barbell),
        ProgramExercise(id: '9', name: 'Leg Press', sets: 3, repMin: 10, repMax: 12, targetRir: 1, restSeconds: 90, progressionMode: ProgressionMode.hypertrophy, category: 'Legs', equipment: 'Machine', equipmentType: EquipmentType.machinePlateLoaded),
      ],
    ),
  ];

  // ─── Recent Activity ───
  static const recentActivity = [
    'Yesterday - Pull Day',
    'Monday - Legs',
    'Saturday - Push Day',
  ];
}
