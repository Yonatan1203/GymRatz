import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_gradients.dart';
import '../../../../theme/app_icons.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../shared/models/workout_exercise.dart';
import '../../../../shared/models/workout_set.dart';
import '../../../../shared/utils/extensions.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../domain/workout_summary.dart';

/// Full-screen workout completion UI with staggered stat card animations (GYM-59).
///
/// Owns its AnimationController — the parent only sets `_completed = true` and
/// passes data; it no longer needs to call `_initCompletionAnimations()`.
class WorkoutCompletionScreen extends StatefulWidget {
  final String workoutName;
  final List<WorkoutExercise> exercises;
  final List<List<WorkoutSet>> sets;
  final DateTime startTime;
  final WorkoutSummary? workoutSummary;
  final String unit;
  final VoidCallback onHome;

  const WorkoutCompletionScreen({
    super.key,
    required this.workoutName,
    required this.exercises,
    required this.sets,
    required this.startTime,
    required this.workoutSummary,
    required this.unit,
    required this.onHome,
  });

  @override
  State<WorkoutCompletionScreen> createState() => _WorkoutCompletionScreenState();
}

class _WorkoutCompletionScreenState extends State<WorkoutCompletionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fades = [];
    _slides = [];
    for (int i = 0; i < 6; i++) {
      final start = (i * 150) / 1500.0;
      final end = (start + 400 / 1500.0).clamp(0.0, 1.0);
      final interval = CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
      _fades.add(interval);
      _slides.add(
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(interval),
      );
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final completedSets = widget.sets.fold<int>(
      0, (sum, ex) => sum + ex.where((s) => s.completed).length,
    );
    final totalSets = widget.sets.fold<int>(0, (sum, ex) => sum + ex.length);
    final totalReps = widget.workoutSummary?.totalReps ??
        widget.sets.fold<int>(
          0, (sum, ex) => sum + ex.fold<int>(0, (s, set) => s + set.reps),
        );
    final totalVolume = widget.workoutSummary?.totalVolume ??
        widget.sets.fold<double>(
          0, (sum, ex) => sum + ex.fold<double>(0, (s, set) => s + (set.weight * set.reps)),
        );
    final duration = DateTime.now().difference(widget.startTime);
    final durationStr =
        '${duration.inMinutes}m ${(duration.inSeconds % 60).toString().padLeft(2, '0')}s';
    final completionPct = totalSets > 0 ? ((completedSets / totalSets) * 100).round() : 0;
    final newPRs = widget.workoutSummary?.newPRs ?? [];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.primaryColor.withValues(alpha: 0.15),
              isDark ? Colors.black : Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              children: [
                SizedBox(height: 32.h),
                Container(
                  width: 120.r,
                  height: 120.r,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary(isDark: isDark),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: context.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(AppIcons.trophy, size: 56.r, color: Colors.white),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Workout Complete!',
                  style: AppTextStyles.h1.copyWith(
                    color: context.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'You absolutely crushed it today',
                  style: AppTextStyles.body.copyWith(color: context.mutedForeground),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.15),
                    borderRadius: AppRadius.borderFull,
                  ),
                  child: Text(
                    '$completionPct% completed',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (newPRs.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          context.coralColor.withValues(alpha: 0.15),
                          context.coralColor.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: AppRadius.borderXl,
                      border: Border.all(color: context.coralColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(AppIcons.trophy, size: 18.r, color: context.coralColor),
                            SizedBox(width: 8.w),
                            Text(
                              'New Personal Records!',
                              style: AppTextStyles.h4.copyWith(
                                color: context.coralColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        ...newPRs.map((pr) => Padding(
                              padding: EdgeInsets.only(bottom: 4.h),
                              child: Text(
                                pr,
                                style: AppTextStyles.bodySmall.copyWith(color: context.foreground),
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 28.h),
                Row(
                  children: [
                    Expanded(child: _statCard(context, isDark, 0, AppIcons.clock, 'Duration', durationStr)),
                    SizedBox(width: 12.w),
                    Expanded(child: _statCard(context, isDark, 1, AppIcons.layers, 'Sets', '$completedSets / $totalSets')),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(child: _statCard(context, isDark, 2, AppIcons.repeat, 'Total Reps', null, countValue: totalReps)),
                    SizedBox(width: 12.w),
                    Expanded(child: _statCard(context, isDark, 3, AppIcons.barChart2, 'Volume', null, countValue: totalVolume.toInt(), countSuffix: ' ${widget.unit}')),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(child: _statCard(context, isDark, 4, AppIcons.dumbbell, 'Exercises', null, countValue: widget.exercises.length)),
                    SizedBox(width: 12.w),
                    Expanded(child: _statCard(context, isDark, 5, AppIcons.flame, 'Intensity', completionPct >= 80 ? 'High' : completionPct >= 50 ? 'Medium' : 'Light')),
                  ],
                ),
                SizedBox(height: 32.h),
                CustomButton(
                  text: 'Back to Home',
                  variant: ButtonVariant.gradient,
                  icon: AppIcons.home,
                  onPressed: widget.onHome,
                ),
                SizedBox(height: 12.h),
                CustomButton(
                  text: 'Share Workout',
                  variant: ButtonVariant.outline,
                  icon: AppIcons.share2,
                  onPressed: () {
                    final n = widget.exercises.length;
                    final word = n == 1 ? 'exercise' : 'exercises';
                    Share.share('I just completed ${widget.workoutName} — $n $word 💪 #GymRatz');
                  },
                ),
                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(
    BuildContext context,
    bool isDark,
    int index,
    IconData icon,
    String label,
    String? staticValue, {
    int? countValue,
    String countSuffix = '',
  }) {
    final card = Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20.r, color: context.primaryColor),
          SizedBox(height: 8.h),
          if (countValue != null)
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: countValue),
              duration: const Duration(milliseconds: 800),
              builder: (_, val, __) => Text(
                '$val$countSuffix',
                style: AppTextStyles.h3.copyWith(
                  color: context.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Text(
              staticValue ?? '',
              style: AppTextStyles.h3.copyWith(
                color: context.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          SizedBox(height: 2.h),
          Text(label, style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
        ],
      ),
    );

    if (_fades.length <= index) return card;

    return FadeTransition(
      opacity: _fades[index],
      child: SlideTransition(position: _slides[index], child: card),
    );
  }
}
