import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/weight_entry.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/custom_input.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/scale_tap.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/staggered_list.dart';
import '../../../shared/data/sample_data.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

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
  int? _selectedDay;

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

  bool _isCurrentMonth() {
    final now = DateTime.now();
    return _currentYear == now.year && _currentMonth == now.month;
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _currentYear = now.year;
      _currentMonth = now.month;
      _selectedDay = null;
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth--;
      if (_currentMonth < 1) {
        _currentMonth = 12;
        _currentYear--;
      }
      _selectedDay = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth++;
      if (_currentMonth > 12) {
        _currentMonth = 1;
        _currentYear++;
      }
      _selectedDay = null;
    });
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
              child: StaggeredList(
                children: [
                  _buildCalendarGrid(context, isDark),
                  SizedBox(height: AppSpacing.lg),
                  _buildStreakCards(context, isDark),
                  SizedBox(height: AppSpacing.lg),
                  _buildWeightSection(context, isDark),
                  SizedBox(height: AppSpacing.xxl),
                  _buildLegend(context),
                  SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return GradientHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workout Calendar',
            style: AppTextStyles.h2.copyWith(color: context.foreground, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              ScaleTap(
                onTap: _previousMonth,
                child: _navButton(AppIcons.chevronLeft),
              ),
              const Spacer(),
              Text(
                '${_monthName(_currentMonth)} $_currentYear',
                style: AppTextStyles.h2.copyWith(color: context.foreground),
              ),
              const Spacer(),
              if (!_isCurrentMonth())
                Padding(
                  padding: EdgeInsets.only(right: AppSpacing.md),
                  child: ScaleTap(
                    onTap: _goToToday,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withOpacity(0.15),
                        borderRadius: AppRadius.borderFull,
                      ),
                      child: Text(
                        'Today',
                        style: AppTextStyles.caption.copyWith(
                          color: context.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ScaleTap(
                onTap: _nextMonth,
                child: _navButton(AppIcons.chevronRight),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          _buildCompletionRing(context, isDark),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon) {
    return SizedBox(
      width: 40.r,
      height: 40.r,
      child: Center(child: Icon(icon, size: 20.r, color: context.foreground)),
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
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.primaryColor.withOpacity(0.1),
        borderRadius: AppRadius.borderXl,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48.r,
            height: 48.r,
            child: CustomPaint(painter: _RingPainter(progress: progress.clamp(0.0, 1.0), color: context.primaryColor)),
          ),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$pct% Complete',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: context.foreground),
                ),
                SizedBox(height: AppSpacing.xs),
                Text('$completedCount of $target workouts this month', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }

  Widget _buildCalendarGrid(BuildContext context, bool isDark) {
    final dayHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final calendarAsync = ref.watch(calendarMonthProvider('$_currentYear-$_currentMonth'));

    return Column(
      children: [
        Row(
          children: dayHeaders.map((d) => Expanded(
            child: Center(
              child: Text(
                d,
                style: AppTextStyles.caption.copyWith(
                  color: context.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )).toList(),
        ),
        SizedBox(height: AppSpacing.md),
        _buildCalendarDays(context, isDark, calendarAsync.valueOrNull ?? {}),
      ],
    );
  }

  Widget _buildCalendarDays(BuildContext context, bool isDark, Map<int, WorkoutStatus> calendarData) {
    final now = DateTime.now();
    final daysInMonth = DateTime(_currentYear, _currentMonth + 1, 0).day;
    final firstWeekday = DateTime(_currentYear, _currentMonth, 1).weekday;
    final totalCells = firstWeekday - 1 + daysInMonth;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayNumber = index - (firstWeekday - 2);
        if (dayNumber < 1 || dayNumber > daysInMonth) return const SizedBox();

        final isToday = _currentYear == now.year && _currentMonth == now.month && dayNumber == now.day;
        final isSelected = _selectedDay == dayNumber;

        final workoutStatus = calendarData[dayNumber];
        int statusCode = 0;
        if (workoutStatus == WorkoutStatus.completed) {
          statusCode = 1;
        } else if (workoutStatus == WorkoutStatus.scheduled) {
          statusCode = 2;
        } else if (workoutStatus == WorkoutStatus.missed) {
          statusCode = 3;
        }

        // Fall back to SampleData if no Firestore data
        if (calendarData.isEmpty && dayNumber - 1 < SampleData.calendarDays.length) {
          statusCode = SampleData.calendarDays[dayNumber - 1];
        }

        Color bgColor;
        Color textColor;
        switch (statusCode) {
          case 1: // Completed — teal tint
            bgColor = context.primaryColor.withOpacity(0.15);
            textColor = context.primaryColor;
            break;
          case 2: // Scheduled
            bgColor = context.mutedColor;
            textColor = context.mutedForeground;
            break;
          case 3: // Missed — orange
            bgColor = const Color(0xFFF97316).withValues(alpha: 0.15);
            textColor = const Color(0xFFF97316);
            break;
          default: // Rest
            bgColor = context.cardColor;
            textColor = context.mutedForeground;
        }

        // Today highlight overrides
        Border? border;
        if (isToday) {
          border = Border.all(color: context.primaryColor, width: 2.5);
          if (statusCode == 0) {
            bgColor = context.primaryColor.withValues(alpha: 0.12);
            textColor = context.primaryColor;
          }
        } else if (isSelected) {
          border = Border.all(color: context.primaryColor, width: 2);
        } else if (statusCode == 2) {
          border = Border.all(color: context.borderColor);
        } else if (statusCode == 0) {
          border = Border.all(color: context.borderColor);
        }

        return ScaleTap(
          onTap: () {
            setState(() {
              _selectedDay = _selectedDay == dayNumber ? null : dayNumber;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: AppRadius.borderLg,
              border: border,
              boxShadow: AppShadows.sm,
            ),
            child: Center(
              child: Text(
                '$dayNumber',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegend(BuildContext context) {
    final items = [
      ('Completed', context.primaryColor),
      ('Scheduled', context.mutedForeground),
      ('Missed', const Color(0xFFF97316)),
      ('Rest', context.cardColor),
    ];

    return Wrap(
      spacing: AppSpacing.xl,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: items.map((item) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.r,
            height: 8.r,
            decoration: BoxDecoration(
              color: item.$2,
              shape: BoxShape.circle,
              border: item.$1 == 'Rest' ? Border.all(color: context.borderColor, width: 0.5) : null,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            item.$1,
            style: TextStyle(fontSize: 11.sp, color: context.mutedForeground),
          ),
        ],
      )).toList(),
    );
  }

  Widget _buildStreakCards(BuildContext context, bool isDark) {
    final stats = ref.watch(workoutStatsProvider).valueOrNull;
    final currentStreak = stats?['streak'] as int? ?? 0;
    final totalWorkouts = stats?['totalWorkouts'] as int? ?? 0;

    return Row(
      children: [
        Expanded(
          child: CustomCard(
            child: Row(
              children: [
                SizedBox(
                  width: 36.r,
                  height: 36.r,
                  child: Center(child: Icon(AppIcons.flame, size: 18.r, color: context.primaryColor)),
                ),
                SizedBox(width: AppSpacing.lg),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$currentStreak',
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600, color: context.foreground),
                    ),
                    Text('Day Streak', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: AppSpacing.lg),
        Expanded(
          child: CustomCard(
            child: Row(
              children: [
                SizedBox(
                  width: 36.r,
                  height: 36.r,
                  child: Center(child: Icon(AppIcons.dumbbell, size: 18.r, color: context.secondaryColor)),
                ),
                SizedBox(width: AppSpacing.lg),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalWorkouts',
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600, color: context.foreground),
                    ),
                    Text('Workouts', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightSection(BuildContext context, bool isDark) {
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final unit = userProfile?.unit ?? 'lbs';

    return Column(
      children: [
        SectionHeader(title: 'Weight Tracking'),
        SizedBox(height: AppSpacing.lg),
        CustomCard(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(AppIcons.scale, size: 20.r, color: context.primaryColor),
                  SizedBox(width: AppSpacing.md),
                  Text(
                    'Log Your Weight',
                    style: AppTextStyles.h4.copyWith(color: context.foreground, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xl),
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
                      label: 'Weight ($unit)',
                      hint: 'e.g., 175',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: double.tryParse(_weightController.text) != null
                                ? () async {
                                    final weight = double.tryParse(_weightController.text);
                                    if (weight != null) {
                                      final uid = ref.read(currentUidProvider);
                                      if (uid != null) {
                                        final entry = WeightEntry(
                                          id: const Uuid().v4(),
                                          date: DateTime.now(),
                                          weight: weight,
                                          unit: unit,
                                        );
                                        await ref.read(weightEntryRepositoryProvider).addWeightEntry(uid, entry);
                                      }
                                    }
                                    _weightController.clear();
                                    setState(() => _showWeightLog = false);
                                  }
                                : null,
                            child: const Text('Save'),
                          ),
                        ),
                        SizedBox(width: AppSpacing.md),
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
              SizedBox(height: AppSpacing.xl),
              Divider(color: context.mutedForeground.withOpacity(0.15)),
              SizedBox(height: AppSpacing.lg),
              Text('Recent Entries', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
              SizedBox(height: AppSpacing.md),
              _buildWeightEntries(context, unit),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeightEntries(BuildContext context, String unit) {
    return ref.watch(weightEntriesProvider).when(
      data: (entries) {
        if (entries.isNotEmpty) {
          return Column(
            children: entries.take(5).map((e) => Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${e.date.month}/${e.date.day}/${e.date.year}',
                    style: AppTextStyles.bodySmall.copyWith(color: context.foreground),
                  ),
                  Text(
                    '${e.weight} ${e.unit}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )).toList(),
          );
        }
        return _buildSampleWeightEntries(context, unit);
      },
      loading: () => Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => _buildSampleWeightEntries(context, unit),
    );
  }

  Widget _buildSampleWeightEntries(BuildContext context, String unit) {
    return Column(
      children: SampleData.weightEntries.map((e) => Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              e['date'] as String,
              style: AppTextStyles.bodySmall.copyWith(color: context.foreground),
            ),
            Text(
              '${e['weight']} $unit',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final trackPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
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
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress || old.color != color;
}
