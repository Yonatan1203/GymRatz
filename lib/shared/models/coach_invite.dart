class CoachInvite {
  final String id;
  final String code;
  final String? clientEmail;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;

  const CoachInvite({
    required this.id,
    required this.code,
    this.clientEmail,
    this.status = 'pending',
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isPending => status == 'pending' && !isExpired;

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'clientEmail': clientEmail,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory CoachInvite.fromJson(Map<String, dynamic> json) => CoachInvite(
        id: json['id'] as String,
        code: json['code'] as String? ?? '',
        clientEmail: json['clientEmail'] as String?,
        status: json['status'] as String? ?? 'pending',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : DateTime.now().add(const Duration(days: 7)),
      );

  CoachInvite copyWith({
    String? id,
    String? code,
    String? clientEmail,
    String? status,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) =>
      CoachInvite(
        id: id ?? this.id,
        code: code ?? this.code,
        clientEmail: clientEmail ?? this.clientEmail,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
      );
}
