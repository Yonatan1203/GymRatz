import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../shared/models/coach_invite.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/staggered_list.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

class InviteManagementScreen extends ConsumerStatefulWidget {
  const InviteManagementScreen({super.key});

  @override
  ConsumerState<InviteManagementScreen> createState() =>
      _InviteManagementScreenState();
}

class _InviteManagementScreenState
    extends ConsumerState<InviteManagementScreen> {
  bool _isCreating = false;

  Future<void> _generateInvite() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    setState(() => _isCreating = true);
    try {
      final invite =
          await ref.read(coachServiceProvider).createInvite(uid);
      if (mounted) {
        _showCodeDialog(invite.code);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _showCodeDialog(String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite Code Generated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share this code with your client:',
              style: AppTextStyles.bodySmall,
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: Theme.of(ctx).brightness == Brightness.dark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: SelectableText(
                code,
                style: AppTextStyles.h2.copyWith(
                  letterSpacing: 4,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Expires in 7 days',
              style: AppTextStyles.caption.copyWith(
                color: Theme.of(ctx).brightness == Brightness.dark
                    ? Colors.white54
                    : Colors.black45,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _revokeInvite(CoachInvite invite) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Invite'),
        content: Text('Revoke invite code ${invite.code}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    await ref.read(coachServiceProvider).revokeInvite(uid, invite);
  }

  @override
  Widget build(BuildContext context) {
    final invitesAsync = ref.watch(coachInvitesProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              showBackButton: true,
              child: Text(
                'Invites',
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
                  CustomButton(
                    text: 'Generate Invite Code',
                    icon: AppIcons.plus,
                    isLoading: _isCreating,
                    onPressed: _generateInvite,
                  ),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildInviteList(context, invitesAsync),
                  SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteList(
      BuildContext context, AsyncValue<List<CoachInvite>> invitesAsync) {
    return invitesAsync.when(
      loading: () => Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
        child: Center(
          child: SizedBox(
            width: 24.r,
            height: 24.r,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: context.primaryColor),
          ),
        ),
      ),
      error: (e, _) => Center(
        child: Text('Failed to load invites',
            style: AppTextStyles.bodySmall
                .copyWith(color: context.mutedForeground)),
      ),
      data: (invites) {
        if (invites.isEmpty) {
          return EmptyStateWidget(
            icon: AppIcons.mail,
            title: 'No invites yet',
            subtitle:
                'Generate an invite code to share with clients you want to coach.',
          );
        }

        final pending =
            invites.where((i) => i.isPending && !i.isExpired).toList();
        final accepted =
            invites.where((i) => i.status == 'accepted').toList();
        final expired = invites
            .where((i) => i.isExpired || i.status == 'expired')
            .where((i) => i.status != 'accepted')
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pending.isNotEmpty) ...[
              _sectionLabel(context, 'PENDING'),
              ...pending.map((i) => _buildInviteCard(context, i)),
              SizedBox(height: AppSpacing.lg),
            ],
            if (accepted.isNotEmpty) ...[
              _sectionLabel(context, 'ACCEPTED'),
              ...accepted.map((i) => _buildInviteCard(context, i)),
              SizedBox(height: AppSpacing.lg),
            ],
            if (expired.isNotEmpty) ...[
              _sectionLabel(context, 'EXPIRED'),
              ...expired.map((i) => _buildInviteCard(context, i)),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: context.mutedForeground,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildInviteCard(BuildContext context, CoachInvite invite) {
    final isPending = invite.isPending && !invite.isExpired;
    final isAccepted = invite.status == 'accepted';

    Color statusColor;
    String statusLabel;
    if (isAccepted) {
      statusColor = const Color(0xFF34C759);
      statusLabel = 'Accepted';
    } else if (isPending) {
      statusColor = context.primaryColor;
      statusLabel = 'Pending';
    } else {
      statusColor = context.mutedForeground;
      statusLabel = 'Expired';
    }

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: CustomCard(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(AppIcons.mail, size: 18.r, color: statusColor),
              ),
            ),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invite.code,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    invite.clientEmail ?? 'Code invite',
                    style: AppTextStyles.caption
                        .copyWith(color: context.mutedForeground),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Created ${DateFormat.yMMMd().format(invite.createdAt)}',
                    style: AppTextStyles.caption
                        .copyWith(color: context.mutedForeground),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                statusLabel,
                style: AppTextStyles.caption.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isPending) ...[
              SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: () => _revokeInvite(invite),
                child: Icon(AppIcons.x,
                    size: 18.r, color: context.destructiveColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
