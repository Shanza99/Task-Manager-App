import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeNotifications();
  runApp(MyApp());
}

Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Request notification permissions
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TaskScreen(),
    );
  }
}

class Task {
  final String title;
  final String description;
  final DateTime date;
  final bool isRepeated;

  Task({
    required this.title,
    required this.description,
    required this.date,
    required this.isRepeated,
  });

  // Convert Task to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'isRepeated': isRepeated,
    };
  }

  // Create Task from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      isRepeated: json['isRepeated'],
    );
  }
}

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // Load tasks from shared preferences
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString('tasks');
    if (tasksJson != null) {
      final List<dynamic> taskList = jsonDecode(tasksJson);
      setState(() {
        _tasks.clear();
        _tasks.addAll(taskList.map((json) => Task.fromJson(json)).toList());
      });
    }
  }

  // Save tasks to shared preferences
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String tasksJson = jsonEncode(_tasks.map((task) => task.toJson()).toList());
    await prefs.setString('tasks', tasksJson);
  }

  // Add task and schedule notification
  void _addTask(String title, String description, DateTime date, bool isRepeated) {
    final task = Task(
      title: title,
      description: description,
      date: date,
      isRepeated: isRepeated,
    );

    setState(() {
      _tasks.add(task);
    });
    _saveTasks();
    _scheduleNotification(task);
  }

  // Schedule notification for a task
  Future<void> _scheduleNotification(Task task) async {
    var androidDetails = const AndroidNotificationDetails(
      'task_channel_id',
      'Task Notifications',
      channelDescription: 'Notifications for tasks due',
      importance: Importance.high,
      priority: Priority.high,
    );

    var notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.schedule(
      task.date.hashCode, // Unique ID for each task
      task.title,
      task.description,
      task.date,
      notificationDetails,
      androidAllowWhileIdle: true,
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool isRepeated = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                    }
                  },
                  child: const Text('Select Date'),
                ),
                TextButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        selectedDate = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  },
                  child: const Text('Select Time'),
                ),
              ],
            ),
            CheckboxListTile(
              title: const Text('Repeat'),
              value: isRepeated,
              onChanged: (value) {
                setState(() {
                  isRepeated = value ?? false;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final title = titleController.text;
              final description = descriptionController.text;
              _addTask(title, description, selectedDate, isRepeated);
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task App'),
      ),
      body: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return ListTile(
            title: Text(task.title),
            subtitle: Text(task.description),
            trailing: Text(task.date.toString()),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTaskDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
