import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/achievement.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/exercise.dart';
import '../../shared/models/personal_record.dart';
import '../../shared/models/program.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/weight_entry.dart';
import '../../shared/models/workout.dart';
import '../../features/exercises/data/exercise_repository.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

// ─── User Profile ───
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(uid);
});

// ─── Active Program ───
final activeProgramProvider = StreamProvider<Program?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(programRepositoryProvider).watchActiveProgram(uid);
});

// ─── User Programs ───
final userProgramsProvider = StreamProvider<List<Program>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(programRepositoryProvider).watchPrograms(uid);
});

// ─── Program by ID (family) ───
final programByIdProvider =
    FutureProvider.family<Program?, String>((ref, programId) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  return ref.watch(programRepositoryProvider).getProgram(uid, programId);
});

// ─── Recent Workouts ───
final recentWorkoutsProvider = StreamProvider<List<Workout>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(workoutRepositoryProvider).watchRecentWorkouts(uid);
});

// ─── Personal Records ───
final personalRecordsProvider = StreamProvider<List<PersonalRecord>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(prRepositoryProvider).watchPRs(uid);
});

// ─── Achievements ───
final achievementsProvider = StreamProvider<List<Achievement>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(achievementRepositoryProvider).watchAchievements(uid);
});

// ─── Weight Entries ───
final weightEntriesProvider = StreamProvider<List<WeightEntry>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(weightEntryRepositoryProvider).watchWeightEntries(uid);
});

// ─── Exercise Library ───
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  final firestore = ref.watch(firestoreProvider)!;
  return ExerciseRepository(firestore);
});

final bundledExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.loadBundledExercises();
});

final userExercisesProvider = StreamProvider<List<Exercise>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.watchUserExercises(uid);
});

final allExercisesProvider = Provider<List<Exercise>>((ref) {
  final bundled = ref.watch(bundledExercisesProvider).valueOrNull ?? [];
  final userExercises = ref.watch(userExercisesProvider).valueOrNull ?? [];
  final userNames = userExercises.map((e) => e.name.toLowerCase()).toSet();
  final filtered =
      bundled.where((e) => !userNames.contains(e.name.toLowerCase())).toList();
  return [...filtered, ...userExercises];
});

final exerciseLibraryProvider = Provider<List<Exercise>>((ref) {
  return ref.watch(allExercisesProvider);
});

// ─── Favorite Exercise IDs ───
final favoriteExerciseIdsProvider = StreamProvider<Set<String>>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  if (profile == null) return Stream.value({});
  return Stream.value(profile.favoriteExerciseIds.toSet());
});

// ─── Workout Stats ───
final workoutStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) {
    return {'totalWorkouts': 0, 'streak': 0, 'weeklyVolume': 0.0, 'weeklyWorkouts': 0};
  }
  return ref.watch(workoutServiceProvider).getStats(uid);
});

// ─── Calendar Month (family: "year-month") ───
final calendarMonthProvider = FutureProvider.family<Map<int, WorkoutStatus>, String>(
    (ref, yearMonth) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return {};

  final parts = yearMonth.split('-');
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);

  final workouts = await ref
      .watch(workoutRepositoryProvider)
      .getWorkoutsForMonth(uid, year, month);

  final result = <int, WorkoutStatus>{};
  for (final w in workouts) {
    result[w.date.day] = w.status;
  }
  return result;
});

// ─── Weekly Volume (6 weeks) ───
final weeklyVolumeProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return [];

  final now = DateTime.now();
  final results = <Map<String, dynamic>>[];

  for (int i = 5; i >= 0; i--) {
    final weekStart = now.subtract(Duration(days: now.weekday - 1 + (i * 7)));
    final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59));

    final workouts = await ref
        .watch(workoutRepositoryProvider)
        .getWorkoutsForMonth(uid, weekStart.year, weekStart.month);

    double volume = 0;
    for (final w in workouts) {
      if (w.date.isAfter(weekStart) &&
          w.date.isBefore(weekEnd) &&
          w.status == WorkoutStatus.completed) {
        volume += w.totalVolume;
      }
    }

    results.add({'week': 'W${6 - i}', 'value': volume});
  }

  return results;
});

// ─── Exercise Filter List (derived from PRs) ───
final exerciseFilterProvider = Provider<List<String>>((ref) {
  final prs = ref.watch(personalRecordsProvider).valueOrNull;
  if (prs == null || prs.isEmpty) return ['All'];
  final names = prs.map((p) => p.exerciseName).toSet().toList()..sort();
  return ['All', ...names];
});
