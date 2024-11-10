import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._privateConstructor();
  static final NotificationService instance = NotificationService._privateConstructor();

  // Initialize notifications
  Future<void> initialize() async {
    tzData.initializeTimeZones(); // Ensure timezone data is loaded
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        const InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Schedule a notification
  Future<void> scheduleNotification(DateTime dateTime, String taskTitle) async {
    // Convert to TZDateTime
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(dateTime, tz.local);

    // Define the notification details
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        'task_channel_id',
        'Task Notifications',
        channelDescription: 'Notification for task reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    // Schedule the notification
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      taskTitle.hashCode,  // Use a unique ID for the task
      'Task Reminder',
      'Your task "$taskTitle" is due!',
      scheduledDate,
      platformChannelSpecifics,
      androidAllowWhileIdle: true,  // Important to allow notification when device is idle
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,  // Match based on the time of day
    );
  }
}
