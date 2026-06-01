import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/analytics_service.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/program.dart';
import '../../../shared/models/workout.dart';
import '../../../shared/models/workout_day.dart';
import '../../../shared/models/workout_exercise.dart';
import '../../../shared/models/workout_set.dart';
import '../../achievements/domain/achievement_service.dart';
import '../../progression/data/progression_repository.dart';
import '../../progression/domain/progression_engine.dart';
import '../../progression/domain/progression_suggestion.dart';
import '../../progression/domain/models/progression_history.dart';
import '../../progress/data/pr_repository.dart';
import '../data/workout_repository.dart';
import 'workout_summary.dart';

class WorkoutService {
  final WorkoutRepository _workoutRepo;
  final PrRepository _prRepo;
  final ProgressionRepository _progressionRepo;
  final AchievementService _achievementService;
  final AnalyticsService _analyticsService;
  static const _uuid = Uuid();

  WorkoutService(
    this._workoutRepo,
    this._prRepo,
    this._progressionRepo,
    this._achievementService,
    this._analyticsService,
  );

  /// Create a new workout from a program day template.
  ///
  /// Pre-fills weights and reps from the PO engine's saved suggestions.
  /// If no suggestion exists (first time), prefills reps from the program
  /// template and leaves weight at 0.
  Future<Workout> startWorkout({
    required String uid,
    required Program program,
    required WorkoutDay day,
  }) async {
    // Load saved PO suggestions for all exercises in this day.
    final exerciseNames = day.exercises.map((e) => e.name).toList();
    Map<String, ProgressionSuggestion> suggestions = {};
    try {
      suggestions = await _progressionRepo.getSuggestionsForExercises(
        uid,
        exerciseNames,
      );
    } catch (e) {
      // Non-fatal: proceed without PO prefill. Logged so a failing read
      // (e.g. a missing Firestore index) is visible instead of silently
      // leaving the weights empty.
      debugPrint('startWorkout: failed to load PO suggestions: $e');
    }

    // Also load last completed workout for fallback.
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
    } catch (e) {
      // Non-fatal: proceed without fallback. The day-scoped query needs a
      // composite index (programId, workoutDayId, status, date); log so a
      // missing index surfaces instead of silently disabling prefill.
      debugPrint('startWorkout: failed to load last workout for fallback: $e');
    }

    final exercises = day.exercises.map((pe) {
      final suggestion = suggestions[pe.name] ??
          suggestions[ProgressionRepository.exerciseKey(pe.name)];
      final lastExercise = lastExercises?[pe.name];

      return _buildExerciseFromTemplate(pe, suggestion, lastExercise);
    }).toList();

    final workout = Workout(
      id: _uuid.v4(),
      programId: program.id,
      workoutDayId: day.id,
      date: DateTime.now(),
      status: WorkoutStatus.inProgress,
      exercises: exercises,
    );

    _analyticsService
        .logWorkoutStarted(programId: program.id, workoutDayId: day.id)
        .ignore();

    return workout;
  }

  /// Build a WorkoutExercise from a program template, using PO suggestions
  /// for prefill.
  WorkoutExercise _buildExerciseFromTemplate(
    dynamic pe, // ProgramExercise
    ProgressionSuggestion? suggestion,
    WorkoutExercise? lastExercise,
  ) {
    final int numSets;
    final double prefillWeight;
    final int prefillReps;
    final int prefillRir;

    if (suggestion != null) {
      // PO suggestion available: use it for prefill.
      numSets = suggestion.suggestedSets > 0
          ? suggestion.suggestedSets
          : pe.sets;
      prefillWeight = suggestion.suggestedWeight;
      prefillReps = suggestion.suggestedReps;
      prefillRir = pe.targetRir;
    } else if (lastExercise != null && lastExercise.sets.isNotEmpty) {
      // No PO suggestion but has history: copy last session as fallback.
      numSets = pe.sets;
      prefillWeight = lastExercise.sets.first.weight;
      prefillReps = lastExercise.sets.first.reps;
      prefillRir = pe.targetRir;
    } else {
      // First time: prefill reps from template, leave weight empty.
      numSets = pe.sets;
      prefillWeight = 0;
      prefillReps = pe.repMax;
      prefillRir = pe.targetRir;
    }

    return WorkoutExercise(
      name: pe.name,
      equipment: pe.equipment ?? '',
      equipmentType: pe.equipmentType,
      repRange: '${pe.repMin}-${pe.repMax}',
      targetRir: pe.targetRir,
      progressionMode: pe.progressionMode,
      restSeconds: pe.restSeconds,
      sets: List.generate(
        numSets,
        (i) {
          // For sets beyond what the suggestion covers, use same values.
          final weight = (suggestion != null && i < (lastExercise?.sets.length ?? 0))
              ? lastExercise!.sets[i].weight
              : prefillWeight;

          return WorkoutSet(
            weight: i == 0 ? prefillWeight : weight,
            reps: prefillReps,
            rir: prefillRir,
            equipmentType: pe.equipmentType,
          );
        },
      ),
    );
  }

  /// Complete a workout: calculate volume, check PRs, run PO engine,
  /// persist suggestions + history for next workout.
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

        // Check for PRs.
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

      // Parse rep range.
      final repMin = exercise.repMin;
      final repMax = exercise.repMax;

      // Run PO engine with real history.
      if (completedSets.isNotEmpty) {
        // Load existing history for this exercise.
        ProgressionHistory history;
        try {
          history = await _progressionRepo.getHistory(uid, exercise.name);
        } catch (_) {
          history = const ProgressionHistory();
        }

        final suggestion = ProgressionEngine.suggest(
          performedSets: exercise.sets,
          currentWeight: completedSets.last.weight,
          repMin: repMin,
          repMax: repMax,
          targetRir: exercise.targetRir,
          equipment: exercise.equipmentType,
          unit: unit,
          mode: exercise.progressionMode,
          history: history,
        );

        // Create suggestion with exercise name for storage.
        final namedSuggestion = ProgressionSuggestion(
          exerciseName: exercise.name,
          suggestedWeight: suggestion.suggestedWeight,
          suggestedReps: suggestion.suggestedReps,
          suggestedSets: suggestion.suggestedSets,
          suggestedDuration: suggestion.suggestedDuration,
          suggestedRestSeconds: suggestion.suggestedRestSeconds,
          reasoning: suggestion.reasoning,
          isDeload: suggestion.isDeload,
          backoffWeight: suggestion.backoffWeight,
          backoffSets: suggestion.backoffSets,
          score: suggestion.score,
          metrics: suggestion.metrics,
        );
        suggestions.add(namedSuggestion);

        // Compute updated history with this session's data.
        final metrics = suggestion.metrics;
        final score = suggestion.score;
        final updatedHistory = history.appendSession(
          sessionE1RM: metrics?.sessionE1RM ?? 0,
          smoothedE1RM: metrics?.smoothedE1RM ?? 0,
          score: score,
          density: metrics?.density,
          lowScoreThreshold: exercise.progressionMode == ProgressionMode.hypertrophy
              ? 75.0
              : 80.0,
          improvementThreshold: 0.25,
        );

        // Persist both the suggestion and updated history.
        try {
          await _progressionRepo.saveProgressionData(
            uid: uid,
            exerciseName: exercise.name,
            history: updatedHistory,
            suggestion: namedSuggestion,
          );
        } catch (e) {
          // Non-fatal: PO data will just not persist this session. Logged so
          // a failing write doesn't silently break next-session prefill.
          debugPrint('completeWorkout: failed to persist PO data for '
              '${exercise.name}: $e');
        }
      }
    }

    final duration = workout.completedAt != null
        ? workout.completedAt!.difference(workout.date).inSeconds
        : 0;

    // Save completed workout.
    final completed = workout.copyWith(
      status: WorkoutStatus.completed,
      totalVolume: totalVolume,
      duration: duration,
      completedAt: DateTime.now(),
    );
    await _workoutRepo.completeWorkout(uid, completed);

    // Best-effort achievement check after save. Uses month-scoped workout count
    // and per-session volume/PRs — cumulative stats require a future dedicated
    // stats document (tracked separately). Non-fatal: failures are logged but
    // do not block the summary being returned to the caller.
    List<String> unlockedAchievements = [];
    try {
      final stats = await getStats(uid);
      unlockedAchievements = await _achievementService.checkAchievements(
        uid,
        totalWorkouts: (stats['totalWorkouts'] as int? ?? 0),
        streak: (stats['streak'] as int? ?? 0),
        totalVolume: totalVolume,
        prCount: newPRs.length,
      );
      for (final id in unlockedAchievements) {
        _analyticsService.logAchievementUnlocked(id).ignore();
      }
    } catch (e) {
      debugPrint('completeWorkout: achievement check failed: $e');
    }

    _analyticsService.logWorkoutCompleted(
      durationSeconds: duration,
      exerciseCount: workout.exercises.length,
      totalSets: totalSets,
      totalVolume: totalVolume,
    ).ignore();

    return WorkoutSummary(
      totalSets: totalSets,
      totalReps: totalReps,
      totalVolume: totalVolume,
      duration: duration,
      newPRs: newPRs,
      suggestions: suggestions,
      unlockedAchievements: unlockedAchievements,
    );
  }

  /// Get workout stats for a user.
  Future<Map<String, dynamic>> getStats(String uid) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

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

    // Calculate streak (consecutive days).
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
