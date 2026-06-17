import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/workout_exercise.dart';
import '../../shared/models/workout_set.dart';

class ActiveWorkoutSession {
  final String dayId;
  final DateTime startTime;
  final String workoutName;
  final String currentExerciseName;
  final List<WorkoutExercise> exercises;
  final List<List<WorkoutSet>> sets;
  final Set<int> expandedIndices;
  final int restSeconds;
  final bool restActive;
  final bool restMinimized;
  final bool timerRunning;
  final String notes;
  /// When the rest timer will reach zero (set when countdown begins).
  final DateTime? restEndTime;

  const ActiveWorkoutSession({
    required this.dayId,
    required this.startTime,
    required this.workoutName,
    this.currentExerciseName = '',
    this.exercises = const [],
    this.sets = const [],
    this.expandedIndices = const {},
    this.restSeconds = 120,
    this.restActive = false,
    this.restMinimized = false,
    this.timerRunning = false,
    this.notes = '',
    this.restEndTime,
  });

  ActiveWorkoutSession copyWith({
    String? dayId,
    DateTime? startTime,
    String? workoutName,
    String? currentExerciseName,
    List<WorkoutExercise>? exercises,
    List<List<WorkoutSet>>? sets,
    Set<int>? expandedIndices,
    int? restSeconds,
    bool? restActive,
    bool? restMinimized,
    bool? timerRunning,
    String? notes,
    DateTime? restEndTime,
    bool clearRestEndTime = false,
  }) {
    return ActiveWorkoutSession(
      dayId: dayId ?? this.dayId,
      startTime: startTime ?? this.startTime,
      workoutName: workoutName ?? this.workoutName,
      currentExerciseName: currentExerciseName ?? this.currentExerciseName,
      exercises: exercises ?? this.exercises,
      sets: sets ?? this.sets,
      expandedIndices: expandedIndices ?? this.expandedIndices,
      restSeconds: restSeconds ?? this.restSeconds,
      restActive: restActive ?? this.restActive,
      restMinimized: restMinimized ?? this.restMinimized,
      timerRunning: timerRunning ?? this.timerRunning,
      notes: notes ?? this.notes,
      restEndTime: clearRestEndTime ? null : (restEndTime ?? this.restEndTime),
    );
  }
}

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutSession?> {
  ActiveWorkoutNotifier() : super(null);

  void startSession({
    required String dayId,
    required String workoutName,
    required List<WorkoutExercise> exercises,
    required List<List<WorkoutSet>> sets,
  }) {
    state = ActiveWorkoutSession(
      dayId: dayId,
      startTime: DateTime.now(),
      workoutName: workoutName,
      exercises: exercises,
      sets: sets,
      expandedIndices: {0},
      currentExerciseName: exercises.isNotEmpty ? exercises.first.name : '',
    );
  }

  ActiveWorkoutSession? getSessionForDay(String dayId) {
    if (state != null && state!.dayId == dayId) return state;
    return null;
  }

  void syncState({
    List<WorkoutExercise>? exercises,
    List<List<WorkoutSet>>? sets,
    Set<int>? expandedIndices,
    int? restSeconds,
    bool? restActive,
    bool? restMinimized,
    bool? timerRunning,
    String? currentExerciseName,
    String? notes,
    DateTime? restEndTime,
    bool clearRestEndTime = false,
  }) {
    if (state == null) return;
    state = state!.copyWith(
      exercises: exercises,
      sets: sets,
      expandedIndices: expandedIndices,
      restSeconds: restSeconds,
      restActive: restActive,
      restMinimized: restMinimized,
      timerRunning: timerRunning,
      currentExerciseName: currentExerciseName,
      notes: notes,
      restEndTime: restEndTime,
      clearRestEndTime: clearRestEndTime,
    );
  }

  void endSession() {
    state = null;
  }
}

final activeWorkoutSessionProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutSession?>((ref) {
  return ActiveWorkoutNotifier();
});

final workoutElapsedSecondsProvider = StreamProvider<int>((ref) {
  final session = ref.watch(activeWorkoutSessionProvider);
  if (session == null) return const Stream.empty();
  return Stream.periodic(const Duration(seconds: 1), (_) {
    return DateTime.now().difference(session.startTime).inSeconds;
  });
});

/// Live countdown of rest timer seconds remaining (derived from restEndTime).
final restTimerSecondsProvider = StreamProvider<int>((ref) {
  final session = ref.watch(activeWorkoutSessionProvider);
  if (session == null || session.restEndTime == null || !session.timerRunning) {
    return const Stream.empty();
  }
  return Stream.periodic(const Duration(seconds: 1), (_) {
    return max(0, session.restEndTime!.difference(DateTime.now()).inSeconds);
  });
});
