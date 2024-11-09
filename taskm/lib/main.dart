import 'dart:html' as html;
import 'dart:convert';  // for encoding CSV to string
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart'; // CSV generation
import 'package:pdf/widgets.dart' as pw;  // PDF generation
import 'package:flutter_email_sender/flutter_email_sender.dart'; // Email sending
import 'package:path_provider/path_provider.dart';  // File storage access
import 'dart:io'; // for file handling

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
      persistentFooterButtons: [
        TextButton(
          onPressed: _exportTasksToCSV,
          child: Text("Export to CSV"),
        ),
        TextButton(
          onPressed: _exportTasksToPDF,
          child: Text("Export to PDF"),
        ),
        TextButton(
          onPressed: _sendTasksByEmail,
          child: Text("Send by Email"),
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

  // Function to export tasks to CSV
  void _exportTasksToCSV() async {
    List<List<dynamic>> rows = [
      ["ID", "Title", "Description", "Due Date", "Completed"]
    ];

    for (var task in _tasks) {
      rows.add([
        task['id'],
        task['title'],
        task['description'],
        task['dueDate'],
        task['isCompleted'] ? 'Yes' : 'No',
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/tasks.csv');
    await file.writeAsString(csv);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tasks exported to CSV')));
  }

  // Function to export tasks to PDF
  void _exportTasksToPDF() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (pw.Context context) {
      return pw.Column(
        children: [
          pw.Text("Task List", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(headers: ["ID", "Title", "Description", "Due Date", "Completed"], data: [
            for (var task in _tasks)
              [
                task['id'],
                task['title'],
                task['description'],
                task['dueDate'],
                task['isCompleted'] ? 'Yes' : 'No',
              ],
          ]),
        ],
      );
    }));

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/tasks.pdf');
    await file.writeAsBytes(await pdf.save());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tasks exported to PDF')));
  }

  // Function to send tasks by email
  void _sendTasksByEmail() async {
    final Email email = Email(
      body: _generateTaskSummary(),
      subject: 'Tasks Report',
      recipients: ['recipient@example.com'],
      isHTML: false,
    );

    await FlutterEmailSender.send(email);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tasks sent via email')));
  }

  // Function to generate task summary for email
  String _generateTaskSummary() {
    StringBuffer sb = StringBuffer();
    sb.writeln('Task Summary\n');
    for (var task in _tasks) {
      sb.writeln('Title: ${task['title']}');
      sb.writeln('Description: ${task['description']}');
      sb.writeln('Due Date: ${task['dueDate']}');
      sb.writeln('Completed: ${task['isCompleted'] ? 'Yes' : 'No'}\n');
    }
    return sb.toString();
  }

  // Function to show add task dialog (simplified)
  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Task Title'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Task Description'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () {}, child: Text('Add')),
          ],
        );
      },
    );
  }

  // Function to show edit task dialog (simplified)
  void _showEditTaskDialog(BuildContext context, Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: task['title']),
                decoration: InputDecoration(labelText: 'Task Title'),
              ),
              TextField(
                controller: TextEditingController(text: task['description']),
                decoration: InputDecoration(labelText: 'Task Description'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () {}, child: Text('Save')),
          ],
        );
      },
    );
  }
}
