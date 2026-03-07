import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/material.dart';
import '../models/todo_item.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> scheduleNotification(TodoItem item) async {
    if (item.reminderTime == null || item.recurrence == RecurrenceType.none) return;

    // יצירת תוכן ההתראה
    String body = item.description ?? "זמן לביצוע הטקס!";
    
    await _notificationsPlugin.zonedSchedule(
      item.id.hashCode, // מזהה ייחודי מבוסס על ה-ID של המשימה
      item.title,
      body,
      _nextInstanceOfTime(item),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'rituals_channel',
          'טקסים ומשימות מחזוריות',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: _getDateTimeComponents(item.recurrence),
    );
  }

  static DateTimeComponents? _getDateTimeComponents(RecurrenceType type) {
    if (type == RecurrenceType.daily) return DateTimeComponents.time;
    if (type == RecurrenceType.weekly) return DateTimeComponents.dayOfWeekAndTime;
    if (type == RecurrenceType.monthly) return DateTimeComponents.dayOfMonthAndTime;
    return null;
  }

  static tz.TZDateTime _nextInstanceOfTime(TodoItem item) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final TimeOfDay time = item.reminderTime!;
    
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, time.hour, time.minute);

    if (item.recurrence == RecurrenceType.weekly && item.repeatValue != null) {
      // התאמה ליום בשבוע (DateTime 1=Mon, 7=Sun | repeatValue 1=Sun, 7=Sat)
      // פלאטר לרוב עובד עם 1=Mon, נתאים לערך ששמרת
      int targetDay = item.repeatValue!; 
      while (scheduledDate.weekday != targetDay) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
    } else if (item.recurrence == RecurrenceType.monthly && item.repeatValue != null) {
      scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, item.repeatValue!, time.hour, time.minute);
    }

    if (scheduledDate.isBefore(now)) {
      if (item.recurrence == RecurrenceType.daily) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      } else if (item.recurrence == RecurrenceType.weekly) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      } else if (item.recurrence == RecurrenceType.monthly) {
        scheduledDate = tz.TZDateTime(
          tz.local, now.year, now.month + 1, item.repeatValue!, time.hour, time.minute);
      }
    }
    return scheduledDate;
  }

  static Future<void> cancelNotification(String id) async {
    await _notificationsPlugin.cancel(id.hashCode);
  }
}