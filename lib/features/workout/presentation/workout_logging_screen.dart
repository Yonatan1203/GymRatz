import 'dart:async';
import 'dart:convert';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../theme/app_icons.dart';

import '../../../app/providers.dart';
import '../../../core/notification_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_gradients.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_shadows.dart';
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

import '../../../shared/models/enums.dart';
import '../../../shared/models/exercise.dart';
import '../../../shared/models/workout.dart';
import '../../../shared/models/workout_set.dart';
import '../../../shared/models/workout_exercise.dart';
import '../domain/workout_summary.dart';

class WorkoutLoggingScreen extends ConsumerStatefulWidget {
  final String dayId;
  const WorkoutLoggingScreen({super.key, required this.dayId});

  @override
  ConsumerState<WorkoutLoggingScreen> createState() => _WorkoutLoggingScreenState();
}

class _WorkoutLoggingScreenState extends ConsumerState<WorkoutLoggingScreen> {
  late List<List<WorkoutSet>> _sets;
  late List<WorkoutExercise> _exercises;
  late Set<int> _expanded;
  int _restSeconds = 120;
  bool _restActive = false;
  bool _restMinimized = false;
  bool _timerRunning = false;
  bool _completed = false;
  bool _saving = false;
  Timer? _timer;
  Timer? _durationTimer;
  int _elapsedSeconds = 0;
  String _notes = '';
  String _workoutName = 'Workout';
  bool _initialized = false;
  bool _loadingExercises = false;
  bool _showFirstTimeTips = false;
  late DateTime _startTime;
  WorkoutSummary? _workoutSummary;
  static const _workoutCacheKeyPrefix = 'in_progress_workout';

  String get _workoutCacheKey {
    final uid = ref.read(currentUidProvider) ?? '';
    return '${_workoutCacheKeyPrefix}_$uid';
  }

  /// Save current workout state after each set update
  Future<void> _saveWorkoutState() async {
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
        _getController(exIdx, setIdx, 'weight', s.weight > 0 ? '${s.weight.toInt()}' : '');
        _getController(exIdx, setIdx, 'rir', (s.rir ?? 0) > 0 ? '${s.rir}' : '');
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

    final existingSession = ref.read(activeWorkoutSessionProvider.notifier)
        .getSessionForDay(widget.dayId);

    if (existingSession != null) {
      _startTime = existingSession.startTime;
      _workoutName = existingSession.workoutName;
      _exercises = List.from(existingSession.exercises);
      _sets = existingSession.sets.map((s) => List<WorkoutSet>.from(s)).toList();
      _expanded = Set.from(existingSession.expandedIndices);
      _restActive = existingSession.restActive;
      _restMinimized = existingSession.restMinimized;
      _timerRunning = existingSession.timerRunning;
      _notes = existingSession.notes;
      _elapsedSeconds = DateTime.now().difference(_startTime).inSeconds;
      // Recalculate rest seconds from restEndTime so it stays accurate
      if (_restActive && _timerRunning && existingSession.restEndTime != null) {
        final remaining = existingSession.restEndTime!.difference(DateTime.now()).inSeconds;
        if (remaining > 0) {
          _restSeconds = remaining;
          // Defer to avoid modifying provider state during build
          Future(_beginCountdown);
        } else {
          _restActive = false;
          _timerRunning = false;
          Future(_syncToProvider);
        }
      } else {
        _restSeconds = existingSession.restSeconds;
      }
    } else {
      _startTime = DateTime.now();

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

    // Check for recoverable workout state from a previous session
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
    ref.read(activeWorkoutSessionProvider.notifier).syncState(
      exercises: List.from(_exercises),
      sets: _sets.map((s) => List<WorkoutSet>.from(s)).toList(),
      expandedIndices: Set.from(_expanded),
      restSeconds: _restSeconds,
      restActive: _restActive,
      restMinimized: _restMinimized,
      timerRunning: _timerRunning,
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
  void dispose() {
    _timer?.cancel();
    _durationTimer?.cancel();
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  void _showRestTimer() {
    _timer?.cancel();
    setState(() {
      _restActive = true;
      _timerRunning = false;
      _restSeconds = _expanded.isNotEmpty ? _exercises[_expanded.first].restSeconds : 120;
      _restMinimized = false;
    });
    _syncToProvider();
  }

  void _beginCountdown() {
    final endTime = DateTime.now().add(Duration(seconds: _restSeconds));
    setState(() => _timerRunning = true);
    // Sync restEndTime so the banner can count down independently
    ref.read(activeWorkoutSessionProvider.notifier).syncState(
      restActive: true,
      timerRunning: true,
      restSeconds: _restSeconds,
      restEndTime: endTime,
    );
    // Schedule a notification for when the timer ends (works even if app is backgrounded)
    NotificationService().showRestTimerNotification(_restSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restSeconds > 0) {
        setState(() => _restSeconds--);
      } else {
        t.cancel();
        PlatformAdapter.hapticSelection();
        // Sound: fire immediate notification with sound instead of silently canceling.
        final soundEnabled = ref.read(timerSettingsProvider).soundEnabled;
        if (soundEnabled) {
          NotificationService().showRestCompleteNow();
        } else {
          NotificationService().cancelRestTimerNotification();
        }
        // Keep restActive true briefly so banner/PiP can show the bell icon
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() { _restActive = false; _timerRunning = false; });
          _syncToProvider();
          if (soundEnabled) {
            NotificationService().cancelRestTimerNotification();
          }
        });
      }
    });
  }

  void _toggleSet(int exIdx, int setIdx) {
    PlatformAdapter.hapticLight();
    final current = _sets[exIdx][setIdx];
    final wasCompleted = current.completed;

    setState(() {
      _sets[exIdx][setIdx] = current.copyWith(completed: !wasCompleted);
    });

    if (!wasCompleted) {
      // Completing a set — auto-start rest timer if enabled.
      _syncToProvider();
      _saveWorkoutState();
      final autoStart = ref.read(timerSettingsProvider).autoStartOnSetComplete;
      if (autoStart && !_restActive) {
        _showRestTimer();
        _beginCountdown();
      }
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

    _timer?.cancel();
    _durationTimer?.cancel();

    final uid = ref.read(currentUidProvider);
    final profile = ref.read(userProfileProvider).valueOrNull;
    final unit = profile?.unit ?? 'lbs';

    final exercises = _buildExercisesWithSets();
    final workout = Workout(
      id: const Uuid().v4(),
      programId: ref.read(activeProgramProvider).valueOrNull?.id,
      workoutDayId: widget.dayId,
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
      }
    });
    _syncToProvider();
  }

  @override
  Widget build(BuildContext context) {
    _initFromProvider();
    if (_completed) return _buildCompletionScreen(context);
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

    final bool timerVisible = _restActive;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, isDark),
          Expanded(
            child: Stack(
              children: [
                ListView(
                  padding: EdgeInsets.only(
                    left: AppSpacing.screenPadding,
                    right: AppSpacing.screenPadding,
                    bottom: AppSpacing.screenPadding,
                    top: timerVisible
                        ? (_restMinimized ? 52.h : 72.h)
                        : AppSpacing.screenPadding,
                  ),
                  children: [
                    if (_showFirstTimeTips) _buildFirstTimeTips(context, isDark),
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
                if (_restActive && !_restMinimized)
                  Positioned(top: 0, left: 0, right: 0, child: _buildRestTimer(context)),
                if (_restActive && _restMinimized)
                  Positioned(top: 0, left: 0, right: 0, child: _buildMinimizedTimer(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppGradients.primary(isDark: isDark),
        boxShadow: AppShadows.lg,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: 'Go back',
                child: GestureDetector(
                  onTap: () {
                    PlatformAdapter.hapticLight();
                    _syncToProvider();
                    context.pop();
                  },
                  child: Container(
                    width: 40.r, height: 40.r,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: AppRadius.borderLg),
                    child: Icon(AppIcons.arrowLeft, size: 20.r, color: Colors.white),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(_workoutName, style: AppTextStyles.h3.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                    Text(
                      _formatElapsed(_elapsedSeconds),
                      style: AppTextStyles.tabular.copyWith(color: Colors.white70, fontSize: 14.sp),
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: 'Open rest timer',
                child: GestureDetector(
                  onTap: () {
                    PlatformAdapter.hapticLight();
                    _showRestTimer();
                  },
                  child: Container(
                    width: 40.r, height: 40.r,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: AppRadius.borderLg),
                    child: Icon(AppIcons.timer, size: 20.r, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Semantics(
                button: true,
                label: 'Finish workout',
                child: GestureDetector(
                  onTap: _saving ? null : () {
                    PlatformAdapter.hapticMedium();
                    _confirmFinish();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: AppRadius.borderLg),
                    child: _saving
                        ? SizedBox(width: 20.r, height: 20.r, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Finish', style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirstTimeTips(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: CustomCard(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.info, size: 18.r, color: context.primaryColor),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Quick Start Guide',
                    style: AppTextStyles.h4.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showFirstTimeTips = false),
                  child: Icon(AppIcons.x, size: 18.r, color: context.mutedForeground),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _tipRow(context, AppIcons.check, 'Tap the circle to complete a set'),
            SizedBox(height: 8.h),
            _tipRow(context, AppIcons.edit, 'Edit weight, reps, and RIR for each set'),
            SizedBox(height: 8.h),
            _tipRow(context, AppIcons.timer, 'Rest timer starts automatically after each set'),
            SizedBox(height: 8.h),
            _tipRow(context, AppIcons.trendingUp, 'Weights auto-adjust next session based on performance'),
          ],
        ),
      ),
    );
  }

  Widget _tipRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14.r, color: context.primaryColor),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
          ),
        ),
      ],
    );
  }

  Widget _buildRestTimer(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.9),
        borderRadius: AppRadius.borderXl,
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          Text(
            Formatters.timer(_restSeconds),
            style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w700, color: Colors.white, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          SizedBox(width: 12.w),
          if (!_timerRunning) ...[
            GestureDetector(
              onTap: () => setState(() => _restSeconds = (_restSeconds - 10).clamp(0, 999)),
              child: Icon(AppIcons.minusCircle, color: Colors.white70, size: 22.r),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () => setState(() => _restSeconds += 10),
              child: Icon(AppIcons.plusCircle, color: Colors.white70, size: 22.r),
            ),
          ],
          const Spacer(),
          if (!_timerRunning)
            GestureDetector(
              onTap: _beginCountdown,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.borderFull,
                ),
                child: Text('Start', style: AppTextStyles.bodySmall.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600)),
              ),
            )
          else ...[
            Semantics(
              button: true,
              label: 'Minimize timer',
              child: GestureDetector(
                onTap: () => setState(() => _restMinimized = true),
                child: Icon(AppIcons.minimize2, size: 18.r, color: Colors.white70),
              ),
            ),
            SizedBox(width: 12.w),
          ],
          SizedBox(width: 8.w),
          Semantics(
            button: true,
            label: 'Dismiss timer',
            child: GestureDetector(
              onTap: () {
                _timer?.cancel();
                NotificationService().cancelRestTimerNotification();
                setState(() { _restActive = false; _timerRunning = false; });
                ref.read(activeWorkoutSessionProvider.notifier).syncState(
                  restActive: false, timerRunning: false, clearRestEndTime: true,
                );
              },
              child: Icon(AppIcons.x, size: 18.r, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimizedTimer(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _restMinimized = false),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: context.primaryColor.withValues(alpha: 0.9),
          borderRadius: AppRadius.borderXl,
          boxShadow: AppShadows.md,
        ),
        child: Row(
          children: [
            Icon(AppIcons.timer, size: 16.r, color: Colors.white),
            SizedBox(width: 8.w),
            Text(
              Formatters.timer(_restSeconds),
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Icon(AppIcons.chevronDown, size: 18.r, color: Colors.white70),
          ],
        ),
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
              // Grid header
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                child: Row(
                  children: [
                    SizedBox(width: 32.w, child: _gridHeaderText(context, 'SET')),
                    Expanded(flex: 2, child: _gridHeaderText(context, 'REPS')),
                    Expanded(flex: 3, child: _gridHeaderText(context, 'WEIGHT')),
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
    return Padding(
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
          Expanded(
            flex: 2,
            child: _numField(context, exIdx, sIdx, 'reps', 'Reps'),
          ),
          Expanded(
            flex: 3,
            child: _exercises[exIdx].equipmentType == EquipmentType.bodyweight
                ? Center(child: Text('-', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)))
                : _numField(context, exIdx, sIdx, 'weight', ref.read(userProfileProvider).valueOrNull?.unit ?? 'lbs'),
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
  }

  Widget _numField(BuildContext context, int exIdx, int setIdx, String field, String hint, {TextInputAction? textInputAction}) {
    final controller = _getController(
      exIdx,
      setIdx,
      field,
      field == 'reps'
          ? (_sets[exIdx][setIdx].reps > 0 ? '${_sets[exIdx][setIdx].reps}' : '')
          : field == 'weight'
              ? (_sets[exIdx][setIdx].weight > 0 ? '${_sets[exIdx][setIdx].weight.toInt()}' : '')
              : ((_sets[exIdx][setIdx].rir ?? 0) > 0 ? '${_sets[exIdx][setIdx].rir}' : ''),
    );

    return SizedBox(
      height: 36.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        child: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
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

  Widget _buildCompletionScreen(BuildContext context) {
    final isDark = context.isDark;
    final completedSets = _sets.fold<int>(0, (sum, ex) => sum + ex.where((s) => s.completed).length);
    final totalSets = _sets.fold<int>(0, (sum, ex) => sum + ex.length);
    final totalReps = _workoutSummary?.totalReps ?? _sets.fold<int>(0, (sum, ex) => sum + ex.fold<int>(0, (s, set) => s + set.reps));
    final totalVolume = _workoutSummary?.totalVolume ?? _sets.fold<double>(0, (sum, ex) => sum + ex.fold<double>(0, (s, set) => s + (set.weight * set.reps)));
    final duration = DateTime.now().difference(_startTime);
    final durationStr = '${duration.inMinutes}m ${(duration.inSeconds % 60).toString().padLeft(2, '0')}s';
    final completionPct = totalSets > 0 ? ((completedSets / totalSets) * 100).round() : 0;
    final newPRs = _workoutSummary?.newPRs ?? [];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.primaryColor.withValues(alpha: 0.15),
              isDark ? Colors.black : Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              children: [
                SizedBox(height: 32.h),
                // Trophy icon with glow
                Container(
                  width: 120.r, height: 120.r,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary(isDark: isDark),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: context.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(AppIcons.trophy, size: 56.r, color: Colors.white),
                ),
                SizedBox(height: 24.h),
                Text('Workout Complete!', style: AppTextStyles.h1.copyWith(color: context.foreground, fontWeight: FontWeight.w700)),
                SizedBox(height: 4.h),
                Text('You absolutely crushed it today', style: AppTextStyles.body.copyWith(color: context.mutedForeground)),
                SizedBox(height: 8.h),
                // Completion badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.15),
                    borderRadius: AppRadius.borderFull,
                  ),
                  child: Text(
                    '$completionPct% completed',
                    style: AppTextStyles.bodySmall.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600),
                  ),
                ),
                // New PRs
                if (newPRs.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [context.coralColor.withValues(alpha: 0.15), context.coralColor.withValues(alpha: 0.08)],
                      ),
                      borderRadius: AppRadius.borderXl,
                      border: Border.all(color: context.coralColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(AppIcons.trophy, size: 18.r, color: context.coralColor),
                            SizedBox(width: 8.w),
                            Text('New Personal Records!', style: AppTextStyles.h4.copyWith(color: context.coralColor, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        ...newPRs.map((pr) => Padding(
                          padding: EdgeInsets.only(bottom: 4.h),
                          child: Text(pr, style: AppTextStyles.bodySmall.copyWith(color: context.foreground)),
                        )),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 28.h),
                // Stats grid — 2x3
                Row(
                  children: [
                    Expanded(child: _completionStatCard(context, isDark, AppIcons.clock, 'Duration', durationStr)),
                    SizedBox(width: 12.w),
                    Expanded(child: _completionStatCard(context, isDark, AppIcons.layers, 'Sets', '$completedSets / $totalSets')),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(child: _completionStatCard(context, isDark, AppIcons.repeat, 'Total Reps', '$totalReps')),
                    SizedBox(width: 12.w),
                    Expanded(child: _completionStatCard(context, isDark, AppIcons.barChart2, 'Volume', '${totalVolume.toInt()} ${ref.read(userProfileProvider).valueOrNull?.unit ?? 'lbs'}')),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(child: _completionStatCard(context, isDark, AppIcons.dumbbell, 'Exercises', '${_exercises.length}')),
                    SizedBox(width: 12.w),
                    Expanded(child: _completionStatCard(context, isDark, AppIcons.flame, 'Intensity', completionPct >= 80 ? 'High' : completionPct >= 50 ? 'Medium' : 'Light')),
                  ],
                ),
                SizedBox(height: 32.h),
                // Buttons
                CustomButton(
                  text: 'Back to Home',
                  variant: ButtonVariant.gradient,
                  icon: AppIcons.home,
                  onPressed: () => context.go('/home'),
                ),
                SizedBox(height: 12.h),
                CustomButton(
                  text: 'Share Workout',
                  variant: ButtonVariant.outline,
                  icon: AppIcons.share2,
                  onPressed: () {
                    final volUnit = ref.read(userProfileProvider).valueOrNull?.unit ?? 'lbs';
                    final summary = '💪 $_workoutName\n$durationStr | $completedSets sets | ${totalVolume.toInt()} $volUnit volume\n\nLogged with GymRatz';
                    Share.share(summary);
                  },
                ),
                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _completionStatCard(BuildContext context, bool isDark, IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20.r, color: context.primaryColor),
          SizedBox(height: 8.h),
          Text(value, style: AppTextStyles.h3.copyWith(color: context.foreground, fontWeight: FontWeight.w700)),
          SizedBox(height: 2.h),
          Text(label, style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
        ],
      ),
    );
  }
}
