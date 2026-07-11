import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';

import '../../../app/providers.dart';
import '../../../shared/data/sample_data.dart';
import '../../../shared/models/program.dart';
import '../../../shared/models/workout_day.dart';
import '../../../theme/app_gradients.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/custom_badge.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/scale_tap.dart';
import '../../../shared/widgets/staggered_list.dart';

class ProgramDetailScreen extends ConsumerStatefulWidget {
  final String programId;
  const ProgramDetailScreen({super.key, required this.programId});

  @override
  ConsumerState<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends ConsumerState<ProgramDetailScreen> {
  int _expandedDayIndex = 0;
  bool _isActivating = false;

  @override
  void initState() {
    super.initState();
    // Invalidate so opening the screen always shows the latest progress
    // (programByIdProvider is a FutureProvider — it caches after first load).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(programByIdProvider(widget.programId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final programAsync = ref.watch(programByIdProvider(widget.programId));
    final communityAsync = ref.watch(communityProgramByIdProvider(widget.programId));

    return Scaffold(
      body: programAsync.when(
        loading: () => _buildLoading(context, isDark),
        error: (e, _) => _buildError(context, isDark),
        data: (program) {
          if (program != null) {
            return _buildBody(context, isDark, program, isUserProgram: true);
          }
          // Still loading the community program — avoid a premature not-found flash.
          if (communityAsync.isLoading) return _buildLoading(context, isDark);
          final community = communityAsync.valueOrNull;
          if (community != null) {
            return _buildBody(context, isDark, community, isUserProgram: false);
          }
          // No Firestore community program — fall back to hardcoded sample data
          // (Stronglifts/PHUL/nSuns shipped with the app as a launch bootstrap).
          final sample = _findSampleProgram(widget.programId);
          if (sample != null) {
            return _buildBody(context, isDark, sample, isUserProgram: false);
          }
          return _buildNotFound(context, isDark);
        },
      ),
    );
  }

  Program? _findSampleProgram(String id) {
    final all = [...SampleData.myPrograms, ...SampleData.explorePrograms];
    for (final p in all) {
      if (p.id == id) {
        // Attach sample days for preview
        return p.copyWith(
          days: SampleData.programDetailDays,
          description: _defaultDescriptionFor(p.name),
        );
      }
    }
    return null;
  }

  String _defaultDescriptionFor(String name) {
    return 'A structured training program designed to help you build '
        'strength and muscle with progressive overload principles. '
        'Follow the weekly schedule and track your progress over time.';
  }

  // ─── Loading ───

  Widget _buildLoading(BuildContext context, bool isDark) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            showBackButton: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 200.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: context.mutedColor,
                    borderRadius: AppRadius.borderSm,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Container(
                  width: 140.w,
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: context.mutedColor,
                    borderRadius: AppRadius.borderSm,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
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
          ),
        ],
      ),
    );
  }

  // ─── Error ───

  Widget _buildError(BuildContext context, bool isDark) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            showBackButton: true,
            child: Text('Program', style: AppTextStyles.h1.copyWith(color: context.foreground)),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.info, size: 48.r, color: context.destructiveColor),
                    SizedBox(height: AppSpacing.lg),
                    Text(
                      'Failed to load program',
                      style: AppTextStyles.h3.copyWith(color: context.foreground),
                    ),
                    SizedBox(height: AppSpacing.md),
                    ScaleTap(
                      onTap: () => ref.invalidate(programByIdProvider(widget.programId)),
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
            ),
          ),
        ],
      ),
    );
  }

  // ─── Not Found ───

  Widget _buildNotFound(BuildContext context, bool isDark) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            showBackButton: true,
            child: Text('Program', style: AppTextStyles.h1.copyWith(color: context.foreground)),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.search, size: 48.r, color: context.mutedForeground),
                    SizedBox(height: AppSpacing.lg),
                    Text(
                      'Program not found',
                      style: AppTextStyles.h3.copyWith(color: context.foreground),
                    ),
                    SizedBox(height: AppSpacing.xl),
                    CustomButton(
                      text: 'Go Back',
                      variant: ButtonVariant.outline,
                      isFullWidth: false,
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Main Body ───

  Widget _buildBody(BuildContext context, bool isDark, Program program, {required bool isUserProgram}) {
    final programDesc = program.description ??
        '${program.workouts} workouts/week \u2022 ${program.weeksLabel}';
    final totalWorkouts =
        program.weeks != null ? program.workouts * program.weeks! : null;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
      child: Column(
        children: [
          GradientHeader(
            showBackButton: true,
            actions: isUserProgram
                ? [
                    _buildHeaderAction(
                      context,
                      icon: AppIcons.edit,
                      onTap: () => context.push('/programs/detail/${program.id}/edit', extra: program),
                    ),
                    SizedBox(width: 28.w),
                    _buildHeaderAction(
                      context,
                      icon: AppIcons.trash2,
                      onTap: () => _confirmDelete(context, program),
                    ),
                  ]
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GYM-58: Hero tag matches the card in ProgramsScreen
                Hero(
                  tag: 'program_title_${program.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      program.name,
                      style: AppTextStyles.h1.copyWith(color: context.foreground),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  programDesc,
                  style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
                ),
                SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.md,
                  children: [
                    _headerChip(AppIcons.clock, program.weeksLabel),
                    if (totalWorkouts != null)
                      _headerChip(AppIcons.dumbbell, '$totalWorkouts workouts'),
                    if (program.difficulty != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withValues(alpha:0.15),
                          borderRadius: AppRadius.borderFull,
                        ),
                        child: Text(
                          program.difficulty!,
                          style: AppTextStyles.caption.copyWith(
                            color: context.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (program.isActive)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: context.coralColor.withValues(alpha:0.12),
                          borderRadius: AppRadius.borderFull,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(AppIcons.check, size: 12.r, color: context.coralColor),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Active',
                              style: AppTextStyles.caption.copyWith(
                                color: context.coralColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (isUserProgram && program.weeks != null) ...[
                  SizedBox(height: AppSpacing.xl),
                  _buildProgressBar(program.progress),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isUserProgram) _buildUserActions(context, program),
                if (!isUserProgram) _buildExploreActions(context, program),
                SizedBox(height: AppSpacing.sectionGap),
                Row(
                  children: [
                    Text(
                      program.days.isNotEmpty ? 'Workout Days' : 'Weekly Breakdown',
                      style: AppTextStyles.h2.copyWith(color: context.foreground),
                    ),
                    const Spacer(),
                    if (program.isActive && program.activatedAt != null)
                      if (program.weeks != null && program.weeks! > 0)
                        _buildWeekBadge(context, program)
                      else if (program.weeks == null)
                        _buildOngoingBadge(context),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),
                if (program.days.isNotEmpty)
                  _buildDaysList(context, isDark, program.days)
                else
                  _buildNoDaysState(context),
                SizedBox(height: AppSpacing.sectionGap),
                _buildAboutSection(context, program),
                SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _headerChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16.r, color: context.mutedForeground),
        SizedBox(width: AppSpacing.sm),
        Text(text, style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
      ],
    );
  }

  Widget _buildHeaderAction(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return ScaleTap(
      onTap: onTap,
      child: Container(
        width: 40.r,
        height: 40.r,
        decoration: BoxDecoration(
          color: context.primaryColor.withValues(alpha:0.15),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: context.foreground, size: 20.r),
      ),
    );
  }

  Widget _buildProgressBar(int progress) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha:0.08),
        borderRadius: AppRadius.borderLg,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
              ),
              Text(
                '$progress%',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.borderFull,
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8.h,
              backgroundColor: context.primaryColor.withValues(alpha:0.15),
              valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Action Buttons ───

  Widget _buildUserActions(BuildContext context, Program program) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Continue',
                variant: ButtonVariant.gradient,
                icon: AppIcons.play,
                onPressed: () => _continueProgram(context, program),
              ),
            ),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: program.isActive
                  ? CustomButton(
                      text: 'Active',
                      variant: ButtonVariant.outline,
                      icon: AppIcons.check,
                      onPressed: null,
                    )
                  : CustomButton(
                      text: _isActivating ? 'Setting...' : 'Set Active',
                      variant: ButtonVariant.outline,
                      icon: AppIcons.target,
                      onPressed: _isActivating ? null : () => _activateProgram(program),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExploreActions(BuildContext context, Program program) {
    return CustomButton(
      text: 'Add to My Programs',
      variant: ButtonVariant.gradient,
      icon: AppIcons.plus,
      onPressed: () => _addToMyPrograms(context, program),
    );
  }

  void _continueProgram(BuildContext context, Program program) {
    if (program.days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No workout days in this program'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    // Navigate to today's workout day, cycling through available days
    final dayIndex = (DateTime.now().weekday - 1) % program.days.length;
    final day = program.days[dayIndex];
    context.push('/workout/${day.id}');
  }

  Future<void> _activateProgram(Program program) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    setState(() => _isActivating = true);
    try {
      await ref.read(programServiceProvider).activateProgram(uid, program.id);
      ref.invalidate(programByIdProvider(widget.programId));
      ref.invalidate(userProgramsProvider);
      ref.invalidate(activeProgramProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${program.name} is now your active program'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to activate program'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActivating = false);
    }
  }

  Future<void> _addToMyPrograms(BuildContext context, Program program) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    try {
      await ref.read(programServiceProvider).createProgram(
            uid,
            name: program.name,
            days: program.days,
            weeks: program.weeks,
            description: program.description,
            difficulty: program.difficulty,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${program.name} added to your programs'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to add program'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, Program program) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Program'),
        content: Text('Are you sure you want to delete "${program.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: context.destructiveColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final uid = ref.read(currentUidProvider);
      if (uid == null) return;
      await ref.read(programRepositoryProvider).deleteProgram(uid, program.id);
      ref.invalidate(userProgramsProvider);
      ref.invalidate(activeProgramProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to delete program'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildWeekBadge(BuildContext context, Program program) {
    // Safe: only called when the caller has already verified program.weeks != null.
    final weeks = program.weeks!;
    final daysSinceActivation = DateTime.now().difference(program.activatedAt!).inDays;
    final currentWeek = (daysSinceActivation ~/ 7) + 1;
    final clampedWeek = currentWeek.clamp(1, weeks);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.12),
        borderRadius: AppRadius.borderFull,
      ),
      child: Text(
        'Week $clampedWeek of $weeks',
        style: AppTextStyles.caption.copyWith(
          color: context.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOngoingBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.12),
        borderRadius: AppRadius.borderFull,
      ),
      child: Text(
        'Ongoing',
        style: AppTextStyles.caption.copyWith(
          color: context.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── Days List ───

  Widget _buildDaysList(BuildContext context, bool isDark, List<WorkoutDay> days) {
    return StaggeredList(
      children: days.asMap().entries.map((entry) {
        final idx = entry.key;
        final day = entry.value;
        final isExpanded = _expandedDayIndex == idx;

        return Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.lg),
          child: CustomCard(
            variant: CardVariant.workout,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ScaleTap(
                  onTap: () => setState(() => _expandedDayIndex = isExpanded ? -1 : idx),
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
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
                            child: Text(
                              '${idx + 1}',
                              style: AppTextStyles.h4.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                day.name,
                                style: AppTextStyles.h4.copyWith(
                                  color: context.foreground,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${day.dayOfWeek} \u2022 ${day.exercises.length} exercises',
                                style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
                              ),
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
                  Divider(color: context.mutedForeground.withValues(alpha:0.15), height: 1),
                  ...day.exercises.asMap().entries.map((exEntry) {
                    final exIdx = exEntry.key;
                    final ex = exEntry.value;
                    return Container(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        border: exIdx < day.exercises.length - 1
                            ? Border(bottom: BorderSide(color: context.borderColor))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32.r,
                            height: 32.r,
                            decoration: BoxDecoration(
                              color: context.primaryColor.withValues(alpha: 0.1),
                              borderRadius: AppRadius.borderSm,
                            ),
                            child: Center(
                              child: Text(
                                '${exIdx + 1}',
                                style: AppTextStyles.caption.copyWith(
                                  color: context.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ex.name,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: context.foreground,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.xs),
                                Text(
                                  '${ex.sets} sets \u2022 ${Formatters.reps(ex.repMin, ex.repMax)} reps \u2022 RIR ${ex.targetRir}',
                                  style: AppTextStyles.caption.copyWith(color: context.mutedForeground),
                                ),
                              ],
                            ),
                          ),
                          if (ex.equipment != null)
                            CustomBadge(text: ex.equipmentType.label),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoDaysState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sectionGap),
      child: Column(
        children: [
          Icon(
            AppIcons.calendar,
            size: 40.r,
            color: context.mutedForeground.withValues(alpha:0.6),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'No workout days defined',
            style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
          ),
        ],
      ),
    );
  }

  // ─── About Section ───

  Widget _buildAboutSection(BuildContext context, Program program) {
    final description = program.description ?? _defaultDescriptionFor(program.name);

    return CustomCard(
      padding: EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About This Program',
            style: AppTextStyles.h3.copyWith(
              color: context.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            description,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.mutedForeground,
              height: 1.5,
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          _buildStatRow(
            context,
            icon: AppIcons.calendar,
            label: 'Duration',
            value: program.weeksLabel,
          ),
          SizedBox(height: AppSpacing.md),
          _buildStatRow(
            context,
            icon: AppIcons.dumbbell,
            label: 'Frequency',
            value: '${program.workouts} workouts/week',
          ),
          if (program.days.isNotEmpty) ...[
            SizedBox(height: AppSpacing.md),
            _buildStatRow(
              context,
              icon: AppIcons.layers,
              label: 'Total Exercises',
              value: '${program.days.fold<int>(0, (sum, d) => sum + d.exercises.length)} across ${program.days.length} days',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, {required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 16.r, color: context.primaryColor),
        SizedBox(width: AppSpacing.md),
        Text(
          '$label: ',
          style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
        ),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: context.foreground,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
