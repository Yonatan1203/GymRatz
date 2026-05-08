import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/providers.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/staggered_list.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

class CoachApplicationScreen extends ConsumerStatefulWidget {
  const CoachApplicationScreen({super.key});

  @override
  ConsumerState<CoachApplicationScreen> createState() =>
      _CoachApplicationScreenState();
}

class _CoachApplicationScreenState
    extends ConsumerState<CoachApplicationScreen> {
  final _nameController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _existingStatus;
  bool _loaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingApplication() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('coach_applications')
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _existingStatus = doc.data()!['status'] as String? ?? 'pending';
        });
      }
    } catch (_) {}
    setState(() => _loaded = true);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingApplication();
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final reason = _reasonController.text.trim();
    if (name.isEmpty || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final uid = ref.read(currentUidProvider);
    final userProfile = ref.read(userProfileProvider).valueOrNull;
    if (uid == null || userProfile == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(coachServiceProvider).submitApplication(
            uid: uid,
            email: userProfile.email,
            displayName: name,
            reason: reason,
          );
      setState(() => _existingStatus = 'pending');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              showBackButton: true,
              child: Text(
                'Apply to Coach',
                style: AppTextStyles.h2.copyWith(
                  color: context.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: _existingStatus != null
                  ? _buildStatusView(context)
                  : _buildForm(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusView(BuildContext context) {
    IconData icon;
    Color color;
    String title;
    String subtitle;

    switch (_existingStatus) {
      case 'approved':
        icon = AppIcons.checkCircle;
        color = const Color(0xFF34C759);
        title = 'Application Approved!';
        subtitle =
            'Your coach application has been approved. Sign out and sign back in to access your coach dashboard.';
        break;
      case 'rejected':
        icon = AppIcons.minusCircle;
        color = context.destructiveColor;
        title = 'Application Rejected';
        subtitle =
            'Unfortunately your application was not approved. You can contact support for more information.';
        break;
      default:
        icon = AppIcons.clock;
        color = context.primaryColor;
        title = 'Application Pending';
        subtitle =
            'Your application is being reviewed. You\'ll be notified when a decision is made.';
    }

    return StaggeredList(
      children: [
        SizedBox(height: AppSpacing.xxxl),
        Center(
          child: Container(
            width: 80.r,
            height: 80.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, size: 40.r, color: color),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        Center(
          child: Text(
            title,
            style: AppTextStyles.h3.copyWith(
              color: context.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              subtitle,
              style: AppTextStyles.bodySmall
                  .copyWith(color: context.mutedForeground),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return StaggeredList(
      children: [
        CustomCard(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(AppIcons.info,
                      size: 20.r, color: context.primaryColor),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Tell us why you want to become a coach on GymRatz.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: context.mutedForeground),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.sectionGap),
        Text(
          'Display Name',
          style: AppTextStyles.bodySmall.copyWith(
            color: context.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Your coaching name',
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
        SizedBox(height: AppSpacing.lg),
        Text(
          'Why do you want to coach?',
          style: AppTextStyles.bodySmall.copyWith(
            color: context.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _reasonController,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText:
                'Describe your experience and what you\'d bring to your clients...',
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
        SizedBox(height: AppSpacing.xxl),
        CustomButton(
          text: 'Submit Application',
          icon: AppIcons.check,
          isLoading: _isSubmitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}
