import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';
import '../../../shared/widgets/empty_state_widget.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_badge.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/progress_bar_widget.dart';
import '../../../shared/widgets/scale_tap.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/staggered_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../shared/data/sample_data.dart';
import '../../../shared/models/program.dart';

class ProgramsScreen extends ConsumerWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  _buildMyPrograms(context, ref),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildExplorePrograms(context),
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
        style: AppTextStyles.h1.copyWith(color: context.foreground),
      ),
    );
  }

  Widget _buildCreateCard(BuildContext context) {
    return ScaleTap(
      onTap: () => context.push('/programs/create'),
      child: Semantics(
        button: true,
        label: 'Create program',
        child: CustomCard(
          variant: CardVariant.actionCta,
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              SizedBox(
                width: 48.r,
                height: 48.r,
                child: Center(child: Icon(AppIcons.plus, size: 24.r, color: context.coralColor)),
              ),
              SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Program',
                      style: AppTextStyles.h3.copyWith(color: context.foreground, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Build your custom workout plan',
                      style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
                    ),
                  ],
                ),
              ),
              Icon(AppIcons.chevronRight, size: 20.r, color: context.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyPrograms(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(userProgramsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'My Programs'),
        SizedBox(height: AppSpacing.lg),
        programsAsync.when(
          loading: () => _buildLoadingState(context),
          error: (e, _) => _buildErrorState(context, ref),
          data: (programs) {
            if (programs.isEmpty) {
              return _buildEmptyState(context);
            }
            // Sort: main program first
            final sorted = [...programs]..sort((a, b) {
              if (a.isActive && !b.isActive) return -1;
              if (!a.isActive && b.isActive) return 1;
              return 0;
            });
            return Column(
              children: sorted
                  .map((p) => Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.itemGap),
                        child: _buildProgramCard(context, ref, p),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProgramCard(BuildContext context, WidgetRef ref, Program p) {
    return ScaleTap(
      onTap: () => context.push('/programs/detail/${p.id}'),
      child: CustomCard(
        variant: CardVariant.program,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.name,
                    style: AppTextStyles.h4.copyWith(
                      color: context.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (p.isActive)
                  Padding(
                    padding: EdgeInsets.only(right: AppSpacing.md),
                    child: CustomBadge(
                      text: 'Main',
                      backgroundColor: context.coralColor.withOpacity(0.12),
                      textColor: context.coralColor,
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.only(right: AppSpacing.md),
                    child: GestureDetector(
                      onTap: () async {
                        final result = await showDialog<Map<String, dynamic>>(
                          context: context,
                          builder: (ctx) => _SetAsMainDialog(programName: p.name),
                        );
                        if (result == null) return;
                        final uid = ref.read(currentUidProvider);
                        if (uid == null) return;
                        final prefillWeights = result['prefillWeights'] as bool;
                        final repo = ref.read(programRepositoryProvider);
                        await repo.setActiveProgram(uid, p.id);
                        await repo.updateProgram(uid, p.id, {'prefillWeights': prefillWeights});
                      },
                      child: CustomBadge(
                        text: 'Set as Main',
                        backgroundColor: context.primaryColor.withOpacity(0.08),
                        textColor: context.primaryColor,
                      ),
                    ),
                  ),
                Icon(AppIcons.chevronRight, size: 20.r, color: context.mutedForeground),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  '${p.workouts} workouts/week \u2022 ${p.weeks} weeks',
                  style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
                ),
                if (p.difficulty != null) ...[
                  SizedBox(width: AppSpacing.md),
                  CustomBadge(text: p.difficulty!),
                ],
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(child: ProgressBarWidget(progress: p.progress / 100)),
                SizedBox(width: AppSpacing.lg),
                Text(
                  '${p.progress}%',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
      child: Center(
        child: SizedBox(
          width: 24.r,
          height: 24.r,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            Icon(AppIcons.info, size: 32.r, color: context.destructiveColor),
            SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load programs',
              style: AppTextStyles.bodySmall.copyWith(color: context.foreground),
            ),
            SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: () => ref.invalidate(userProgramsProvider),
              child: Text(
                'Tap to retry',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateWidget(
      icon: AppIcons.dumbbell,
      title: 'No programs yet',
      subtitle: 'Create your first training program to get started',
      actionLabel: 'Create Program',
      onAction: () => context.push('/programs/create'),
    );
  }

  Widget _buildExplorePrograms(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Explore Programs'),
        SizedBox(height: AppSpacing.lg),
        ...SampleData.explorePrograms.map((p) => Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.itemGap),
              child: ScaleTap(
                onTap: () => context.push('/programs/detail/${p.id}'),
                child: CustomCard(
                  variant: CardVariant.standard,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48.r,
                        height: 48.r,
                        child: Center(child: Icon(AppIcons.dumbbell, size: 24.r, color: context.primaryColor)),
                      ),
                      SizedBox(width: AppSpacing.xl),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: AppTextStyles.h4.copyWith(
                                color: context.foreground,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              '${p.workouts}x/week \u2022 ${p.weeks} weeks',
                              style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
                            ),
                          ],
                        ),
                      ),
                      if (p.difficulty != null) CustomBadge(text: p.difficulty!),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

class _SetAsMainDialog extends StatefulWidget {
  final String programName;
  const _SetAsMainDialog({required this.programName});

  @override
  State<_SetAsMainDialog> createState() => _SetAsMainDialogState();
}

class _SetAsMainDialogState extends State<_SetAsMainDialog> {
  bool _prefillWeights = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set as Main Program'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set "${widget.programName}" as your main program? This will update your calendar and workout schedule.',
          ),
          SizedBox(height: 16.h),
          Text(
            'Workout Weights',
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          RadioListTile<bool>(
            title: Text('Restore previous weights', style: AppTextStyles.bodySmall),
            subtitle: Text('Use weights from your last sessions', style: AppTextStyles.caption),
            value: true,
            groupValue: _prefillWeights,
            onChanged: (v) => setState(() => _prefillWeights = v!),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<bool>(
            title: Text('Start fresh', style: AppTextStyles.bodySmall),
            subtitle: Text('Begin with empty weights', style: AppTextStyles.caption),
            value: false,
            groupValue: _prefillWeights,
            onChanged: (v) => setState(() => _prefillWeights = v!),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop({
            'prefillWeights': _prefillWeights,
          }),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
