import 'dart:html' as html;
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

class _TaskHomePageState extends State<TaskHomePage> with SingleTickerProviderStateMixin {
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  List<Map<String, dynamic>> _tasks = [];
  late TabController _tabController;
  bool isWeb = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    isWeb = (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS);

    if (!isWeb) {
      _initializeNotifications(); // Initialize notifications for mobile/desktop
    }
    _loadDummyTasks(); // Load dummy tasks for testing
  }

  // Initialize local notifications for mobile/desktop platforms
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

  // Dummy function to load tasks (for testing purposes)
  void _loadDummyTasks() {
    _tasks = [
      {
        'id': 1,
        'title': 'Task 1',
        'description': 'Complete project report',
        'dueDate': DateTime.now().add(Duration(seconds: 10)).toIso8601String(),
        'isCompleted': false,
        'repeatDays': 'daily', // Repeats every day
      },
      {
        'id': 2,
        'title': 'Task 2',
        'description': 'Call client',
        'dueDate': DateTime.now().add(Duration(seconds: 20)).toIso8601String(),
        'isCompleted': false,
        'repeatDays': 'weekly', // Repeats every week
      },
      {
        'id': 3,
        'title': 'Task 3',
        'description': 'Submit monthly report',
        'dueDate': DateTime.now().add(Duration(seconds: 30)).toIso8601String(),
        'isCompleted': false,
        'repeatDays': 'monthly', // Repeats every month
      },
    ];
  }

  // Filter tasks for repeated tasks
  List<Map<String, dynamic>> _getRepeatedTasks() {
    return _tasks.where((task) {
      return task['repeatDays'] != null && task['repeatDays'] != '';
    }).toList();
  }

  // Function to check if task is due today and show notification
  void _checkIfTaskIsDueToday(Map<String, dynamic> task) {
    DateTime now = DateTime.now();
    DateTime taskDueDate = DateTime.parse(task['dueDate']);

    // Check if the task's due date is today
    if (taskDueDate.year == now.year && taskDueDate.month == now.month && taskDueDate.day == now.day) {
      if (task['repeatDays'] != null) {
        // If the task repeats, add logic to show repeated task notification
        if (task['repeatDays'] == 'daily') {
          _showNotificationForRepeatedTask(task);
        }
      }
    }
  }

  // Function to show notification for repeated tasks
  void _showNotificationForRepeatedTask(Map<String, dynamic> task) {
    if (isWeb) {
      showWebNotification(
        "Repeated Task: ${task['title']}",
        "Your task is due today: ${task['description']}",
      );
    } else {
      _showDesktopNotification(
        "Repeated Task: ${task['title']}",
        "Your task is due today: ${task['description']}",
      );
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

  // Fetch tasks for different tabs
  List<Map<String, dynamic>> _getTasksForToday() {
    final today = DateTime.now();
    return _tasks.where((task) {
      final dueDate = DateTime.parse(task['dueDate']);
      return dueDate.year == today.year &&
          dueDate.month == today.month &&
          dueDate.day == today.day &&
          task['isCompleted'] == 0;
    }).toList();
  }

  List<Map<String, dynamic>> _getCompletedTasks() {
    return _tasks.where((task) => task['isCompleted'] == 1).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Manager'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All Tasks'),
            Tab(text: 'Today\'s Tasks'),
            Tab(text: 'Completed'),
            Tab(text: 'Repeated'), // Repeated tab
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(_tasks),
          _buildTaskList(_getTasksForToday()),
          _buildTaskList(_getCompletedTasks()),
          _buildTaskList(_getRepeatedTasks()), // Show repeated tasks
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  // Function to build task list
  Widget _buildTaskList(List<Map<String, dynamic>> tasks) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        var task = tasks[index];
        return ListTile(
          title: Text(task['title']),
          subtitle: Text(task['description']),
          trailing: IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              setState(() {
                task['isCompleted'] = 1; // Mark as completed
              });
            },
          ),
        );
      },
    );
  }

  // Dialog to add a new task
  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String repeatValue = 'daily'; // Default repeat value

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Task Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Task Description'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    selectedDate = pickedDate;
                  }
                },
                child: Text('Pick Due Date'),
              ),
              DropdownButton<String>(
                value: repeatValue,
                items: <String>['daily', 'weekly', 'monthly']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    repeatValue = newValue!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final title = titleController.text;
                final description = descriptionController.text;
                if (title.isNotEmpty && description.isNotEmpty) {
                  _addTask(title, description, selectedDate, repeatValue);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add Task'),
            ),
          ],
        );
      },
    );
  }

  // Function to add task
  Future<void> _addTask(String title, String description, DateTime dueDate, String repeatDays) async {
    final newTask = {
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': 0,
      'repeatDays': repeatDays,
    };
    setState(() {
      _tasks.add(newTask);
    });

    // Check if the task is due today and show notification
    _checkIfTaskIsDueToday(newTask);
  }
}
