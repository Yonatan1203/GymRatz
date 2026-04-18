import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';
import '../../../shared/widgets/empty_state_widget.dart';

import '../../../app/providers.dart';
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

  List<Exercise> _getFilteredExercises(List<Exercise> exercises) {
    return exercises.where((ex) {
      if (_selectedCategory != 'All' && ex.category != _selectedCategory) return false;
      if (_selectedEquipment != 'All' && ex.equipment != _selectedEquipment) return false;
      if (_searchQuery.isNotEmpty && !ex.name.toLowerCase().contains(_searchQuery.toLowerCase())) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allExercises = ref.watch(exerciseLibraryProvider);
    final favoriteIds = ref.watch(favoriteExerciseIdsProvider).valueOrNull ?? {};

    final exercisesWithFavStatus = allExercises
        .map((e) => e.copyWith(isFavorite: favoriteIds.contains(e.id)))
        .toList();

    final filtered = _getFilteredExercises(exercisesWithFavStatus);
    final favorites = filtered.where((e) => e.isFavorite).toList();
    final nonFavorites = filtered.where((e) => !e.isFavorite).toList();

    return Scaffold(
      body: Column(
        children: [
          _buildStickyHeader(context),
          Expanded(
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
        ],
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
                      Text(exercise.muscle, style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                      Text(' \u2022 ', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                      Text(exercise.equipment, style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
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
                    exercise.isFavorite ? AppIcons.heart : AppIcons.heart,
                    size: 20.r,
                    color: exercise.isFavorite ? Colors.red : context.mutedForeground,
                  ),
                ),
              ),
            ),
          ],
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
}
