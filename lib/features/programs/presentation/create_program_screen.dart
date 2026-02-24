import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';

import '../../../app/providers.dart';
import '../../../shared/models/enums.dart';
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
  const CreateProgramScreen({super.key});

  @override
  ConsumerState<CreateProgramScreen> createState() => _CreateProgramScreenState();
}

class _CreateProgramScreenState extends ConsumerState<CreateProgramScreen> {
  bool _saving = false;
  final _nameController = TextEditingController();
  final _weeksController = TextEditingController(text: '8');
  final _nameFocus = FocusNode();
  final _weeksFocus = FocusNode();
  String? _pickerOpenForDay;
  String? _customFormOpenForDay;

  final _customName = TextEditingController();
  String _customCategory = 'Chest';
  String _customEquipment = 'Dumbbell';

  final _daysOfWeek = const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  late List<_WorkoutDay> _workoutDays;

  final _availableExercises = const [
    {'name': 'Barbell Bench Press', 'category': 'Chest', 'equipment': 'Barbell', 'sets': 4, 'repMin': 6, 'repMax': 12, 'rir': 2},
    {'name': 'Incline Dumbbell Press', 'category': 'Chest', 'equipment': 'Dumbbell', 'sets': 3, 'repMin': 8, 'repMax': 12, 'rir': 2},
    {'name': 'Cable Flyes', 'category': 'Chest', 'equipment': 'Machine', 'sets': 3, 'repMin': 12, 'repMax': 15, 'rir': 1},
    {'name': 'Deadlift', 'category': 'Back', 'equipment': 'Barbell', 'sets': 4, 'repMin': 5, 'repMax': 8, 'rir': 3},
    {'name': 'Barbell Row', 'category': 'Back', 'equipment': 'Barbell', 'sets': 4, 'repMin': 8, 'repMax': 12, 'rir': 2},
    {'name': 'Pull Ups', 'category': 'Back', 'equipment': 'Body Weight', 'sets': 3, 'repMin': 6, 'repMax': 10, 'rir': 2},
    {'name': 'Back Squat', 'category': 'Legs', 'equipment': 'Barbell', 'sets': 4, 'repMin': 6, 'repMax': 10, 'rir': 2},
    {'name': 'Romanian Deadlift', 'category': 'Legs', 'equipment': 'Barbell', 'sets': 3, 'repMin': 8, 'repMax': 12, 'rir': 2},
    {'name': 'Leg Press', 'category': 'Legs', 'equipment': 'Machine', 'sets': 3, 'repMin': 10, 'repMax': 15, 'rir': 1},
    {'name': 'Overhead Press', 'category': 'Shoulders', 'equipment': 'Barbell', 'sets': 4, 'repMin': 6, 'repMax': 10, 'rir': 2},
    {'name': 'Lateral Raises', 'category': 'Shoulders', 'equipment': 'Dumbbell', 'sets': 3, 'repMin': 12, 'repMax': 15, 'rir': 1},
    {'name': 'Face Pulls', 'category': 'Shoulders', 'equipment': 'Machine', 'sets': 3, 'repMin': 15, 'repMax': 20, 'rir': 1},
  ];

  @override
  void initState() {
    super.initState();
    _workoutDays = [
      _WorkoutDay(id: '1', name: 'Push Day', dayOfWeek: 'Monday', exercises: []),
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weeksController.dispose();
    _nameFocus.dispose();
    _weeksFocus.dispose();
    _customName.dispose();
    super.dispose();
  }

  void _addWorkoutDay() {
    setState(() {
      _workoutDays.add(_WorkoutDay(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Day ${_workoutDays.length + 1}',
        dayOfWeek: 'Monday',
        exercises: [],
      ));
    });
  }

  void _removeWorkoutDay(String id) {
    setState(() => _workoutDays.removeWhere((d) => d.id == id));
  }

  void _addExercise(String dayId, Map<String, Object> template) {
    setState(() {
      final day = _workoutDays.firstWhere((d) => d.id == dayId);
      day.exercises.add(_ExerciseConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: template['name'] as String,
        category: template['category'] as String,
        equipment: template['equipment'] as String?,
        sets: template['sets'] as int,
        repMin: template['repMin'] as int,
        repMax: template['repMax'] as int,
        targetRir: template['rir'] as int,
        restSeconds: 120,
        progressionType: 'Load First',
      ));
      _pickerOpenForDay = null;
    });
  }

  void _addCustomExercise(String dayId) {
    if (_customName.text.trim().isEmpty) return;
    _addExercise(dayId, {
      'name': _customName.text.trim(),
      'category': _customCategory,
      'equipment': _customEquipment,
      'sets': 3,
      'repMin': 8,
      'repMax': 12,
      'rir': 2,
    });
    _customName.clear();
    setState(() => _customFormOpenForDay = null);
  }

  void _removeExercise(String dayId, String exId) {
    setState(() {
      final day = _workoutDays.firstWhere((d) => d.id == dayId);
      day.exercises.removeWhere((e) => e.id == exId);
    });
  }

  Future<void> _saveProgram() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

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
              equipmentType: _mapEquipmentType(ex.equipment),
            );
          }).toList(),
        );
      }).toList();

      await ref.read(programServiceProvider).createProgram(
        uid,
        name: name,
        days: days,
        weeks: weeks,
      );
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  EquipmentType _mapEquipmentType(String? equipment) {
    switch (equipment) {
      case 'Barbell': return EquipmentType.barbell;
      case 'Dumbbell': return EquipmentType.dumbbell;
      case 'Machine': return EquipmentType.machineStack;
      case 'Body Weight': return EquipmentType.bodyweight;
      default: return EquipmentType.barbell;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                ..._workoutDays.map((day) => _buildWorkoutDayCard(context, isDark, day)),
                SizedBox(height: 16.h),
                CustomButton(
                  text: '+ Add Workout Day',
                  variant: ButtonVariant.dashed,
                  icon: AppIcons.plus,
                  onPressed: _addWorkoutDay,
                ),
                SizedBox(height: 80.h),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.screenPadding, 8.h, AppSpacing.screenPadding, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                    child: Text('Create Program', style: AppTextStyles.h1.copyWith(color: context.foreground)),
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
                            SizedBox(width: 16.r, height: 16.r, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          else
                            Icon(AppIcons.save, size: 16.r, color: Colors.white),
                          SizedBox(width: 4.w),
                          Text(_saving ? 'Saving...' : 'Save', style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              CustomInput(
                controller: _nameController,
                label: 'Program Name',
                hint: 'e.g., Push Pull Legs',
                focusNode: _nameFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _weeksFocus.requestFocus(),
              ),
              SizedBox(height: 12.h),
              CustomInput(
                controller: _weeksController,
                label: 'Program Duration (weeks)',
                keyboardType: TextInputType.number,
                focusNode: _weeksFocus,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutDayCard(BuildContext context, bool isDark, _WorkoutDay day) {
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
                  Icon(AppIcons.gripVertical, size: 20.r, color: Colors.white.withValues(alpha: 0.5)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: TextEditingController(text: day.name),
                          onChanged: (v) => day.name = v,
                          style: AppTextStyles.body.copyWith(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Workout name',
                            hintStyle: AppTextStyles.body.copyWith(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.1),
                            border: OutlineInputBorder(borderRadius: AppRadius.borderLg, borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                            enabledBorder: OutlineInputBorder(borderRadius: AppRadius.borderLg, borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                            isDense: true,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Icon(AppIcons.calendar, size: 16.r, color: Colors.white70),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: AppRadius.borderLg,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: day.dayOfWeek,
                                    isExpanded: true,
                                    isDense: true,
                                    dropdownColor: context.cardColor,
                                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                                    icon: Icon(AppIcons.chevronDown, size: 16.r, color: Colors.white70),
                                    items: _daysOfWeek.map((d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d, style: AppTextStyles.bodySmall.copyWith(color: context.foreground)),
                                    )).toList(),
                                    onChanged: (v) => setState(() => day.dayOfWeek = v!),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                          Icon(AppIcons.dumbbell, size: 32.r, color: context.mutedForeground.withValues(alpha: 0.5)),
                          SizedBox(height: 8.h),
                          Text('No exercises added yet', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
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
                Icon(AppIcons.gripVertical, size: 16.r, color: context.mutedForeground),
                SizedBox(width: 4.w),
                Expanded(
                  child: Wrap(
                    spacing: 8.w,
                    runSpacing: 4.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(ex.name, style: AppTextStyles.bodySmall.copyWith(color: context.foreground, fontWeight: FontWeight.w500)),
                      CustomBadge(text: ex.category),
                      if (ex.equipment != null)
                        CustomBadge(
                          text: ex.equipment!,
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
                _configField(context, 'Sets', '${ex.sets}', 60.w),
                SizedBox(width: 8.w),
                _configField(context, 'Rep Range', '${ex.repMin}-${ex.repMax}', 80.w),
                SizedBox(width: 8.w),
                _configField(context, 'RIR', '${ex.targetRir}', 50.w),
                SizedBox(width: 8.w),
                _configField(context, 'Rest', '${ex.restSeconds}s', 60.w),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Text('Progression: ', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                Text(ex.progressionType, style: AppTextStyles.caption.copyWith(color: context.primaryColor, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _configField(BuildContext context, String label, String value, double width) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: context.mutedForeground, fontSize: 10.sp)),
          SizedBox(height: 4.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: AppRadius.borderSm,
              border: Border.all(color: context.borderColor),
            ),
            child: Center(
              child: Text(value, style: AppTextStyles.bodySmall.copyWith(color: context.foreground)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisePicker(BuildContext context, String dayId) {
    return CustomCard(
      padding: EdgeInsets.all(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Exercise', style: AppTextStyles.h4.copyWith(color: context.foreground, fontWeight: FontWeight.w500)),
              GestureDetector(
                onTap: () => setState(() => _pickerOpenForDay = null),
                child: Text('Cancel', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 200.h,
            child: ListView(
              children: _availableExercises.map((ex) {
                return InkWell(
                  onTap: () => _addExercise(dayId, ex),
                  borderRadius: AppRadius.borderLg,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(ex['name'] as String, style: AppTextStyles.bodySmall.copyWith(color: context.foreground)),
                        CustomBadge(text: ex['category'] as String),
                      ],
                    ),
                  ),
                );
              }).toList(),
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

  Widget _buildCustomExerciseForm(BuildContext context, String dayId) {
    return CustomCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Create Custom Exercise', style: AppTextStyles.h4.copyWith(color: context.foreground, fontWeight: FontWeight.w500)),
              GestureDetector(
                onTap: () => setState(() => _customFormOpenForDay = null),
                child: Text('Cancel', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          CustomInput(controller: _customName, label: 'Exercise Name', hint: 'e.g., Dumbbell Press'),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: context.mutedColor,
                        borderRadius: AppRadius.borderLg,
                        border: Border.all(color: context.borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _customCategory,
                          isExpanded: true,
                          dropdownColor: context.cardColor,
                          style: AppTextStyles.bodySmall.copyWith(color: context.foreground),
                          items: ['Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setState(() => _customCategory = v!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Equipment', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: context.mutedColor,
                        borderRadius: AppRadius.borderLg,
                        border: Border.all(color: context.borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _customEquipment,
                          isExpanded: true,
                          dropdownColor: context.cardColor,
                          style: AppTextStyles.bodySmall.copyWith(color: context.foreground),
                          items: ['Dumbbell', 'Barbell', 'Machine', 'Body Weight'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setState(() => _customEquipment = v!),
                        ),
                      ),
                    ),
                  ],
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
}

class _WorkoutDay {
  final String id;
  String name;
  String dayOfWeek;
  final List<_ExerciseConfig> exercises;

  _WorkoutDay({required this.id, required this.name, required this.dayOfWeek, required this.exercises});
}

class _ExerciseConfig {
  final String id;
  final String name;
  final String category;
  final String? equipment;
  int sets;
  int repMin;
  int repMax;
  int targetRir;
  int restSeconds;
  String progressionType;

  _ExerciseConfig({
    required this.id,
    required this.name,
    required this.category,
    this.equipment,
    this.sets = 3,
    this.repMin = 8,
    this.repMax = 12,
    this.targetRir = 2,
    this.restSeconds = 120,
    this.progressionType = 'Load First',
  });
}
