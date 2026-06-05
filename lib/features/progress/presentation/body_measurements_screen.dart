import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../shared/models/body_measurement.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/utils/extensions.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/custom_input.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/gradient_header.dart';

/// Colour palette for each measurement type.
const _measurementColors = <String, Color>{
  'Waist': Color(0xFF6C63FF),
  'Chest': Color(0xFF10B981),
  'Hips': Color(0xFFF59E0B),
  'Thighs': Color(0xFFEF4444),
  'Arms': Color(0xFF3B82F6),
};

const _measurementKeys = ['Waist', 'Chest', 'Hips', 'Thighs', 'Arms'];

/// Returns the measurement value for a given label from a [BodyMeasurement].
double? _getValue(BodyMeasurement m, String label) {
  switch (label) {
    case 'Waist':
      return m.waist;
    case 'Chest':
      return m.chest;
    case 'Hips':
      return m.hips;
    case 'Thighs':
      return m.thighs;
    case 'Arms':
      return m.arms;
    default:
      return null;
  }
}

/// Body measurements tracking screen (GYM-114).
///
/// Shows a line chart per selected measurement over time and allows
/// the user to log new measurements.
class BodyMeasurementsScreen extends ConsumerStatefulWidget {
  const BodyMeasurementsScreen({super.key});

  @override
  ConsumerState<BodyMeasurementsScreen> createState() =>
      _BodyMeasurementsScreenState();
}

class _BodyMeasurementsScreenState
    extends ConsumerState<BodyMeasurementsScreen> {
  String _selected = 'Waist';

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final asyncMeasurements = ref.watch(bodyMeasurementsProvider);
    final unit = ref.watch(userProfileProvider).valueOrNull?.unit == 'kg'
        ? 'cm'
        : 'in';

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              showBackButton: true,
              child: Text(
                'Body Measurements',
                style: AppTextStyles.h1.copyWith(color: context.foreground),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMeasurementSelector(context),
                  SizedBox(height: 16.h),
                  asyncMeasurements.when(
                    loading: () => CustomCard(
                      child: SizedBox(
                        height: 220.h,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: context.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    error: (_, _) => CustomCard(
                      child: SizedBox(
                        height: 220.h,
                        child: Center(
                          child: Text(
                            'Failed to load data',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: context.mutedForeground),
                          ),
                        ),
                      ),
                    ),
                    data: (measurements) {
                      final sorted = measurements.toList()
                        ..sort((a, b) => a.date.compareTo(b.date));
                      final withValue = sorted
                          .where((m) => _getValue(m, _selected) != null)
                          .toList();

                      if (withValue.isEmpty) {
                        return EmptyStateWidget(
                          icon: AppIcons.ruler,
                          title: 'No $_selected measurements yet',
                          subtitle: 'Log your first measurement below',
                        );
                      }
                      return _buildChart(context, withValue, isDark, unit);
                    },
                  ),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildLogForm(context, unit),
                  SizedBox(height: AppSpacing.sectionGap),
                  asyncMeasurements.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (measurements) =>
                        _buildHistoryList(context, measurements, unit),
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementSelector(BuildContext context) {
    return SizedBox(
      height: 36.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _measurementKeys.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final label = _measurementKeys[index];
          final isSelected = _selected == label;
          final color = _measurementColors[label] ?? context.primaryColor;
          return GestureDetector(
            onTap: () => setState(() => _selected = label),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: isSelected ? color : context.cardColor,
                borderRadius: AppRadius.borderFull,
                border: isSelected
                    ? null
                    : Border.all(color: context.borderColor),
              ),
              child: Center(
                child: Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? Colors.white : context.mutedForeground,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<BodyMeasurement> measurements,
    bool isDark,
    String unit,
  ) {
    final color = _measurementColors[_selected] ?? context.primaryColor;
    final values =
        measurements.map((m) => _getValue(m, _selected)!).toList();
    final dataMin = values.reduce(min);
    final dataMax = values.reduce(max);
    final range = dataMax - dataMin;
    final padding = range > 0 ? range * 0.2 : dataMax * 0.1;
    final chartMin = max(0.0, dataMin - padding);
    final chartMax = dataMax + padding;
    final interval = max(1.0, ((chartMax - chartMin) / 4).roundToDouble());

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
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.min || value == meta.max) {
                      return const SizedBox();
                    }
                    return Text(
                      '${value.toStringAsFixed(1)}$unit',
                      style: AppTextStyles.caption
                          .copyWith(color: context.mutedForeground),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: max(
                    1,
                    (measurements.length / 5).ceil(),
                  ).toDouble(),
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= measurements.length) {
                      return const SizedBox();
                    }
                    final d = measurements[idx].date;
                    final months = [
                      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
                    ];
                    return Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Text(
                        '${months[d.month - 1]} ${d.day}',
                        style: AppTextStyles.caption.copyWith(
                          color: context.mutedForeground,
                          fontSize: 10.sp,
                        ),
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)} $unit',
                    AppTextStyles.caption.copyWith(color: Colors.white),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  measurements.length,
                  (i) => FlSpot(
                    i.toDouble(),
                    _getValue(measurements[i], _selected)!,
                  ),
                ),
                isCurved: true,
                color: color,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: color,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData:
                    BarAreaData(show: true, color: color.withValues(alpha: 0.1)),
              ),
            ],
            minY: chartMin,
            maxY: chartMax,
          ),
        ),
      ),
    );
  }

  Widget _buildLogForm(BuildContext context, String unit) {
    return _LogMeasurementForm(unit: unit);
  }

  Widget _buildHistoryList(
    BuildContext context,
    List<BodyMeasurement> measurements,
    String unit,
  ) {
    if (measurements.isEmpty) return const SizedBox.shrink();

    final sorted = measurements.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final recent = sorted.take(10).toList();

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT ENTRIES',
          style: AppTextStyles.caption.copyWith(
            color: context.mutedForeground,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 8.h),
        ...recent.map((m) {
          final d = m.date;
          final dateStr = '${months[d.month - 1]} ${d.day}, ${d.year}';
          final v = _getValue(m, _selected);
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: CustomCard(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  Icon(
                    AppIcons.ruler,
                    size: 18.r,
                    color: _measurementColors[_selected] ?? context.primaryColor,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      dateStr,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: context.foreground),
                    ),
                  ),
                  if (v != null)
                    Text(
                      '${v.toStringAsFixed(1)} $unit',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Text(
                      '—',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: context.mutedForeground),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// Inline form to log a new body measurement.
class _LogMeasurementForm extends ConsumerStatefulWidget {
  final String unit;
  const _LogMeasurementForm({required this.unit});

  @override
  ConsumerState<_LogMeasurementForm> createState() =>
      _LogMeasurementFormState();
}

class _LogMeasurementFormState extends ConsumerState<_LogMeasurementForm> {
  final _waistCtrl = TextEditingController();
  final _chestCtrl = TextEditingController();
  final _hipsCtrl = TextEditingController();
  final _thighsCtrl = TextEditingController();
  final _armsCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _waistCtrl.dispose();
    _chestCtrl.dispose();
    _hipsCtrl.dispose();
    _thighsCtrl.dispose();
    _armsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    final waist = double.tryParse(_waistCtrl.text);
    final chest = double.tryParse(_chestCtrl.text);
    final hips = double.tryParse(_hipsCtrl.text);
    final thighs = double.tryParse(_thighsCtrl.text);
    final arms = double.tryParse(_armsCtrl.text);

    if ([waist, chest, hips, thighs, arms].every((v) => v == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one measurement')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final measurement = BodyMeasurement(
        id: const Uuid().v4(),
        date: DateTime.now(),
        waist: waist,
        chest: chest,
        hips: hips,
        thighs: thighs,
        arms: arms,
        unit: widget.unit,
      );
      await ref
          .read(bodyMeasurementRepositoryProvider)
          .addMeasurement(uid, measurement);
      _waistCtrl.clear();
      _chestCtrl.clear();
      _hipsCtrl.clear();
      _thighsCtrl.clear();
      _armsCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Measurements saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.unit;
    return CustomCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log New Measurement',
            style: AppTextStyles.h4
                .copyWith(color: context.foreground, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: CustomInput(
                  controller: _waistCtrl,
                  label: 'Waist ($u)',
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: CustomInput(
                  controller: _chestCtrl,
                  label: 'Chest ($u)',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: CustomInput(
                  controller: _hipsCtrl,
                  label: 'Hips ($u)',
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: CustomInput(
                  controller: _thighsCtrl,
                  label: 'Thighs ($u)',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: 160.w,
            child: CustomInput(
              controller: _armsCtrl,
              label: 'Arms ($u)',
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(height: 16.h),
          CustomButton(
            text: 'Save Measurements',
            variant: ButtonVariant.gradient,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
    );
  }
}
