import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/coach_client.dart';
import '../../../shared/models/coach_invite.dart';
import '../../../shared/models/coach_profile.dart';

class CoachRepository {
  final FirebaseFirestore _firestore;

  CoachRepository(this._firestore);

  // ─── Collection refs ───

  DocumentReference<Map<String, dynamic>> _coachDoc(String coachUid) =>
      _firestore.collection('coaches').doc(coachUid);

  CollectionReference<Map<String, dynamic>> _clients(String coachUid) =>
      _coachDoc(coachUid).collection('clients');

  CollectionReference<Map<String, dynamic>> _invites(String coachUid) =>
      _coachDoc(coachUid).collection('invites');

  CollectionReference<Map<String, dynamic>> get _inviteCodes =>
      _firestore.collection('invite_codes');

  CollectionReference<Map<String, dynamic>> get _coachApplications =>
      _firestore.collection('coach_applications');

  // ─── Coach Profile ───

  Future<void> createCoachProfile(CoachProfile profile) async {
    await _coachDoc(profile.uid).set(profile.toJson());
  }

  Future<CoachProfile?> getCoachProfile(String coachUid) async {
    final snap = await _coachDoc(coachUid).get();
    if (!snap.exists || snap.data() == null) return null;
    return CoachProfile.fromJson(snap.data()!);
  }

  Stream<CoachProfile?> watchCoachProfile(String coachUid) {
    return _coachDoc(coachUid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return CoachProfile.fromJson(snap.data()!);
    });
  }

  Future<void> updateCoachProfile(
      String coachUid, Map<String, dynamic> fields) async {
    await _coachDoc(coachUid).update(fields);
  }

  // ─── Clients ───

  Stream<List<CoachClient>> watchClients(String coachUid) {
    return _clients(coachUid).snapshots().map((snap) =>
        snap.docs.map((d) => CoachClient.fromJson(d.data())).toList());
  }

  Future<void> addClient(String coachUid, CoachClient client) async {
    await _clients(coachUid).doc(client.clientUid).set(client.toJson());
    await _coachDoc(coachUid).update({
      'clientCount': FieldValue.increment(1),
    });
  }

  Future<void> removeClient(String coachUid, String clientUid) async {
    await _clients(coachUid).doc(clientUid).delete();
    await _coachDoc(coachUid).update({
      'clientCount': FieldValue.increment(-1),
    });
  }

  // ─── Invites ───

  Stream<List<CoachInvite>> watchInvites(String coachUid) {
    return _invites(coachUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CoachInvite.fromJson(d.data())).toList());
  }

  Future<CoachInvite> createInvite(
      String coachUid, {String? clientEmail}) async {
    // Rate limit: max 5 pending invites per day.
    final todayStart = DateTime.now()
        .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    final pendingToday = await _invites(coachUid)
        .where('status', isEqualTo: 'pending')
        .where('createdAt', isGreaterThanOrEqualTo: todayStart.toIso8601String())
        .limit(5)
        .get();
    if (pendingToday.docs.length >= 5) {
      throw Exception('Daily invite limit reached (5 per day). Revoke an existing invite to create a new one.');
    }

    final code = generateInviteCode();
    final now = DateTime.now();
    final invite = CoachInvite(
      id: code,
      code: code,
      clientEmail: clientEmail,
      status: 'pending',
      createdAt: now,
      expiresAt: now.add(const Duration(days: 7)),
    );

    final batch = _firestore.batch();
    batch.set(_invites(coachUid).doc(invite.id), invite.toJson());
    batch.set(_inviteCodes.doc(code), {
      'coachUid': coachUid,
      'inviteId': invite.id,
      'status': 'pending',
    });
    await batch.commit();

    return invite;
  }

  Future<void> revokeInvite(String coachUid, CoachInvite invite) async {
    final batch = _firestore.batch();
    batch.update(_invites(coachUid).doc(invite.id), {'status': 'expired'});
    batch.update(_inviteCodes.doc(invite.code), {'status': 'expired'});
    await batch.commit();
  }

  Future<Map<String, dynamic>?> lookupInviteCode(String code) async {
    final snap = await _inviteCodes.doc(code.toUpperCase()).get();
    if (!snap.exists || snap.data() == null) return null;
    final data = snap.data()!;
    if (data['status'] != 'pending') return null;
    final expiresAtRaw = data['expiresAt'];
    if (expiresAtRaw != null) {
      final expiresAt = expiresAtRaw is Timestamp
          ? expiresAtRaw.toDate()
          : DateTime.tryParse(expiresAtRaw.toString());
      // Fail-closed: unrecognised or expired format → reject the code.
      if (expiresAt == null || DateTime.now().isAfter(expiresAt)) return null;
    }
    return data;
  }

  Future<void> acceptInvite({
    required String code,
    required String coachUid,
    required String inviteId,
    required CoachClient client,
  }) async {
    final batch = _firestore.batch();
    batch.update(_invites(coachUid).doc(inviteId), {'status': 'accepted'});
    batch.update(_inviteCodes.doc(code), {'status': 'accepted'});
    batch.set(_clients(coachUid).doc(client.clientUid), client.toJson());
    batch.update(_coachDoc(coachUid), {
      'clientCount': FieldValue.increment(1),
    });
    batch.update(_firestore.collection('users').doc(client.clientUid), {
      'coachId': coachUid,
      'coachLinkedAt': DateTime.now().toIso8601String(),
    });
    await batch.commit();
  }

  Future<void> unlinkClient(String coachUid, String clientUid) async {
    final batch = _firestore.batch();
    batch.delete(_clients(coachUid).doc(clientUid));
    batch.update(_coachDoc(coachUid), {
      'clientCount': FieldValue.increment(-1),
    });
    batch.update(_firestore.collection('users').doc(clientUid), {
      'coachId': null,
      'coachLinkedAt': null,
    });
    await batch.commit();
  }

  // ─── Coach Applications ───

  Future<void> submitApplication({
    required String uid,
    required String email,
    required String displayName,
    required String reason,
  }) async {
    // Prevent duplicate submissions: block if a pending application exists.
    final existing = await _coachApplications.doc(uid).get();
    if (existing.exists && existing.data()?['status'] == 'pending') {
      throw Exception('A pending coach application already exists for this account.');
    }

    await _coachApplications.doc(uid).set({
      'email': email,
      'displayName': displayName,
      'reason': reason,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchPendingApplications() {
    return _coachApplications
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['uid'] = d.id;
              return data;
            }).toList());
  }

  Future<void> approveApplication(String uid) async {
    await _coachApplications.doc(uid).update({'status': 'approved'});
    await _firestore.collection('users').doc(uid).update({'role': 'coach'});
  }

  Future<void> rejectApplication(String uid) async {
    await _coachApplications.doc(uid).update({'status': 'rejected'});
  }

  // ─── Client data access ───

  Stream<List<Map<String, dynamic>>> watchClientWorkouts(
      String clientUid, {int limit = 20}) {
    return _firestore
        .collection('users')
        .doc(clientUid)
        .collection('workouts')
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> watchClientPrograms(String clientUid) {
    return _firestore
        .collection('users')
        .doc(clientUid)
        .collection('programs')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Future<void> assignProgramToClient({
    required String coachUid,
    required String clientUid,
    required Map<String, dynamic> programJson,
    required String programId,
  }) async {
    final batch = _firestore.batch();
    final existing = await _firestore
        .collection('users')
        .doc(clientUid)
        .collection('programs')
        .get();
    for (final doc in existing.docs) {
      batch.update(doc.reference, {'isActive': false});
    }
    final programData = Map<String, dynamic>.from(programJson);
    programData['id'] = programId;
    programData['isActive'] = true;
    programData['assignedByCoach'] = true;
    programData['coachId'] = coachUid;
    programData['createdAt'] = DateTime.now().toIso8601String();
    batch.set(
      _firestore.collection('users').doc(clientUid).collection('programs').doc(programId),
      programData,
    );
    await batch.commit();
  }

  // ─── Coach Program Templates ───

  CollectionReference<Map<String, dynamic>> _coachPrograms(String coachUid) =>
      _coachDoc(coachUid).collection('programs');

  Stream<List<Map<String, dynamic>>> watchCoachPrograms(String coachUid) {
    return _coachPrograms(coachUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  Future<void> createCoachProgram(
      String coachUid, Map<String, dynamic> programJson) async {
    final docRef = _coachPrograms(coachUid).doc();
    programJson['id'] = docRef.id;
    programJson['createdAt'] = DateTime.now().toIso8601String();
    await docRef.set(programJson);
  }

  Future<void> updateCoachProgram(
      String coachUid, String programId, Map<String, dynamic> fields) async {
    await _coachPrograms(coachUid).doc(programId).update(fields);
  }

  Future<void> deleteCoachProgram(String coachUid, String programId) async {
    await _coachPrograms(coachUid).doc(programId).delete();
  }

  Future<Map<String, dynamic>?> getCoachProgram(
      String coachUid, String programId) async {
    final snap = await _coachPrograms(coachUid).doc(programId).get();
    if (!snap.exists || snap.data() == null) return null;
    final data = snap.data()!;
    data['id'] = snap.id;
    return data;
  }

  // ─── Invite code generation ───

  static String generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
    );
  }
}
