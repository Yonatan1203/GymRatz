import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';
import '../../../shared/widgets/empty_state_widget.dart';

import '../../../theme/app_gradients.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_badge.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/gym_ratz_background.dart';
import '../../../shared/widgets/progress_bar_widget.dart';
import '../../../shared/widgets/section_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../shared/data/sample_data.dart';
import '../../../shared/models/program.dart';

class ProgramsScreen extends ConsumerWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;

    return Scaffold(
      body: GymRatzBackground(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context, isDark),
              Padding(
                padding: EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  children: [
                    _buildCreateCard(context, isDark),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildMyPrograms(context, ref),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildExplorePrograms(context),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppGradients.primary(isDark: isDark),
        boxShadow: AppShadows.lg,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenPadding, 12.h, AppSpacing.screenPadding, AppSpacing.xxl,
          ),
          child: Text('Programs', style: AppTextStyles.h1.copyWith(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildCreateCard(BuildContext context, bool isDark) {
    return Semantics(
      button: true,
      label: 'Create program',
      child: GestureDetector(
        onTap: () => context.push('/programs/create'),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            gradient: AppGradients.primary(isDark: isDark),
            borderRadius: AppRadius.borderXl,
            boxShadow: AppShadows.lg,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 48.r,
                height: 48.r,
                child: Center(child: Icon(AppIcons.plus, size: 24.r, color: Colors.white)),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Program',
                      style: AppTextStyles.h3.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Build your custom workout plan',
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Icon(AppIcons.chevronRight, size: 20.r, color: Colors.white70),
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
            return Column(
              children: programs
                  .map((p) => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: _buildProgramCard(context, p),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProgramCard(BuildContext context, Program p) {
    return CustomCard(
      onTap: () => context.push('/programs/detail/${p.id}'),
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
                  padding: EdgeInsets.only(right: 8.w),
                  child: CustomBadge(
                    text: 'Active',
                    backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                    textColor: const Color(0xFF10B981),
                  ),
                ),
              Icon(AppIcons.chevronRight, size: 20.r, color: context.mutedForeground),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Text(
                '${p.workouts} workouts/week \u2022 ${p.weeks} weeks',
                style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
              ),
              if (p.difficulty != null) ...[
                SizedBox(width: 8.w),
                CustomBadge(text: p.difficulty!),
              ],
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(child: ProgressBarWidget(progress: p.progress / 100)),
              SizedBox(width: 12.w),
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
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32.h),
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
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Column(
          children: [
            Icon(AppIcons.info, size: 32.r, color: context.destructiveColor),
            SizedBox(height: 8.h),
            Text(
              'Failed to load programs',
              style: AppTextStyles.bodySmall.copyWith(color: context.foreground),
            ),
            SizedBox(height: 12.h),
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
              padding: EdgeInsets.only(bottom: 12.h),
              child: CustomCard(
                onTap: () => context.push('/programs/detail/${p.id}'),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48.r,
                      height: 48.r,
                      child: Center(child: Icon(AppIcons.dumbbell, size: 24.r, color: context.primaryColor)),
                    ),
                    SizedBox(width: 16.w),
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
                          SizedBox(height: 2.h),
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
            )),
      ],
    );
  }
}
