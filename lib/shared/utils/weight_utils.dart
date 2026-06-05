/// Helpers for converting and displaying weight values.
class WeightUtils {
  WeightUtils._();

  static const double _lbsToKg = 0.453592;
  static const double _kgToLbs = 2.20462;

  /// Convert [weight] from [fromUnit] to [toUnit].
  /// Returns [weight] unchanged when units are the same or unrecognised.
  static double convert(double weight, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return weight;
    if (fromUnit == 'lbs' && toUnit == 'kg') {
      return double.parse((weight * _lbsToKg).toStringAsFixed(1));
    }
    if (fromUnit == 'kg' && toUnit == 'lbs') {
      return double.parse((weight * _kgToLbs).toStringAsFixed(1));
    }
    return weight;
  }

  /// Format a weight value with its unit label, rounding to one decimal when
  /// needed (whole numbers are displayed without a decimal point).
  static String format(double weight, String unit) {
    if (weight == weight.roundToDouble()) {
      return '${weight.toInt()} $unit';
    }
    return '${weight.toStringAsFixed(1)} $unit';
  }
}
