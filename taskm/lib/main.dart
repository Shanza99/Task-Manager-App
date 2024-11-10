import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'task_exporter.dart'; // Import TaskExporter

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
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        flutterLocalNotificationsPlugin!.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    }
    _loadDummyTasks(); // Load dummy tasks for testing
  }

  // Initialize local notifications for mobile/desktop platforms
  void _initializeNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
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
        'isRepeating': false,
        'repeatInterval': null, // No repeating interval
      },
      {
        'id': 2,
        'title': 'Task 2',
        'description': 'Call client',
        'dueDate': DateTime.now().add(Duration(seconds: 20)).toIso8601String(),
        'isCompleted': false,
        'isRepeating': false,
        'repeatInterval': null, // No repeating interval
      },
    ];
  }

  // Check if task is due today and show notification
  void _checkIfTaskIsDueToday(Map<String, dynamic> task) {
    DateTime now = DateTime.now();
    DateTime taskDueDate = DateTime.parse(task['dueDate']);

    // Compare only the year, month, and day (ignore time portion)
    if (taskDueDate.year == now.year &&
        taskDueDate.month == now.month &&
        taskDueDate.day == now.day) {
      if (task['isCompleted'] == false) {
        _showNotificationForTask(task);
      }
    }
  }

  // Function to show notification for tasks due today
  void _showNotificationForTask(Map<String, dynamic> task) {
    if (isWeb) {
      showWebNotification(
        "Task Due Today: ${task['title']}",
        "Don't forget to complete: ${task['description']}",
      );
    } else {
      _showDesktopNotification(
        "Task Due Today: ${task['title']}",
        "Don't forget to complete: ${task['description']}",
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
          task['isCompleted'] == false;  // Only show non-completed tasks
    }).toList();
  }

  List<Map<String, dynamic>> _getCompletedTasks() {
    return _tasks.where((task) => task['isCompleted'] == true).toList();
  }

  // Export methods (added for the exporting feature)
  void _exportToPDF() {
    TaskExporter.exportToPDF(_tasks, context); // Pass BuildContext here
  }

  void _exportToCSV() {
    TaskExporter.exportToCSV(_tasks, context); // Pass BuildContext here
  }

  void _exportToEmail() {
    TaskExporter.exportToEmail(_tasks, context); // Pass BuildContext here
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(_tasks),
          _buildTaskList(_getTasksForToday()),
          _buildTaskList(_getCompletedTasks()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: Icon(Icons.add),
      ),
      // Adding the export buttons for PDF, CSV, and Email export
      persistentFooterButtons: [
        ElevatedButton(
          onPressed: _exportToPDF, // Trigger export to PDF
          child: Text('Export to PDF'),
        ),
        ElevatedButton(
          onPressed: _exportToCSV, // Trigger export to CSV
          child: Text('Export to CSV'),
        ),
        ElevatedButton(
          onPressed: _exportToEmail, // Trigger export via Email
          child: Text('Export via Email'),
        ),
      ],
    );
  }

  // Function to build task list
  Widget _buildTaskList(List<Map<String, dynamic>> tasks) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        var task = tasks[index];
        return ListTile(
          title: Row(
            children: [
              Text(task['title']),
              if (task['repeatInterval'] != 'None') ...[
                SizedBox(width: 8),
                Text(
                  '(Repeated)',
                  style: TextStyle(color: Colors.blue, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
          subtitle: Text(task['description']),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => _showEditTaskDialog(context, task),
              ),
              IconButton(
                icon: Icon(Icons.check),
                onPressed: () {
                  setState(() {
                    task['isCompleted'] = true; // Mark as completed
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  // Show delete confirmation dialog
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Delete Task'),
                        content: Text('Are you sure you want to delete this task?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Cancel the deletion
                            },
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _tasks.removeAt(index); // Remove task from list
                              });
                              Navigator.pop(context); // Close the dialog
                            },
                            child: Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Dialog to edit a task
  void _showEditTaskDialog(BuildContext context, Map<String, dynamic> task) {
    final titleController = TextEditingController(text: task['title']);
    final descriptionController = TextEditingController(text: task['description']);
    DateTime selectedDate = DateTime.parse(task['dueDate']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Task'),
          content: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Task Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Task Description'),
              ),
              // Date picker for due date
              Row(
                children: [
                  Text('Due Date: ${DateFormat.yMd().format(selectedDate)}'),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2121),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog without saving
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  task['title'] = titleController.text;
                  task['description'] = descriptionController.text;
                  task['dueDate'] = selectedDate.toIso8601String();
                });
                Navigator.pop(context); // Close dialog after saving
              },
              child: Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  // Dialog to add a new task
  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Task'),
          content: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Task Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Task Description'),
              ),
              // Date picker for due date
              Row(
                children: [
                  Text('Due Date: ${DateFormat.yMd().format(selectedDate)}'),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2121),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog without saving
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _tasks.add({
                    'id': _tasks.length + 1,
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'dueDate': selectedDate.toIso8601String(),
                    'isCompleted': false,
                    'isRepeating': false,
                    'repeatInterval': null, // Default to no repeat
                  });
                });
                Navigator.pop(context); // Close dialog after adding task
              },
              child: Text('Add Task'),
            ),
          ],
        );
      },
    );
  }
}
