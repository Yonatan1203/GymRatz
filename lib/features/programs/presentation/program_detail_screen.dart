import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';

import '../../../app/providers.dart';
import '../../../shared/models/workout_day.dart';
import '../../../theme/app_gradients.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/gradient_header.dart';

class ProgramDetailScreen extends ConsumerStatefulWidget {
  final String programId;
  const ProgramDetailScreen({super.key, required this.programId});

  @override
  ConsumerState<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends ConsumerState<ProgramDetailScreen> {
  int _expandedWeek = 1;

  // Fallback hardcoded data when no Firestore program is found
  static const _fallbackProgram = {
    'name': 'Push Pull Legs',
    'description': 'A comprehensive 6-day training split focusing on push, pull, and leg movements',
    'weeks': 8,
    'workouts': 48,
    'difficulty': 'Intermediate',
    'progress': 65,
  };

  static const _fallbackWeeks = [
    {
      'week': 1,
      'workouts': [
        {'day': 'Monday', 'name': 'Push - Chest Focus', 'exercises': 6, 'duration': '60 min'},
        {'day': 'Tuesday', 'name': 'Pull - Back Width', 'exercises': 6, 'duration': '55 min'},
        {'day': 'Wednesday', 'name': 'Legs - Quad Focus', 'exercises': 7, 'duration': '70 min'},
        {'day': 'Thursday', 'name': 'Push - Shoulder Focus', 'exercises': 5, 'duration': '50 min'},
        {'day': 'Friday', 'name': 'Pull - Back Thickness', 'exercises': 6, 'duration': '55 min'},
        {'day': 'Saturday', 'name': 'Legs - Hamstring Focus', 'exercises': 6, 'duration': '65 min'},
      ],
    },
    {
      'week': 2,
      'workouts': [
        {'day': 'Monday', 'name': 'Push - Volume Day', 'exercises': 7, 'duration': '65 min'},
        {'day': 'Tuesday', 'name': 'Pull - Heavy Day', 'exercises': 5, 'duration': '60 min'},
        {'day': 'Wednesday', 'name': 'Legs - Power Day', 'exercises': 6, 'duration': '75 min'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final programAsync = ref.watch(programByIdProvider(widget.programId));
    final program = programAsync.valueOrNull;

    // Use Firestore program data if available, otherwise fall back to hardcoded
    final programName = program?.name ?? _fallbackProgram['name'] as String;
    final programDesc = program != null
        ? '${program.workouts} workouts/week \u2022 ${program.weeks} weeks'
        : _fallbackProgram['description'] as String;
    final programWeeks = program?.weeks ?? _fallbackProgram['weeks'] as int;
    final totalWorkouts = program?.workouts != null ? (program!.workouts * program.weeks) : _fallbackProgram['workouts'] as int;
    final programDifficulty = program?.difficulty ?? _fallbackProgram['difficulty'] as String;
    final progress = program?.progress ?? _fallbackProgram['progress'] as int;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              showBackButton: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(programName, style: AppTextStyles.h1.copyWith(color: Colors.white)),
                  SizedBox(height: 4.h),
                  Text(
                    programDesc,
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Icon(AppIcons.clock, size: 16.r, color: Colors.white70),
                      SizedBox(width: 4.w),
                      Text('$programWeeks weeks', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                      SizedBox(width: 16.w),
                      Icon(AppIcons.dumbbell, size: 16.r, color: Colors.white70),
                      SizedBox(width: 4.w),
                      Text('$totalWorkouts workouts', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                      SizedBox(width: 16.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: AppRadius.borderFull,
                        ),
                        child: Text(
                          programDifficulty,
                          style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: AppRadius.borderLg,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Overall Progress', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                            Text('$progress%', style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        ClipRRect(
                          borderRadius: AppRadius.borderFull,
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 8.h,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Continue',
                          variant: ButtonVariant.gradient,
                          icon: AppIcons.play,
                          onPressed: () => context.push('/workout/1'),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: CustomButton(
                          text: 'Restart',
                          variant: ButtonVariant.outline,
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sectionGap),
                  Text('Weekly Breakdown', style: AppTextStyles.h2.copyWith(color: context.foreground)),
                  SizedBox(height: AppSpacing.lg),
                  if (program != null && program.days.isNotEmpty)
                    // Show program days from Firestore as a single "week" view
                    _buildProgramDaysSection(context, isDark, program.days)
                  else
                    ..._fallbackWeeks.map((weekData) {
                      final weekNum = weekData['week'] as int;
                      final workouts = weekData['workouts'] as List<Map<String, Object>>;
                      final isExpanded = _expandedWeek == weekNum;
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: CustomCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () => setState(() => _expandedWeek = isExpanded ? 0 : weekNum),
                                borderRadius: AppRadius.borderXl,
                                child: Padding(
                                  padding: EdgeInsets.all(16.r),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40.r,
                                        height: 40.r,
                                        decoration: BoxDecoration(
                                          gradient: AppGradients.primary(isDark: isDark),
                                          borderRadius: AppRadius.borderLg,
                                          boxShadow: AppShadows.md,
                                        ),
                                        child: Center(
                                          child: Text('$weekNum', style: AppTextStyles.h4.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Week $weekNum', style: AppTextStyles.h4.copyWith(color: context.foreground, fontWeight: FontWeight.w500)),
                                            Text('${workouts.length} workouts', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        isExpanded ? AppIcons.chevronUp : AppIcons.chevronDown,
                                        size: 20.r,
                                        color: context.mutedForeground,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isExpanded) ...[
                                Divider(color: context.borderColor, height: 1),
                                ...workouts.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final workout = entry.value;
                                  return InkWell(
                                    onTap: () => context.push('/workout/$weekNum-${idx + 1}'),
                                    child: Container(
                                      padding: EdgeInsets.all(16.r),
                                      decoration: BoxDecoration(
                                        border: idx < workouts.length - 1
                                            ? Border(bottom: BorderSide(color: context.borderColor))
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  workout['name'] as String,
                                                  style: AppTextStyles.bodySmall.copyWith(color: context.foreground, fontWeight: FontWeight.w500),
                                                ),
                                                SizedBox(height: 2.h),
                                                Text(
                                                  workout['day'] as String,
                                                  style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${workout['exercises']} exercises',
                                                style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
                                              ),
                                              Text(
                                                workout['duration'] as String,
                                                style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildAboutSection(context),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramDaysSection(BuildContext context, bool isDark, List<WorkoutDay> days) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expandedWeek = _expandedWeek == 1 ? 0 : 1),
            borderRadius: AppRadius.borderXl,
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary(isDark: isDark),
                      borderRadius: AppRadius.borderLg,
                      boxShadow: AppShadows.md,
                    ),
                    child: Center(
                      child: Text('1', style: AppTextStyles.h4.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Weekly Schedule', style: AppTextStyles.h4.copyWith(color: context.foreground, fontWeight: FontWeight.w500)),
                        Text('${days.length} workouts', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                      ],
                    ),
                  ),
                  Icon(
                    _expandedWeek == 1 ? AppIcons.chevronUp : AppIcons.chevronDown,
                    size: 20.r,
                    color: context.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
          if (_expandedWeek == 1) ...[
            Divider(color: context.borderColor, height: 1),
            ...days.asMap().entries.map((entry) {
              final idx = entry.key;
              final day = entry.value;
              return InkWell(
                onTap: () => context.push('/workout/${day.id}'),
                child: Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    border: idx < days.length - 1
                        ? Border(bottom: BorderSide(color: context.borderColor))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(day.name, style: AppTextStyles.bodySmall.copyWith(color: context.foreground, fontWeight: FontWeight.w500)),
                            SizedBox(height: 2.h),
                            Text(day.dayOfWeek, style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                          ],
                        ),
                      ),
                      Text(
                        '${day.exercises.length} exercises',
                        style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About This Program', style: AppTextStyles.h3.copyWith(color: context.foreground, fontWeight: FontWeight.w500)),
          SizedBox(height: 12.h),
          Text(
            'This push-pull-legs routine is designed for intermediate to advanced lifters looking to maximize muscle growth and strength. Each muscle group is trained twice per week with optimal volume and intensity.',
            style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground, height: 1.5),
          ),
          SizedBox(height: 16.h),
          _bulletPoint(context, 'Progressive overload principles'),
          _bulletPoint(context, 'Balanced muscle development'),
          _bulletPoint(context, 'Built-in deload weeks'),
        ],
      ),
    );
  }

  Widget _bulletPoint(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Container(
            width: 8.r,
            height: 8.r,
            decoration: BoxDecoration(
              color: context.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Text(text, style: AppTextStyles.bodySmall.copyWith(color: context.foreground)),
        ],
      ),
    );
  }
}
