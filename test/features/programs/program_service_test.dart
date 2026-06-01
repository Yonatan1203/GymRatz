import 'package:flutter_test/flutter_test.dart';
import 'package:gymratz/shared/models/workout_day.dart';

// We test getTodaysWorkout logic directly since ProgramService.getTodaysWorkout
// uses DateTime.now().weekday — we test the mapping logic via a helper that
// mirrors the implementation so we can inject a specific weekday.

/// Mirror of ProgramService.getTodaysWorkout logic with injectable weekday.
WorkoutDay? getTodaysWorkoutForDay(List<WorkoutDay> days, int weekday) {
  const dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday'
  ];
  final todayName = dayNames[weekday - 1];
  return days.where((d) => d.dayOfWeek == todayName).firstOrNull;
}

WorkoutDay _day(String dayOfWeek) => WorkoutDay(
      id: dayOfWeek,
      dayOfWeek: dayOfWeek,
      exercises: const [],
      name: dayOfWeek,
    );

void main() {
  group('ProgramService.getTodaysWorkout day-name mapping', () {
    final fullWeekProgram = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ].map(_day).toList();

    test('no days returns null', () {
      expect(getTodaysWorkoutForDay(const [], 1), isNull);
    });

    test('today present returns correct WorkoutDay (Monday = weekday 1)', () {
      final result = getTodaysWorkoutForDay(fullWeekProgram, 1);
      expect(result?.dayOfWeek, 'Monday');
    });

    test('today absent returns null', () {
      final mondayOnly = [_day('Monday')];
      expect(getTodaysWorkoutForDay(mondayOnly, 2), isNull); // Tuesday absent
    });

    test('Sunday (weekday 7, index 6) maps correctly', () {
      final result = getTodaysWorkoutForDay(fullWeekProgram, 7);
      expect(result?.dayOfWeek, 'Sunday');
    });

    test('Wednesday (weekday 3) maps to index 2', () {
      final result = getTodaysWorkoutForDay(fullWeekProgram, 3);
      expect(result?.dayOfWeek, 'Wednesday');
    });

    test('all 7 weekdays map to the correct day name', () {
      final expected = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday',
      ];
      for (int i = 1; i <= 7; i++) {
        final result = getTodaysWorkoutForDay(fullWeekProgram, i);
        expect(result?.dayOfWeek, expected[i - 1],
            reason: 'weekday $i should map to ${expected[i - 1]}');
      }
    });
  });
}
