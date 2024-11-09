import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';  // Import the plugin

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
  List<Map<String, dynamic>> _tasks = [];
  late TabController _tabController;
  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;  // Declare the plugin

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();  // Initialize the plugin
    _initializeNotifications();
    _loadDummyTasks();
  }

  // Initialize local notifications
  Future<void> _initializeNotifications() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin?.initialize(initializationSettings);
  }

  // Schedule local notification for task
  Future<void> _scheduleNotification(Map<String, dynamic> task) async {
    DateTime dueDate = DateTime.parse(task['dueDate']);
    var scheduledTime = dueDate.subtract(Duration(minutes: 10)); // Set 10 minutes before due date as notification time

    const androidDetails = AndroidNotificationDetails(
      'task_channel',
      'Task Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin?.schedule(
      task['id'],
      'Task Reminder',
      'Your task "${task['title']}" is due!',
      scheduledTime,
      platformDetails,
    );
  }

  // Load dummy tasks for demonstration
  void _loadDummyTasks() {
    _tasks = [
      {
        'id': 1,
        'title': 'Task 1',
        'description': 'Complete project report',
        'dueDate': DateTime.now().add(Duration(days: 1)).toIso8601String(),
        'isCompleted': false,
        'repeatDays': 'daily',
      },
      {
        'id': 2,
        'title': 'Task 2',
        'description': 'Call client',
        'dueDate': DateTime.now().add(Duration(days: 2)).toIso8601String(),
        'isCompleted': false,
        'repeatDays': 'weekly',
      },
      {
        'id': 3,
        'title': 'Task 3',
        'description': 'Submit monthly report',
        'dueDate': DateTime.now().add(Duration(days: 3)).toIso8601String(),
        'isCompleted': false,
        'repeatDays': 'monthly',
      },
    ];

    // Schedule notifications for all tasks
    for (var task in _tasks) {
      _scheduleNotification(task);
    }
  }

  // Export tasks to CSV
  void _exportToCSV() {
    List<List<dynamic>> rows = [
      ["ID", "Title", "Description", "Due Date", "Completed", "Repeat Days"]
    ];

    for (var task in _tasks) {
      List<dynamic> row = [];
      row.add(task['id']);
      row.add(task['title']);
      row.add(task['description']);
      row.add(task['dueDate']);
      row.add(task['isCompleted'] ? 'Yes' : 'No');
      row.add(task['repeatDays']);
      rows.add(row);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final bytes = Utf8Encoder().convert(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute("download", "tasks.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // Export tasks to PDF
  Future<void> _exportToPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.ListView.builder(
          itemCount: _tasks.length,
          itemBuilder: (context, index) {
            final task = _tasks[index];
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Task ${task['id']}: ${task['title']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text("Description: ${task['description']}"),
                pw.Text("Due Date: ${task['dueDate']}"),
                pw.Text("Completed: ${task['isCompleted'] ? 'Yes' : 'No'}"),
                pw.Text("Repeat Days: ${task['repeatDays']}"),
                pw.SizedBox(height: 10),
              ],
            );
          },
        ),
      ),
    );

    final pdfBytes = await pdf.save();
    final blob = html.Blob([pdfBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute("download", "tasks.pdf")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // Export tasks via email
  void _exportToEmail() {
    final String email = "example@example.com"; // Change to your email address
    final String subject = Uri.encodeComponent("Task List");
    final String body = Uri.encodeComponent(_generateTaskListForEmail());

    final String url = "mailto:$email?subject=$subject&body=$body";
    launch(url);
  }

  // Generate task list in string format for email
  String _generateTaskListForEmail() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln("Task List:");
    for (var task in _tasks) {
      buffer.writeln("Task ${task['id']}: ${task['title']}");
      buffer.writeln("Description: ${task['description']}");
      buffer.writeln("Due Date: ${task['dueDate']}");
      buffer.writeln("Completed: ${task['isCompleted'] ? 'Yes' : 'No'}");
      buffer.writeln("Repeat Days: ${task['repeatDays']}");
      buffer.writeln();
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Manager'),
        actions: [
          IconButton(icon: Icon(Icons.file_download), onPressed: _exportToCSV),
          IconButton(icon: Icon(Icons.picture_as_pdf), onPressed: _exportToPDF),
          IconButton(icon: Icon(Icons.email), onPressed: _exportToEmail),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All Tasks'),
            Tab(text: 'Today\'s Tasks'),
            Tab(text: 'Completed'),
            Tab(text: 'Repeated'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(_tasks),
          _buildTaskList(_getTasksForToday()),
          _buildTaskList(_getCompletedTasks()),
          _buildTaskList(_getRepeatedTasks()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  // Build task list view
  Widget _buildTaskList(List<Map<String, dynamic>> tasks) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        var task = tasks[index];
        return ListTile(
          title: Text(task['title']),
          subtitle: Text(task['description']),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: Icon(Icons.edit), onPressed: () => _showEditTaskDialog(context, task)),
              IconButton(
                icon: Icon(Icons.check),
                onPressed: () {
                  setState(() {
                    task['isCompleted'] = true;
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _tasks.removeAt(index);
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

// Dummy method to get today's tasks
List<Map<String, dynamic>> _getTasksForToday() {
  return _tasks.where((task) {
    DateTime dueDate = DateTime.parse(task['dueDate']);
    DateTime now = DateTime.now();
    
    // Compare only the date part (ignoring the time)
    return dueDate.year == now.year &&
           dueDate.month == now.month &&
           dueDate.day == now.day;
  }).toList();
}


  // Dummy method to get completed tasks
  List<Map<String, dynamic>> _getCompletedTasks() {
    return _tasks.where((task) => task['isCompleted']).toList();
  }

  // Dummy method to get repeated tasks
  List<Map<String, dynamic>> _getRepeatedTasks() {
    return _tasks.where((task) => task['repeatDays'] != null).toList();
  }

  // Show dialog to add task
  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Task'),
          content: Column(
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Description'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Due Date'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Add task logic here
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Show dialog to edit task
  void _showEditTaskDialog(BuildContext context, Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Task'),
          content: Column(
            children: [
              TextField(
                controller: TextEditingController(text: task['title']),
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: TextEditingController(text: task['description']),
                decoration: InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: TextEditingController(text: task['dueDate']),
                decoration: InputDecoration(labelText: 'Due Date'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Edit task logic here
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
