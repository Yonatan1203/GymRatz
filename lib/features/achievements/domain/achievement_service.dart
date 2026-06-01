import '../../../shared/models/achievement.dart';
import '../data/achievement_repository.dart';

class AchievementService {
  final AchievementRepository _repo;

  AchievementService(this._repo);

  /// Default achievements for new users.
  static const defaultAchievements = [
    Achievement(id: 'first_workout', title: 'First Workout', description: 'Complete your first workout', iconName: 'trophy', progress: 0, total: 1, rarity: 'Common', points: 10),
    Achievement(id: 'week_warrior', title: 'Week Warrior', description: 'Work out 5 days in a week', iconName: 'flame', progress: 0, total: 5, rarity: 'Common', points: 25),
    Achievement(id: 'pr_machine', title: 'PR Machine', description: 'Set 10 personal records', iconName: 'award', progress: 0, total: 10, rarity: 'Rare', points: 50),
    Achievement(id: 'iron_will', title: 'Iron Will', description: 'Maintain a 30-day streak', iconName: 'target', progress: 0, total: 30, rarity: 'Epic', points: 100),
    Achievement(id: 'century_club', title: 'Century Club', description: 'Complete 100 workouts', iconName: 'star', progress: 0, total: 100, rarity: 'Epic', points: 150),
    Achievement(id: 'volume_king', title: 'Volume King', description: 'Log 100,000 lbs total volume', iconName: 'crown', progress: 0, total: 100000, rarity: 'Legendary', points: 200),
    Achievement(id: 'consistency', title: 'Consistency', description: 'Work out for 4 consecutive weeks', iconName: 'calendar', progress: 0, total: 4, rarity: 'Rare', points: 50),
    Achievement(id: 'early_bird', title: 'Early Bird', description: 'Complete 5 workouts before 8am', iconName: 'sunrise', progress: 0, total: 5, rarity: 'Common', points: 25),
    Achievement(id: 'program_complete', title: 'Program Complete', description: 'Finish an entire program', iconName: 'checkCircle', progress: 0, total: 1, rarity: 'Rare', points: 75),
    Achievement(id: 'legend', title: 'Legend', description: 'Reach 1000 total points', iconName: 'crown', progress: 0, total: 1000, rarity: 'Legendary', points: 500),
  ];

  /// Initialize achievements for a new user.
  Future<void> initForNewUser(String uid) async {
    await _repo.initializeAchievements(uid, defaultAchievements);
  }

  /// Check and update all achievements based on current stats.
  Future<List<String>> checkAchievements(
    String uid, {
    required int totalWorkouts,
    required int streak,
    required double totalVolume,
    required int prCount,
    int weeklyWorkouts = 0,
    bool programCompleted = false,
  }) async {
    final unlocked = <String>[];

    final checks = <String, int>{
      'first_workout': totalWorkouts,
      'century_club': totalWorkouts,
      'iron_will': streak,
      'consistency': streak ~/ 7,
      'volume_king': totalVolume.toInt(),
      'pr_machine': prCount,
      'week_warrior': weeklyWorkouts,
      'program_complete': programCompleted ? 1 : 0,
    };

    for (final entry in checks.entries) {
      await _repo.updateProgress(uid, entry.key, entry.value);
    }

    // Check which ones should be unlocked
    final achievements = defaultAchievements;
    for (final a in achievements) {
      final progress = checks[a.id];
      if (progress != null && progress >= a.total) {
        await _repo.unlock(uid, a.id);
        unlocked.add(a.title);
      }
    }

    return unlocked;
  }
}
