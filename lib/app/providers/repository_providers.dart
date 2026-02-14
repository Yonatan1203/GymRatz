import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/achievements/data/achievement_repository.dart';
import '../../features/calendar/data/weight_entry_repository.dart';
import '../../features/programs/data/program_repository.dart';
import '../../features/progress/data/pr_repository.dart';
import '../../features/user/data/user_repository.dart';
import '../../features/workout/data/workout_repository.dart';
import 'auth_providers.dart';

/// All repository providers throw if Firebase isn't initialized.
/// This is safe because data_providers guard with `uid == null` checks —
/// repositories are only accessed when a user is authenticated (Firebase is up).

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(firestoreProvider)!);
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(ref.watch(firestoreProvider)!);
});

final programRepositoryProvider = Provider<ProgramRepository>((ref) {
  return ProgramRepository(ref.watch(firestoreProvider)!);
});

final prRepositoryProvider = Provider<PrRepository>((ref) {
  return PrRepository(ref.watch(firestoreProvider)!);
});

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepository(ref.watch(firestoreProvider)!);
});

final weightEntryRepositoryProvider = Provider<WeightEntryRepository>((ref) {
  return WeightEntryRepository(ref.watch(firestoreProvider)!);
});
