import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

class CoachApprovalScreen extends ConsumerWidget {
  const CoachApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(pendingApplicationsProvider);

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            showBackButton: true,
            child: Text(
              'Coach Approvals',
              style: AppTextStyles.h2.copyWith(
                color: context.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: applicationsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Failed to load applications',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: context.mutedForeground)),
              ),
              data: (applications) {
                if (applications.isEmpty) {
                  return EmptyStateWidget(
                    icon: AppIcons.checkCircle,
                    title: 'No pending applications',
                    subtitle:
                        'All coach applications have been reviewed. Check back later.',
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.all(AppSpacing.screenPadding),
                  itemCount: applications.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) =>
                      _buildApplicationCard(context, ref, applications[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(
      BuildContext context, WidgetRef ref, Map<String, dynamic> app) {
    final name = app['displayName'] as String? ?? 'Unknown';
    final email = app['email'] as String? ?? '';
    final reason = app['reason'] as String? ?? '';
    final uid = app['uid'] as String? ?? '';
    final createdAt = app['createdAt'] != null
        ? DateTime.tryParse(app['createdAt'] as String)
        : null;

    return CustomCard(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(AppIcons.user,
                      size: 20.r, color: context.primaryColor),
                ),
              ),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      email,
                      style: AppTextStyles.caption
                          .copyWith(color: context.mutedForeground),
                    ),
                    if (createdAt != null)
                      Text(
                        'Applied ${DateFormat.yMMMd().format(createdAt)}',
                        style: AppTextStyles.caption
                            .copyWith(color: context.mutedForeground),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (reason.isNotEmpty) ...[
            SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.mutedColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                reason,
                style: AppTextStyles.bodySmall
                    .copyWith(color: context.foreground),
              ),
            ),
          ],
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleReject(context, ref, uid, name),
                  icon: Icon(AppIcons.x, size: 16.r),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.destructiveColor,
                    side: BorderSide(color: context.destructiveColor),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleApprove(context, ref, uid, name),
                  icon: Icon(AppIcons.check, size: 16.r),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34C759),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleApprove(
      BuildContext context, WidgetRef ref, String uid, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Coach'),
        content: Text(
            'Approve $name as a coach? Their role will be changed to "coach".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(coachServiceProvider)
                    .approveApplication(uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$name approved as coach')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _handleReject(
      BuildContext context, WidgetRef ref, String uid, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Application'),
        content: Text('Reject $name\'s coach application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(coachServiceProvider)
                    .rejectApplication(uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$name\'s application rejected')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
