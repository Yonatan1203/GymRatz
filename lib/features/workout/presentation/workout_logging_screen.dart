import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/providers.dart';
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
  bool _completed = false;
  Timer? _timer;
  String _notes = '';
  bool _initialized = false;

  void _initFromProvider() {
    if (_initialized) return;
    _initialized = true;

    final activeProgram = ref.read(activeProgramProvider).valueOrNull;
    final matchingDay = activeProgram?.days
        .where((d) => d.id == widget.dayId)
        .toList();

    if (matchingDay != null && matchingDay.isNotEmpty) {
      final day = matchingDay.first;
      // Convert ProgramExercise -> WorkoutExercise for the logging screen
      _exercises = day.exercises.map((pe) => WorkoutExercise(
        name: pe.name,
        equipment: pe.equipment ?? 'Barbell',
        equipmentType: pe.equipmentType,
        repRange: '${pe.repMin}-${pe.repMax}',
        targetRir: pe.targetRir,
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
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRest() {
    _timer?.cancel();
    setState(() {
      _restActive = true;
      _restSeconds = 120;
      _restMinimized = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restSeconds > 0) {
        setState(() => _restSeconds--);
      } else {
        t.cancel();
        setState(() => _restActive = false);
      }
    });
  }

  void _completeSet(int exIdx, int setIdx) {
    PlatformAdapter.hapticHeavy();
    setState(() {
      _sets[exIdx][setIdx] = _sets[exIdx][setIdx].copyWith(completed: true);
    });
    _startRest();
    _checkCompletion();
  }

  void _checkCompletion() {
    final allDone = _sets.every((ex) => ex.every((s) => s.completed));
    if (allDone) {
      _timer?.cancel();
      setState(() => _completed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    _initFromProvider();
    if (_completed) return _buildCompletionScreen(context);

    final isDark = context.isDark;
    final exercises = _exercises;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, isDark),
          if (_restActive && !_restMinimized) _buildRestTimer(context),
          if (_restActive && _restMinimized) _buildMinimizedTimer(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                ...List.generate(exercises.length, (i) => _buildExerciseCard(context, isDark, i, exercises[i])),
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: CustomInput(
                    label: 'Workout Notes',
                    hint: 'How did it go?',
                    maxLines: 3,
                    onChanged: (v) => _notes = v,
                  ),
                ),
                SizedBox(height: 16.h),
                CustomButton(text: '+ Add Exercise', variant: ButtonVariant.dashed, icon: LucideIcons.plus, onPressed: () {}),
                SizedBox(height: 80.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
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
                    context.pop();
                  },
                  child: Container(
                    width: 40.r, height: 40.r,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: AppRadius.borderLg),
                    child: Icon(LucideIcons.arrowLeft, size: 20.r, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Push Day', style: AppTextStyles.h3.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                    Text('Upper Body', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: 'Finish workout',
                child: GestureDetector(
                  onTap: () {
                    PlatformAdapter.hapticMedium();
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
      padding: EdgeInsets.all(16.r),
      color: context.primaryColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rest Timer', style: AppTextStyles.h4.copyWith(color: Colors.white)),
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Minimize timer',
                    child: GestureDetector(
                      onTap: () => setState(() => _restMinimized = true),
                      child: Icon(LucideIcons.minimize2, size: 20.r, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Semantics(
                    button: true,
                    label: 'Dismiss timer',
                    child: GestureDetector(
                      onTap: () { _timer?.cancel(); setState(() => _restActive = false); },
                      child: Icon(LucideIcons.x, size: 20.r, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            Formatters.timer(_restSeconds),
            style: TextStyle(fontSize: 48.sp, fontWeight: FontWeight.w700, color: Colors.white, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(LucideIcons.minusCircle, color: Colors.white, size: 32.r),
                onPressed: () => setState(() => _restSeconds = (_restSeconds - 10).clamp(0, 999)),
              ),
              SizedBox(width: 24.w),
              IconButton(
                icon: Icon(LucideIcons.plusCircle, color: Colors.white, size: 32.r),
                onPressed: () => setState(() => _restSeconds += 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMinimizedTimer(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _restMinimized = false),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        color: context.primaryColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Rest: ${_restSeconds}s', style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
            Icon(LucideIcons.chevronUp, size: 20.r, color: Colors.white),
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
              onTap: () => setState(() {
                if (isExpanded) { _expanded.remove(exIdx); } else { _expanded.add(exIdx); }
              }),
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
                    Icon(isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 24.r, color: context.mutedForeground),
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
                  onPressed: () => setState(() => _sets[exIdx].add(const WorkoutSet())),
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
                child: set.completed ? Icon(LucideIcons.check, size: 16.r, color: Colors.white) : null,
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
    final totalSets = _sets.fold<int>(0, (sum, ex) => sum + ex.length);
    final totalReps = _sets.fold<int>(0, (sum, ex) => sum + ex.fold<int>(0, (s, set) => s + set.reps));

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96.r, height: 96.r,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary(isDark: isDark),
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.xxl,
                  ),
                  child: Icon(LucideIcons.trophy, size: 48.r, color: Colors.white),
                ),
                SizedBox(height: 24.h),
                Text('Great Job!', style: AppTextStyles.h1.copyWith(color: context.foreground, fontWeight: FontWeight.w700)),
                SizedBox(height: 8.h),
                Text('You crushed it today', style: AppTextStyles.body.copyWith(color: context.mutedForeground)),
                SizedBox(height: 32.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statChip(context, '$totalSets', 'Sets'),
                    _statChip(context, '$totalReps', 'Reps'),
                    _statChip(context, '${_exercises.length}', 'Exercises'),
                  ],
                ),
                SizedBox(height: 48.h),
                CustomButton(
                  text: 'Back to Home',
                  variant: ButtonVariant.gradient,
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statChip(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h1.copyWith(color: context.primaryColor, fontWeight: FontWeight.w700)),
        Text(label, style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
      ],
    );
  }

}
