import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  /// Optional override — pass a real or fake instance in tests to avoid
  /// requiring Firebase initialization at object-construction time.
  final FirebaseAnalytics? _override;

  /// Returns the injected instance, or the Firebase singleton lazily.
  FirebaseAnalytics get _a => _override ?? FirebaseAnalytics.instance;

  AnalyticsService([this._override]);

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _a);

  // All methods are async so synchronous Firebase exceptions (e.g. Firebase
  // not initialized in tests) are wrapped in Futures and discarded by callers
  // using .ignore().

  Future<void> logSignUp(String method) async =>
      _a.logSignUp(signUpMethod: method);

  Future<void> logLogin(String method) async =>
      _a.logLogin(loginMethod: method);

  Future<void> logWorkoutStarted({
    required String programId,
    required String workoutDayId,
  }) async =>
      _a.logEvent(name: 'workout_started', parameters: {
        'program_id': programId,
        'workout_day_id': workoutDayId,
      });

  Future<void> logWorkoutCompleted({
    required int durationSeconds,
    required int exerciseCount,
    required int totalSets,
    required double totalVolume,
  }) async =>
      _a.logEvent(name: 'workout_completed', parameters: {
        'duration_seconds': durationSeconds,
        'exercise_count': exerciseCount,
        'total_sets': totalSets,
        'total_volume': totalVolume,
      });

  Future<void> logProgramCreated(String programName) async =>
      _a.logEvent(name: 'program_created', parameters: {
        'program_name': programName,
      });

  Future<void> logAchievementUnlocked(String achievementId) async =>
      _a.logEvent(name: 'achievement_unlocked', parameters: {
        'achievement_id': achievementId,
      });

  Future<void> logSubscriptionStarted(String planId) async =>
      _a.logEvent(name: 'subscription_started', parameters: {
        'plan_id': planId,
      });

  Future<void> logSubscriptionRestored() async =>
      _a.logEvent(name: 'subscription_restored');

  Future<void> logOnboardingCompleted(int stepCount) async =>
      _a.logEvent(name: 'onboarding_completed', parameters: {
        'step_count': stepCount,
      });

  Future<void> logOnboardingAbandoned(int lastStep) async =>
      _a.logEvent(name: 'onboarding_abandoned', parameters: {
        'last_step': lastStep,
      });

  Future<void> setUserId(String? uid) async => _a.setUserId(id: uid);
}
