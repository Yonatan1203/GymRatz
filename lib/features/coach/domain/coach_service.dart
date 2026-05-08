import 'package:uuid/uuid.dart';

import '../../../core/constants.dart';
import '../../../shared/models/coach_client.dart';
import '../../../shared/models/coach_invite.dart';
import '../../../shared/models/coach_profile.dart';
import '../data/coach_repository.dart';

class CoachService {
  final CoachRepository _repo;

  CoachService(this._repo);

  Stream<CoachProfile?> watchProfile(String coachUid) =>
      _repo.watchCoachProfile(coachUid);

  Future<CoachProfile?> getProfile(String coachUid) =>
      _repo.getCoachProfile(coachUid);

  Future<void> createProfile({
    required String uid,
    required String displayName,
    required String email,
    required String planTier,
  }) async {
    final profile = CoachProfile(
      uid: uid,
      displayName: displayName,
      email: email,
      planTier: planTier,
      maxClients: AppConstants.maxClientsForTier(planTier),
      createdAt: DateTime.now(),
    );
    await _repo.createCoachProfile(profile);
  }

  Stream<List<CoachClient>> watchClients(String coachUid) =>
      _repo.watchClients(coachUid);

  Future<void> removeClient(String coachUid, String clientUid) =>
      _repo.unlinkClient(coachUid, clientUid);

  Stream<List<CoachInvite>> watchInvites(String coachUid) =>
      _repo.watchInvites(coachUid);

  Future<CoachInvite> createInvite(
    String coachUid, {
    String? clientEmail,
  }) async {
    final profile = await _repo.getCoachProfile(coachUid);
    if (profile == null) throw StateError('Coach profile not found');
    if (profile.isFull) throw StateError('Client roster is full');
    return _repo.createInvite(coachUid, clientEmail: clientEmail);
  }

  Future<void> revokeInvite(String coachUid, CoachInvite invite) =>
      _repo.revokeInvite(coachUid, invite);

  Future<String> joinCoach({
    required String code,
    required String clientUid,
    required String clientName,
    required String clientEmail,
  }) async {
    final lookup = await _repo.lookupInviteCode(code.toUpperCase());
    if (lookup == null) throw StateError('Invalid or expired invite code');

    final coachUid = lookup['coachUid'] as String;
    final inviteId = lookup['inviteId'] as String;

    final coachProfile = await _repo.getCoachProfile(coachUid);
    if (coachProfile == null) throw StateError('Coach not found');
    if (coachProfile.isFull) throw StateError('Coach roster is full');

    final client = CoachClient(
      clientUid: clientUid,
      clientName: clientName,
      clientEmail: clientEmail,
      linkedAt: DateTime.now(),
      inviteMethod: 'code',
    );

    await _repo.acceptInvite(
      code: code.toUpperCase(),
      coachUid: coachUid,
      inviteId: inviteId,
      client: client,
    );

    return coachProfile.displayName;
  }

  Future<void> assignProgram({
    required String coachUid,
    required String clientUid,
    required Map<String, dynamic> programJson,
  }) async {
    final programId = const Uuid().v4();
    await _repo.assignProgramToClient(
      coachUid: coachUid,
      clientUid: clientUid,
      programJson: programJson,
      programId: programId,
    );
  }

  Stream<List<Map<String, dynamic>>> watchClientWorkouts(
          String clientUid, {int limit = 20}) =>
      _repo.watchClientWorkouts(clientUid, limit: limit);

  Stream<List<Map<String, dynamic>>> watchClientPrograms(String clientUid) =>
      _repo.watchClientPrograms(clientUid);

  Future<void> submitApplication({
    required String uid,
    required String email,
    required String displayName,
    required String reason,
  }) =>
      _repo.submitApplication(
        uid: uid,
        email: email,
        displayName: displayName,
        reason: reason,
      );

  Stream<List<Map<String, dynamic>>> watchPendingApplications() =>
      _repo.watchPendingApplications();

  Future<void> approveApplication(String uid) =>
      _repo.approveApplication(uid);

  Future<void> rejectApplication(String uid) =>
      _repo.rejectApplication(uid);
}
