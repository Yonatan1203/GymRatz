import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';

import '../../../app/providers.dart';
import '../../../shared/models/enums.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/utils/platform_adapter.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/menu_item_widget.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stats_grid.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String _chartView = 'Exercise Progress';
  String _selectedExercise = 'All';

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(workoutStatsProvider).valueOrNull;
    final prs = ref.watch(personalRecordsProvider).valueOrNull;

    final totalWorkouts = stats?['totalWorkouts'] as int? ?? 0;
    final streak = stats?['streak'] as int? ?? 0;
    final prCount = prs?.length ?? 0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(workoutStatsProvider);
          ref.invalidate(personalRecordsProvider);
          ref.invalidate(weeklyVolumeProvider);
          ref.invalidate(recentWorkoutsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
          children: [
            GradientHeader(
              showBackButton: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Progress', style: AppTextStyles.h1.copyWith(color: context.foreground)),
                  SizedBox(height: 16.h),
                  StatsGrid(
                    useTransparentBg: true,
                    items: [
                      StatsGridItem(icon: AppIcons.dumbbell, iconColor: context.foreground, value: '$totalWorkouts', label: 'Total'),
                      StatsGridItem(icon: AppIcons.flame, iconColor: context.foreground, value: '$streak', label: 'Streak'),
                      StatsGridItem(icon: AppIcons.trophy, iconColor: context.foreground, value: '$prCount', label: 'New PRs'),
                    ],
                  ),
                ],
              ),
            ),
            if (totalWorkouts == 0 && streak == 0 && prCount == 0)
              Padding(
                padding: EdgeInsets.all(AppSpacing.screenPadding),
                child: EmptyStateWidget(
                  icon: AppIcons.barChart2,
                  title: 'No progress data yet',
                  subtitle: 'Complete your first workout to start tracking your progress',
                ),
              )
            else
              Padding(
                padding: EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  children: [
                    _buildViewToggle(context),
                    SizedBox(height: 16.h),
                    if (_chartView == 'Exercise Progress') ...[
                      _buildExerciseFilters(context),
                      SizedBox(height: 16.h),
                      _buildChart(context),
                    ] else if (_chartView == 'Body Weight') ...[
                      _buildBodyWeightChart(context),
                      SizedBox(height: 16.h),
                      _buildWeightSummary(context),
                    ] else ...[
                      _buildBodyMeasurementsEntry(context),
                    ],
                    SizedBox(height: AppSpacing.sectionGap),
                    _buildPRSection(context),
                    SizedBox(height: AppSpacing.sectionGap),
                    _buildRecentWorkouts(context),
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

  Widget _buildBodyMeasurementsEntry(BuildContext context) {
    final asyncMeasurements = ref.watch(bodyMeasurementsProvider);
    final count = asyncMeasurements.valueOrNull?.length ?? 0;

    return CustomCard(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: MenuItemWidget(
        icon: AppIcons.ruler,
        label: 'Body Measurements${count > 0 ? ' ($count entries)' : ''}',
        onTap: () => context.push('/progress/body-measurements'),
      ),
    );
  }

  Widget _buildViewToggle(BuildContext context) {
    return Row(
      children: ['Exercise Progress', 'Body Weight', 'Measurements'].map((v) {
        final isSelected = _chartView == v;
        return Expanded(
          child: Semantics(
            button: true,
            label: v,
            selected: isSelected,
            child: GestureDetector(
              onTap: () {
                PlatformAdapter.hapticSelection();
                setState(() => _chartView = v);
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                decoration: BoxDecoration(
                  color: isSelected ? context.primaryColor : context.mutedColor,
                  borderRadius: AppRadius.borderLg,
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(v, style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? Colors.white : context.mutedForeground,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    )),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExerciseFilters(BuildContext context) {
    final filters = ref.watch(exerciseFilterProvider);
    final isAll = _selectedExercise == 'All';

    return GestureDetector(
      onTap: () => _showExercisePicker(context, filters),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isAll ? context.mutedColor : context.primaryColor.withValues(alpha: 0.12),
          borderRadius: AppRadius.borderFull,
          border: Border.all(
            color: isAll ? context.borderColor : context.primaryColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.dumbbell,
              size: 14.r,
              color: isAll ? context.mutedForeground : context.primaryColor,
            ),
            SizedBox(width: 8.w),
            Text(
              _selectedExercise,
              style: AppTextStyles.bodySmall.copyWith(
                color: isAll ? context.mutedForeground : context.primaryColor,
                fontWeight: isAll ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16.r,
              color: isAll ? context.mutedForeground : context.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showExercisePicker(BuildContext context, List<String> exercises) async {
    PlatformAdapter.hapticLight();
    final searchController = TextEditingController();
    String query = '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = query.isEmpty
                ? exercises
                : exercises
                    .where((e) => e.toLowerCase().contains(query.toLowerCase()))
                    .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (ctx, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: ctx.cardColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 12.h),
                      Container(
                        width: 36.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: ctx.mutedForeground.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'Select Exercise',
                          style: AppTextStyles.h3.copyWith(color: ctx.foreground),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: TextField(
                          controller: searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search exercises…',
                            hintStyle: AppTextStyles.bodySmall.copyWith(color: ctx.mutedForeground),
                            prefixIcon: Icon(Icons.search_rounded, size: 18.r, color: ctx.mutedForeground),
                            filled: true,
                            fillColor: ctx.mutedColor,
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.borderLg,
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                          ),
                          style: AppTextStyles.body.copyWith(color: ctx.foreground),
                          onChanged: (v) => setModalState(() => query = v),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final name = filtered[i];
                            final isSelected = name == _selectedExercise;
                            return ListTile(
                              title: Text(
                                name,
                                style: AppTextStyles.body.copyWith(
                                  color: isSelected ? ctx.primaryColor : ctx.foreground,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check_rounded, size: 18.r, color: ctx.primaryColor)
                                  : null,
                              onTap: () {
                                PlatformAdapter.hapticSelection();
                                setState(() => _selectedExercise = name);
                                Navigator.of(ctx).pop();
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8.h),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    searchController.dispose();
  }

  Widget _buildChart(BuildContext context) {
    final isDark = context.isDark;
    // Use per-exercise data when a specific exercise is selected; otherwise
    // fall back to the weekly total volume loader so both are async-safe.
    final isAll = _selectedExercise == 'All';
    final chartData = ref.watch(exerciseChartDataProvider(_selectedExercise));
    final weeklyAsync = ref.watch(weeklyVolumeProvider);

    if (isAll) {
      return weeklyAsync.when(
        loading: () => CustomCard(
          child: SizedBox(
            height: 220.h,
            child: Center(child: CircularProgressIndicator(color: context.primaryColor)),
          ),
        ),
        error: (_, _) => CustomCard(
          child: SizedBox(
            height: 220.h,
            child: Center(
              child: Text('Failed to load chart data', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
            ),
          ),
        ),
        data: (data) {
          if (data.isEmpty || data.every((d) => (d['value'] as double) == 0)) {
            return _buildEmptyChart(context, 'No workout data yet');
          }
          return _buildLineChart(context, data, isDark, prValue: null, unit: 'vol');
        },
      );
    }

    // Per-exercise: synchronous (derived from recentWorkoutsProvider).
    if (chartData.length < 2) {
      final msg = chartData.isEmpty
          ? 'No data for $_selectedExercise yet'
          : 'Need at least 2 sessions to draw a graph';
      return _buildEmptyChart(context, msg);
    }

    // Find the PR for the selected exercise to draw an annotation line.
    final prs = ref.watch(personalRecordsProvider).valueOrNull ?? [];
    final prForExercise = prs
        .where((p) => p.exerciseName.toLowerCase() == _selectedExercise.toLowerCase())
        .fold<double?>(null, (best, p) => best == null || p.weight > best ? p.weight : best);

    final userUnit = ref.watch(userProfileProvider).valueOrNull?.unit ?? 'lbs';
    return _buildLineChart(context, chartData, isDark, prValue: prForExercise, unit: userUnit);
  }

  Widget _buildLineChart(BuildContext context, List<Map<String, dynamic>> data, bool isDark, {required double? prValue, required String unit}) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final coral = context.coralColor;
    final values = data.map((d) => d['value'] as double).toList();
    final dataMin = values.reduce(min);
    final dataMax = values.reduce(max);
    final range = dataMax - dataMin;
    final padding = range > 0 ? range * 0.2 : max(dataMax * 0.2, 5.0);
    final chartMin = max(0.0, dataMin - padding);
    // Ensure the PR line (if any) fits in the chart.
    final chartMax = prValue != null && prValue > dataMax
        ? prValue + padding
        : dataMax + padding;

    final interval = max(1.0, ((chartMax - chartMin) / 4).roundToDouble());

    // Build optional PR horizontal line.
    final extraLines = <HorizontalLine>[];
    if (prValue != null) {
      extraLines.add(HorizontalLine(
        y: prValue,
        color: coral.withValues(alpha: 0.7),
        strokeWidth: 1.5,
        dashArray: [6, 4],
        label: HorizontalLineLabel(
          show: true,
          alignment: Alignment.topRight,
          padding: EdgeInsets.only(right: 4.w, bottom: 2.h),
          style: AppTextStyles.caption.copyWith(color: coral, fontWeight: FontWeight.w600),
          labelResolver: (_) => 'PR',
        ),
      ));
    }

    return CustomCard(
      child: SizedBox(
        height: 220.h,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (value) => FlLine(
                color: context.borderColor,
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
            ),
            extraLinesData: ExtraLinesData(horizontalLines: extraLines),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.min || value == meta.max) return const SizedBox();
                    final label = unit == 'vol' ? Formatters.volume(value) : '${value.toInt()}';
                    return Text(label, style: AppTextStyles.caption.copyWith(color: context.mutedForeground));
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  // Show at most 6 labels to avoid crowding.
                  interval: max(1, (data.length / 6).ceil()).toDouble(),
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= 0 && idx < data.length) {
                      return Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Text(
                          data[idx]['week'] as String,
                          style: AppTextStyles.caption.copyWith(
                            color: context.mutedForeground,
                            fontSize: 10.sp,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots.map((spot) {
                  final label = unit == 'vol'
                      ? Formatters.volume(spot.y)
                      : Formatters.weight(spot.y, unit);
                  return LineTooltipItem(label, AppTextStyles.caption.copyWith(color: Colors.white));
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i]['value'] as double)),
                isCurved: true,
                color: primary,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(radius: 5, color: primary, strokeWidth: 2, strokeColor: Colors.white),
                ),
                belowBarData: BarAreaData(show: true, color: primary.withValues(alpha: 0.1)),
              ),
            ],
            minY: chartMin,
            maxY: chartMax,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context, String message) {
    return CustomCard(
      child: SizedBox(
        height: 220.h,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.barChart2, size: 40.r, color: context.mutedForeground.withValues(alpha:0.6)),
              SizedBox(height: 12.h),
              Text(message, style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyWeightChart(BuildContext context) {
    final isDark = context.isDark;
    final asyncEntries = ref.watch(weightEntriesProvider);

    return asyncEntries.when(
      loading: () => CustomCard(
        child: SizedBox(
          height: 220.h,
          child: Center(child: CircularProgressIndicator(color: context.primaryColor)),
        ),
      ),
      error: (_, _) => CustomCard(
        child: SizedBox(
          height: 220.h,
          child: Center(
            child: Text('Failed to load weight data', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
          ),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return _buildEmptyChart(context, 'No weight entries yet');
        }

        final sorted = entries.toList()..sort((a, b) => a.date.compareTo(b.date));
        final recent = sorted.length > 30 ? sorted.sublist(sorted.length - 30) : sorted;
        final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
        final weights = recent.map((e) => e.weight).toList();
        final dataMin = weights.reduce(min);
        final dataMax = weights.reduce(max);
        final pad = max(2.0, (dataMax - dataMin) * 0.2);
        final chartMin = max(0.0, dataMin - pad);
        final chartMax = dataMax + pad;

        return CustomCard(
          child: SizedBox(
            height: 220.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: max(1.0, ((chartMax - chartMin) / 4).roundToDouble()),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: context.borderColor,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.min || value == meta.max) return const SizedBox();
                        return Text('${value.toInt()}', style: AppTextStyles.caption.copyWith(color: context.mutedForeground));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: max(1, (recent.length / 5).ceil()).toDouble(),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < recent.length) {
                          final d = recent[idx].date;
                          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                          return Padding(
                            padding: EdgeInsets.only(top: 8.h),
                            child: Text('${months[d.month - 1]} ${d.day}', style: AppTextStyles.caption.copyWith(color: context.mutedForeground, fontSize: 10.sp)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((spot) {
                      final idx = spot.x.toInt();
                      final unit = idx < recent.length ? recent[idx].unit : 'lbs';
                      return LineTooltipItem(
                        Formatters.weight(spot.y, unit),
                        AppTextStyles.caption.copyWith(color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(recent.length, (i) => FlSpot(i.toDouble(), recent[i].weight)),
                    isCurved: true,
                    color: accent,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(radius: 4, color: accent, strokeWidth: 2, strokeColor: Colors.white),
                    ),
                    belowBarData: BarAreaData(show: true, color: accent.withValues(alpha: 0.1)),
                  ),
                ],
                minY: chartMin,
                maxY: chartMax,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeightSummary(BuildContext context) {
    final entries = ref.watch(weightEntriesProvider).valueOrNull;
    if (entries == null || entries.isEmpty) return const SizedBox.shrink();

    final sorted = entries.toList()..sort((a, b) => b.date.compareTo(a.date));
    final latest = sorted.first;
    final change = sorted.length >= 2 ? latest.weight - sorted[1].weight : null;

    return CustomCard(
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          SizedBox(
            width: 44.r,
            height: 44.r,
            child: Center(child: Icon(AppIcons.scale, size: 22.r, color: context.primaryColor)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Weight', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
                SizedBox(height: 2.h),
                Text(Formatters.weight(latest.weight, latest.unit), style: AppTextStyles.h3.copyWith(color: context.foreground, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (change != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: (change <= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.1),
                borderRadius: AppRadius.borderFull,
              ),
              child: Text(
                '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} ${latest.unit}',
                style: AppTextStyles.caption.copyWith(
                  color: change <= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPRSection(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final unit = profile?.unit ?? 'lbs';
    final asyncPrs = ref.watch(personalRecordsProvider);

    return asyncPrs.when(
      loading: () => Column(
        children: [
          const SectionHeader(title: 'Personal Records'),
          SizedBox(height: AppSpacing.lg),
          SizedBox(height: 60.h, child: Center(child: CircularProgressIndicator(color: context.primaryColor))),
        ],
      ),
      error: (_, _) => Column(
        children: [
          const SectionHeader(title: 'Personal Records'),
          SizedBox(height: AppSpacing.lg),
          Center(child: Text('Failed to load PRs', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground))),
        ],
      ),
      data: (prsList) {
        final filtered = _selectedExercise == 'All' || _chartView != 'Exercise Progress'
            ? prsList
            : prsList.where((p) => p.exerciseName.toLowerCase().contains(_selectedExercise.toLowerCase())).toList();

        return Column(
          children: [
            const SectionHeader(title: 'Personal Records'),
            SizedBox(height: AppSpacing.lg),
            if (filtered.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Column(
                  children: [
                    Icon(AppIcons.trophy, size: 36.r, color: context.mutedForeground.withValues(alpha:0.6)),
                    SizedBox(height: 8.h),
                    Text(
                      prsList.isEmpty ? 'No personal records yet' : 'No PRs for this exercise',
                      style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground),
                    ),
                  ],
                ),
              )
            else
              ...filtered.map((pr) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: CustomCard(
                  padding: EdgeInsets.all(12.r),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40.r,
                        height: 40.r,
                        child: Center(child: Icon(AppIcons.trophy, size: 20.r, color: context.primaryColor)),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pr.exerciseName, style: AppTextStyles.bodySmall.copyWith(color: context.foreground, fontWeight: FontWeight.w500)),
                            Text(Formatters.dayDate(pr.date), style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(Formatters.weight(pr.weight, unit), style: AppTextStyles.h4.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600)),
                          Text('${pr.reps} rep${pr.reps == 1 ? '' : 's'}', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
          ],
        );
      },
    );
  }

  Widget _buildRecentWorkouts(BuildContext context) {
    final asyncWorkouts = ref.watch(recentWorkoutsProvider);

    return asyncWorkouts.when(
      loading: () => Column(
        children: [
          const SectionHeader(title: 'Recent Workouts'),
          SizedBox(height: AppSpacing.lg),
          SizedBox(height: 60.h, child: Center(child: CircularProgressIndicator(color: context.primaryColor))),
        ],
      ),
      error: (_, _) => Column(
        children: [
          const SectionHeader(title: 'Recent Workouts'),
          SizedBox(height: AppSpacing.lg),
          Center(child: Text('Failed to load workouts', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground))),
        ],
      ),
      data: (workouts) {
        final completed = workouts.where((w) => w.status == WorkoutStatus.completed).take(5).toList();

        return Column(
          children: [
            const SectionHeader(title: 'Recent Workouts'),
            SizedBox(height: AppSpacing.lg),
            if (completed.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Column(
                  children: [
                    Icon(AppIcons.dumbbell, size: 36.r, color: context.mutedForeground.withValues(alpha:0.6)),
                    SizedBox(height: 8.h),
                    Text('No workouts logged yet', style: AppTextStyles.bodySmall.copyWith(color: context.mutedForeground)),
                  ],
                ),
              )
            else
              ...completed.map((w) {
                final names = w.exercises.map((e) => e.name).toList();
                final display = names.length <= 2
                    ? names.join(', ')
                    : '${names.take(2).join(', ')} +${names.length - 2} more';

                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: CustomCard(
                    padding: EdgeInsets.all(12.r),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40.r,
                          height: 40.r,
                          child: Center(child: Icon(AppIcons.dumbbell, size: 20.r, color: context.primaryColor)),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(display, style: AppTextStyles.bodySmall.copyWith(color: context.foreground, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(Formatters.dayDate(w.date), style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(Formatters.volume(w.totalVolume), style: AppTextStyles.bodySmall.copyWith(color: context.foreground, fontWeight: FontWeight.w600)),
                            Text(Formatters.duration(w.duration ~/ 60), style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
