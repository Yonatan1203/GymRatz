import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  bool _initialized = false;
  bool _notifications = true;
  bool _restDayReminders = false;
  bool _darkMode = true;

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _weightFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _weightController.dispose();
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
  }

  @override
  Widget build(BuildContext context) {
    _initControllers();
    final user = ref.watch(userProfileProvider).valueOrNull ?? SampleData.user;
    final isDark = context.isDark;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              showBackButton: true,
              child: Text('Edit Profile', style: AppTextStyles.h1.copyWith(color: Colors.white)),
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
                            child: Text('YG', style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.w700, color: Colors.white)),
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
                  SizedBox(height: 32.h),
                  _sectionTitle('Personal Information'),
                  SizedBox(height: 12.h),
                  CustomInput(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'Your name',
                    focusNode: _nameFocus,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                  ),
                  SizedBox(height: 16.h),
                  CustomInput(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'email@example.com',
                    keyboardType: TextInputType.emailAddress,
                    focusNode: _emailFocus,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _weightFocus.requestFocus(),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(child: CustomInput(label: 'Age', initialValue: '${user.age}', keyboardType: TextInputType.number)),
                      SizedBox(width: 12.w),
                      Expanded(child: CustomInput(label: 'Height', initialValue: user.height)),
                    ],
                  ),
                  SizedBox(height: 32.h),
                  _sectionTitle('Fitness Profile'),
                  SizedBox(height: 12.h),
                  CustomInput(
                    controller: _weightController,
                    label: 'Current Weight (lbs)',
                    keyboardType: TextInputType.number,
                    focusNode: _weightFocus,
                    textInputAction: TextInputAction.done,
                  ),
                  SizedBox(height: 16.h),
                  CustomInput(label: 'Experience Level', initialValue: SampleData.user.experienceLevel),
                  SizedBox(height: 16.h),
                  CustomInput(label: 'Primary Goal', initialValue: SampleData.user.primaryGoal),
                  SizedBox(height: 32.h),
                  _sectionTitle('Preferences'),
                  SizedBox(height: 12.h),
                  _prefRow('Notifications', _notifications, (v) => setState(() => _notifications = v)),
                  _prefRow('Rest Day Reminders', _restDayReminders, (v) => setState(() => _restDayReminders = v)),
                  _prefRow('Dark Mode', _darkMode, (v) => setState(() => _darkMode = v)),
                  SizedBox(height: 32.h),
                  CustomButton(
                    text: 'Save Changes',
                    variant: ButtonVariant.gradient,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(height: 24.h),
                  Center(
                    child: GestureDetector(
                      onTap: () {}, // TODO: delete account
                      child: Text(
                        'Delete Account',
                        style: AppTextStyles.bodySmall.copyWith(color: context.destructiveColor),
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ],
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
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body.copyWith(color: context.foreground))),
          CustomToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
