import 'package:add_2_calendar/add_2_calendar.dart';

import '../shared/models/workout_day.dart';

class CalendarSyncService {
  /// Opens the device calendar with a pre-filled workout event.
  static Future<void> addWorkoutToCalendar({
    required WorkoutDay day,
    required DateTime date,
  }) async {
    final exerciseList = day.exercises.map((e) => e.name).join(', ');
    final event = Event(
      title: 'GymRatz: ${day.name}',
      description: '${day.exercises.length} exercises: $exerciseList',
      location: '',
      startDate: DateTime(date.year, date.month, date.day, 7, 0),
      endDate: DateTime(date.year, date.month, date.day, 8, 0),
    );
    await Add2Calendar.addEvent2Cal(event);
  }

  /// Exports a full week of workouts to the device calendar.
  static Future<void> addWeekToCalendar({
    required List<WorkoutDay> days,
    required Map<String, DateTime> dayDates,
  }) async {
    for (final day in days) {
      final date = dayDates[day.dayOfWeek];
      if (date != null) {
        await addWorkoutToCalendar(day: day, date: date);
      }
    }
  }
}
