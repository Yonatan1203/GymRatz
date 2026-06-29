import 'package:device_calendar/device_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../shared/models/workout_day.dart';

class CalendarSyncService {
  static final _plugin = DeviceCalendarPlugin();
  static const _prefsKeyPrefix = 'cal_event_';
  static String? _calendarId;

  static String eventKey(String dayId, DateTime date) =>
      '$_prefsKeyPrefix${dayId}_'
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

  static Future<bool> requestPermission() async {
    var result = await _plugin.hasPermissions();
    if (result.isSuccess && (result.data ?? false)) return true;
    result = await _plugin.requestPermissions();
    return result.isSuccess && (result.data ?? false);
  }

  static Future<String?> _getWritableCalendarId() async {
    if (_calendarId != null) return _calendarId;
    final result = await _plugin.retrieveCalendars();
    if (!result.isSuccess) return null;
    final writable = (result.data ?? [])
        .where((c) => !(c.isReadOnly ?? true))
        .toList();
    if (writable.isEmpty) return null;
    _calendarId = writable.first.id;
    return _calendarId;
  }

  static Future<Set<String>> syncedEventKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs
        .getKeys()
        .where((k) => k.startsWith(_prefsKeyPrefix))
        .where((k) => (prefs.getString(k) ?? '').isNotEmpty)
        .toSet();
  }

  static Future<bool> addWorkoutToCalendar({
    required WorkoutDay day,
    required DateTime date,
    int startHour = 7,
  }) async {
    if (!await requestPermission()) return false;
    final calId = await _getWritableCalendarId();
    if (calId == null) return false;

    final startDt = DateTime(date.year, date.month, date.day, startHour);
    final start = tz.TZDateTime.from(startDt, tz.local);
    final end = tz.TZDateTime.from(
      startDt.add(const Duration(hours: 1)),
      tz.local,
    );
    final exerciseList = day.exercises.map((e) => e.name).join(', ');

    final event = Event(
      calId,
      title: 'GymRatz: ${day.name}',
      description: '${day.exercises.length} exercises: $exerciseList',
      start: start,
      end: end,
      reminders: [Reminder(minutes: 30)],
    );

    final result = await _plugin.createOrUpdateEvent(event);
    if (result?.isSuccess == true && result?.data != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(eventKey(day.id, date), result!.data!);
      return true;
    }
    return false;
  }

  static Future<bool> removeWorkoutFromCalendar({
    required String dayId,
    required DateTime date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = eventKey(dayId, date);
    final calEventId = prefs.getString(key);
    if (calEventId == null || calEventId.isEmpty) return false;

    final calId = await _getWritableCalendarId();
    if (calId == null) return false;

    final result = await _plugin.deleteEvent(calId, calEventId);
    if (result.isSuccess) {
      await prefs.remove(key);
      return true;
    }
    return false;
  }

  static Future<void> addWeekToCalendar({
    required List<WorkoutDay> days,
    required Map<String, DateTime> dayDates,
    Set<String> alreadySyncedKeys = const {},
  }) async {
    for (final day in days) {
      final date = dayDates[day.dayOfWeek];
      if (date == null) continue;
      if (alreadySyncedKeys.contains(eventKey(day.id, date))) continue;
      await addWorkoutToCalendar(day: day, date: date);
    }
  }
}
