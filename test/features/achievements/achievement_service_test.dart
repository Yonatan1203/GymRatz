import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/features/achievements/data/achievement_repository.dart';
import 'package:gymratz/features/achievements/domain/achievement_service.dart';

void main() {
  late AchievementService service;
  late AchievementRepository repo;

  setUp(() {
    final fakeFirestore = FakeFirebaseFirestore();
    repo = AchievementRepository(fakeFirestore);
    service = AchievementService(repo);
  });

  group('AchievementService.defaultAchievements invariants', () {
    test('has exactly 10 items', () {
      expect(AchievementService.defaultAchievements.length, 10);
    });

    test('all IDs are unique', () {
      final ids = AchievementService.defaultAchievements.map((a) => a.id);
      expect(ids.toSet().length, ids.length);
    });

    test('all total values are > 0 (guards against divide-by-zero in progress bars)', () {
      for (final a in AchievementService.defaultAchievements) {
        expect(a.total, greaterThan(0), reason: '${a.id}.total must be > 0');
      }
    });
  });

  group('AchievementService.checkAchievements', () {
    test('returns first_workout when totalWorkouts == 1', () async {
      final unlocked = await service.checkAchievements(
        'uid1',
        totalWorkouts: 1,
        streak: 0,
        totalVolume: 0,
        prCount: 0,
      );
      expect(unlocked, contains('first_workout'));
    });

    test('returns century_club when totalWorkouts == 100', () async {
      final unlocked = await service.checkAchievements(
        'uid1',
        totalWorkouts: 100,
        streak: 0,
        totalVolume: 0,
        prCount: 0,
      );
      expect(unlocked, contains('century_club'));
    });

    test('does NOT return titles for unmet thresholds', () async {
      final unlocked = await service.checkAchievements(
        'uid1',
        totalWorkouts: 0,
        streak: 0,
        totalVolume: 0,
        prCount: 0,
      );
      expect(unlocked, isEmpty);
    });

    test('consistency: 28 days streak triggers achievement (streak ~/ 7 == 4)', () async {
      final unlocked = await service.checkAchievements(
        'uid1',
        totalWorkouts: 0,
        streak: 28,
        totalVolume: 0,
        prCount: 0,
      );
      expect(unlocked, contains('consistency'));
    });

    test('consistency: 27 days streak does NOT trigger (streak ~/ 7 == 3)', () async {
      final unlocked = await service.checkAchievements(
        'uid1',
        totalWorkouts: 0,
        streak: 27,
        totalVolume: 0,
        prCount: 0,
      );
      expect(unlocked, isNot(contains('consistency')));
    });
  });
}
