import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/subscription/data/entitlement_repository.dart';
import '../../features/subscription/data/entitlement_repository.dart' show SubscriptionState;
import '../../features/subscription/domain/entitlement_service.dart';

final entitlementRepositoryProvider = Provider<EntitlementRepository>((ref) {
  return EntitlementRepository();
});

final entitlementServiceProvider = Provider<EntitlementService>((ref) {
  return EntitlementService(ref.watch(entitlementRepositoryProvider));
});

final isProProvider = StreamProvider<bool>((ref) {
  return ref.watch(entitlementServiceProvider).isProStream();
});

final subscriptionStateProvider = StreamProvider<SubscriptionState>((ref) {
  return ref.watch(entitlementServiceProvider).subscriptionStateStream();
});
