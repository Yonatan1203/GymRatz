import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../shared/utils/extensions.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../shared/widgets/custom_input.dart';
import '../../../../shared/widgets/select_field.dart';

/// Inline form for creating a custom exercise.
///
/// Manages its own name controller and category/equipment selection.
/// Calls [onSubmit] with the entered values; the parent handles persistence.
class CustomExerciseFormCard extends StatefulWidget {
  final void Function(String name, String category, String equipment) onSubmit;
  final VoidCallback onCancel;

  const CustomExerciseFormCard({
    super.key,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<CustomExerciseFormCard> createState() => _CustomExerciseFormCardState();
}

class _CustomExerciseFormCardState extends State<CustomExerciseFormCard> {
  final _nameController = TextEditingController();
  String _category = 'Chest';
  String _equipment = 'Dumbbell';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                onTap: widget.onCancel,
                child: Text(
                  'Cancel',
                  style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          CustomInput(
            controller: _nameController,
            label: 'Exercise Name',
            hint: 'e.g., Dumbbell Press',
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: SelectField(
                  label: 'Category',
                  value: _category,
                  options: const ['Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core'],
                  onChanged: (v) => setState(() => _category = v),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: SelectField(
                  label: 'Equipment',
                  value: _equipment,
                  options: const ['Dumbbell', 'Barbell', 'Machine', 'Body Weight'],
                  onChanged: (v) => setState(() => _equipment = v),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          CustomButton(
            text: 'Add Custom Exercise',
            variant: ButtonVariant.primary,
            onPressed: () => widget.onSubmit(
              _nameController.text.trim(),
              _category,
              _equipment,
            ),
          ),
        ],
      ),
    );
  }
}
