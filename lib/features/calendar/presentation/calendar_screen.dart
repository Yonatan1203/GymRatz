import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/weight_entry.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_gradients.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/custom_input.dart';
import '../../../shared/data/sample_data.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  bool _showWeightLog = false;
  final _weightController = TextEditingController();
  late int _currentYear;
  late int _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentYear = now.year;
    _currentMonth = now.month;
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                children: [
                  _buildCalendarGrid(context, isDark),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildLegend(context),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildStreakCards(context, isDark),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildWeightSection(context, isDark),
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Workout Calendar', style: AppTextStyles.h1.copyWith(color: context.foreground)),
              SizedBox(height: AppSpacing.sectionGap),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      _currentMonth--;
                      if (_currentMonth < 1) { _currentMonth = 12; _currentYear--; }
                    }),
                    child: _navButton(context, LucideIcons.chevronLeft),
                  ),
                  Text('${_monthName(_currentMonth)} $_currentYear', style: AppTextStyles.h2.copyWith(color: context.foreground)),
                  GestureDetector(
                    onTap: () => setState(() {
                      _currentMonth++;
                      if (_currentMonth > 12) { _currentMonth = 1; _currentYear++; }
                    }),
                    child: _navButton(context, LucideIcons.chevronRight),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sectionGap),
              _buildCompletionRing(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navButton(BuildContext context, IconData icon) {
    return Container(
      width: 40.r,
      height: 40.r,
      decoration: BoxDecoration(
        color: context.mutedColor,
        borderRadius: AppRadius.borderLg,
        boxShadow: AppShadows.sm,
      ),
      child: Icon(icon, size: 20.r, color: context.foreground),
    );
  }

  Widget _buildCompletionRing(BuildContext context, bool isDark) {
    final calendarData = ref.watch(calendarMonthProvider('$_currentYear-$_currentMonth')).valueOrNull ?? {};
    final completedCount = calendarData.values.where((s) => s == WorkoutStatus.completed).length;
    final totalPlanned = calendarData.values.where((s) => s == WorkoutStatus.completed || s == WorkoutStatus.scheduled || s == WorkoutStatus.missed).length;
    final target = totalPlanned > 0 ? totalPlanned : 12;
    final pct = (completedCount / target * 100).round();
    final progress = completedCount / target;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: AppGradients.primary(isDark: isDark),
        borderRadius: AppRadius.borderXl,
        boxShadow: AppShadows.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Progress', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                SizedBox(height: 4.h),
                Text('$pct%', style: TextStyle(fontSize: 30.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                SizedBox(height: 4.h),
                Text('$completedCount of $target workouts', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          SizedBox(
            width: 80.r,
            height: 80.r,
            child: CustomPaint(painter: _RingPainter(progress: progress.clamp(0.0, 1.0))),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  Widget _buildCalendarGrid(BuildContext context, bool isDark) {
    final dayHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final calendarData = ref.watch(calendarMonthProvider('$_currentYear-$_currentMonth')).valueOrNull;

    final daysInMonth = DateTime(_currentYear, _currentMonth + 1, 0).day;
    final firstWeekday = DateTime(_currentYear, _currentMonth, 1).weekday; // Mon=1
    final totalCells = firstWeekday - 1 + daysInMonth;

    return Column(
      children: [
        Row(
          children: dayHeaders.map((d) => Expanded(
            child: Center(
              child: Text(d, style: AppTextStyles.caption.copyWith(color: context.mutedForeground, fontWeight: FontWeight.w600)),
            ),
          )).toList(),
        ),
        SizedBox(height: 8.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            final dayNumber = index - (firstWeekday - 2);
            if (dayNumber < 1 || dayNumber > daysInMonth) return const SizedBox();

            final workoutStatus = calendarData?[dayNumber];
            int statusCode = 0;
            if (workoutStatus == WorkoutStatus.completed) statusCode = 1;
            else if (workoutStatus == WorkoutStatus.scheduled) statusCode = 2;
            else if (workoutStatus == WorkoutStatus.missed) statusCode = 3;

            // Fall back to SampleData if no Firestore data
            if (calendarData == null || calendarData.isEmpty) {
              if (index < SampleData.calendarDays.length) {
                statusCode = SampleData.calendarDays[index];
              }
            }

            Color bgColor;
            Color textColor;
            switch (statusCode) {
              case 1:
                bgColor = context.primaryColor;
                textColor = Colors.white;
                break;
              case 2:
                bgColor = context.secondaryColor;
                textColor = Colors.white;
                break;
              case 3:
                bgColor = context.destructiveColor.withValues(alpha: 0.2);
                textColor = isDark ? AppColors.darkMissedDay : context.destructiveColor;
                break;
              default:
                bgColor = context.cardColor;
                textColor = context.mutedForeground;
            }

            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: AppRadius.borderLg,
                border: statusCode == 0 ? Border.all(color: context.borderColor) : null,
                boxShadow: AppShadows.sm,
              ),
              child: Center(
                child: Text(
                  '$dayNumber',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: textColor),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    final items = [
      ('Completed', context.primaryColor),
      ('Scheduled', context.secondaryColor),
      ('Missed', context.destructiveColor.withValues(alpha: 0.2)),
      ('Rest Day', context.cardColor),
    ];

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Legend', style: AppTextStyles.bodySmall.copyWith(color: context.foreground, fontWeight: FontWeight.w600)),
          SizedBox(height: 12.h),
          ...items.map((item) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              children: [
                Container(
                  width: 24.r,
                  height: 24.r,
                  decoration: BoxDecoration(
                    color: item.$2,
                    borderRadius: AppRadius.borderSm,
                    border: item.$1 == 'Rest Day' ? Border.all(color: context.borderColor) : null,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(item.$1, style: AppTextStyles.bodySmall.copyWith(color: context.foreground)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStreakCards(BuildContext context, bool isDark) {
    final stats = ref.watch(workoutStatsProvider).valueOrNull;
    final currentStreak = stats?['streak'] as int? ?? 12;

    return Row(
      children: [
        Expanded(
          child: CustomCard(
            child: Column(
              children: [
                Text('$currentStreak \u{1F525}', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w600, color: context.primaryColor)),
                SizedBox(height: 4.h),
                Text('Current Streak', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
              ],
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: CustomCard(
            child: Column(
              children: [
                Text('18 \u26A1', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w600, color: context.secondaryColor)),
                SizedBox(height: 4.h),
                Text('Best Streak', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightSection(BuildContext context, bool isDark) {
    return CustomCard(
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.scale, size: 20.r, color: context.primaryColor),
              SizedBox(width: 8.w),
              Text('Log Your Weight', style: AppTextStyles.h4.copyWith(color: context.foreground, fontWeight: FontWeight.w500)),
            ],
          ),
          SizedBox(height: 16.h),
          if (!_showWeightLog)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() => _showWeightLog = true),
                child: const Text('+ Add Weight Entry'),
              ),
            )
          else
            Column(
              children: [
                CustomInput(
                  controller: _weightController,
                  label: 'Weight (lbs)',
                  hint: 'e.g., 175',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final weight = double.tryParse(_weightController.text);
                          if (weight != null) {
                            final uid = ref.read(currentUidProvider);
                            if (uid != null) {
                              final entry = WeightEntry(
                                id: const Uuid().v4(),
                                date: DateTime.now(),
                                weight: weight,
                                unit: 'lbs',
                              );
                              await ref.read(weightEntryRepositoryProvider).addWeightEntry(uid, entry);
                            }
                          }
                          _weightController.clear();
                          setState(() => _showWeightLog = false);
                        },
                        child: const Text('Save'),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _weightController.clear();
                          setState(() => _showWeightLog = false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.mutedColor,
                          foregroundColor: context.foreground,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          SizedBox(height: 16.h),
          Divider(color: context.borderColor),
          SizedBox(height: 12.h),
          Text('Recent Entries', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
          SizedBox(height: 8.h),
          ...(() {
            final entries = ref.watch(weightEntriesProvider).valueOrNull;
            if (entries != null && entries.isNotEmpty) {
              return entries.map((e) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${e.date.month}/${e.date.day}/${e.date.year}', style: AppTextStyles.bodySmall.copyWith(color: context.foreground)),
                    Text('${e.weight} ${e.unit}', style: AppTextStyles.bodySmall.copyWith(color: context.primaryColor, fontWeight: FontWeight.w500)),
                  ],
                ),
              ));
            }
            return SampleData.weightEntries.map((e) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e['date'] as String, style: AppTextStyles.bodySmall.copyWith(color: context.foreground)),
                  Text('${e['weight']} lbs', style: AppTextStyles.bodySmall.copyWith(color: context.primaryColor, fontWeight: FontWeight.w500)),
                ],
              ),
            ));
          })(),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}
