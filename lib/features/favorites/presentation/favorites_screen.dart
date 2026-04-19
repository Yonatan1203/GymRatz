import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_icons.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/section_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../shared/data/sample_data.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoriteExerciseIdsProvider).valueOrNull ?? {};
    final allExercises = ref.watch(exerciseLibraryProvider);
    final favExercises = favoriteIds.isNotEmpty
        ? allExercises.where((e) => favoriteIds.contains(e.id)).toList()
        : SampleData.exercises.where((e) => e.isFavorite).toList();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              showBackButton: true,
              child: Text('Favorites', style: AppTextStyles.h1.copyWith(color: Colors.white)),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                children: [
                  const SectionHeader(title: 'Favorite Programs'),
                  SizedBox(height: AppSpacing.lg),
                  _emptyState(context, 'No favorite programs yet'),
                  SizedBox(height: AppSpacing.sectionGap),
                  const SectionHeader(title: 'Favorite Workouts'),
                  SizedBox(height: AppSpacing.lg),
                  _emptyState(context, 'No favorite workouts yet'),
                  SizedBox(height: AppSpacing.sectionGap),
                  const SectionHeader(title: 'Favorite Exercises'),
                  SizedBox(height: AppSpacing.lg),
                  if (favExercises.isEmpty)
                    _emptyState(context, 'No favorite exercises yet')
                  else
                    ...favExercises.map((e) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: CustomCard(
                        padding: EdgeInsets.all(12.r),
                        child: Row(
                          children: [
                            Icon(AppIcons.dumbbell, size: 20.r, color: context.primaryColor),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.name, style: AppTextStyles.bodySmall.copyWith(color: context.foreground, fontWeight: FontWeight.w500)),
                                  Text('${e.muscle} \u2022 ${e.equipment}', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                                ],
                              ),
                            ),
                            Icon(AppIcons.heart, size: 20.r, color: Colors.red),
                          ],
                        ),
                      ),
                    )),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32.r),
      child: Column(
        children: [
          Icon(AppIcons.heart, size: 48.r, color: context.mutedForeground.withOpacity(0.6)),
          SizedBox(height: 12.h),
          Text(message, style: AppTextStyles.body.copyWith(color: context.mutedForeground)),
        ],
      ),
    );
  }
}
