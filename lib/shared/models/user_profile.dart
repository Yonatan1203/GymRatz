import 'enums.dart';

class UserProfile {
  final String? uid;
  final String name;
  final String initials;
  final String email;
  final int age;
  final String height;
  final double weight;
  final String unit;
  final String experienceLevel;
  final String primaryGoal;
  final Set<String> injuries;
  final String? style;
  final bool notificationsEnabled;
  final bool healthEnabled;
  final String? discovery;
  final List<String> favoriteExerciseIds;
  final List<String> favoriteProgramIds;
  final UserRole role;

  /// Complimentary Pro access (e.g. for testers/comps), decoupled from admin
  /// roles so it grants full feature access WITHOUT admin privileges or the
  /// coach experience. Set on the user's Firestore doc to true to grant.
  final bool complimentaryPro;
  final String? coachId;
  final DateTime? coachLinkedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool weekStartsOnMonday;

  const UserProfile({
    this.uid,
    required this.name,
    required this.initials,
    required this.email,
    this.age = 25,
    this.height = '5\'10"',
    this.weight = 175.2,
    this.unit = 'lbs',
    this.experienceLevel = 'Intermediate',
    this.primaryGoal = 'Build Muscle',
    this.injuries = const {},
    this.style,
    this.notificationsEnabled = true,
    this.healthEnabled = false,
    this.discovery,
    this.favoriteExerciseIds = const [],
    this.favoriteProgramIds = const [],
    this.role = UserRole.user,
    this.complimentaryPro = false,
    this.coachId,
    this.coachLinkedAt,
    this.createdAt,
    this.updatedAt,
    this.weekStartsOnMonday = true,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'initials': initials,
        'email': email,
        'age': age,
        'height': height,
        'weight': weight,
        'unit': unit,
        'experienceLevel': experienceLevel,
        'primaryGoal': primaryGoal,
        'injuries': injuries.toList(),
        'style': style,
        'notificationsEnabled': notificationsEnabled,
        'healthEnabled': healthEnabled,
        'discovery': discovery,
        'favoriteExerciseIds': favoriteExerciseIds,
        'favoriteProgramIds': favoriteProgramIds,
        'role': role.value,
        'complimentaryPro': complimentaryPro,
        'coachId': coachId,
        'coachLinkedAt': coachLinkedAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'weekStartsOnMonday': weekStartsOnMonday,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        uid: json['uid'] as String?,
        name: json['name'] as String? ?? '',
        initials: json['initials'] as String? ?? '',
        email: json['email'] as String? ?? '',
        age: json['age'] as int? ?? 25,
        height: json['height'] as String? ?? '5\'10"',
        weight: (json['weight'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] as String? ?? 'lbs',
        experienceLevel: json['experienceLevel'] as String? ?? 'Intermediate',
        primaryGoal: json['primaryGoal'] as String? ?? 'Build Muscle',
        injuries: (json['injuries'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toSet() ??
            {},
        style: json['style'] as String?,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        healthEnabled: json['healthEnabled'] as bool? ?? false,
        discovery: json['discovery'] as String?,
        favoriteExerciseIds: (json['favoriteExerciseIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        favoriteProgramIds: (json['favoriteProgramIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        role: UserRole.fromString(json['role'] as String?),
        complimentaryPro: json['complimentaryPro'] as bool? ?? false,
        coachId: json['coachId'] as String?,
        coachLinkedAt: json['coachLinkedAt'] != null
            ? DateTime.tryParse(json['coachLinkedAt'] as String)
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
        weekStartsOnMonday: json['weekStartsOnMonday'] as bool? ?? true,
      );

  UserProfile copyWith({
    String? uid,
    String? name,
    String? initials,
    String? email,
    int? age,
    String? height,
    double? weight,
    String? unit,
    String? experienceLevel,
    String? primaryGoal,
    Set<String>? injuries,
    String? style,
    bool? notificationsEnabled,
    bool? healthEnabled,
    String? discovery,
    List<String>? favoriteExerciseIds,
    List<String>? favoriteProgramIds,
    UserRole? role,
    bool? complimentaryPro,
    String? coachId,
    DateTime? coachLinkedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? weekStartsOnMonday,
  }) =>
      UserProfile(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        initials: initials ?? this.initials,
        email: email ?? this.email,
        age: age ?? this.age,
        height: height ?? this.height,
        weight: weight ?? this.weight,
        unit: unit ?? this.unit,
        experienceLevel: experienceLevel ?? this.experienceLevel,
        primaryGoal: primaryGoal ?? this.primaryGoal,
        injuries: injuries ?? this.injuries,
        style: style ?? this.style,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        healthEnabled: healthEnabled ?? this.healthEnabled,
        discovery: discovery ?? this.discovery,
        favoriteExerciseIds: favoriteExerciseIds ?? this.favoriteExerciseIds,
        favoriteProgramIds: favoriteProgramIds ?? this.favoriteProgramIds,
        role: role ?? this.role,
        complimentaryPro: complimentaryPro ?? this.complimentaryPro,
        coachId: coachId ?? this.coachId,
        coachLinkedAt: coachLinkedAt ?? this.coachLinkedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        weekStartsOnMonday: weekStartsOnMonday ?? this.weekStartsOnMonday,
      );
}
