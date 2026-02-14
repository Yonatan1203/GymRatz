class WeightEntry {
  final String id;
  final DateTime date;
  final double weight;
  final String unit;

  const WeightEntry({
    required this.id,
    required this.date,
    required this.weight,
    this.unit = 'lbs',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'weight': weight,
        'unit': unit,
      };

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        weight: (json['weight'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] as String? ?? 'lbs',
      );

  WeightEntry copyWith({
    String? id,
    DateTime? date,
    double? weight,
    String? unit,
  }) =>
      WeightEntry(
        id: id ?? this.id,
        date: date ?? this.date,
        weight: weight ?? this.weight,
        unit: unit ?? this.unit,
      );
}
