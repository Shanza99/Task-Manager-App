import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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

  // Export tasks to CSV
  void _exportToCSV() async {
    List<List<dynamic>> rows = [];
    rows.add(["ID", "Title", "Description", "Due Date", "Completed", "Repeating", "Repeat Interval"]);

    for (var task in _tasks) {
      rows.add([
        task['id'],
        task['title'],
        task['description'],
        task['dueDate'],
        task['isCompleted'] ? "Yes" : "No",
        task['isRepeating'] ? "Yes" : "No",
        task['repeatInterval'] ?? "None",
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/tasks.csv";
    File file = File(path);
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV file saved at: $path')));
  }

  // Export tasks to PDF
  void _exportToPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: ["ID", "Title", "Description", "Due Date", "Completed", "Repeating", "Repeat Interval"],
            data: _tasks.map((task) {
              return [
                task['id'],
                task['title'],
                task['description'],
                task['dueDate'],
                task['isCompleted'] ? "Yes" : "No",
                task['isRepeating'] ? "Yes" : "No",
                task['repeatInterval'] ?? "None",
              ];
            }).toList(),
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/tasks.pdf";
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF file saved at: $path')));
  }

  // Export tasks via Email
  void _exportToEmail() async {
    final email = Email(
      body: 'Tasks exported from Task Manager App: \n\n' + _tasks.map((task) {
        return "ID: ${task['id']}\nTitle: ${task['title']}\nDescription: ${task['description']}\nDue Date: ${task['dueDate']}\nCompleted: ${task['isCompleted'] ? "Yes" : "No"}\n\n";
      }).join(),
      subject: 'Task Export',
      recipients: ['recipient@example.com'],
      isHTML: false,
    );
    
    await FlutterEmailSender.send(email);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tasks sent via email')));
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
        ElevatedButton(
          onPressed: _exportToCSV,
          child: Text('Export to CSV'),
        ),
        ElevatedButton(
          onPressed: _exportToPDF,
          child: Text('Export to PDF'),
        ),
        ElevatedButton(
          onPressed: _exportToEmail,
          child: Text('Email Tasks'),
        ),
      ],
    );
  }

  // Build task list
  Widget _buildTaskList(List<Map<String, dynamic>> tasks) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> task = tasks[index];
        return ListTile(
          title: Text(task['title']),
          subtitle: Text(task['description']),
          trailing: IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              setState(() {
                task['isCompleted'] = true;
              });
              _checkIfTaskIsDueToday(task); // Check if task is due today
            },
          ),
        );
      },
    );
  }

  // Show dialog to add new task
  void _showAddTaskDialog(BuildContext context) {
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Task'),
          content: Column(
            children: [
              TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
              TextField(controller: descriptionController, decoration: InputDecoration(labelText: 'Description')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _tasks.add({
                    'id': _tasks.length + 1,
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'dueDate': DateTime.now().add(Duration(minutes: 5)).toIso8601String(),
                    'isCompleted': false,
                    'isRepeating': false,
                    'repeatInterval': null,
                  });
                });
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
