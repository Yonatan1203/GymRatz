class CoachClient {
  final String clientUid;
  final String clientName;
  final String clientEmail;
  final DateTime linkedAt;
  final String inviteMethod;

  const CoachClient({
    required this.clientUid,
    required this.clientName,
    required this.clientEmail,
    required this.linkedAt,
    required this.inviteMethod,
  });

  Map<String, dynamic> toJson() => {
        'clientUid': clientUid,
        'clientName': clientName,
        'clientEmail': clientEmail,
        'linkedAt': linkedAt.toIso8601String(),
        'inviteMethod': inviteMethod,
      };

  factory CoachClient.fromJson(Map<String, dynamic> json) => CoachClient(
        clientUid: json['clientUid'] as String,
        clientName: json['clientName'] as String? ?? '',
        clientEmail: json['clientEmail'] as String? ?? '',
        linkedAt: json['linkedAt'] != null
            ? DateTime.parse(json['linkedAt'] as String)
            : DateTime.now(),
        inviteMethod: json['inviteMethod'] as String? ?? 'code',
      );
}
