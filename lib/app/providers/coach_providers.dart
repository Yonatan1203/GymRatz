import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/coach/data/coach_repository.dart';
import '../../features/coach/domain/coach_service.dart';
import '../../shared/models/coach_client.dart';
import '../../shared/models/coach_invite.dart';
import '../../shared/models/coach_profile.dart';
import 'auth_providers.dart';

final coachRepositoryProvider = Provider<CoachRepository>((ref) {
  return CoachRepository(ref.watch(firestoreProvider)!);
});

final coachServiceProvider = Provider<CoachService>((ref) {
  return CoachService(ref.watch(coachRepositoryProvider));
});

final coachProfileProvider = StreamProvider<CoachProfile?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(coachServiceProvider).watchProfile(uid);
});

final coachClientsProvider = StreamProvider<List<CoachClient>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(coachServiceProvider).watchClients(uid);
});

final coachInvitesProvider = StreamProvider<List<CoachInvite>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(coachServiceProvider).watchInvites(uid);
});

final pendingApplicationsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(coachServiceProvider).watchPendingApplications();
});
