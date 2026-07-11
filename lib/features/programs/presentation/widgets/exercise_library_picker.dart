import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/models/exercise.dart';
import '../../../../theme/app_icons.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../shared/utils/extensions.dart';
import '../../../../shared/widgets/custom_badge.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_card.dart';

/// Inline exercise-library search + category-filter picker.
///
/// Manages its own search query and selected-category state so the parent
/// only tracks which day has the picker open, not the filter state.
class ExerciseLibraryPicker extends StatefulWidget {
  final List<Exercise> exercises;
  final ValueChanged<Exercise> onExerciseSelected;
  final VoidCallback onCustomRequested;
  final VoidCallback onCancel;
  /// Category to pre-select on open (e.g. 'Cardio' for a cardio day).
  /// The user can still switch to another category or "All" afterward.
  final String? initialCategory;

  const ExerciseLibraryPicker({
    super.key,
    required this.exercises,
    required this.onExerciseSelected,
    required this.onCustomRequested,
    required this.onCancel,
    this.initialCategory,
  });

  @override
  State<ExerciseLibraryPicker> createState() => _ExerciseLibraryPickerState();
}

class _ExerciseLibraryPickerState extends State<ExerciseLibraryPicker> {
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.exercises.map((e) => e.category).toSet().toList()..sort();
    final filtered = widget.exercises.where((e) {
      final matchesSearch = _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(_searchQuery.toLowerCase());
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
                onTap: widget.onCancel,
                child: Text(
                  'Cancel',
                  style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
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
          SizedBox(
            height: 32.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                ...categories.map((c) => _FilterChip(
                      label: c,
                      isSelected: _selectedCategory == c,
                      onTap: () => setState(
                        () => _selectedCategory = _selectedCategory == c ? null : c,
                      ),
                    )),
              ],
            ),
          ),
          SizedBox(height: 8.h),
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
                        onTap: () => widget.onExerciseSelected(ex),
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
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: context.foreground,
                                      ),
                                    ),
                                    Text(
                                      '${ex.muscle} • ${ex.equipment}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: context.mutedForeground,
                                      ),
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
            onPressed: widget.onCustomRequested,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : context.mutedForeground,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
