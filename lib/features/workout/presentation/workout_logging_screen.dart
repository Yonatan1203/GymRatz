import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';

import '../../../app/providers.dart';
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
import '../../../shared/data/sample_data.dart';
import '../../../shared/models/workout_set.dart';
import '../../../shared/models/workout_exercise.dart';

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
  Timer? _timer;
  Timer? _durationTimer;
  int _elapsedSeconds = 0;
  String _notes = '';
  String _workoutName = 'Workout';
  bool _initialized = false;
  late DateTime _startTime;

  void _initFromProvider() {
    if (_initialized) return;
    _initialized = true;

    // Check if there's an existing session for this day (returning from banner)
    final existingSession = ref.read(activeWorkoutSessionProvider.notifier)
        .getSessionForDay(widget.dayId);

    if (existingSession != null) {
      _startTime = existingSession.startTime;
      _workoutName = existingSession.workoutName;
      _exercises = List.from(existingSession.exercises);
      _sets = existingSession.sets.map((s) => List<WorkoutSet>.from(s)).toList();
      _expanded = Set.from(existingSession.expandedIndices);
      _restSeconds = existingSession.restSeconds;
      _restActive = existingSession.restActive;
      _restMinimized = existingSession.restMinimized;
      _timerRunning = existingSession.timerRunning;
      _notes = existingSession.notes;
      _elapsedSeconds = DateTime.now().difference(_startTime).inSeconds;
      if (_restActive && _timerRunning) {
        _beginCountdown();
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
        // Convert ProgramExercise -> WorkoutExercise for the logging screen
        _exercises = day.exercises.map((pe) => WorkoutExercise(
          name: pe.name,
          equipment: pe.equipment ?? 'Barbell',
          equipmentType: pe.equipmentType,
          repRange: '${pe.repMin}-${pe.repMax}',
          targetRir: pe.targetRir,
          restSeconds: pe.restSeconds,
          sets: List.generate(pe.sets, (_) => const WorkoutSet()),
        )).toList();
        _sets = _exercises.map((e) => List<WorkoutSet>.from(e.sets)).toList();
      } else {
        // Fallback to sample data
        final sampleExercises = SampleData.todayExercises;
        _exercises = sampleExercises;
        _sets = sampleExercises.map((e) => List<WorkoutSet>.from(e.sets)).toList();
      }
      _expanded = {0};

      // Start a new session in the provider (deferred to avoid modifying during build)
      Future(() {
        ref.read(activeWorkoutSessionProvider.notifier).startSession(
          dayId: widget.dayId,
          workoutName: _workoutName,
          exercises: _exercises,
          sets: _sets,
        );
      });
    }

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
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
    setState(() => _timerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restSeconds > 0) {
        setState(() => _restSeconds--);
      } else {
        t.cancel();
        setState(() { _restActive = false; _timerRunning = false; });
      }
    });
  }

  void _completeSet(int exIdx, int setIdx) {
    PlatformAdapter.hapticHeavy();
    setState(() {
      _sets[exIdx][setIdx] = _sets[exIdx][setIdx].copyWith(completed: true);
    });
    _showRestTimer();
    _beginCountdown();
    _checkCompletion();
    _syncToProvider();
  }

  void _checkCompletion() {
    final allDone = _sets.every((ex) => ex.every((s) => s.completed));
    if (allDone) {
      _timer?.cancel();
      _durationTimer?.cancel();
      ref.read(activeWorkoutSessionProvider.notifier).endSession();
      setState(() => _completed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    _initFromProvider();
    if (_completed) return _buildCompletionScreen(context);

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
                    ...List.generate(exercises.length, (i) => _buildExerciseCard(context, isDark, i, exercises[i])),
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('\ud83d\udcdd', style: TextStyle(fontSize: 18.sp)),
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
                    CustomButton(text: '+ Add Exercise', variant: ButtonVariant.dashed, icon: AppIcons.plus, onPressed: () {}),
                    SizedBox(height: 80.h),
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
                  onTap: () {
                    PlatformAdapter.hapticMedium();
                    _durationTimer?.cancel();
                    ref.read(activeWorkoutSessionProvider.notifier).endSession();
                    setState(() => _completed = true);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: AppRadius.borderLg),
                    child: Text('Finish', style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
          // Time display
          Text(
            Formatters.timer(_restSeconds),
            style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w700, color: Colors.white, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          SizedBox(width: 12.w),
          // +/- buttons (only when not running)
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
          // Start button or action buttons
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
              onTap: () { _timer?.cancel(); setState(() { _restActive = false; _timerRunning = false; }); },
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

  Widget _buildExerciseCard(BuildContext context, bool isDark, int exIdx, dynamic exercise) {
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
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                child: Row(
                  children: [
                    _gridHeader('SET', 40.w),
                    _gridHeader('REPS', 60.w),
                    _gridHeader('WEIGHT', 70.w),
                    _gridHeader('RIR', 50.w),
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
                    setState(() => _sets[exIdx].add(const WorkoutSet()));
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

  Widget _gridHeader(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(text, style: AppTextStyles.caption.copyWith(color: context.mutedForeground, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
    );
  }

  Widget _buildSetRow(BuildContext context, int exIdx, int sIdx, WorkoutSet set) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 6.h),
      child: Row(
        children: [
          SizedBox(width: 40.w, child: Center(child: Text('${sIdx + 1}', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)))),
          _numField(context, 60.w, set.reps > 0 ? '${set.reps}' : '', 'Reps'),
          _numField(context, 70.w, set.weight > 0 ? '${set.weight.toInt()}' : '', 'lbs'),
          _numField(context, 50.w, set.rir > 0 ? '${set.rir}' : '', 'RIR', textInputAction: TextInputAction.done),
          SizedBox(
            width: 36.w,
            child: Semantics(
              button: true,
              label: 'Complete set ${sIdx + 1}',
              child: GestureDetector(
              onTap: () => _completeSet(exIdx, sIdx),
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

  Widget _numField(BuildContext context, double width, String value, String hint, {TextInputAction? textInputAction}) {
    return SizedBox(
      width: width,
      height: 36.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        child: TextField(
          controller: TextEditingController(text: value),
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          textInputAction: textInputAction ?? TextInputAction.next,
          style: AppTextStyles.bodySmall.copyWith(color: context.foreground),
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
    final totalReps = _sets.fold<int>(0, (sum, ex) => sum + ex.fold<int>(0, (s, set) => s + set.reps));
    final totalVolume = _sets.fold<double>(0, (sum, ex) => sum + ex.fold<double>(0, (s, set) => s + (set.weight * set.reps)));
    final duration = DateTime.now().difference(_startTime);
    final durationStr = '${duration.inMinutes}m ${(duration.inSeconds % 60).toString().padLeft(2, '0')}s';
    final completionPct = totalSets > 0 ? ((completedSets / totalSets) * 100).round() : 0;

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
                SizedBox(height: 28.h),
                // Stats grid — 2x2
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
                    Expanded(child: _completionStatCard(context, isDark, AppIcons.barChart2, 'Volume', '${totalVolume.toInt()} lbs')),
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
                  onPressed: () {},
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
