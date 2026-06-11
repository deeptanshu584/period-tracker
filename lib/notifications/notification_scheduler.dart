import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/models/prediction_result.dart';
import '../data/models/user_prefs.dart';
import '../core/constants/cycle_constants.dart';

class NotificationScheduler {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback if timezone cannot be determined
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false, 
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: darwinInit);
    await _plugin.initialize(
      settings: initSettings,
    );
  }

  static Future<void> requestPermissions() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
      await androidImpl.requestExactAlarmsPermission();
    }
    
    final iosImpl = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      await iosImpl.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<void> reschedule(PredictionResult? prediction, UserPrefs prefs) async {
    // Always cancel existing notifications to ensure we don't have stale ones
    await _plugin.cancelAll();

    if (!prefs.notificationsEnabled || prediction == null) {
      return;
    }

    final leadDays = prefs.notificationLeadDays;
    final targetDate = prediction.nextPeriodStart.subtract(Duration(days: leadDays));
    
    // Schedule for the correct hour in the user's local timezone
    final scheduledDate = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      kNotificationHour,
    );

    final now = DateTime.now();
    if (scheduledDate.isBefore(now)) {
      return; // The reminder time has already passed
    }

    if (scheduledDate.difference(now).inDays > kMaxFutureNotificationDays) {
      return; // Don't schedule more than 60 days in advance per GEMINI.md
    }

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'period_tracker_channel',
      'Period Reminders',
      channelDescription: 'Reminders for upcoming periods',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(android: androidDetails, iOS: darwinDetails);

    await _plugin.zonedSchedule(
      id: 0, 
      title: 'Period incoming',
      body: 'Your period is expected in $leadDays ${leadDays == 1 ? 'day' : 'days'}.',
      scheduledDate: tzDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
