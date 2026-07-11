import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/models/enums.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../shared/utils/extensions.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../shared/widgets/custom_input.dart';
import '../../../../shared/widgets/select_field.dart';

class ProgramInfoCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController weeksController;
  final TextEditingController descriptionController;
  final FocusNode nameFocus;
  final FocusNode weeksFocus;
  final bool isOngoing;
  final ValueChanged<bool> onOngoingChanged;
  final String difficulty;
  final ValueChanged<String> onDifficultyChanged;
  final bool forCoach;
  final WeightAutofillMode weightAutofillMode;
  final ValueChanged<bool> onWeightAutofillChanged;

  const ProgramInfoCard({
    super.key,
    required this.nameController,
    required this.weeksController,
    required this.descriptionController,
    required this.nameFocus,
    required this.weeksFocus,
    required this.isOngoing,
    required this.onOngoingChanged,
    required this.difficulty,
    required this.onDifficultyChanged,
    required this.forCoach,
    required this.weightAutofillMode,
    required this.onWeightAutofillChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomInput(
            controller: nameController,
            label: 'Program Name',
            hint: 'e.g., Push Pull Legs',
            focusNode: nameFocus,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => weeksFocus.requestFocus(),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              if (!isOngoing) ...[
                Expanded(
                  child: CustomInput(
                    controller: weeksController,
                    label: 'Duration (weeks)',
                    keyboardType: TextInputType.number,
                    focusNode: weeksFocus,
                    textInputAction: TextInputAction.done,
                  ),
                ),
                SizedBox(width: 12.w),
              ],
              Expanded(
                child: SelectField(
                  label: 'Difficulty',
                  value: difficulty,
                  options: const ['Beginner', 'Intermediate', 'Advanced'],
                  onChanged: onDifficultyChanged,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Ongoing — no end date',
              style: AppTextStyles.bodySmall.copyWith(color: context.foreground),
            ),
            subtitle: Text(
              'Program continues indefinitely instead of a fixed week count',
              style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
            ),
            value: isOngoing,
            activeColor: context.primaryColor,
            onChanged: onOngoingChanged,
          ),
          SizedBox(height: 12.h),
          CustomInput(
            controller: descriptionController,
            label: 'Description (optional)',
            hint: 'Brief description of this program',
            maxLines: 2,
          ),
          if (forCoach) ...[
            SizedBox(height: 12.h),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Auto-suggest weights',
                style: AppTextStyles.bodySmall.copyWith(color: context.foreground),
              ),
              subtitle: Text(
                weightAutofillMode == WeightAutofillMode.systemSuggested
                    ? 'PO engine pre-fills weights for athletes'
                    : 'Athletes enter weights manually from scratch',
                style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
              ),
              value: weightAutofillMode == WeightAutofillMode.systemSuggested,
              activeColor: context.primaryColor,
              onChanged: onWeightAutofillChanged,
            ),
          ],
        ],
      ),
    );
  }
}
