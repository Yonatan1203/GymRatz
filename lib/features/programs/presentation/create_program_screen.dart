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
import '../../../shared/widgets/custom_badge.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/custom_input.dart';

class CreateProgramScreen extends ConsumerStatefulWidget {
  const CreateProgramScreen({super.key, this.forCoach = false});

  final bool forCoach;

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
  String _exerciseSearchQuery = '';
  String? _selectedCategory;
  String _difficulty = 'Intermediate';

  final _customName = TextEditingController();
  String _customCategory = 'Chest';
  String _customEquipment = 'Dumbbell';

  final _daysOfWeek = const [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  late List<_WorkoutDay> _workoutDays;
  final Map<String, TextEditingController> _dayNameControllers = {};

  @override
  void initState() {
    super.initState();
    _workoutDays = [
      _WorkoutDay(id: '1', name: 'Push Day', dayOfWeek: 'Monday', exercises: []),
    ];
    _dayNameControllers['1'] = TextEditingController(text: 'Push Day');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weeksController.dispose();
    _descriptionController.dispose();
    _nameFocus.dispose();
    _weeksFocus.dispose();
    _customName.dispose();
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
        progressionType: ProgressionMode.hypertrophy,
      ));
      _pickerOpenForDay = null;
      _exerciseSearchQuery = '';
      _selectedCategory = null;
    });
  }

  void _addCustomExercise(String dayId) {
    if (_customName.text.trim().isEmpty) return;
    setState(() {
      final day = _workoutDays.firstWhere((d) => d.id == dayId);
      day.exercises.add(_ExerciseConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _customName.text.trim(),
        category: _customCategory,
        equipment: _customEquipment,
        equipmentType: _mapEquipmentType(_customEquipment),
        sets: 3,
        repMin: 8,
        repMax: 12,
        targetRir: 2,
        restSeconds: 120,
        progressionType: ProgressionMode.hypertrophy,
      ));
      _customName.clear();
      _customFormOpenForDay = null;
    });
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
        ).toJson();
        await ref.read(coachRepositoryProvider).createCoachProgram(uid, programJson);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                _buildProgramInfoSection(context),
                SizedBox(height: AppSpacing.sectionGap),
                ..._workoutDays.map((day) => _buildWorkoutDayCard(context, context.isDark, day)),
                SizedBox(height: 16.h),
                CustomButton(
                  text: '+ Add Workout Day',
                  variant: ButtonVariant.dashed,
                  icon: AppIcons.plus,
                  onPressed: _addWorkoutDay,
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.screenPadding, 8.h, AppSpacing.screenPadding, 16.h),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Padding(
                  padding: EdgeInsets.all(8.r),
                  child: Icon(AppIcons.arrowLeft, size: 20.r, color: context.foreground),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text('Create Program', style: AppTextStyles.h2.copyWith(color: context.foreground)),
              ),
              GestureDetector(
                onTap: _saving ? null : _saveProgram,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: _saving ? context.mutedForeground : context.primaryColor,
                    borderRadius: AppRadius.borderLg,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_saving)
                        SizedBox(
                          width: 16.r,
                          height: 16.r,
                          child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      else
                        Icon(AppIcons.save, size: 16.r, color: Colors.white),
                      SizedBox(width: 4.w),
                      Text(
                        _saving ? 'Saving...' : 'Save',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgramInfoSection(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomInput(
            controller: _nameController,
            label: 'Program Name',
            hint: 'e.g., Push Pull Legs',
            focusNode: _nameFocus,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _weeksFocus.requestFocus(),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: CustomInput(
                  controller: _weeksController,
                  label: 'Duration (weeks)',
                  keyboardType: TextInputType.number,
                  focusNode: _weeksFocus,
                  textInputAction: TextInputAction.done,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildSelectField(
                  context: context,
                  label: 'Difficulty',
                  value: _difficulty,
                  options: const ['Beginner', 'Intermediate', 'Advanced'],
                  onChanged: (v) => setState(() => _difficulty = v),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          CustomInput(
            controller: _descriptionController,
            label: 'Description (optional)',
            hint: 'Brief description of this program',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutDayCard(BuildContext context, bool isDark, _WorkoutDay day) {
    final nameController = _dayNameControllers[day.id]!;

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
                          style: AppTextStyles.body.copyWith(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Workout name',
                            hintStyle: AppTextStyles.body.copyWith(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.borderLg,
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadius.borderLg,
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AppRadius.borderLg,
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                            isDense: true,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        _buildSelectField(
                          context: context,
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
                        child: Icon(AppIcons.trash2, size: 24.r, color: Colors.white),
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
                    _buildCustomExerciseForm(context, day.id)
                  else if (_pickerOpenForDay == day.id)
                    _buildExercisePicker(context, day.id)
                  else
                    CustomButton(
                      text: '+ Add Exercise',
                      variant: ButtonVariant.dashed,
                      icon: AppIcons.plus,
                      onPressed: () => setState(() {
                        _pickerOpenForDay = day.id;
                        _exerciseSearchQuery = '';
                        _selectedCategory = null;
                      }),
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
            Row(
              children: [
                _editableConfigField(context, dayId, ex, 'Sets', '${ex.sets}', 60.w),
                SizedBox(width: 8.w),
                _editableConfigField(context, dayId, ex, 'Rep Range', '${ex.repMin}-${ex.repMax}', 80.w),
                SizedBox(width: 8.w),
                _editableConfigField(context, dayId, ex, 'RIR', '${ex.targetRir}', 50.w),
                SizedBox(width: 8.w),
                _editableConfigField(context, dayId, ex, 'Rest', '${ex.restSeconds}s', 60.w),
              ],
            ),
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: () => _editProgressionType(dayId, ex),
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
        ),
      ),
    );
  }

  Widget _editableConfigField(
    BuildContext context,
    String dayId,
    _ExerciseConfig ex,
    String label,
    String value,
    double width,
  ) {
    return GestureDetector(
      onTap: () => _showEditDialog(context, dayId, ex, label),
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
                        value,
                        style: AppTextStyles.bodySmall.copyWith(color: context.foreground),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Icon(AppIcons.edit, size: 10.r, color: context.mutedForeground),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, String dayId, _ExerciseConfig ex, String label) async {
    if (label == 'Rep Range') {
      await _showRepRangeDialog(context, dayId, ex);
      return;
    }

    String currentValue;
    switch (label) {
      case 'Sets':
        currentValue = '${ex.sets}';
      case 'RIR':
        currentValue = '${ex.targetRir}';
      case 'Rest':
        currentValue = '${ex.restSeconds}';
      default:
        return;
    }

    final controller = TextEditingController(text: currentValue);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: label == 'Rest' ? 'Seconds' : 'Enter value',
            suffixText: label == 'Rest' ? 's' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null || result.isEmpty) return;
    final parsed = int.tryParse(result);
    if (parsed == null || parsed < 0) return;

    setState(() {
      switch (label) {
        case 'Sets':
          ex.sets = parsed.clamp(1, 20);
        case 'RIR':
          ex.targetRir = parsed.clamp(0, 5);
        case 'Rest':
          ex.restSeconds = parsed.clamp(0, 600);
      }
    });
  }

  Future<void> _showRepRangeDialog(BuildContext context, String dayId, _ExerciseConfig ex) async {
    final minController = TextEditingController(text: '${ex.repMin}');
    final maxController = TextEditingController(text: '${ex.repMax}');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Rep Range'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Min'),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: const Text('-'),
            ),
            Expanded(
              child: TextField(
                controller: maxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );

    if (result != true) {
      minController.dispose();
      maxController.dispose();
      return;
    }

    final min = int.tryParse(minController.text);
    final max = int.tryParse(maxController.text);
    minController.dispose();
    maxController.dispose();

    if (min == null || max == null || min < 1 || max < min) return;

    setState(() {
      ex.repMin = min.clamp(1, 100);
      ex.repMax = max.clamp(min, 100);
    });
  }

  void _editProgressionType(String dayId, _ExerciseConfig ex) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Progression Type'),
        children: ProgressionMode.values.map((mode) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() => ex.progressionType = mode);
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                if (ex.progressionType == mode)
                  Icon(AppIcons.check, size: 16.r, color: context.primaryColor)
                else
                  SizedBox(width: 16.r),
                SizedBox(width: 8.w),
                Text(mode.label),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExercisePicker(BuildContext context, String dayId) {
    final allExercises = ref.read(exerciseLibraryProvider);
    final categories = allExercises.map((e) => e.category).toSet().toList()..sort();

    final filtered = allExercises.where((e) {
      final matchesSearch = _exerciseSearchQuery.isEmpty ||
          e.name.toLowerCase().contains(_exerciseSearchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == null || e.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return CustomCard(
      padding: EdgeInsets.all(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Exercise',
                style: AppTextStyles.h4.copyWith(
                  color: context.foreground,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _pickerOpenForDay = null;
                  _exerciseSearchQuery = '';
                  _selectedCategory = null;
                }),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // Search field
          TextField(
            onChanged: (v) => setState(() => _exerciseSearchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search exercises...',
              hintStyle: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
              prefixIcon: Icon(AppIcons.search, size: 18.r),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              border: OutlineInputBorder(borderRadius: AppRadius.borderLg),
            ),
            style: AppTextStyles.bodySmall.copyWith(color: context.foreground),
          ),
          SizedBox(height: 8.h),
          // Category filter chips
          SizedBox(
            height: 32.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip(context, 'All', _selectedCategory == null, () {
                  setState(() => _selectedCategory = null);
                }),
                ...categories.map((c) => _filterChip(context, c, _selectedCategory == c, () {
                      setState(() => _selectedCategory = _selectedCategory == c ? null : c);
                    })),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          // Exercise list
          SizedBox(
            height: 200.h,
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No exercises found',
                      style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final ex = filtered[index];
                      return InkWell(
                        onTap: () => _addExerciseFromLibrary(dayId, ex),
                        borderRadius: AppRadius.borderLg,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ex.name,
                                      style: AppTextStyles.bodySmall.copyWith(color: context.foreground),
                                    ),
                                    Text(
                                      '${ex.muscle} \u2022 ${ex.equipment}',
                                      style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
                                    ),
                                  ],
                                ),
                              ),
                              CustomBadge(text: ex.category),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(height: 8.h),
          CustomButton(
            text: '+ Create Custom Exercise',
            variant: ButtonVariant.dashed,
            icon: AppIcons.plus,
            onPressed: () => setState(() {
              _pickerOpenForDay = null;
              _customFormOpenForDay = dayId;
            }),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(right: 6.w),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isSelected ? context.primaryColor : context.mutedColor,
            borderRadius: AppRadius.borderFull,
            border: Border.all(
              color: isSelected ? context.primaryColor : context.borderColor,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isSelected ? Colors.white : context.mutedForeground,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomExerciseForm(BuildContext context, String dayId) {
    return CustomCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Create Custom Exercise',
                style: AppTextStyles.h4.copyWith(
                  color: context.foreground,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _customFormOpenForDay = null),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          CustomInput(
            controller: _customName,
            label: 'Exercise Name',
            hint: 'e.g., Dumbbell Press',
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildSelectField(
                  context: context,
                  label: 'Category',
                  value: _customCategory,
                  options: const ['Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core'],
                  onChanged: (v) => setState(() => _customCategory = v),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildSelectField(
                  context: context,
                  label: 'Equipment',
                  value: _customEquipment,
                  options: const ['Dumbbell', 'Barbell', 'Machine', 'Body Weight'],
                  onChanged: (v) => setState(() => _customEquipment = v),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          CustomButton(
            text: 'Add Custom Exercise',
            variant: ButtonVariant.primary,
            onPressed: () => _addCustomExercise(dayId),
          ),
        ],
      ),
    );
  }

  // ─── Reusable Select Field (replaces ugly DropdownButton) ───

  Widget _buildSelectField({
    required BuildContext context,
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
    bool onDark = false,
    IconData? icon,
    String? sheetTitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: onDark ? Colors.white70 : context.mutedForeground,
            ),
          ),
          SizedBox(height: 8.h),
        ],
        GestureDetector(
          onTap: () => _showSelectionSheet(
            context,
            sheetTitle ?? label,
            value,
            options,
            onChanged,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: onDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : context.mutedColor,
              borderRadius: AppRadius.borderLg,
              border: Border.all(
                color: onDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : context.borderColor,
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16.r,
                    color: onDark ? Colors.white70 : context.mutedForeground,
                  ),
                  SizedBox(width: 8.w),
                ],
                Expanded(
                  child: Text(
                    value,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: onDark ? Colors.white : context.foreground,
                    ),
                  ),
                ),
                Icon(
                  AppIcons.chevronDown,
                  size: 16.r,
                  color: onDark ? Colors.white70 : context.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSelectionSheet(
    BuildContext context,
    String title,
    String currentValue,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: context.mutedForeground.withValues(alpha: 0.3),
                  borderRadius: AppRadius.borderFull,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h3.copyWith(color: context.foreground),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Icon(AppIcons.x, size: 20.r, color: context.mutedForeground),
                    ),
                  ],
                ),
              ),
              Divider(color: context.mutedForeground.withValues(alpha:0.15), height: 1),
              ...options.map((option) {
                final isSelected = option == currentValue;
                return InkWell(
                  onTap: () {
                    onChanged(option);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.primaryColor.withValues(alpha: 0.08)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: AppTextStyles.body.copyWith(
                              color: isSelected
                                  ? context.primaryColor
                                  : context.foreground,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            AppIcons.check,
                            size: 20.r,
                            color: context.primaryColor,
                          ),
                      ],
                    ),
                  ),
                );
              }),
              SizedBox(height: 8.h),
            ],
          ),
        );
      },
    );
  }
}

class _WorkoutDay {
  final String id;
  String name;
  String dayOfWeek;
  final List<_ExerciseConfig> exercises;

  _WorkoutDay({
    required this.id,
    required this.name,
    required this.dayOfWeek,
    required this.exercises,
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
  });
}
