import 'dart:math';

import '../../../shared/models/enums.dart';

enum RoundMode { nearest, down, up }

class LoadQuantizer {
  /// Snap a target weight to the nearest achievable increment for the equipment.
  static double snap(double target, EquipmentType equipment, String unit,
      {RoundMode mode = RoundMode.nearest}) {
    final increment = minIncrement(equipment, unit);
    if (increment <= 0) return target;
    switch (mode) {
      case RoundMode.nearest:
        return (target / increment).round() * increment;
      case RoundMode.down:
        return (target / increment).floor() * increment;
      case RoundMode.up:
        return (target / increment).ceil() * increment;
    }
  }

  /// Minimum weight increment for the equipment type.
  static double minIncrement(EquipmentType equipment, String unit) {
    final isKg = unit.toLowerCase() == 'kg';
    switch (equipment) {
      case EquipmentType.barbell:
        return isKg ? 2.5 : 5.0;
      case EquipmentType.dumbbell:
        return isKg ? 2.0 : 5.0;
      case EquipmentType.machineStack:
        return isKg ? 5.0 : 10.0;
      case EquipmentType.machinePlateLoaded:
        return isKg ? 2.5 : 5.0;
      case EquipmentType.bodyweight:
        return isKg ? 2.5 : 5.0;
    }
  }

  /// Check if a proposed jump exceeds the weekly cap (default 10%).
  static bool exceedsWeeklyCap(double currentWeight, double newWeight,
      {double maxPercent = 10.0}) {
    if (currentWeight <= 0) return false;
    final percentChange = ((newWeight - currentWeight) / currentWeight) * 100;
    return percentChange > maxPercent;
  }

  /// Clamp a proposed weight to stay within the weekly cap.
  static double clampToWeeklyCap(
      double currentWeight, double proposed, EquipmentType equipment, String unit,
      {double maxPercent = 10.0}) {
    if (!exceedsWeeklyCap(currentWeight, proposed, maxPercent: maxPercent)) {
      return proposed;
    }
    final maxAllowed = currentWeight * (1 + maxPercent / 100);
    return snap(min(proposed, maxAllowed), equipment, unit);
  }
}
