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
  static const _keyStreakEnabled = 'notif_streak_enabled';

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

    await _plugin.zonedSchedule(
      _streakNotifId,
      'Keep your streak alive!',
      'Log a workout today to maintain your streak.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_reminders',
          'Streak Reminders',
          channelDescription: 'Daily reminder to keep your workout streak going',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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

  static const _restTimerNotifId = 100;
  static const _restDoneNotifId = 101;

  /// Show an ongoing notification and schedule a "Rest Complete" alert.
  Future<void> showRestTimerNotification(int seconds) async {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final timerText = '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    // Show ongoing notification with timer info
    await _plugin.show(
      _restTimerNotifId,
      'Rest Timer',
      'Resting for $timerText',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'rest_timer',
          'Rest Timer',
          channelDescription: 'Rest timer countdown during workouts',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          showWhen: false,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );

    // Schedule a "Rest Complete" notification for when the timer ends
    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
    await _plugin.zonedSchedule(
      _restDoneNotifId,
      'Rest Complete!',
      'Time to get back to work!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'rest_timer_done',
          'Rest Timer Done',
          channelDescription: 'Notification when rest timer completes',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Cancel rest timer notifications.
  Future<void> cancelRestTimerNotification() async {
    await _plugin.cancel(_restTimerNotifId);
    await _plugin.cancel(_restDoneNotifId);
  }

  /// Fire the "Rest Complete" notification immediately (for foreground completion).
  /// This ensures the user gets an audible alert even when the app is in the foreground.
  Future<void> showRestCompleteNow() async {
    await _plugin.cancel(_restTimerNotifId); // Remove ongoing timer notif
    await _plugin.cancel(_restDoneNotifId); // Cancel scheduled one
    await _plugin.show(
      _restDoneNotifId,
      'Rest Complete!',
      'Time to get back to work!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'rest_timer_done',
          'Rest Timer Done',
          channelDescription: 'Notification when rest timer completes',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Cancel only the ongoing timer notification (keep the scheduled completion).
  Future<void> cancelOngoingTimerNotification() async {
    await _plugin.cancel(_restTimerNotifId);
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
