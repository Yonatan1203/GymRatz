import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import 'crashlytics_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _keyReminderEnabled = 'notif_reminder_enabled';
  static const _keyReminderHour = 'notif_reminder_hour';
  static const _keyReminderMinute = 'notif_reminder_minute';
  static const _keyStreakEnabled = 'notif_streak_enabled';

  static const _restTimerNotifId = 100;
  static const _streakNotifId = 200;

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

  /// Schedule a one-shot notification to fire when the rest timer ends.
  /// Safe to call while the app is backgrounded — fires even if force-quit.
  Future<void> scheduleRestTimerNotification(int seconds) async {
    await _plugin.cancel(_restTimerNotifId);
    await _zonedSchedule(
      id: _restTimerNotifId,
      title: 'Rest over!',
      body: 'Time to hit your next set 💪',
      scheduledDate: tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'rest_timer',
          'Rest Timer',
          channelDescription: 'Fires when your rest period ends',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
    );
  }

  Future<void> cancelRestTimer() async {
    await _plugin.cancel(_restTimerNotifId);
  }

  Future<void> scheduleWorkoutReminder({
    required int hour,
    required int minute,
    required List<int> weekdays, // 1=Mon, 7=Sun
  }) async {
    // Cancel existing reminders
    await cancelWorkoutReminders();

    for (final day in weekdays) {
      await _zonedSchedule(
        id: day, // unique ID per day
        title: 'Time to train!',
        body: 'Your workout is waiting. Let\'s go!',
        scheduledDate: _nextInstanceOfDayTime(day, hour, minute),
        details: const NotificationDetails(
          android: AndroidNotificationDetails(
            'workout_reminders',
            'Workout Reminders',
            channelDescription: 'Daily workout reminder notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
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

  /// Schedule a daily streak reminder at 20:00 local time.
  /// Call this when the user has an active streak and enables streak reminders.
  Future<void> scheduleStreakReminder() async {
    await cancelStreakReminder();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _zonedSchedule(
      id: _streakNotifId,
      title: 'Keep your streak alive!',
      body: 'Log a workout today to maintain your streak.',
      scheduledDate: scheduled,
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_reminders',
          'Streak Reminders',
          channelDescription: 'Daily reminder to keep your workout streak going',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      matchDateTimeComponents: DateTimeComponents.time,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStreakEnabled, true);
  }

  /// Cancel the daily streak reminder.
  Future<void> cancelStreakReminder() async {
    await _plugin.cancel(_streakNotifId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStreakEnabled, false);
  }

  static const _fcmNotifId = 300;

  /// Display a server-sent FCM message as a local notification while the app
  /// is in the foreground. [payload] is an optional route string for tap handling.
  Future<void> showFcmNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      _fcmNotifId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'gymratz_push',
          'GymRatz Notifications',
          channelDescription: 'Streak alerts, trial reminders, and coach messages',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      ),
      payload: payload,
    );
  }

  static const _dayNameToInt = {
    'Monday': 1, 'Tuesday': 2, 'Wednesday': 3,
    'Thursday': 4, 'Friday': 5, 'Saturday': 6, 'Sunday': 7,
  };

  /// Convert a list of day-of-week names (e.g. ['Monday', 'Wednesday']) to
  /// the integer weekday values used by [scheduleWorkoutReminder].
  static List<int> weekdaysFromDayNames(List<String> dayNames) {
    return dayNames
        .map((n) => _dayNameToInt[n])
        .whereType<int>()
        .toList();
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

  /// Schedules a notification with exact timing, falling back to inexact if the
  /// SCHEDULE_EXACT_ALARM permission has been revoked on Android 12+.
  Future<void> _zonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: matchDateTimeComponents,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException {
      // SCHEDULE_EXACT_ALARM permission not granted or revoked — use inexact.
      CrashlyticsService().log(
        'NotificationService: exact alarm denied, falling back to inexact for id=$id',
      );
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: matchDateTimeComponents,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
