import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';

import '../../../theme/app_gradients.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_input.dart';
import '../../../shared/widgets/custom_toggle.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/scale_tap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../shared/data/sample_data.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _weightController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  bool _initialized = false;
  bool _notifications = true;
  bool _isSaving = false;

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _weightFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _weightFocus.dispose();
    super.dispose();
  }

  void _initControllers() {
    if (_initialized) return;
    _initialized = true;
    final user = ref.read(userProfileProvider).valueOrNull ?? SampleData.user;
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
    _weightController = TextEditingController(text: '${user.weight}');
    _ageController = TextEditingController(text: '${user.age}');
    _heightController = TextEditingController(text: _formatHeightForUnit(user.height, user.unit));
    _notifications = user.notificationsEnabled;
  }

  /// Display height in the correct unit format
  String _formatHeightForUnit(String stored, String unit) {
    if (unit == 'kg') {
      // Metric: should display as cm. If stored in imperial format, convert.
      final cm = _parseToCm(stored);
      if (cm != null) return '${cm.round()} cm';
    }
    // Imperial: keep as-is (e.g., "5'10\"")
    return stored;
  }

  /// Parse height string to cm (handles both "170 cm" and "5'10\"" formats)
  double? _parseToCm(String h) {
    final trimmed = h.trim().toLowerCase();
    // Already cm format
    final cmMatch = RegExp(r'^(\d+\.?\d*)\s*cm$').firstMatch(trimmed);
    if (cmMatch != null) return double.tryParse(cmMatch.group(1)!);
    // Imperial format: X'Y" or X' Y"
    final impMatch = RegExp(r"(\d+)['\s]+(\d+)?").firstMatch(trimmed);
    if (impMatch != null) {
      final feet = int.tryParse(impMatch.group(1)!) ?? 0;
      final inches = int.tryParse(impMatch.group(2) ?? '0') ?? 0;
      return (feet * 12 + inches) * 2.54;
    }
    return null;
  }

  String? _validate() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return 'Name cannot be empty';
    final email = _emailController.text.trim();
    if (!email.contains('@')) return 'Please enter a valid email';
    final age = int.tryParse(_ageController.text);
    if (age == null || age < 13 || age > 120) return 'Please enter a valid age (13-120)';
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) return 'Please enter a valid weight';
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    setState(() => _isSaving = true);
    try {
      final name = _nameController.text.trim();
      final fields = <String, dynamic>{
        'name': name,
        'initials': name
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase(),
        'email': _emailController.text.trim(),
        'age': int.tryParse(_ageController.text) ?? 25,
        'height': _heightController.text.trim(),
        'weight': double.tryParse(_weightController.text) ?? 0,
        'notificationsEnabled': _notifications,
      };
      await ref.read(userRepositoryProvider).updateUser(uid, fields);
      if (mounted) Navigator.of(context).pop();
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

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: context.destructiveColor)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await ref.read(authServiceProvider).deleteAccount();
        if (mounted) context.go('/onboarding');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete account: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _initControllers();
    final user = ref.watch(userProfileProvider).valueOrNull ?? SampleData.user;
    final isDark = context.isDark;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
            GradientHeader(
              showBackButton: true,
              child: Text('Edit Profile', style: AppTextStyles.h1.copyWith(color: context.foreground)),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 96.r,
                          height: 96.r,
                          decoration: BoxDecoration(
                            gradient: AppGradients.primary(isDark: isDark),
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.lg,
                          ),
                          child: Center(
                            child: Text(user.initials, style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 32.r,
                            height: 32.r,
                            decoration: BoxDecoration(
                              color: context.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: context.cardColor, width: 2),
                            ),
                            child: Icon(AppIcons.camera, size: 16.r, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxxl),
                  _sectionTitle('Personal Information'),
                  SizedBox(height: AppSpacing.lg),
                  CustomInput(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'Your name',
                    focusNode: _nameFocus,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  CustomInput(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'email@example.com',
                    keyboardType: TextInputType.emailAddress,
                    focusNode: _emailFocus,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _weightFocus.requestFocus(),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(child: CustomInput(controller: _ageController, label: 'Age', keyboardType: TextInputType.number)),
                      SizedBox(width: AppSpacing.lg),
                      Expanded(child: CustomInput(
                        controller: _heightController,
                        label: "Height (${user.unit == 'kg' ? 'cm' : "ft'in"})",
                        keyboardType: TextInputType.text,
                      )),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xxxl),
                  _sectionTitle('Fitness Profile'),
                  SizedBox(height: AppSpacing.lg),
                  CustomInput(
                    controller: _weightController,
                    label: 'Current Weight (${user.unit})',
                    keyboardType: TextInputType.number,
                    focusNode: _weightFocus,
                    textInputAction: TextInputAction.done,
                  ),
                  SizedBox(height: AppSpacing.xl),
                  CustomInput(label: 'Experience Level', initialValue: user.experienceLevel),
                  SizedBox(height: AppSpacing.xl),
                  CustomInput(label: 'Primary Goal', initialValue: user.primaryGoal),
                  SizedBox(height: AppSpacing.xxxl),
                  _sectionTitle('Preferences'),
                  SizedBox(height: AppSpacing.lg),
                  _prefRow('Notifications', _notifications, (v) => setState(() => _notifications = v)),
                  SizedBox(height: AppSpacing.xxxl),
                  CustomButton(
                    text: 'Save Changes',
                    variant: ButtonVariant.gradient,
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _save,
                  ),
                  SizedBox(height: AppSpacing.sectionGap),
                  Center(
                    child: ScaleTap(
                      onTap: _deleteAccount,
                      child: Text(
                        'Delete Account',
                        style: AppTextStyles.bodySmall.copyWith(color: context.destructiveColor),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.h3.copyWith(color: context.foreground, fontWeight: FontWeight.w600),
    );
  }

  Widget _prefRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xl),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body.copyWith(color: context.foreground))),
          CustomToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
