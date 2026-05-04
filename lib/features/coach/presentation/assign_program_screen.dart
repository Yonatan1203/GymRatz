import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

class AssignProgramScreen extends ConsumerWidget {
  final String clientUid;
  const AssignProgramScreen({super.key, required this.clientUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestore = ref.watch(firestoreProvider)!;
    final uid = ref.watch(currentUidProvider);

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            showBackButton: true,
            child: Text(
              'Assign Program',
              style: AppTextStyles.h2.copyWith(
                color: context.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: uid == null
                ? const Center(child: Text('Not signed in'))
                : StreamBuilder<QuerySnapshot>(
                    stream: firestore
                        .collection('coaches')
                        .doc(uid)
                        .collection('programs')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return EmptyStateWidget(
                          icon: AppIcons.layers,
                          title: 'No program templates yet',
                          subtitle:
                              'Create templates in the Programs tab.',
                        );
                      }

                      return ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                          vertical: AppSpacing.lg,
                        ),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data()! as Map<String, dynamic>;
                          return _ProgramTemplateCard(
                            data: data,
                            onTap: () => _showConfirmDialog(
                              context,
                              ref,
                              uid: uid,
                              programData: data,
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmDialog(
    BuildContext context,
    WidgetRef ref, {
    required String uid,
    required Map<String, dynamic> programData,
  }) async {
    final programName = programData['name'] as String? ?? 'this program';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Program'),
        content: Text('Assign $programName to this client?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Assign'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(coachServiceProvider).assignProgram(
            coachUid: uid,
            clientUid: clientUid,
            programJson: programData,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Program assigned!')),
        );
        context.pop();
      }
    }
  }
}

class _ProgramTemplateCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _ProgramTemplateCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'Untitled Program';
    final description = data['description'] as String?;
    final days = data['days'];
    final dayCount = days is List ? days.length : 0;

    return GestureDetector(
      onTap: onTap,
      child: CustomCard(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Center(
                child: Icon(
                  AppIcons.layers,
                  size: 20.r,
                  color: context.primaryColor,
                ),
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
                  SizedBox(height: 2.h),
                  Text(
                    '$dayCount ${dayCount == 1 ? 'day' : 'days'}',
                    style: AppTextStyles.caption
                        .copyWith(color: context.mutedForeground),
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      description,
                      style: AppTextStyles.caption
                          .copyWith(color: context.mutedForeground),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(AppIcons.chevronRight,
                size: 18.r, color: context.mutedForeground),
          ],
        ),
      ),
    );
  }
}
