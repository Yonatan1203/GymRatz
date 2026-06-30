import 'dart:async';
import 'dart:convert';
import 'dart:math' show max;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../theme/app_icons.dart';

import '../../../app/providers.dart';
import '../../../core/notification_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/utils/platform_adapter.dart';
import '../../../shared/widgets/custom_badge.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/custom_input.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import 'widgets/first_time_workout_tips.dart';
import 'widgets/workout_completion_screen.dart';
import 'widgets/workout_screen_header.dart';

import '../../../shared/models/enums.dart';
import '../../../shared/models/exercise.dart';
import '../../../shared/models/workout.dart';
import '../../../shared/models/workout_set.dart';
import '../../../shared/models/workout_exercise.dart';
import '../domain/workout_summary.dart';

class WorkoutLoggingScreen extends ConsumerStatefulWidget {
  final String dayId;
  /// When true the screen operates in free-workout mode: no program day is
  /// loaded; the user builds the workout from scratch by adding exercises.
  final bool isFreeWorkout;

  const WorkoutLoggingScreen({
    super.key,
    this.dayId = '',
    this.isFreeWorkout = false,
  });

  @override
  ConsumerState<WorkoutLoggingScreen> createState() => _WorkoutLoggingScreenState();
}

class _WorkoutLoggingScreenState extends ConsumerState<WorkoutLoggingScreen>
    with TickerProviderStateMixin {
  late List<List<WorkoutSet>> _sets;
  late List<WorkoutExercise> _exercises;
  late Set<int> _expanded;
  bool _completed = false;
  bool _saving = false;
  Timer? _durationTimer;
  int _elapsedSeconds = 0;
  String _notes = '';
  String _workoutName = 'Workout';
  bool _initialized = false;
  bool _loadingExercises = false;
  bool _showFirstTimeTips = false;
  late DateTime _startTime;
  WorkoutSummary? _workoutSummary;

  // Rest timer state
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  int _restTotalSeconds = 0;
  bool _restTimerActive = false;

  static const _workoutCacheKeyPrefix = 'in_progress_workout';

  String get _workoutCacheKey {
    final uid = ref.read(currentUidProvider) ?? '';
    return '${_workoutCacheKeyPrefix}_$uid';
  }

  /// Save current workout state after each set update
  Future<void> _saveWorkoutState() async {
    // Skip persistence for free workouts — they have no dayId anchor and
    // recovery would require selecting exercises again anyway.
    if (widget.isFreeWorkout) return;
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'dayId': widget.dayId,
      'workoutName': _workoutName,
      'elapsedSeconds': _elapsedSeconds,
      'exercises': _exercises.map((e) => e.toJson()).toList(),
      'sets': _sets
          .map((exSets) => exSets.map((s) => s.toJson()).toList())
          .toList(),
      'savedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_workoutCacheKey, json.encode(data));
  }

  /// Check for and restore incomplete workout on screen init
  Future<bool> _checkForRecovery() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_workoutCacheKey);
    if (cached == null) return false;

    final data = json.decode(cached) as Map<String, dynamic>;
    final savedAt = DateTime.parse(data['savedAt'] as String);
    // Only offer recovery if saved within last 24 hours
    if (DateTime.now().difference(savedAt).inHours > 24) {
      await prefs.remove(_workoutCacheKey);
      return false;
    }
    return true;
  }

  Future<void> _clearWorkoutCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_workoutCacheKey);
  }

  Future<void> _restoreWorkoutFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_workoutCacheKey);
    if (cached == null) return;

    try {
      final data = json.decode(cached) as Map<String, dynamic>;
      final exercisesList = (data['exercises'] as List)
          .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList();
      final setsList = (data['sets'] as List)
          .map((exSets) => (exSets as List)
              .map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>))
              .toList())
          .toList();

      if (mounted) {
        setState(() {
          _workoutName = data['workoutName'] as String? ?? _workoutName;
          _elapsedSeconds = data['elapsedSeconds'] as int? ?? _elapsedSeconds;
          _exercises = exercisesList;
          _sets = setsList;
        });
        _rebuildAllControllers();
        _syncToProvider();
      }
    } catch (e) {
      debugPrint('Failed to restore workout from cache: $e');
      await _clearWorkoutCache();
    }
  }

  // Persistent controllers keyed by 'exIdx-setIdx-field'
  final Map<String, TextEditingController> _controllers = {};

  /// Formats a weight value for display in the text field.
  /// Shows integers without decimals (80), fractional values with one decimal (82.5).
  /// Returns empty string for 0 so the hint text shows instead.
  static String _weightText(double weight) {
    if (weight <= 0) return '';
    return weight % 1 == 0 ? '${weight.toInt()}' : weight.toStringAsFixed(1);
  }

  TextEditingController _getController(int exIdx, int setIdx, String field, String initialValue) {
    final key = '$exIdx-$setIdx-$field';
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: initialValue);
    }
    return _controllers[key]!;
  }

  void _rebuildAllControllers() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    for (int exIdx = 0; exIdx < _sets.length; exIdx++) {
      for (int setIdx = 0; setIdx < _sets[exIdx].length; setIdx++) {
        final s = _sets[exIdx][setIdx];
        _getController(exIdx, setIdx, 'reps', s.reps > 0 ? '${s.reps}' : '');
        _getController(exIdx, setIdx, 'weight', _weightText(s.weight));
        _getController(exIdx, setIdx, 'rir', (s.rir ?? 0) > 0 ? '${s.rir}' : '');
        _getController(exIdx, setIdx, 'duration', s.durationSeconds > 0 ? '${s.durationSeconds}' : '');
      }
    }
  }

  void _updateSet(int exIdx, int setIdx, String field, String text) {
    final current = _sets[exIdx][setIdx];
    WorkoutSet updated;
    switch (field) {
      case 'reps':
        updated = current.copyWith(reps: int.tryParse(text) ?? 0);
        break;
      case 'weight':
        updated = current.copyWith(weight: double.tryParse(text) ?? 0);
        break;
      case 'rir':
        updated = current.copyWith(rir: int.tryParse(text) ?? 0);
        break;
      case 'duration':
        updated = current.copyWith(durationSeconds: int.tryParse(text) ?? 0, reps: 0);
        break;
      default:
        return;
    }
    _sets[exIdx][setIdx] = updated;
    // Debounce sync — don't setState here to avoid rebuild during typing
    _syncToProvider();
    _saveWorkoutState();
  }

  void _initFromProvider() {
    if (_initialized) return;
    _initialized = true;

    // Free workouts use a sentinel dayId; look up any existing free session.
    final sessionDayId = widget.isFreeWorkout ? '__free__' : widget.dayId;
    final existingSession = ref.read(activeWorkoutSessionProvider.notifier)
        .getSessionForDay(sessionDayId);

    if (existingSession != null) {
      _startTime = existingSession.startTime;
      _workoutName = existingSession.workoutName;
      _exercises = List.from(existingSession.exercises);
      _sets = existingSession.sets.map((s) => List<WorkoutSet>.from(s)).toList();
      _expanded = Set.from(existingSession.expandedIndices);
      _notes = existingSession.notes;
      _elapsedSeconds = DateTime.now().difference(_startTime).inSeconds;
    } else {
      _startTime = DateTime.now();

      if (widget.isFreeWorkout) {
        // Free workout — start empty; user adds exercises via the FAB.
        _workoutName = 'Free Workout';
        _exercises = [];
        _sets = [];
        Future(() {
          ref.read(activeWorkoutSessionProvider.notifier).startSession(
            dayId: '__free__',
            workoutName: _workoutName,
            exercises: _exercises,
            sets: _sets,
          );
        });
      } else {
        final activeProgram = ref.read(activeProgramProvider).valueOrNull;
        final matchingDay = activeProgram?.days
            .where((d) => d.id == widget.dayId)
            .toList();

        if (matchingDay != null && matchingDay.isNotEmpty) {
          final day = matchingDay.first;
          _workoutName = day.name;
          // Start with template defaults synchronously (weight=0).
          _exercises = day.exercises.map((pe) => WorkoutExercise(
            name: pe.name,
            equipment: pe.equipment ?? 'Barbell',
            equipmentType: pe.equipmentType,
            exerciseType: pe.isTimeBased ? ExerciseType.timed : ExerciseType.reps,
            repRange: Formatters.reps(pe.repMin, pe.repMax),
            targetRir: pe.targetRir,
            restSeconds: pe.restSeconds,
            sets: List.generate(pe.sets, (_) => const WorkoutSet()),
          )).toList();
          _sets = _exercises.map((e) => List<WorkoutSet>.from(e.sets)).toList();

          // Async: load PO-prefilled exercises from WorkoutService.
          final uid = ref.read(currentUidProvider);
          if (uid != null) {
            _loadingExercises = true;
            Future(() async {
              try {
                final workout = await ref.read(workoutServiceProvider).startWorkout(
                  uid: uid,
                  program: activeProgram!,
                  day: day,
                );
                if (mounted) {
                  setState(() {
                    _exercises = List.from(workout.exercises);
                    _sets = _exercises.map((e) => List<WorkoutSet>.from(e.sets)).toList();
                    _loadingExercises = false;
                    _rebuildAllControllers();
                  });
                  ref.read(activeWorkoutSessionProvider.notifier).startSession(
                    dayId: widget.dayId,
                    workoutName: _workoutName,
                    exercises: _exercises,
                    sets: _sets,
                  );
                }
              } catch (e, st) {
                // PO prefill failed — keep template defaults already set above.
                // Log so a failing read (e.g. a missing Firestore index) is
                // visible instead of silently leaving weights empty.
                debugPrint('startWorkout prefill failed, using template defaults: $e');
                FirebaseCrashlytics.instance.recordError(
                  e, st,
                  reason: 'workout weight prefill failed',
                  fatal: false,
                );
                if (mounted) {
                  setState(() => _loadingExercises = false);
                  ref.read(activeWorkoutSessionProvider.notifier).startSession(
                    dayId: widget.dayId,
                    workoutName: _workoutName,
                    exercises: _exercises,
                    sets: _sets,
                  );
                }
              }
            });
          } else {
            // No uid — use template defaults.
            Future(() {
              ref.read(activeWorkoutSessionProvider.notifier).startSession(
                dayId: widget.dayId,
                workoutName: _workoutName,
                exercises: _exercises,
                sets: _sets,
              );
            });
          }
        } else {
          _exercises = [];
          _sets = [];
        }
      }
      _expanded = {0};
    }

    _rebuildAllControllers();

    // Show first-time tips if user hasn't completed a workout before.
    if (existingSession == null) {
      SharedPreferences.getInstance().then((prefs) {
        if (mounted && !(prefs.getBool('has_completed_workout') ?? false)) {
          setState(() => _showFirstTimeTips = true);
        }
      });
    }

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });

    // Check for recoverable workout state from a previous session.
    // Free workouts are never persisted, so skip the recovery check.
    if (widget.isFreeWorkout) return;
    _checkForRecovery().then((hasRecovery) {
      if (hasRecovery && mounted && existingSession == null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Resume Workout?'),
            content: const Text(
              'A previous workout session was interrupted. Would you like to resume where you left off?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _clearWorkoutCache();
                  Navigator.pop(ctx);
                },
                child: const Text('Discard'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _restoreWorkoutFromCache();
                },
                child: const Text('Resume'),
              ),
            ],
          ),
        );
      }
    });
  }

  void _syncToProvider() {
    final currentExercise = _expanded.isNotEmpty && _expanded.first < _exercises.length
        ? _exercises[_expanded.first].name
        : '';
    // Ensure a session exists before syncing (may not be initialized yet for
    // free workouts where the session is started asynchronously).
    if (ref.read(activeWorkoutSessionProvider) == null) return;
    ref.read(activeWorkoutSessionProvider.notifier).syncState(
      exercises: List.from(_exercises),
      sets: _sets.map((s) => List<WorkoutSet>.from(s)).toList(),
      expandedIndices: Set.from(_expanded),
      currentExerciseName: currentExercise,
      notes: _notes,
    );
  }

  String _formatElapsed(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _restTimer?.cancel();
    NotificationService().cancelRestTimer();
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  void _startRestTimer(int seconds) {
    if (seconds <= 0) return;
    _restTimer?.cancel();
    NotificationService().cancelRestTimer();
    NotificationService().scheduleRestTimerNotification(seconds);

    setState(() {
      _restTimerActive = true;
      _restSecondsRemaining = seconds;
      _restTotalSeconds = seconds;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_restSecondsRemaining <= 1) {
        t.cancel();
        _restTimer = null;
        if (mounted) {
          setState(() {
            _restTimerActive = false;
            _restSecondsRemaining = 0;
            _restTotalSeconds = 0;
          });
          PlatformAdapter.hapticMedium();
        }
      } else {
        setState(() => _restSecondsRemaining--);
      }
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    _restTimer = null;
    NotificationService().cancelRestTimer();
    if (mounted) {
      setState(() {
        _restTimerActive = false;
        _restSecondsRemaining = 0;
        _restTotalSeconds = 0;
      });
    }
  }

  void _toggleSet(int exIdx, int setIdx) {
    PlatformAdapter.hapticLight();
    final current = _sets[exIdx][setIdx];
    final wasCompleted = current.completed;

    setState(() {
      _sets[exIdx][setIdx] = current.copyWith(completed: !wasCompleted);
    });

    if (!wasCompleted) {
      _syncToProvider();
      _saveWorkoutState();
      // Start rest timer using the exercise's configured rest time (default 60s).
      final restSecs = (_exercises[exIdx].restSeconds > 0)
          ? _exercises[exIdx].restSeconds
          : 60;
      _startRestTimer(restSecs);
      // Auto-advance: if all sets of this exercise are done, expand the next one.
      final allDone = _sets[exIdx].every((s) => s.completed);
      if (allDone && exIdx + 1 < _exercises.length) {
        setState(() {
          _expanded.clear();
          _expanded.add(exIdx + 1);
        });
        _syncToProvider();
      }
    } else {
      // Uncompleting — just sync
      _syncToProvider();
    }
  }

  List<WorkoutExercise> _buildExercisesWithSets() {
    return List.generate(_exercises.length, (i) {
      return _exercises[i].copyWith(sets: List<WorkoutSet>.from(_sets[i]));
    });
  }

  Future<void> _finishWorkout() async {
    if (_saving) return;

    // Guard: ensure subscription is active before saving workout
    try {
      await ref.read(subscriptionGuardProvider)();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription expired — subscribe to continue.')),
        );
      }
      return;
    }

    setState(() => _saving = true);

    _durationTimer?.cancel();
    _stopRestTimer();

    final uid = ref.read(currentUidProvider);
    final profile = ref.read(userProfileProvider).valueOrNull;
    final unit = profile?.unit ?? 'lbs';

    final exercises = _buildExercisesWithSets();
    // Free workouts have no program/day linkage; store empty strings so
    // completeWorkout (and the Firestore repo) can accept the record.
    final programId = widget.isFreeWorkout
        ? ''
        : (ref.read(activeProgramProvider).valueOrNull?.id ?? '');
    final workoutDayId = widget.isFreeWorkout ? '' : widget.dayId;
    final workout = Workout(
      id: const Uuid().v4(),
      programId: programId,
      workoutDayId: workoutDayId,
      date: _startTime,
      status: WorkoutStatus.completed,
      exercises: exercises,
      completedAt: DateTime.now(),
      notes: _notes.isNotEmpty ? _notes : null,
    );

    ref.read(activeWorkoutSessionProvider.notifier).endSession();
    await _clearWorkoutCache();

    if (uid != null) {
      try {
        final summary = await ref.read(workoutServiceProvider).completeWorkout(uid, workout, unit);
        if (mounted) {
          PlatformAdapter.hapticMedium();
          SharedPreferences.getInstance().then((p) => p.setBool('has_completed_workout', true));
          setState(() {
            _workoutSummary = summary;
            _completed = true;
            _saving = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _completed = true;
            _saving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Workout saved locally. Sync failed: $e')),
          );
        }
      }
    } else {
      // Not authenticated — still show completion
      setState(() {
        _completed = true;
        _saving = false;
      });
    }
  }

  Future<void> _confirmFinish() async {
    final incompleteSets = _sets.fold<int>(0, (sum, ex) => sum + ex.where((s) => !s.completed).length);

    if (incompleteSets == 0) {
      await _finishWorkout();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish Workout?'),
        content: Text('You have $incompleteSets incomplete ${incompleteSets == 1 ? 'set' : 'sets'}. Are you sure you want to finish?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _finishWorkout();
    }
  }

  void _showAddExerciseSheet() {
    final allExercises = ref.read(exerciseLibraryProvider);
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filtered = searchQuery.isEmpty
                ? allExercises
                : allExercises.where((e) => e.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (ctx, scrollController) {
                return Column(
                  children: [
                    SizedBox(height: 12.h),
                    Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: context.mutedForeground.withValues(alpha: 0.3),
                        borderRadius: AppRadius.borderFull,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Add Exercise', style: AppTextStyles.h3.copyWith(color: context.foreground)),
                          SizedBox(height: 12.h),
                          CustomInput(
                            hint: 'Search exercises...',
                            prefixIcon: Icon(AppIcons.search, size: 20.r, color: context.mutedForeground),
                            onChanged: (v) => setSheetState(() => searchQuery = v),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final exercise = filtered[i];
                          return ListTile(
                            title: Text(exercise.name, style: AppTextStyles.bodySmall.copyWith(color: context.foreground)),
                            subtitle: Text('${exercise.equipment} • ${exercise.muscle}',
                                style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                            trailing: Icon(AppIcons.plus, size: 20.r, color: context.primaryColor),
                            onTap: () {
                              _addExercise(exercise);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _addExercise(Exercise exercise) {
    final newExercise = WorkoutExercise(
      name: exercise.name,
      equipment: exercise.equipment,
      equipmentType: exercise.equipmentType,
      repRange: '8-12',
      targetRir: 2,
      sets: List.generate(3, (_) => const WorkoutSet()),
    );

    setState(() {
      _exercises.add(newExercise);
      _sets.add(List<WorkoutSet>.from(newExercise.sets));
      final newIdx = _exercises.length - 1;
      _expanded.clear();
      _expanded.add(newIdx);

      // Create controllers for the new sets
      for (int setIdx = 0; setIdx < 3; setIdx++) {
        _getController(newIdx, setIdx, 'reps', '');
        _getController(newIdx, setIdx, 'weight', '');
        _getController(newIdx, setIdx, 'rir', '');
        _getController(newIdx, setIdx, 'duration', '');
      }
    });
    _syncToProvider();
  }

  @override
  Widget build(BuildContext context) {
    _initFromProvider();
    if (_completed) return WorkoutCompletionScreen(
      workoutName: _workoutName,
      exercises: _exercises,
      sets: _sets,
      startTime: _startTime,
      workoutSummary: _workoutSummary,
      unit: ref.read(userProfileProvider).valueOrNull?.unit ?? 'lbs',
      onHome: () => context.go('/home'),
    );
    if (_loadingExercises) {
      return Scaffold(
        body: SafeArea(
          child: SkeletonLoader(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLine(width: 180, height: 24),
                  SizedBox(height: AppSpacing.sm),
                  const SkeletonLine(width: 120, height: 14),
                  SizedBox(height: AppSpacing.xl),
                  ...List.generate(3, (_) => Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: SkeletonCard(height: 90),
                  )),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final isDark = context.isDark;
    final exercises = _exercises;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
          WorkoutScreenHeader(
            workoutName: _workoutName,
            formattedElapsed: _formatElapsed(_elapsedSeconds),
            saving: _saving,
            onBack: () {
              _syncToProvider();
              context.pop();
            },
            onFinish: _confirmFinish,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
                  children: [
                    if (_showFirstTimeTips)
                      FirstTimeWorkoutTips(
                        onClose: () => setState(() => _showFirstTimeTips = false),
                      ),
                    if (widget.isFreeWorkout && exercises.isEmpty)
                      _buildFreeWorkoutEmptyState(context),
                    ...List.generate(exercises.length, (i) => _buildExerciseCard(context, isDark, i, exercises[i])),
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(AppIcons.fileText, size: 18.r, color: context.primaryColor),
                              SizedBox(width: 8.w),
                              Text('Workout Notes', style: AppTextStyles.h4.copyWith(color: context.foreground, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          CustomInput(
                            hint: 'How did it go?',
                            maxLines: 3,
                            onChanged: (v) => _notes = v,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    CustomButton(
                      text: '+ Add Exercise',
                      variant: ButtonVariant.dashed,
                      icon: AppIcons.plus,
                      onPressed: _showAddExerciseSheet,
                    ),
                    SizedBox(height: 60.h),
                  ],
                ),
          ),
            ],
          ),
          // Rest timer — overlaid at the bottom when active
          if (_restTimerActive)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildRestTimerBanner(context),
            ),
        ],
      ),
    );
  }

  Widget _buildRestTimerBanner(BuildContext context) {
    final progress = _restTotalSeconds > 0
        ? _restSecondsRemaining / _restTotalSeconds
        : 0.0;
    final minutes = _restSecondsRemaining ~/ 60;
    final seconds = _restSecondsRemaining % 60;
    final timeStr = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: AppRadius.borderLg,
          border: Border.all(color: context.primaryColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36.r,
              height: 36.r,
              child: Stack(
                children: [
                  CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 3,
                    backgroundColor: context.mutedColor,
                    valueColor: AlwaysStoppedAnimation(context.primaryColor),
                  ),
                  Center(
                    child: Icon(Icons.timer_outlined, size: 14.r, color: context.primaryColor),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('REST', style: AppTextStyles.caption.copyWith(color: context.mutedForeground, fontWeight: FontWeight.w600, letterSpacing: 1)),
                Text(timeStr, style: AppTextStyles.h3.copyWith(color: context.foreground, fontWeight: FontWeight.w700)),
              ],
            ),
            const Spacer(),
            _restAdjustButton(context, '−30', () {
              setState(() => _restSecondsRemaining = max(5, _restSecondsRemaining - 30));
            }),
            SizedBox(width: 6.w),
            _restAdjustButton(context, '+30', () {
              setState(() {
                _restSecondsRemaining += 30;
                _restTotalSeconds = max(_restTotalSeconds, _restSecondsRemaining);
              });
            }),
            SizedBox(width: 12.w),
            GestureDetector(
              onTap: _stopRestTimer,
              child: Text('Skip', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _restAdjustButton(BuildContext context, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        PlatformAdapter.hapticLight();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: context.mutedColor,
          borderRadius: AppRadius.borderSm,
        ),
        child: Text(label, style: AppTextStyles.caption.copyWith(color: context.mutedForeground, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildFreeWorkoutEmptyState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: CustomCard(
        padding: EdgeInsets.all(24.r),
        child: Column(
          children: [
            Icon(AppIcons.dumbbell, size: 40.r, color: context.mutedForeground),
            SizedBox(height: 16.h),
            Text(
              'Build Your Workout',
              style: AppTextStyles.h3.copyWith(color: context.foreground, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            Text(
              'Tap "+ Add Exercise" below to start adding exercises.',
              style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Shows last-session weights and PO suggestion as compact context chips.
  Widget _buildExerciseContext(BuildContext context, WorkoutExercise exercise) {
    final unit = ref.read(userProfileProvider).valueOrNull?.unit ?? 'lbs';
    final hasPrev = exercise.previousSets.isNotEmpty;
    final hasPo = exercise.poSuggestedWeight != null && exercise.poSuggestedWeight! > 0;
    if (!hasPrev && !hasPo) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 6.h),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 4.h,
        children: [
          if (hasPrev) ...[
            Text('Last:', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
            ...exercise.previousSets.take(4).map((s) {
              final isBw = exercise.equipmentType == EquipmentType.bodyweight;
              final wStr = (isBw || s.weight <= 0) ? 'BW' : '${_weightText(s.weight)}$unit';
              return Text(
                '${s.reps}×$wStr',
                style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
              );
            }),
          ],
          if (hasPo)
            CustomBadge(
              text: 'PO: ${_weightText(exercise.poSuggestedWeight!)} $unit',
              backgroundColor: context.primaryColor.withValues(alpha: 0.12),
              textColor: context.primaryColor,
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, bool isDark, int exIdx, WorkoutExercise exercise) {
    final isExpanded = _expanded.contains(exIdx);
    final sets = _sets[exIdx];
    final completedCount = sets.where((s) => s.completed).length;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: CustomCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) { _expanded.clear(); } else { _expanded.clear(); _expanded.add(exIdx); }
                });
                _syncToProvider();
              },
              borderRadius: AppRadius.borderXl,
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(exercise.name, style: AppTextStyles.h4.copyWith(color: context.foreground, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              CustomBadge(
                                text: exercise.equipment,
                                backgroundColor: context.secondaryColor.withValues(alpha: 0.2),
                                textColor: context.secondaryColor,
                              ),
                              SizedBox(width: 8.w),
                              Text('$completedCount/${sets.length} sets', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(isExpanded ? AppIcons.chevronUp : AppIcons.chevronDown, size: 24.r, color: context.mutedForeground),
                  ],
                ),
              ),
            ),
            if (isExpanded) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 4.h),
                child: Row(
                  children: [
                    CustomBadge(text: '${exercise.repRange} reps'),
                    SizedBox(width: 8.w),
                    CustomBadge(text: 'RIR ${exercise.targetRir}', backgroundColor: context.accentColor.withValues(alpha: 0.2), textColor: context.accentColor),
                  ],
                ),
              ),
              _buildExerciseContext(context, exercise),
              // Grid header
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                child: Row(
                  children: [
                    SizedBox(width: 32.w, child: _gridHeaderText(context, 'SET')),
                    Expanded(flex: 2, child: _gridHeaderText(context, exercise.isTimed ? 'SEC' : 'REPS')),
                    Expanded(flex: 3, child: _gridHeaderText(context, exercise.equipmentType == EquipmentType.bodyweight ? 'BW' : 'WEIGHT')),
                    Expanded(flex: 2, child: _gridHeaderText(context, 'RIR')),
                    SizedBox(width: 36.w),
                  ],
                ),
              ),
              ...List.generate(sets.length, (sIdx) => _buildSetRow(context, exIdx, sIdx, sets[sIdx])),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                child: CustomButton(
                  text: '+ Add Set',
                  variant: ButtonVariant.dashed,
                  onPressed: () {
                    final newSetIdx = _sets[exIdx].length;
                    setState(() => _sets[exIdx].add(const WorkoutSet()));
                    _getController(exIdx, newSetIdx, 'reps', '');
                    _getController(exIdx, newSetIdx, 'weight', '');
                    _getController(exIdx, newSetIdx, 'rir', '');
                    _getController(exIdx, newSetIdx, 'duration', '');
                    _syncToProvider();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _gridHeaderText(BuildContext context, String text) {
    return Text(text, style: AppTextStyles.caption.copyWith(color: context.mutedForeground, fontWeight: FontWeight.w600), textAlign: TextAlign.center);
  }

  Widget _buildSetRow(BuildContext context, int exIdx, int sIdx, WorkoutSet set) {
    final exercise = _exercises[exIdx];
    final isBw = exercise.equipmentType == EquipmentType.bodyweight;
    final isTimed = exercise.isTimed;
    final unit = ref.read(userProfileProvider).valueOrNull?.unit ?? 'lbs';

    final rowContent = Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 6.h),
      child: Row(
        children: [
          SizedBox(
            width: 32.w,
            child: Center(
              child: Text(
                '${sIdx + 1}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: set.completed ? context.primaryColor : context.mutedForeground,
                  fontWeight: set.completed ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
          // Reps or Duration field (GYM-122)
          Expanded(
            flex: 2,
            child: isTimed
                ? _numField(context, exIdx, sIdx, 'duration', 'sec')
                : _numField(context, exIdx, sIdx, 'reps', 'Reps'),
          ),
          Expanded(
            flex: 3,
            child: _numField(context, exIdx, sIdx, 'weight', isBw ? '+$unit' : unit,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false)),
          ),
          Expanded(
            flex: 2,
            child: _numField(context, exIdx, sIdx, 'rir', 'RIR', textInputAction: TextInputAction.done),
          ),
          SizedBox(
            width: 36.w,
            child: Semantics(
              button: true,
              label: set.completed ? 'Undo set ${sIdx + 1}' : 'Complete set ${sIdx + 1}',
              child: GestureDetector(
                onTap: () => _toggleSet(exIdx, sIdx),
                child: Container(
                  width: 28.r, height: 28.r,
                  decoration: BoxDecoration(
                    color: set.completed ? context.primaryColor : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: set.completed ? context.primaryColor : context.borderColor, width: 2),
                  ),
                  child: set.completed ? Icon(AppIcons.check, size: 16.r, color: Colors.white) : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // GYM-133: swipe-to-dismiss to remove a set
    return Dismissible(
      key: ValueKey('set_${exIdx}_$sIdx'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16.w),
        color: Colors.red,
        child: Icon(Icons.delete, color: Colors.white, size: 20.r),
      ),
      confirmDismiss: (_) async {
        if (_sets[exIdx].length <= 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot remove the last set')),
          );
          return false;
        }
        return true;
      },
      onDismissed: (_) {
        setState(() {
          // Dispose controllers for this set
          for (final field in ['reps', 'weight', 'rir', 'duration']) {
            final key = '$exIdx-$sIdx-$field';
            _controllers[key]?.dispose();
            _controllers.remove(key);
          }
          _sets[exIdx].removeAt(sIdx);
        });
        _syncToProvider();
        _saveWorkoutState();
      },
      child: rowContent,
    );
  }

  Widget _numField(BuildContext context, int exIdx, int setIdx, String field, String hint, {TextInputAction? textInputAction, TextInputType? keyboardType}) {
    final s = _sets[exIdx][setIdx];
    String initialValue;
    if (field == 'reps') {
      initialValue = s.reps > 0 ? '${s.reps}' : '';
    } else if (field == 'weight') {
      initialValue = _weightText(s.weight);
    } else if (field == 'duration') {
      initialValue = s.durationSeconds > 0 ? '${s.durationSeconds}' : '';
    } else {
      initialValue = (s.rir ?? 0) > 0 ? '${s.rir}' : '';
    }
    final controller = _getController(exIdx, setIdx, field, initialValue);

    return SizedBox(
      height: 36.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        child: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: keyboardType ?? TextInputType.number,
          textInputAction: textInputAction ?? TextInputAction.next,
          style: AppTextStyles.bodySmall.copyWith(color: context.foreground),
          onChanged: (value) => _updateSet(exIdx, setIdx, field, value),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.caption.copyWith(color: context.mutedForeground),
            contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
            isDense: true,
            border: OutlineInputBorder(borderRadius: AppRadius.borderSm, borderSide: BorderSide(color: context.borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: AppRadius.borderSm, borderSide: BorderSide(color: context.borderColor)),
            filled: true,
            fillColor: context.mutedColor,
          ),
        ),
      ),
    );
  }

}
