import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/staggered_list.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

class CoachEditProfileScreen extends ConsumerStatefulWidget {
  const CoachEditProfileScreen({super.key});

  @override
  ConsumerState<CoachEditProfileScreen> createState() =>
      _CoachEditProfileScreenState();
}

class _CoachEditProfileScreenState
    extends ConsumerState<CoachEditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _specializationsController = TextEditingController();
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _specializationsController.dispose();
    super.dispose();
  }

  void _initFromProfile() {
    final profile = ref.read(coachProfileProvider).valueOrNull;
    if (profile != null && !_initialized) {
      _nameController.text = profile.displayName;
      _bioController.text = profile.bio ?? '';
      _specializationsController.text = profile.specializations.join(', ');
      _initialized = true;
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    setState(() => _isSaving = true);
    try {
      final specs = _specializationsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await ref.read(coachRepositoryProvider).updateCoachProfile(uid, {
        'displayName': name,
        'bio': _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        'specializations': specs,
      });

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _initFromProfile();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              showBackButton: true,
              child: Text(
                'Edit Profile',
                style: AppTextStyles.h2.copyWith(
                  color: context.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: StaggeredList(
                children: [
                  _buildField(context, 'Display Name', _nameController,
                      'Your coaching name'),
                  SizedBox(height: AppSpacing.lg),
                  _buildField(context, 'Bio', _bioController,
                      'Tell clients about yourself...', maxLines: 4),
                  SizedBox(height: AppSpacing.lg),
                  _buildField(
                      context,
                      'Specializations',
                      _specializationsController,
                      'e.g. Strength, Hypertrophy, Nutrition'),
                  SizedBox(height: 8.h),
                  Text(
                    'Separate with commas',
                    style: AppTextStyles.caption
                        .copyWith(color: context.mutedForeground),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  CustomButton(
                    text: 'Save Changes',
                    icon: AppIcons.save,
                    isLoading: _isSaving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(BuildContext context, String label,
      TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: context.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          maxLines: maxLines,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodySmall
                .copyWith(color: context.mutedForeground),
            filled: true,
            fillColor: context.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: context.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: context.borderColor),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          ),
          style:
              AppTextStyles.bodySmall.copyWith(color: context.foreground),
        ),
      ],
    );
  }
}
