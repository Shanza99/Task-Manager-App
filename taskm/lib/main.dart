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
    bool isRepeating = task['isRepeating'];
    String repeatInterval = task['repeatInterval'] ?? 'None';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Task'),
          content: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              // DateTime Picker
              Row(
                children: [
                  Text("Due Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}"),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null && pickedDate != selectedDate) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Text("Time: ${DateFormat('HH:mm').format(selectedDate)}"),
                  IconButton(
                    icon: Icon(Icons.access_time),
                    onPressed: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedDate = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    },
                  ),
                ],
              ),
              // Repeating task selection
              Row(
                children: [
                  Text("Repeat: "),
                  DropdownButton<String>(
                    value: repeatInterval,
                    items: ['None', 'Daily', 'Weekly', 'Monthly']
                        .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        repeatInterval = value!;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  task['title'] = titleController.text;
                  task['description'] = descriptionController.text;
                  task['dueDate'] = selectedDate.toIso8601String();
                  task['isRepeating'] = isRepeating;
                  task['repeatInterval'] = repeatInterval;
                  // After saving, check if task is due today
                  _checkIfTaskIsDueToday(task);
                });
                Navigator.pop(context);
              },
              child: Text('Save Task'),
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
    bool isRepeating = false;
    String repeatInterval = 'None';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Task'),
          content: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              // DateTime Picker
              Row(
                children: [
                  Text("Due Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}"),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null && pickedDate != selectedDate) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Text("Time: ${DateFormat('HH:mm').format(selectedDate)}"),
                  IconButton(
                    icon: Icon(Icons.access_time),
                    onPressed: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedDate = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    },
                  ),
                ],
              ),
              // Repeating task selection
              Row(
                children: [
                  Text("Repeat: "),
                  DropdownButton<String>(
                    value: repeatInterval,
                    items: ['None', 'Daily', 'Weekly', 'Monthly']
                        .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        repeatInterval = value!;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _tasks.add({
                    'id': DateTime.now().millisecondsSinceEpoch,
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'dueDate': selectedDate.toIso8601String(),
                    'isCompleted': false,
                    'isRepeating': isRepeating,
                    'repeatInterval': repeatInterval,
                  });
                  // Check if the newly created task is due today
                  _checkIfTaskIsDueToday(_tasks.last);
                });
                Navigator.pop(context);
              },
              child: Text('Add Task'),
            ),
          ],
        );
      },
    );
  }
}
