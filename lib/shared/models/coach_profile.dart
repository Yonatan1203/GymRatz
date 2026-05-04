class CoachProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? bio;
  final List<String> specializations;
  final String planTier;
  final int clientCount;
  final int maxClients;
  final DateTime? approvedAt;
  final DateTime createdAt;

  const CoachProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.bio,
    this.specializations = const [],
    required this.planTier,
    this.clientCount = 0,
    this.maxClients = 5,
    this.approvedAt,
    required this.createdAt,
  });

  bool get isFull => clientCount >= maxClients;

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'bio': bio,
        'specializations': specializations,
        'planTier': planTier,
        'clientCount': clientCount,
        'maxClients': maxClients,
        'approvedAt': approvedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory CoachProfile.fromJson(Map<String, dynamic> json) => CoachProfile(
        uid: json['uid'] as String,
        displayName: json['displayName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        bio: json['bio'] as String?,
        specializations: (json['specializations'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        planTier: json['planTier'] as String? ?? 'coach_5',
        clientCount: json['clientCount'] as int? ?? 0,
        maxClients: json['maxClients'] as int? ?? 5,
        approvedAt: json['approvedAt'] != null
            ? DateTime.tryParse(json['approvedAt'] as String)
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );

  CoachProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? bio,
    List<String>? specializations,
    String? planTier,
    int? clientCount,
    int? maxClients,
    DateTime? approvedAt,
    DateTime? createdAt,
  }) =>
      CoachProfile(
        uid: uid ?? this.uid,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        bio: bio ?? this.bio,
        specializations: specializations ?? this.specializations,
        planTier: planTier ?? this.planTier,
        clientCount: clientCount ?? this.clientCount,
        maxClients: maxClients ?? this.maxClients,
        approvedAt: approvedAt ?? this.approvedAt,
        createdAt: createdAt ?? this.createdAt,
      );
}
