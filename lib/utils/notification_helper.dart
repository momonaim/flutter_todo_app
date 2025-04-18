import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../db/database_helper.dart';
import '../main.dart';

class NotifHelper {
  static Future<void> showPendingTasksNotification(
      DateTime selectedDate) async {
    final dbHelper = DatabaseHelper();
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final todos = await dbHelper.getTodosByDate(dateStr);
    final pendingCount = todos.where((t) => !t.isDone).length;

    if (pendingCount == 0) return;

    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      channelDescription: 'Notification for today\'s tasks',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Tâches du jour',
      'Tu as $pendingCount tâche(s) à faire aujourd\'hui.',
      platformChannelSpecifics,
    );
  }

  static Future<void> scheduleDailyReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      channelDescription: 'Rappel quotidien à 23h',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'Rappel quotidien',
      'Vérifie si tu as terminé toutes tes tâches !',
      _nextInstanceOf23h(),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOf23h() {
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 23);
    return scheduled.isBefore(now)
        ? scheduled.add(const Duration(days: 1))
        : scheduled;
  }
}
