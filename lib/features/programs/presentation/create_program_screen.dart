import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../theme/app_icons.dart';

import '../../../app/providers.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/exercise.dart';
import '../../../shared/models/program.dart';
import '../../../shared/models/program_exercise.dart';
import '../../../shared/models/workout_day.dart' as wd;
import '../../../theme/app_gradients.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/custom_badge.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/select_field.dart';
import 'widgets/custom_exercise_form_card.dart';
import 'widgets/exercise_library_picker.dart';
import 'widgets/program_info_card.dart';
import 'widgets/program_screen_header.dart';

class CreateProgramScreen extends ConsumerStatefulWidget {
  const CreateProgramScreen({super.key, this.forCoach = false, this.editProgram});

  final bool forCoach;

  /// When non-null, the screen edits this existing program instead of creating
  /// a new one. The program's id, isActive, progress, and createdAt are
  /// preserved on save.
  final Program? editProgram;

  bool get isEditing => editProgram != null;

  @override
  ConsumerState<CreateProgramScreen> createState() => _CreateProgramScreenState();
}

class _CreateProgramScreenState extends ConsumerState<CreateProgramScreen> {
  bool _saving = false;
  final _nameController = TextEditingController();
  final _weeksController = TextEditingController(text: '8');
  final _descriptionController = TextEditingController();
  final _nameFocus = FocusNode();
  final _weeksFocus = FocusNode();
  String? _pickerOpenForDay;
  String? _customFormOpenForDay;
  String _difficulty = 'Intermediate';
  /// Weight autofill mode for coach-created programs.
  /// Only used when [CreateProgramScreen.forCoach] is true.
  WeightAutofillMode _weightAutofillMode = WeightAutofillMode.systemSuggested;

  /// Normalized names of custom exercises already persisted this session —
  /// guards against duplicate writes from rapid double-taps before the
  /// Firestore-backed library provider reflects the new entry.
  final Set<String> _persistedExerciseNames = {};

  final _daysOfWeek = const [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  late List<_WorkoutDay> _workoutDays;
  final Map<String, TextEditingController> _dayNameControllers = {};

  @override
  void initState() {
    super.initState();
    final edit = widget.editProgram;
    if (edit != null) {
      _nameController.text = edit.name;
      _weeksController.text = '${edit.weeks}';
      _descriptionController.text = edit.description ?? '';
      _difficulty = edit.difficulty ?? 'Intermediate';
      _weightAutofillMode = edit.weightAutofillMode;
      var dayIndex = 0;
      final seenDayIds = <String>{};
      _workoutDays = edit.days.map((d) {
        // Legacy programs may have empty or duplicate day ids — derive a stable
        // unique id so the day-name controller map and removal logic work.
        var dayId = d.id.isNotEmpty ? d.id : 'day_${dayIndex++}';
        while (!seenDayIds.add(dayId)) {
          dayId = 'day_${dayIndex++}';
        }
        _dayNameControllers[dayId] = TextEditingController(text: d.name);
        return _WorkoutDay(
          id: dayId,
          name: d.name,
          dayOfWeek: d.dayOfWeek,
          isCardio: d.isCardio,
          exercises: d.exercises.map((ex) => _ExerciseConfig(
            id: ex.id,
            name: ex.name,
            category: ex.category,
            equipment: ex.equipment,
            equipmentType: ex.equipmentType,
            sets: ex.sets,
            repMin: ex.repMin,
            repMax: ex.repMax,
            targetRir: ex.targetRir,
            restSeconds: ex.restSeconds,
            progressionType: ex.progressionMode,
            durationMinutes: ex.durationMinutes,
            isTimeBased: ex.isTimeBased,
          )).toList(),
        );
      }).toList();
      // Guard against an empty program (shouldn't happen, but keep UI usable).
      if (_workoutDays.isEmpty) {
        _workoutDays = [
          _WorkoutDay(id: '1', name: 'Day 1', dayOfWeek: 'Monday', exercises: []),
        ];
        _dayNameControllers['1'] = TextEditingController(text: 'Day 1');
      }
    } else {
      _workoutDays = [
        _WorkoutDay(id: '1', name: 'Push Day', dayOfWeek: 'Monday', exercises: []),
      ];
      _dayNameControllers['1'] = TextEditingController(text: 'Push Day');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weeksController.dispose();
    _descriptionController.dispose();
    _nameFocus.dispose();
    _weeksFocus.dispose();
    for (final c in _dayNameControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _addWorkoutDay() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final name = 'Day ${_workoutDays.length + 1}';
    setState(() {
      _workoutDays.add(_WorkoutDay(id: id, name: name, dayOfWeek: 'Monday', exercises: []));
      _dayNameControllers[id] = TextEditingController(text: name);
    });
  }

  void _addCardioDay() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final name = 'Cardio';
    setState(() {
      _workoutDays.add(_WorkoutDay(id: id, name: name, dayOfWeek: 'Monday', exercises: [], isCardio: true));
      _dayNameControllers[id] = TextEditingController(text: name);
    });
  }

  void _removeWorkoutDay(String id) {
    setState(() {
      _workoutDays.removeWhere((d) => d.id == id);
      _dayNameControllers[id]?.dispose();
      _dayNameControllers.remove(id);
    });
  }

  void _addExerciseFromLibrary(String dayId, Exercise exercise) {
    setState(() {
      final day = _workoutDays.firstWhere((d) => d.id == dayId);
      if (day.isCardio) {
        day.exercises.add(_ExerciseConfig(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: exercise.name,
          category: exercise.category,
          equipment: exercise.equipment,
          equipmentType: exercise.equipmentType,
          durationMinutes: 30,
        ));
      } else {
        day.exercises.add(_ExerciseConfig(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: exercise.name,
          category: exercise.category,
          equipment: exercise.equipment,
          equipmentType: exercise.equipmentType,
          sets: 3,
          repMin: 8,
          repMax: 12,
          targetRir: 2,
          restSeconds: 120,
          progressionType: ref.read(userProfileProvider).valueOrNull?.defaultProgressionMode
              ?? ProgressionMode.hypertrophy,
        ));
      }
      _pickerOpenForDay = null;
    });
  }

  void _addCustomExercise(String dayId, String name, String category, String equipment) {
    if (name.isEmpty) return;
    final equipmentType = _mapEquipmentType(equipment);
    setState(() {
      final day = _workoutDays.firstWhere((d) => d.id == dayId);
      day.exercises.add(_ExerciseConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        category: category,
        equipment: equipment,
        equipmentType: equipmentType,
        sets: 3,
        repMin: 8,
        repMax: 12,
        targetRir: 2,
        restSeconds: 120,
        progressionType: ref.read(userProfileProvider).valueOrNull?.defaultProgressionMode
            ?? ProgressionMode.hypertrophy,
      ));
      _customFormOpenForDay = null;
    });
    // Also persist to the user's exercise library so it is reusable (GYM-123).
    _persistCustomExercise(name, category, equipment, equipmentType);
  }

  /// Saves an inline-created custom exercise to the user's exercise library,
  /// skipping if an exercise with the same normalized name already exists.
  Future<void> _persistCustomExercise(
    String name,
    String category,
    String equipment,
    EquipmentType equipmentType,
  ) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final normalized = name.toLowerCase().trim();
    if (!_persistedExerciseNames.add(normalized)) return;
    final existing = ref.read(exerciseLibraryProvider);
    if (existing.any((e) => e.name.toLowerCase().trim() == normalized)) {
      return;
    }
    final exercise = Exercise(
      id: '${uid}_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: category,
      type: 'Strength',
      muscle: category,
      equipment: equipment,
      equipmentType: equipmentType,
      difficulty: 'Intermediate',
      isDefault: false,
    );
    try {
      await ref.read(exerciseRepositoryProvider).createExercise(uid, exercise);
    } catch (e) {
      // Non-fatal — exercise is already in the program; library sync can be
      // retried manually. Drop the session guard so a retry is possible.
      _persistedExerciseNames.remove(normalized);
      debugPrint('Failed to persist custom exercise to library: $e');
    }
  }

  void _removeExercise(String dayId, String exId) {
    setState(() {
      final day = _workoutDays.firstWhere((d) => d.id == dayId);
      day.exercises.removeWhere((e) => e.id == exId);
    });
  }

  Future<void> _saveProgram() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a program name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _nameFocus.requestFocus();
      return;
    }

    final hasExercises = _workoutDays.any((d) => d.exercises.isNotEmpty);
    if (!hasExercises) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one exercise to a workout day'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    setState(() => _saving = true);

    try {
      final weeks = int.tryParse(_weeksController.text) ?? 8;

      final days = _workoutDays.map((day) {
        return wd.WorkoutDay(
          id: day.id,
          name: day.name,
          dayOfWeek: day.dayOfWeek,
          isCardio: day.isCardio,
          exercises: day.exercises.map((ex) {
            return ProgramExercise(
              id: ex.id,
              name: ex.name,
              sets: ex.sets,
              repMin: ex.repMin,
              repMax: ex.repMax,
              targetRir: ex.targetRir,
              restSeconds: ex.restSeconds,
              progressionMode: ex.progressionType,
              category: ex.category,
              equipment: ex.equipment,
              equipmentType: ex.equipmentType,
              durationMinutes: ex.durationMinutes,
              isTimeBased: ex.isTimeBased,
            );
          }).toList(),
        );
      }).toList();

      if (widget.forCoach) {
        final programJson = Program(
          id: const Uuid().v4(),
          name: name,
          workouts: days.length,
          weeks: weeks,
          days: days,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          difficulty: _difficulty,
          createdAt: DateTime.now(),
          weightAutofillMode: _weightAutofillMode,
        ).toJson();
        await ref.read(coachRepositoryProvider).createCoachProgram(uid, programJson);
      } else if (widget.isEditing) {
        await ref.read(programServiceProvider).editProgram(
              uid,
              widget.editProgram!.id,
              name: name,
              days: days,
              weeks: weeks,
              description: _descriptionController.text.trim().isNotEmpty
                  ? _descriptionController.text.trim()
                  : null,
              difficulty: _difficulty,
            );
        ref.invalidate(programByIdProvider(widget.editProgram!.id));
        ref.invalidate(userProgramsProvider);
      } else {
        await ref.read(programServiceProvider).createProgram(
              uid,
              name: name,
              days: days,
              weeks: weeks,
              description: _descriptionController.text.trim().isNotEmpty
                  ? _descriptionController.text.trim()
                  : null,
              difficulty: _difficulty,
            );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  EquipmentType _mapEquipmentType(String? equipment) {
    switch (equipment) {
      case 'Barbell':
        return EquipmentType.barbell;
      case 'Dumbbell':
        return EquipmentType.dumbbell;
      case 'Machine':
      case 'Machine (Stack)':
        return EquipmentType.machineStack;
      case 'Machine (Plate Loaded)':
        return EquipmentType.machinePlateLoaded;
      case 'Body Weight':
      case 'Bodyweight':
        return EquipmentType.bodyweight;
      default:
        return EquipmentType.barbell;
    }
  }

  List<Exercise> _cachedExercises = const [];
  bool _exercisesLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_exercisesLoaded) {
      _cachedExercises = ref.read(exerciseLibraryProvider);
      _exercisesLoaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            ProgramScreenHeader(
              isEditing: widget.isEditing,
              saving: _saving,
              onSave: _saveProgram,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  ProgramInfoCard(
                    nameController: _nameController,
                    weeksController: _weeksController,
                    descriptionController: _descriptionController,
                    nameFocus: _nameFocus,
                    weeksFocus: _weeksFocus,
                    difficulty: _difficulty,
                    onDifficultyChanged: (v) => setState(() => _difficulty = v),
                    forCoach: widget.forCoach,
                    weightAutofillMode: _weightAutofillMode,
                    onWeightAutofillChanged: (on) => setState(() {
                      _weightAutofillMode = on
                          ? WeightAutofillMode.systemSuggested
                          : WeightAutofillMode.manual;
                    }),
                  ),
                  SizedBox(height: AppSpacing.sectionGap),
                  ..._workoutDays.map((day) => _buildWorkoutDayCard(context, context.isDark, day)),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: '+ Workout Day',
                          variant: ButtonVariant.dashed,
                          icon: AppIcons.plus,
                          onPressed: _addWorkoutDay,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: CustomButton(
                          text: '+ Cardio Day',
                          variant: ButtonVariant.dashed,
                          icon: AppIcons.heart,
                          onPressed: _addCardioDay,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutDayCard(BuildContext context, bool isDark, _WorkoutDay day) {
    final nameController = _dayNameControllers[day.id]!;
    final onGradient = Theme.of(context).colorScheme.onPrimary;
    final onGradientMuted = onGradient.withValues(alpha: 0.7);

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: CustomCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: AppGradients.primary(isDark: isDark),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14.r),
                  topRight: Radius.circular(14.r),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: nameController,
                          onChanged: (v) => day.name = v,
                          style: AppTextStyles.body.copyWith(color: onGradient),
                          decoration: InputDecoration(
                            hintText: 'Workout name',
                            hintStyle: AppTextStyles.body.copyWith(color: onGradientMuted),
                            filled: true,
                            fillColor: onGradient.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.borderLg,
                              borderSide: BorderSide(color: onGradient.withValues(alpha: 0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadius.borderLg,
                              borderSide: BorderSide(color: onGradient.withValues(alpha: 0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AppRadius.borderLg,
                              borderSide: BorderSide(color: onGradient),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                            isDense: true,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        SelectField(
                          label: '',
                          value: day.dayOfWeek,
                          options: _daysOfWeek,
                          onChanged: (v) => setState(() => day.dayOfWeek = v),
                          onDark: true,
                          icon: AppIcons.calendar,
                          sheetTitle: 'Select Day',
                        ),
                      ],
                    ),
                  ),
                  if (_workoutDays.length > 1) ...[
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: () => _removeWorkoutDay(day.id),
                      child: Padding(
                        padding: EdgeInsets.all(8.r),
                        child: Icon(AppIcons.trash2, size: 24.r, color: onGradient),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                children: [
                  if (day.exercises.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.h),
                      child: Column(
                        children: [
                          Icon(
                            AppIcons.dumbbell,
                            size: 32.r,
                            color: context.mutedForeground.withValues(alpha:0.6),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'No exercises added yet',
                            style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
                          ),
                        ],
                      ),
                    )
                  else
                    ...day.exercises.map((ex) => _buildExerciseConfig(context, day.id, ex)),
                  SizedBox(height: 8.h),
                  if (_customFormOpenForDay == day.id)
                    CustomExerciseFormCard(
                      onSubmit: (name, category, equipment) =>
                          _addCustomExercise(day.id, name, category, equipment),
                      onCancel: () => setState(() => _customFormOpenForDay = null),
                    )
                  else if (_pickerOpenForDay == day.id)
                    ExerciseLibraryPicker(
                      exercises: _cachedExercises,
                      onExerciseSelected: (ex) => _addExerciseFromLibrary(day.id, ex),
                      onCustomRequested: () => setState(() {
                        _pickerOpenForDay = null;
                        _customFormOpenForDay = day.id;
                      }),
                      onCancel: () => setState(() => _pickerOpenForDay = null),
                    )
                  else
                    CustomButton(
                      text: '+ Add Exercise',
                      variant: ButtonVariant.dashed,
                      icon: AppIcons.plus,
                      onPressed: () => setState(() => _pickerOpenForDay = day.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseConfig(BuildContext context, String dayId, _ExerciseConfig ex) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: context.mutedColor,
          borderRadius: AppRadius.borderLg,
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8.w,
                    runSpacing: 4.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        ex.name,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.foreground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      CustomBadge(text: ex.category),
                      CustomBadge(
                        text: ex.equipmentType.label,
                        backgroundColor: context.secondaryColor.withValues(alpha: 0.2),
                        textColor: context.secondaryColor,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _removeExercise(dayId, ex.id),
                  child: Padding(
                    padding: EdgeInsets.all(4.r),
                    child: Icon(AppIcons.trash2, size: 20.r, color: context.destructiveColor),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (ex.durationMinutes != null)
              // Cardio exercise: show duration
              Row(
                children: [
                  _configSheetField(context, ex, 'Duration', '${ex.durationMinutes} min', 100.w),
                ],
              )
            else ...[
              // Reps / Time toggle (GYM-122)
              Row(
                children: [
                  _modeToggleButton(context, 'Reps', !ex.isTimeBased, () => setState(() => ex.isTimeBased = false)),
                  SizedBox(width: 8.w),
                  _modeToggleButton(context, 'Time', ex.isTimeBased, () => setState(() => ex.isTimeBased = true)),
                ],
              ),
              SizedBox(height: 8.h),
              // Strength exercise: show sets/reps(or duration)/rir/rest
              Row(
                children: [
                  _configSheetField(context, ex, 'Sets', '${ex.sets}', 60.w),
                  SizedBox(width: 8.w),
                  if (ex.isTimeBased)
                    _configSheetField(context, ex, 'Sec', '${ex.setDurationSeconds}s', 80.w)
                  else
                    _configSheetField(context, ex, 'Reps', Formatters.reps(ex.repMin, ex.repMax), 80.w),
                  SizedBox(width: 8.w),
                  _configSheetField(context, ex, 'RIR', '${ex.targetRir}', 50.w),
                  SizedBox(width: 8.w),
                  _configSheetField(context, ex, 'Rest', '${ex.restSeconds}s', 60.w),
                ],
              ),
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: () => showAppBottomSheet(
                  context,
                  title: 'Progression Type',
                  currentValue: ex.progressionType.label,
                  options: ProgressionMode.values.map((m) => m.label).toList(),
                  onChanged: (v) => setState(
                    () => ex.progressionType = ProgressionMode.values.firstWhere((m) => m.label == v),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Progression: ',
                      style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
                    ),
                    Text(
                      ex.progressionType.label,
                      style: AppTextStyles.caption.copyWith(
                        color: context.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(AppIcons.edit, size: 12.r, color: context.primaryColor),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Small toggle button for Reps / Time mode selection (GYM-122).
  Widget _modeToggleButton(BuildContext context, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isActive ? context.primaryColor : context.mutedColor,
          borderRadius: AppRadius.borderFull,
          border: Border.all(color: isActive ? context.primaryColor : context.borderColor),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isActive ? Colors.white : context.mutedForeground,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _configSheetField(
    BuildContext context,
    _ExerciseConfig ex,
    String label,
    String displayValue,
    double width,
  ) {
    return GestureDetector(
      onTap: () => _openConfigSheet(context, ex, label),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: context.mutedForeground,
                fontSize: 10.sp,
              ),
            ),
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: AppRadius.borderSm,
                border: Border.all(color: context.borderColor),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        displayValue,
                        style: AppTextStyles.bodySmall.copyWith(color: context.foreground),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Icon(AppIcons.chevronDown, size: 10.r, color: context.mutedForeground),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openConfigSheet(BuildContext context, _ExerciseConfig ex, String label) {
    switch (label) {
      case 'Sets':
        showAppBottomSheet(
          context,
          title: 'Sets',
          currentValue: '${ex.sets}',
          options: List.generate(10, (i) => '${i + 1}'),
          onChanged: (v) => setState(() => ex.sets = int.parse(v)),
        );
      case 'Reps':
        showAppBottomSheet(
          context,
          title: 'Reps',
          currentValue: Formatters.reps(ex.repMin, ex.repMax),
          options: const [
            '1', '2', '3', '5', '6', '8', '10', '12', '15', '20',
            '1-3', '1-5', '3-5', '3-6', '4-6', '5-8', '6-8', '6-10',
            '8-10', '8-12', '10-12', '10-15', '12-15', '15-20', '20-30',
          ],
          onChanged: (v) {
            setState(() {
              if (v.contains('-')) {
                final parts = v.split('-');
                ex.repMin = int.parse(parts[0]);
                ex.repMax = int.parse(parts[1]);
              } else {
                final n = int.parse(v);
                ex.repMin = n;
                ex.repMax = n;
              }
            });
          },
        );
      case 'RIR':
        showAppBottomSheet(
          context,
          title: 'RIR (Reps in Reserve)',
          currentValue: '${ex.targetRir}',
          options: const ['0', '1', '2', '3', '4', '5'],
          onChanged: (v) => setState(() => ex.targetRir = int.parse(v)),
        );
      case 'Rest':
        showAppBottomSheet(
          context,
          title: 'Rest (seconds)',
          currentValue: '${ex.restSeconds}s',
          options: const ['30', '45', '60', '90', '120', '150', '180', '240', '300'],
          onChanged: (v) => setState(() => ex.restSeconds = int.parse(v)),
          displayTransform: (v) => '${v}s',
        );
      case 'Duration':
        showAppBottomSheet(
          context,
          title: 'Duration (minutes)',
          currentValue: '${ex.durationMinutes} min',
          options: const ['10', '15', '20', '25', '30', '35', '40', '45', '50', '60', '75', '90'],
          onChanged: (v) => setState(() => ex.durationMinutes = int.parse(v)),
          displayTransform: (v) => '$v min',
        );
      case 'Sec':
        showAppBottomSheet(
          context,
          title: 'Set Duration (seconds)',
          currentValue: '${ex.setDurationSeconds}s',
          options: const ['10', '15', '20', '30', '40', '45', '60', '90', '120'],
          onChanged: (v) => setState(() => ex.setDurationSeconds = int.parse(v)),
          displayTransform: (v) => '${v}s',
        );
    }
  }

}

class _WorkoutDay {
  final String id;
  String name;
  String dayOfWeek;
  bool isCardio;
  final List<_ExerciseConfig> exercises;

  _WorkoutDay({
    required this.id,
    required this.name,
    required this.dayOfWeek,
    required this.exercises,
    this.isCardio = false,
  });
}

class _ExerciseConfig {
  final String id;
  final String name;
  final String category;
  final String? equipment;
  final EquipmentType equipmentType;
  int sets;
  int repMin;
  int repMax;
  int targetRir;
  int restSeconds;
  ProgressionMode progressionType;
  /// Duration in minutes for cardio exercises.
  int? durationMinutes;
  /// When true, sets are logged by duration (seconds) rather than reps.
  bool isTimeBased;
  /// Default duration in seconds for time-based sets.
  int setDurationSeconds = 30;

  _ExerciseConfig({
    required this.id,
    required this.name,
    required this.category,
    this.equipment,
    this.equipmentType = EquipmentType.barbell,
    this.sets = 3,
    this.repMin = 8,
    this.repMax = 12,
    this.targetRir = 2,
    this.restSeconds = 120,
    this.progressionType = ProgressionMode.hypertrophy,
    this.durationMinutes,
    this.isTimeBased = false,
  });
}
