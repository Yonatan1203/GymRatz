import 'package:uuid/uuid.dart';

import '../../../shared/models/enums.dart';
import '../../../shared/models/program.dart';
import '../../../shared/models/workout.dart';
import '../../../shared/models/workout_day.dart';
import '../../../shared/models/workout_exercise.dart';
import '../../../shared/models/workout_set.dart';
import '../../progression/domain/progression_engine.dart';
import '../../progression/domain/progression_suggestion.dart';
import '../../progress/data/pr_repository.dart';
import '../data/workout_repository.dart';
import 'workout_summary.dart';

class WorkoutService {
  final WorkoutRepository _workoutRepo;
  final PrRepository _prRepo;
  static const _uuid = Uuid();

  WorkoutService(this._workoutRepo, this._prRepo);

  /// Create a new workout from a program day template.
  /// Pre-fills weights from the most recent completed workout for this day.
  Future<Workout> startWorkout({
    required String uid,
    required Program program,
    required WorkoutDay day,
  }) async {
    // Look up last completed workout for this program day
    Map<String, WorkoutExercise>? lastExercises;
    try {
      final recentWorkouts = await _workoutRepo.getRecentWorkoutsForDay(
        uid, program.id, day.id,
      );
      if (recentWorkouts.isNotEmpty) {
        lastExercises = {
          for (final e in recentWorkouts.first.exercises) e.name: e
        };
      }
    } catch (_) {
      // Non-fatal: proceed without pre-fill
    }

    final exercises = day.exercises.map((pe) {
      final lastExercise = lastExercises?[pe.name];
      final lastSets = lastExercise?.sets ?? [];

      return WorkoutExercise(
        name: pe.name,
        equipment: pe.equipment ?? '',
        equipmentType: pe.equipmentType,
        repRange: '${pe.repMin}-${pe.repMax}',
        targetRir: pe.targetRir,
        progressionMode: pe.progressionMode,
        sets: List.generate(
          pe.sets,
          (i) => WorkoutSet(
            weight: i < lastSets.length ? lastSets[i].weight : 0,
            reps: i < lastSets.length ? lastSets[i].reps : 0,
            rir: pe.targetRir,
            equipmentType: pe.equipmentType,
          ),
        ),
      );
    }).toList();

    return Workout(
      id: _uuid.v4(),
      programId: program.id,
      workoutDayId: day.id,
      date: DateTime.now(),
      status: WorkoutStatus.inProgress,
      exercises: exercises,
    );
  }

  /// Complete a workout: calculate volume, check PRs, run PO engine.
  Future<WorkoutSummary> completeWorkout(
      String uid, Workout workout, String unit) async {
    int totalSets = 0;
    int totalReps = 0;
    double totalVolume = 0;
    final newPRs = <String>[];
    final suggestions = <ProgressionSuggestion>[];

    for (final exercise in workout.exercises) {
      final completedSets =
          exercise.sets.where((s) => s.completed && !s.isWarmup).toList();
      totalSets += completedSets.length;

      for (final set in completedSets) {
        totalReps += set.reps;
        totalVolume += set.weight * set.reps;

        // Check for PRs
        final isPR = await _prRepo.checkAndUpdatePR(
          uid,
          exerciseId: exercise.name.toLowerCase().replaceAll(' ', '_'),
          exerciseName: exercise.name,
          weight: set.weight,
          reps: set.reps,
        );
        if (isPR && !newPRs.contains(exercise.name)) {
          newPRs.add(exercise.name);
        }
      }

      // Parse rep range
      final parts = exercise.repRange.split('-');
      final repMin = int.tryParse(parts.first) ?? 8;
      final repMax = parts.length > 1 ? int.tryParse(parts.last) ?? 12 : repMin;

      // Run PO engine
      if (completedSets.isNotEmpty) {
        final suggestion = ProgressionEngine.suggest(
          performedSets: exercise.sets,
          currentWeight: completedSets.last.weight,
          repMin: repMin,
          repMax: repMax,
          targetRir: exercise.targetRir,
          equipment: exercise.equipmentType,
          unit: unit,
          mode: exercise.progressionMode,
        );
        suggestions.add(suggestion);
      }
    }

    final duration = workout.completedAt != null
        ? workout.completedAt!.difference(workout.date).inSeconds
        : 0;

    // Save completed workout
    final completed = workout.copyWith(
      status: WorkoutStatus.completed,
      totalVolume: totalVolume,
      duration: duration,
      completedAt: DateTime.now(),
    );
    await _workoutRepo.completeWorkout(uid, completed);

    return WorkoutSummary(
      totalSets: totalSets,
      totalReps: totalReps,
      totalVolume: totalVolume,
      duration: duration,
      newPRs: newPRs,
      suggestions: suggestions,
    );
  }

  /// Get workout stats for a user.
  Future<Map<String, dynamic>> getStats(String uid) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    // Get all workouts (use a wide range)
    final allWorkouts = await _workoutRepo
        .getWorkoutsForMonth(uid, now.year, now.month);

    final completedWorkouts =
        allWorkouts.where((w) => w.status == WorkoutStatus.completed).toList();
    final weeklyWorkouts = completedWorkouts
        .where((w) => w.date.isAfter(weekStart))
        .toList();

    double weeklyVolume = 0;
    for (final w in weeklyWorkouts) {
      weeklyVolume += w.totalVolume;
    }

    // Calculate streak (consecutive days)
    int streak = 0;
    if (completedWorkouts.isNotEmpty) {
      completedWorkouts.sort((a, b) => b.date.compareTo(a.date));
      var checkDate = DateTime(now.year, now.month, now.day);
      for (final w in completedWorkouts) {
        final wDate = DateTime(w.date.year, w.date.month, w.date.day);
        if (wDate == checkDate || wDate == checkDate.subtract(const Duration(days: 1))) {
          streak++;
          checkDate = wDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }

    return {
      'totalWorkouts': completedWorkouts.length,
      'streak': streak,
      'weeklyVolume': weeklyVolume,
      'weeklyWorkouts': weeklyWorkouts.length,
    };
  }
}
