import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/app_gradients.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_badge.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/progress_bar_widget.dart';
import '../../../shared/widgets/section_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../shared/data/sample_data.dart';

class ProgramsScreen extends ConsumerWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                children: [
                  _buildCreateCard(context, isDark),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildMyPrograms(context, ref),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildExplorePrograms(context),
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
        boxShadow: AppShadows.md,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.screenPadding, 12.h, AppSpacing.screenPadding, AppSpacing.xxl),
          child: Text('Programs', style: AppTextStyles.h1.copyWith(color: context.foreground)),
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
            Container(
              width: 48.r,
              height: 48.r,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: AppRadius.borderLg,
              ),
              child: Icon(LucideIcons.plus, size: 24.r, color: Colors.white),
            ),
            SizedBox(width: 16.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create Program', style: AppTextStyles.h3.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                Text('Build your custom plan', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildMyPrograms(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(userProgramsProvider);
    final programs = programsAsync.valueOrNull ?? SampleData.myPrograms;
    return Column(
      children: [
        const SectionHeader(title: 'My Programs'),
        SizedBox(height: AppSpacing.lg),
        ...programs.map((p) => Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: CustomCard(
            onTap: () => context.push('/programs/detail/${p.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: AppTextStyles.h4.copyWith(color: context.foreground, fontWeight: FontWeight.w600)),
                SizedBox(height: 4.h),
                Text('${p.workouts} workouts/week \u2022 ${p.weeks} weeks', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(child: ProgressBarWidget(progress: p.progress / 100)),
                    SizedBox(width: 12.w),
                    Text('${p.progress}%', style: AppTextStyles.bodySmall.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildExplorePrograms(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(title: 'Explore Programs'),
        SizedBox(height: AppSpacing.lg),
        ...SampleData.explorePrograms.map((p) => Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: CustomCard(
            onTap: () => context.push('/programs/detail/${p.id}'),
            child: Row(
              children: [
                Container(
                  width: 48.r,
                  height: 48.r,
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.2),
                    borderRadius: AppRadius.borderLg,
                  ),
                  child: Icon(LucideIcons.dumbbell, size: 24.r, color: context.primaryColor),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: AppTextStyles.h4.copyWith(color: context.foreground, fontWeight: FontWeight.w600)),
                      Text('${p.workouts}x/week \u2022 ${p.weeks} weeks', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
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
