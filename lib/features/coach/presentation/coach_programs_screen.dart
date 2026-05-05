import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/scale_tap.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/staggered_list.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

class CoachProgramsScreen extends ConsumerWidget {
  const CoachProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(coachProgramsProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: StaggeredList(
                children: [
                  _buildCreateCard(context),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildTemplateList(context, ref, programsAsync),
                  SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return GradientHeader(
      child: Text(
        'Programs',
        style: AppTextStyles.h2.copyWith(
          color: context.foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCreateCard(BuildContext context) {
    return ScaleTap(
      onTap: () => _showCreateDialog(context),
      child: CustomCard(
        variant: CardVariant.actionCta,
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            SizedBox(
              width: 48.r,
              height: 48.r,
              child: Center(
                child:
                    Icon(AppIcons.plus, size: 24.r, color: context.coralColor),
              ),
            ),
            SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Template',
                    style: AppTextStyles.h3.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Build a program to assign to clients',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: context.mutedForeground),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.chevronRight,
                size: 20.r, color: context.mutedForeground),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateList(BuildContext context, WidgetRef ref,
      AsyncValue<List<Map<String, dynamic>>> programsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'My Templates'),
        SizedBox(height: AppSpacing.lg),
        programsAsync.when(
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
            child: Text('Failed to load templates',
                style: AppTextStyles.bodySmall
                    .copyWith(color: context.mutedForeground)),
          ),
          data: (programs) {
            if (programs.isEmpty) {
              return EmptyStateWidget(
                icon: AppIcons.layers,
                title: 'No templates yet',
                subtitle:
                    'Create program templates that you can assign to your clients.',
              );
            }
            return Column(
              children: programs
                  .map((p) => Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.itemGap),
                        child: _buildTemplateCard(context, ref, p),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTemplateCard(
      BuildContext context, WidgetRef ref, Map<String, dynamic> programJson) {
    final name = programJson['name'] as String? ?? 'Untitled';
    final workouts = programJson['workouts'] as int? ?? 0;
    final weeks = programJson['weeks'] as int? ?? 0;
    final difficulty = programJson['difficulty'] as String?;
    final programId = programJson['id'] as String;

    return CustomCard(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(AppIcons.dumbbell,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  '${workouts}x/week \u2022 $weeks weeks${difficulty != null ? ' \u2022 $difficulty' : ''}',
                  style: AppTextStyles.caption
                      .copyWith(color: context.mutedForeground),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          // Assign to client
          GestureDetector(
            onTap: () => _showAssignClientPicker(context, ref, programJson),
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                'Assign',
                style: AppTextStyles.caption.copyWith(
                  color: context.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          // Delete
          GestureDetector(
            onTap: () => _confirmDelete(context, ref, programId, name),
            child: Icon(AppIcons.trash2,
                size: 18.r, color: context.destructiveColor),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    GoRouter.of(context).push('/coach/programs/create');
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String programId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final uid = ref.read(currentUidProvider);
              if (uid == null) return;
              await ref
                  .read(coachRepositoryProvider)
                  .deleteCoachProgram(uid, programId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAssignClientPicker(
      BuildContext context, WidgetRef ref, Map<String, dynamic> programJson) {
    final clients = ref.read(coachClientsProvider).valueOrNull ?? [];
    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No clients to assign to')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign to Client'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: clients.length,
            itemBuilder: (_, index) {
              final client = clients[index];
              return ListTile(
                title: Text(client.clientName),
                subtitle: Text(client.clientEmail),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.go(
                      '/coach/clients/${client.clientUid}/assign');
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

