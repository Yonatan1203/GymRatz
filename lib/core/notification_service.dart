import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _keyReminderEnabled = 'notif_reminder_enabled';
  static const _keyReminderHour = 'notif_reminder_hour';
  static const _keyReminderMinute = 'notif_reminder_minute';
  // ignore: unused_field
  static const _keyStreakEnabled = 'notif_streak_enabled';

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
  }

  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  Future<void> scheduleWorkoutReminder({
    required int hour,
    required int minute,
    required List<int> weekdays, // 1=Mon, 7=Sun
  }) async {
    // Cancel existing reminders
    await cancelWorkoutReminders();

    for (final day in weekdays) {
      await _plugin.zonedSchedule(
        day, // unique ID per day
        'Time to train!',
        'Your workout is waiting. Let\'s go!',
        _nextInstanceOfDayTime(day, hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'workout_reminders',
            'Workout Reminders',
            channelDescription: 'Daily workout reminder notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    // Save preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReminderEnabled, true);
    await prefs.setInt(_keyReminderHour, hour);
    await prefs.setInt(_keyReminderMinute, minute);
  }

  Future<void> cancelWorkoutReminders() async {
    for (int day = 1; day <= 7; day++) {
      await _plugin.cancel(day);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReminderEnabled, false);
  }

  tz.TZDateTime _nextInstanceOfDayTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }
    return scheduled;
  }
}
