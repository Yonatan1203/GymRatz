import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/skeleton_loader.dart';

import '../../../app/providers.dart';
import '../../../shared/models/enums.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/utils/platform_adapter.dart';
import '../../../shared/widgets/custom_badge.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/models/exercise.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedEquipment = 'All';

  final _categories = const ['All', 'Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core'];
  final _equipmentTypes = const ['All', 'Dumbbell', 'Barbell', 'Machine', 'Body Weight'];

  void _toggleFavorite(Exercise exercise) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    await ref.read(userRepositoryProvider).toggleFavoriteExercise(uid, exercise.id);
  }

  void _confirmDeleteExercise(BuildContext context, Exercise exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text('Are you sure you want to delete "${exercise.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final uid = ref.read(currentUidProvider);
      if (uid != null) {
        await ref.read(exerciseRepositoryProvider).deleteExercise(uid, exercise.id);
      }
    }
  }

  List<Exercise> _getFilteredExercises(List<Exercise> exercises) {
    return exercises.where((ex) {
      if (_selectedCategory != 'All' && ex.category != _selectedCategory) return false;
      if (_selectedEquipment != 'All' && ex.equipment != _selectedEquipment) return false;
      if (_searchQuery.isNotEmpty && !ex.name.toLowerCase().contains(_searchQuery.toLowerCase())) return false;
      return true;
    }).toList();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(bundledExercisesProvider);
    ref.invalidate(userExercisesProvider);
    // Wait for bundled exercises to reload; stream will re-emit automatically.
    await ref
        .read(bundledExercisesProvider.future)
        .catchError((_) => <Exercise>[]);
  }

  void _showExerciseDetail(BuildContext context, Exercise exercise) {
    final activeSession = ref.read(activeWorkoutSessionProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ExerciseDetailSheet(
        exercise: exercise,
        hasActiveWorkout: activeSession != null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bundledAsync = ref.watch(bundledExercisesProvider);
    final userAsync = ref.watch(userExercisesProvider);
    final isLoading = bundledAsync.isLoading || userAsync.isLoading;

    final allExercises = ref.watch(exerciseLibraryProvider);
    final favoriteIds = ref.watch(favoriteExerciseIdsProvider).valueOrNull ?? {};

    final exercisesWithFavStatus = allExercises
        .map((e) => e.copyWith(isFavorite: favoriteIds.contains(e.id)))
        .toList();

    final filtered = _getFilteredExercises(exercisesWithFavStatus);
    final favorites = filtered.where((e) => e.isFavorite).toList();
    final nonFavorites = filtered.where((e) => !e.isFavorite).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateExerciseSheet(context),
        tooltip: 'Create custom exercise',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildStickyHeader(context),
          Expanded(
            child: isLoading && allExercises.isEmpty
                ? _buildSkeletonList(context)
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: filtered.isEmpty
                        ? _buildEmptyState(context)
                        : ListView(
                            padding: EdgeInsets.all(AppSpacing.screenPadding),
                            children: [
                              if (favorites.isNotEmpty) ...[
                                Text('Favorites', style: AppTextStyles.h2.copyWith(color: context.foreground)),
                                SizedBox(height: 12.h),
                                ...favorites.map((ex) => _buildExerciseCard(context, ex)),
                                SizedBox(height: AppSpacing.sectionGap),
                              ],
                              Text(
                                _selectedCategory == 'All' ? 'All Exercises' : '$_selectedCategory Exercises',
                                style: AppTextStyles.h2.copyWith(color: context.foreground),
                              ),
                              SizedBox(height: 12.h),
                              ...nonFavorites.map((ex) => _buildExerciseCard(context, ex)),
                              SizedBox(height: 16.h),
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList(BuildContext context) {
    return SkeletonLoader(
      child: ListView.builder(
        padding: EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: 8,
        itemBuilder: (_, __) => Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: SkeletonCard(
            height: 90,
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonCircle(size: 32),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SkeletonLine(width: 180.w, height: 14),
                        SizedBox(height: 8.h),
                        SkeletonLine(width: 120.w, height: 12),
                        SizedBox(height: 8.h),
                        SkeletonLine(width: 64.w, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickyHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.screenPadding, 8.h, AppSpacing.screenPadding, 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Go back',
                    child: GestureDetector(
                      onTap: () {
                        PlatformAdapter.hapticLight();
                        context.pop();
                      },
                      child: Padding(
                        padding: EdgeInsets.all(8.r),
                        child: Icon(AppIcons.arrowLeft, size: 20.r, color: context.foreground),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text('Exercise Library', style: AppTextStyles.h1.copyWith(color: context.foreground)),
                ],
              ),
              SizedBox(height: 12.h),
              TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: AppTextStyles.body.copyWith(color: context.foreground),
                decoration: InputDecoration(
                  hintText: 'Search exercises...',
                  hintStyle: AppTextStyles.body.copyWith(color: context.mutedForeground),
                  prefixIcon: Icon(AppIcons.search, size: 20.r, color: context.mutedForeground),
                  filled: true,
                  fillColor: context.mutedColor,
                  border: OutlineInputBorder(borderRadius: AppRadius.borderLg, borderSide: BorderSide(color: context.borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: AppRadius.borderLg, borderSide: BorderSide(color: context.borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: AppRadius.borderLg, borderSide: BorderSide(color: context.primaryColor, width: 2)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              ),
              SizedBox(height: 12.h),
              _buildFilterRow(context, _categories, _selectedCategory, (v) => setState(() => _selectedCategory = v)),
              SizedBox(height: 8.h),
              _buildFilterRow(context, _equipmentTypes, _selectedEquipment, (v) => setState(() => _selectedEquipment = v)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context, List<String> items, String selected, ValueChanged<String> onSelected) {
    return SizedBox(
      height: 36.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (_, index) {
          final isSelected = selected == items[index];
          return Semantics(
            button: true,
            label: items[index],
            selected: isSelected,
            child: GestureDetector(
            onTap: () {
              PlatformAdapter.hapticSelection();
              onSelected(items[index]);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: isSelected ? context.primaryColor : context.mutedColor,
                borderRadius: AppRadius.borderLg,
              ),
              child: Center(
                child: Text(
                  items[index],
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? Colors.white : context.mutedForeground,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
          );
        },
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, Exercise exercise) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Semantics(
        button: true,
        label: 'View details for ${exercise.name}',
        child: GestureDetector(
          onTap: () {
            PlatformAdapter.hapticLight();
            _showExerciseDetail(context, exercise);
          },
          child: CustomCard(
            padding: EdgeInsets.all(16.r),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(AppIcons.dumbbell, size: 16.r, color: context.primaryColor),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(exercise.name, style: AppTextStyles.h4.copyWith(color: context.foreground, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          CustomBadge(text: exercise.type, backgroundColor: context.mutedColor, textColor: context.mutedForeground),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: Text(
                              '${exercise.muscle} • ${exercise.equipment}',
                              style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      CustomBadge(
                        text: exercise.difficulty,
                        backgroundColor: exercise.difficulty == 'Beginner'
                            ? context.accentColor.withValues(alpha: 0.2)
                            : exercise.difficulty == 'Intermediate'
                                ? context.primaryColor.withValues(alpha: 0.2)
                                : context.secondaryColor.withValues(alpha: 0.2),
                        textColor: exercise.difficulty == 'Beginner'
                            ? context.accentColor
                            : exercise.difficulty == 'Intermediate'
                                ? context.primaryColor
                                : context.secondaryColor,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      button: true,
                      label: exercise.isFavorite ? 'Remove from favorites' : 'Add to favorites',
                      child: GestureDetector(
                        onTap: () {
                          PlatformAdapter.hapticSelection();
                          _toggleFavorite(exercise);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(8.r),
                          child: Icon(
                            exercise.isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 20.r,
                            color: exercise.isFavorite ? Colors.red : context.mutedForeground,
                          ),
                        ),
                      ),
                    ),
                    if (exercise.isDefault == false)
                      Semantics(
                        button: true,
                        label: 'Delete exercise',
                        child: GestureDetector(
                          onTap: () => _confirmDeleteExercise(context, exercise),
                          child: Padding(
                            padding: EdgeInsets.all(8.r),
                            child: Icon(
                              AppIcons.trash2,
                              size: 16.r,
                              color: context.destructiveColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateWidget(
      icon: AppIcons.search,
      title: 'No exercises found',
      subtitle: 'Try adjusting your search or filters',
    );
  }

  void _showCreateExerciseSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    String category = 'Chest';
    String equipment = 'Barbell';
    final categories = const ['Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core', 'Other'];
    final equipmentOptions = const ['Barbell', 'Dumbbell', 'Machine', 'Body Weight', 'Cable', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.xl,
            AppSpacing.screenPadding,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Custom Exercise', style: AppTextStyles.h2.copyWith(color: context.foreground)),
              SizedBox(height: AppSpacing.lg),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Exercise name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setSheetState(() => category = v ?? category),
              ),
              SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: equipment,
                decoration: InputDecoration(
                  labelText: 'Equipment',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                items: equipmentOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setSheetState(() => equipment = v ?? equipment),
              ),
              SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final uid = ref.read(currentUidProvider);
                    if (uid == null) return;
                    final exercise = Exercise(
                      id: '${uid}_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      category: category,
                      type: 'Strength',
                      muscle: category,
                      equipment: equipment,
                      difficulty: 'Intermediate',
                      equipmentType: EquipmentType.barbell,
                      isDefault: false,
                    );
                    await ref.read(exerciseRepositoryProvider).createExercise(uid, exercise);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: const Text('Save Exercise'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Exercise Detail Bottom Sheet ───────────────────────────────────────────

class _ExerciseDetailSheet extends StatelessWidget {
  final Exercise exercise;
  final bool hasActiveWorkout;

  const _ExerciseDetailSheet({
    required this.exercise,
    required this.hasActiveWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final muscleGroups = [
      if (exercise.muscle.isNotEmpty) exercise.muscle,
      ...exercise.muscleGroups.where((m) => m.toLowerCase() != exercise.muscle.toLowerCase()),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollController) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Scaffold(
          backgroundColor: context.cardColor,
          body: Column(
            children: [
              // Drag handle
              Padding(
                padding: EdgeInsets.only(top: 12.h, bottom: 4.h),
                child: Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: context.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.lg,
                    AppSpacing.screenPadding,
                    AppSpacing.xl,
                  ),
                  children: [
                    // Title row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withValues(alpha: 0.15),
                            borderRadius: AppRadius.borderMd,
                          ),
                          child: Icon(AppIcons.dumbbell, size: 24.r, color: context.primaryColor),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(exercise.name, style: AppTextStyles.h2.copyWith(color: context.foreground)),
                              SizedBox(height: 4.h),
                              Text(
                                exercise.category,
                                style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xl),

                    // Chips: category + equipment + difficulty
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        CustomBadge(
                          text: exercise.category,
                          backgroundColor: context.primaryColor.withValues(alpha: 0.15),
                          textColor: context.primaryColor,
                        ),
                        CustomBadge(
                          text: exercise.equipment,
                          backgroundColor: context.mutedColor,
                          textColor: context.mutedForeground,
                        ),
                        CustomBadge(
                          text: exercise.difficulty,
                          backgroundColor: exercise.difficulty == 'Beginner'
                              ? context.accentColor.withValues(alpha: 0.2)
                              : exercise.difficulty == 'Intermediate'
                                  ? context.primaryColor.withValues(alpha: 0.2)
                                  : context.secondaryColor.withValues(alpha: 0.2),
                          textColor: exercise.difficulty == 'Beginner'
                              ? context.accentColor
                              : exercise.difficulty == 'Intermediate'
                                  ? context.primaryColor
                                  : context.secondaryColor,
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xl),

                    // Muscles worked
                    if (muscleGroups.isNotEmpty) ...[
                      Text('Muscles Worked', style: AppTextStyles.h4.copyWith(color: context.foreground)),
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: muscleGroups
                            .map((m) => CustomBadge(
                                  text: m,
                                  backgroundColor: context.mutedColor,
                                  textColor: context.mutedForeground,
                                ))
                            .toList(),
                      ),
                      SizedBox(height: AppSpacing.xl),
                    ],

                    // Description / instructions
                    Text('Form Tips', style: AppTextStyles.h4.copyWith(color: context.foreground)),
                    SizedBox(height: 8.h),
                    Text(
                      exercise.instructions?.isNotEmpty == true
                          ? exercise.instructions!
                          : 'No form tips available for this exercise. Focus on controlled movement, proper breathing, and full range of motion.',
                      style: AppTextStyles.body.copyWith(color: context.mutedForeground),
                    ),
                    SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),

              // Action buttons
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  MediaQuery.of(context).viewPadding.bottom + AppSpacing.xl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          PlatformAdapter.hapticLight();
                          Navigator.of(context).pop();
                          context.push('/programs/create');
                        },
                        child: const Text('Add to Program'),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: hasActiveWorkout
                            ? () {
                                PlatformAdapter.hapticLight();
                                Navigator.of(context).pop();
                              }
                            : null,
                        style: hasActiveWorkout
                            ? null
                            : OutlinedButton.styleFrom(
                                foregroundColor: context.mutedForeground,
                                side: BorderSide(color: context.borderColor),
                              ),
                        child: Text(
                          hasActiveWorkout ? 'Log in Current Workout' : 'No Active Workout',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
