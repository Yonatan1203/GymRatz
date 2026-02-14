class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final int progress;
  final int total;
  final bool unlocked;
  final DateTime? unlockedDate;
  final String rarity;
  final int points;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.progress,
    required this.total,
    this.unlocked = false,
    this.unlockedDate,
    required this.rarity,
    required this.points,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'iconName': iconName,
        'progress': progress,
        'total': total,
        'unlocked': unlocked,
        'unlockedDate': unlockedDate?.toIso8601String(),
        'rarity': rarity,
        'points': points,
      };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        iconName: json['iconName'] as String? ?? '',
        progress: json['progress'] as int? ?? 0,
        total: json['total'] as int? ?? 1,
        unlocked: json['unlocked'] as bool? ?? false,
        unlockedDate: json['unlockedDate'] != null
            ? DateTime.tryParse(json['unlockedDate'] as String)
            : null,
        rarity: json['rarity'] as String? ?? 'Common',
        points: json['points'] as int? ?? 0,
      );

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconName,
    int? progress,
    int? total,
    bool? unlocked,
    DateTime? unlockedDate,
    String? rarity,
    int? points,
  }) =>
      Achievement(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        iconName: iconName ?? this.iconName,
        progress: progress ?? this.progress,
        total: total ?? this.total,
        unlocked: unlocked ?? this.unlocked,
        unlockedDate: unlockedDate ?? this.unlockedDate,
        rarity: rarity ?? this.rarity,
        points: points ?? this.points,
      );
}
