import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/exceptions.dart';
import '../../features/subscription/data/entitlement_repository.dart';
import '../../features/subscription/domain/entitlement_service.dart';
import 'auth_providers.dart';
import 'data_providers.dart';

final entitlementRepositoryProvider = Provider<EntitlementRepository>((ref) {
  return EntitlementRepository();
});

final entitlementServiceProvider = Provider<EntitlementService>((ref) {
  return EntitlementService(ref.watch(entitlementRepositoryProvider));
});

/// Resolves pro access: own sub OR admin role OR complimentary grant OR coach-sponsored.
final isProProvider = StreamProvider<bool>((ref) async* {
  // Watch profile so we re-evaluate when it loads/changes
  final profile = ref.watch(userProfileProvider).valueOrNull;

  // 1. Check non-purchased pro (admin role or complimentary grant) — fast path
  if (profile != null && EntitlementService.hasComplimentaryPro(profile)) {
    yield true;
    return;
  }

  // 2. Check coach-sponsored pro
  if (profile != null && profile.coachId != null) {
    final coachHasPlan = await _coachHasActivePlan(
      ref.read(firestoreProvider),
      profile.coachId!,
    );
    if (coachHasPlan) {
      yield true;
      return;
    }
  }

  // 3. Check RevenueCat subscription
  final rcStream = ref.watch(entitlementServiceProvider).isProStream();
  await for (final rcPro in rcStream) {
    yield rcPro;
  }
});

/// Check if a coach has an active plan by reading their profile doc.
Future<bool> _coachHasActivePlan(
    FirebaseFirestore? firestore, String coachUid) async {
  if (firestore == null) return false;
  try {
    final snap = await firestore.collection('coaches').doc(coachUid).get();
    if (!snap.exists || snap.data() == null) return false;
    final tier = snap.data()!['planTier'] as String?;
    return tier != null && tier.isNotEmpty;
  } catch (_) {
    return false;
  }
}

final subscriptionStateProvider = StreamProvider<SubscriptionState>((ref) {
  return ref.watch(entitlementServiceProvider).subscriptionStateStream();
});

/// Call before any write action. Throws [SubscriptionExpiredException] if expired.
final subscriptionGuardProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    // Non-purchased pro bypass (admin role or complimentary grant)
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile != null && EntitlementService.hasComplimentaryPro(profile)) {
      return;
    }

    final state = await ref.read(entitlementServiceProvider).getSubscriptionState();
    if (state == SubscriptionState.expired) {
      throw SubscriptionExpiredException();
    }
  };
});
