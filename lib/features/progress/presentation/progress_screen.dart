import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/utils/platform_adapter.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stats_grid.dart';
import '../../../shared/data/sample_data.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String _chartView = 'Exercise Progress';
  String _selectedExercise = 'All';
  String _selectedMetric = 'Volume';

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final stats = ref.watch(workoutStatsProvider).valueOrNull;
    final prs = ref.watch(personalRecordsProvider).valueOrNull;

    final totalWorkouts = stats?['totalWorkouts'] as int? ?? 0;
    final streak = stats?['streak'] as int? ?? 0;
    final prCount = prs?.length ?? 0;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              showBackButton: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Progress', style: AppTextStyles.h1.copyWith(color: Colors.white)),
                  SizedBox(height: 16.h),
                  StatsGrid(
                    useTransparentBg: true,
                    items: [
                      StatsGridItem(icon: LucideIcons.dumbbell, iconColor: Colors.white, value: '$totalWorkouts', label: 'Total'),
                      StatsGridItem(icon: LucideIcons.flame, iconColor: Colors.white, value: '$streak', label: 'Streak'),
                      StatsGridItem(icon: LucideIcons.trophy, iconColor: Colors.white, value: '$prCount', label: 'New PRs'),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                children: [
                  _buildViewToggle(context),
                  SizedBox(height: 16.h),
                  _buildExerciseFilters(context),
                  SizedBox(height: 16.h),
                  _buildChart(context, isDark),
                  SizedBox(height: 16.h),
                  _buildMetricButtons(context),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildPRSection(context),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildBodyMetrics(context),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle(BuildContext context) {
    return Row(
      children: ['Exercise Progress', 'Body Weight'].map((v) {
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
                child: Text(v, style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? Colors.white : context.mutedForeground,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                )),
              ),
            ),
          ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExerciseFilters(BuildContext context) {
    final filters = ['All', 'Bench', 'Squat', 'Deadlift', 'OHP'];
    return SizedBox(
      height: 36.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final isSelected = _selectedExercise == filters[index];
          return Semantics(
            button: true,
            label: filters[index],
            selected: isSelected,
            child: GestureDetector(
              onTap: () {
                PlatformAdapter.hapticSelection();
                setState(() => _selectedExercise = filters[index]);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: isSelected ? context.primaryColor : context.cardColor,
                  borderRadius: AppRadius.borderFull,
                  border: isSelected ? null : Border.all(color: context.borderColor),
                ),
                child: Center(
                  child: Text(filters[index], style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? Colors.white : context.mutedForeground,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  )),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChart(BuildContext context, bool isDark) {
    final volumeData = ref.watch(weeklyVolumeProvider).valueOrNull;
    final data = (volumeData != null && volumeData.isNotEmpty) ? volumeData : SampleData.volumeData;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return CustomCard(
      child: SizedBox(
        height: 220.h,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 3000,
              getDrawingHorizontalLine: (value) => FlLine(color: context.borderColor, strokeWidth: 1, dashArray: [5, 5]),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text('${(value / 1000).toStringAsFixed(0)}k', style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= 0 && idx < data.length) {
                      return Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Text(data[idx]['week'] as String, style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
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
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i]['value'] as double)),
                isCurved: true,
                color: primary,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 5, color: primary, strokeWidth: 2, strokeColor: Colors.white),
                ),
                belowBarData: BarAreaData(show: true, color: primary.withValues(alpha: 0.1)),
              ),
            ],
            minY: 6000,
            maxY: 14000,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricButtons(BuildContext context) {
    final metrics = ['Volume', 'Frequency', 'Intensity'];
    return Row(
      children: metrics.map((m) {
        final isSelected = _selectedMetric == m;
        return Expanded(
          child: Semantics(
            button: true,
            label: m,
            selected: isSelected,
            child: GestureDetector(
              onTap: () {
                PlatformAdapter.hapticSelection();
                setState(() => _selectedMetric = m);
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                decoration: BoxDecoration(
                  color: isSelected ? context.primaryColor.withValues(alpha: 0.15) : context.mutedColor,
                  borderRadius: AppRadius.borderLg,
                  border: isSelected ? Border.all(color: context.primaryColor) : null,
                ),
                child: Center(
                  child: Text(m, style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? context.primaryColor : context.mutedForeground,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  )),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPRSection(BuildContext context) {
    final prsList = ref.watch(personalRecordsProvider).valueOrNull;
    final prList = (prsList != null && prsList.isNotEmpty)
        ? prsList
            .map((p) => {
                  'exercise': p.exerciseName,
                  'weight': p.weight.toInt(),
                  'unit': 'lbs',
                  'date': '${p.date.month}/${p.date.day}/${p.date.year}',
                })
            .toList()
        : SampleData.personalRecords;

    return Column(
      children: [
        const SectionHeader(title: 'Personal Records'),
        SizedBox(height: AppSpacing.lg),
        ...prList.map((pr) => Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: CustomCard(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                Container(
                  width: 40.r, height: 40.r,
                  decoration: BoxDecoration(color: context.primaryColor.withValues(alpha: 0.2), borderRadius: AppRadius.borderLg),
                  child: Icon(LucideIcons.trophy, size: 20.r, color: context.primaryColor),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pr['exercise'] as String, style: AppTextStyles.bodySmall.copyWith(color: context.foreground, fontWeight: FontWeight.w500)),
                      Text(pr['date'] as String, style: AppTextStyles.caption.copyWith(color: context.mutedForeground)),
                    ],
                  ),
                ),
                Text('${pr['weight']} ${pr['unit']}', style: AppTextStyles.h4.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildBodyMetrics(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(title: 'Body Metrics'),
        SizedBox(height: AppSpacing.lg),
        _metricRow(context, 'Body Weight', '175.2 lbs', '\u2193 1.6 lbs', true),
        _metricRow(context, 'Body Fat %', '15.2%', '\u2193 0.8%', true),
        _metricRow(context, 'Muscle Mass', '145 lbs', '\u2191 1.2 lbs', true),
      ],
    );
  }

  Widget _metricRow(BuildContext context, String label, String value, String change, bool positive) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: CustomCard(
        padding: EdgeInsets.all(12.r),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.body.copyWith(color: context.foreground))),
            Text(value, style: AppTextStyles.h4.copyWith(color: context.foreground, fontWeight: FontWeight.w600)),
            SizedBox(width: 8.w),
            Text(change, style: AppTextStyles.caption.copyWith(color: positive ? Colors.green : context.destructiveColor)),
          ],
        ),
      ),
    );
  }
}
