import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logSignUp(String method) =>
      _analytics.logSignUp(signUpMethod: method);

  Future<void> logLogin(String method) =>
      _analytics.logLogin(loginMethod: method);

  Future<void> logWorkoutStarted({
    required String programId,
    required String workoutDayId,
  }) =>
      _analytics.logEvent(name: 'workout_started', parameters: {
        'program_id': programId,
        'workout_day_id': workoutDayId,
      });

  Future<void> logWorkoutCompleted({
    required int durationSeconds,
    required int exerciseCount,
    required int totalSets,
    required double totalVolume,
  }) =>
      _analytics.logEvent(name: 'workout_completed', parameters: {
        'duration_seconds': durationSeconds,
        'exercise_count': exerciseCount,
        'total_sets': totalSets,
        'total_volume': totalVolume,
      });

  Future<void> logProgramCreated(String programName) =>
      _analytics.logEvent(name: 'program_created', parameters: {
        'program_name': programName,
      });

  Future<void> logAchievementUnlocked(String achievementId) =>
      _analytics.logEvent(name: 'achievement_unlocked', parameters: {
        'achievement_id': achievementId,
      });

  Future<void> logSubscriptionStarted(String planId) =>
      _analytics.logEvent(name: 'subscription_started', parameters: {
        'plan_id': planId,
      });

  Future<void> logSubscriptionRestored() =>
      _analytics.logEvent(name: 'subscription_restored');

  Future<void> logOnboardingCompleted(int stepCount) =>
      _analytics.logEvent(name: 'onboarding_completed', parameters: {
        'step_count': stepCount,
      });

  Future<void> logOnboardingAbandoned(int lastStep) =>
      _analytics.logEvent(name: 'onboarding_abandoned', parameters: {
        'last_step': lastStep,
      });

  Future<void> setUserId(String? uid) => _analytics.setUserId(id: uid);
}
