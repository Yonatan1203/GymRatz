/// A single body-measurement snapshot (GYM-114).
class BodyMeasurement {
  final String id;
  final DateTime date;

  /// All measurements stored in the user's preferred unit (cm or inches).
  final double? waist;
  final double? chest;
  final double? hips;
  final double? thighs;
  final double? arms;
  final String unit; // 'cm' or 'in'

  const BodyMeasurement({
    required this.id,
    required this.date,
    this.waist,
    this.chest,
    this.hips,
    this.thighs,
    this.arms,
    this.unit = 'cm',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'waist': waist,
        'chest': chest,
        'hips': hips,
        'thighs': thighs,
        'arms': arms,
        'unit': unit,
      };

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) =>
      BodyMeasurement(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        waist: (json['waist'] as num?)?.toDouble(),
        chest: (json['chest'] as num?)?.toDouble(),
        hips: (json['hips'] as num?)?.toDouble(),
        thighs: (json['thighs'] as num?)?.toDouble(),
        arms: (json['arms'] as num?)?.toDouble(),
        unit: json['unit'] as String? ?? 'cm',
      );

  BodyMeasurement copyWith({
    String? id,
    DateTime? date,
    double? waist,
    double? chest,
    double? hips,
    double? thighs,
    double? arms,
    String? unit,
  }) =>
      BodyMeasurement(
        id: id ?? this.id,
        date: date ?? this.date,
        waist: waist ?? this.waist,
        chest: chest ?? this.chest,
        hips: hips ?? this.hips,
        thighs: thighs ?? this.thighs,
        arms: arms ?? this.arms,
        unit: unit ?? this.unit,
      );
}
