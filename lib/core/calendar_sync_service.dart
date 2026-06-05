import 'package:add_2_calendar/add_2_calendar.dart';

import '../shared/models/workout_day.dart';

class CalendarSyncService {
  /// Adds a single workout to the device calendar (Apple Calendar / Google Calendar).
  /// Shows the native OS sheet. Includes a 30-minute reminder on iOS.
  static Future<void> addWorkoutToCalendar({
    required WorkoutDay day,
    required DateTime date,
    int startHour = 7,
  }) async {
    final exerciseList = day.exercises.map((e) => e.name).join(', ');
    final start = DateTime(date.year, date.month, date.day, startHour, 0);
    final event = Event(
      title: 'GymRatz: ${day.name}',
      description: '${day.exercises.length} exercises: $exerciseList',
      location: '',
      startDate: start,
      endDate: start.add(const Duration(hours: 1)),
      iosParams: const IOSParams(reminder: -30),
    );
    await Add2Calendar.addEvent2Cal(event);
  }

  /// Adds every workout day for a week to the device calendar.
  /// [dayDates] maps day-of-week name (e.g. "Monday") to its date this week.
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
