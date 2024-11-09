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
      {
        'id': 4,
        'title': 'Task 4',
        'description': 'Yearly audit report',
        'dueDate': DateTime.now().add(Duration(days: 365)).toIso8601String(),
        'isCompleted': false,
        'repeatDays': 'yearly', // Repeats every year
      },
    ];
  }

  // Function to get repeated tasks (daily, weekly, etc.)
  List<Map<String, dynamic>> _getRepeatedTasks() {
    return _tasks.where((task) {
      return task['repeatDays'] != 'once'; // Filter out tasks that are 'once'
    }).toList();
  }

  // Helper function to get the week number of the year
  int getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirst = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirst / 7).floor()) + 1;
  }

  // Function to check if two dates are in the same week
  bool _isSameWeek(DateTime date1, DateTime date2) {
    return date1.year == date2.year && getWeekOfYear(date1) == getWeekOfYear(date2);
  }

  // Function to check if task is due today and show notification
  void _checkIfTaskIsDueToday(Map<String, dynamic> task) {
    DateTime now = DateTime.now();
    DateTime taskDueDate = DateTime.parse(task['dueDate']);

    // Compare only the year, month, and day (ignore time portion)
    if (taskDueDate.year == now.year &&
        taskDueDate.month == now.month &&
        taskDueDate.day == now.day) {
      if (task['repeatDays'] != null) {
        // If the task repeats, add logic to show repeated task notification
        _showNotificationForRepeatedTask(task);
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

  // Check if task is due based on repeat type (daily, weekly, monthly, yearly)
  void _checkTaskDueDates() {
    DateTime now = DateTime.now();
    for (var task in _tasks) {
      DateTime taskDueDate = DateTime.parse(task['dueDate']);
      switch (task['repeatDays']) {
        case 'daily':
          // Show notification for daily tasks if due
          if (_isSameDay(now, taskDueDate)) {
            _showNotificationForRepeatedTask(task);
          }
          break;
        case 'weekly':
          // Show notification for weekly tasks if due
          if (_isSameWeek(now, taskDueDate)) {
            _showNotificationForRepeatedTask(task);
          }
          break;
        case 'monthly':
          // Show notification for monthly tasks if due
          if (_isSameMonth(now, taskDueDate)) {
            _showNotificationForRepeatedTask(task);
          }
          break;
        case 'yearly':
          // Show notification for yearly tasks if due
          if (_isSameYear(now, taskDueDate)) {
            _showNotificationForRepeatedTask(task);
          }
          break;
        default:
          break;
      }
    }
  }

  // Helper function to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Helper function to check if two dates are in the same month
  bool _isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  // Helper function to check if two dates are in the same year
  bool _isSameYear(DateTime date1, DateTime date2) {
    return date1.year == date2.year;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Task Manager"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Today'),
            Tab(text: 'Completed'),
            Tab(text: 'Repeated'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskListView(_getTasksForToday()),
          _buildTaskListView(_getCompletedTasks()),
          _buildTaskListView(_getRepeatedTasks()),
          _buildTaskListView(_tasks),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  // Function to build a task list view
  Widget _buildTaskListView(List<Map<String, dynamic>> tasks) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ListTile(
          title: Text(task['title']),
          subtitle: Text(task['description']),
          trailing: task['isCompleted']
              ? Icon(Icons.check_circle, color: Colors.green)
              : Icon(Icons.circle_outlined),
          onTap: () => _markTaskAsCompleted(task),
        );
      },
    );
  }

  // Get tasks for today
  List<Map<String, dynamic>> _getTasksForToday() {
    DateTime now = DateTime.now();
    return _tasks.where((task) {
      DateTime taskDueDate = DateTime.parse(task['dueDate']);
      return _isSameDay(now, taskDueDate);
    }).toList();
  }

  // Get completed tasks
  List<Map<String, dynamic>> _getCompletedTasks() {
    return _tasks.where((task) => task['isCompleted'] == 1).toList();
  }

  // Mark task as completed
  void _markTaskAsCompleted(Map<String, dynamic> task) {
    setState(() {
      task['isCompleted'] = 1;
    });
  }

  // Dialog to add new task
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
                items: <String>['once', 'daily', 'weekly', 'monthly', 'yearly']
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

  // Add task
  void _addTask(String title, String description, DateTime dueDate, String repeatDays) {
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

    // Check if task is due today and show notification
    _checkIfTaskIsDueToday(newTask);
  }
}
