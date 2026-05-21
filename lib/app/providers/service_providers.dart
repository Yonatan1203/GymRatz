import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymratz/core/analytics_service.dart';

import '../../features/achievements/domain/achievement_service.dart';
import '../../features/programs/domain/program_service.dart';
import '../../features/workout/domain/workout_service.dart';
import 'repository_providers.dart';

final workoutServiceProvider = Provider<WorkoutService>((ref) {
  return WorkoutService(
    ref.watch(workoutRepositoryProvider),
    ref.watch(prRepositoryProvider),
    ref.watch(progressionRepositoryProvider),
  );
});

final programServiceProvider = Provider<ProgramService>((ref) {
  return ProgramService(ref.watch(programRepositoryProvider));
});

final achievementServiceProvider = Provider<AchievementService>((ref) {
  return AchievementService(ref.watch(achievementRepositoryProvider));
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});
