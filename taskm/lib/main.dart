import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TaskHomePage(),
    );
  }
}

class TaskHomePage extends StatefulWidget {
  @override
  _TaskHomePageState createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage> {
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  List<Map<String, dynamic>> _tasks = [];
  bool isWeb = false;

  @override
  void initState() {
    super.initState();
    isWeb = (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS);
    if (!isWeb) {
      _initializeNotifications();
    }
    _loadDummyTasks(); // Load dummy tasks for testing
  }

  // Initialize local notifications for desktop platforms
  void _initializeNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin!.initialize(initializationSettings);
  }

  // Function for triggering web notifications
  void showWebNotification(String title, String body) {
    if (html.Notification.permission == "granted") {
      html.Notification(title, body: body);
    } else if (html.Notification.permission != "denied") {
      html.Notification.requestPermission().then((permission) {
        if (permission == "granted") {
          html.Notification(title, body: body);
        }
      });
    }
  }

  // Dummy function to load tasks
  void _loadDummyTasks() {
    _tasks = [
      {
        'id': 1,
        'title': 'Task 1',
        'description': 'Complete project report',
        'dueDate': DateTime.now().add(Duration(seconds: 10)).toIso8601String(),
        'isCompleted': false,
      },
      {
        'id': 2,
        'title': 'Task 2',
        'description': 'Call client',
        'dueDate': DateTime.now().add(Duration(seconds: 20)).toIso8601String(),
        'isCompleted': false,
      },
    ];
  }

  // Function to check due tasks and send notifications
  void _checkTaskDueDate() {
    DateTime now = DateTime.now();

    for (var task in _tasks) {
      DateTime taskDueDate = DateTime.parse(task['dueDate']);

      // Check if the task is due right now
      if (taskDueDate.isBefore(now) && task['isCompleted'] == false) {
        if (isWeb) {
          // Trigger Web Notification
          showWebNotification(
            "Task Due: ${task['title']}",
            "Your task is due now: ${task['description']}",
          );
        } else {
          // Trigger Desktop Notification
          _showDesktopNotification(
            "Task Due: ${task['title']}",
            "Your task is due now: ${task['description']}",
          );
        }
      }
    }
  }

  // Function to show desktop notification (Flutter Local Notifications)
  void _showDesktopNotification(String title, String body) {
    var androidDetails = AndroidNotificationDetails(
      'task_channel_id',
      'Task Notifications',
      channelDescription: 'Channel for task notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    var generalNotificationDetails = NotificationDetails(android: androidDetails);
    flutterLocalNotificationsPlugin!
        .show(0, title, body, generalNotificationDetails);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Manager'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _checkTaskDueDate,
            child: Text('Check Task Due Dates'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return ListTile(
                  title: Text(task['title']),
                  subtitle: Text(task['description']),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _tasks.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
