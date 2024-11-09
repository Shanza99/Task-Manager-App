import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeNotifications();
    _loadDummyTasks();
  }

  // Initialize local notifications
  Future<void> _initializeNotifications() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    
    // Schedule notification for today's tasks
    _scheduleTodaysTasksNotifications();
  }

  // Schedule notifications for today's tasks
  void _scheduleTodaysTasksNotifications() {
    final todayTasks = _getTasksForToday();
    for (var task in todayTasks) {
      _scheduleNotification(task);
    }
  }

  // Schedule local notification for a task
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

    await _flutterLocalNotificationsPlugin.schedule(
      task['id'], // Ensure 'id' is a unique integer for each task
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
        'dueDate': DateTime.now().add(Duration(hours: 2)).toIso8601String(),
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

  // Dummy method to get today's tasks
  List<Map<String, dynamic>> _getTasksForToday() {
    return _tasks.where((task) {
      DateTime taskDate = DateTime.parse(task['dueDate']);
      return taskDate.year == DateTime.now().year &&
             taskDate.month == DateTime.now().month &&
             taskDate.day == DateTime.now().day;
    }).toList();
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

  Widget _buildTaskList(List<Map<String, dynamic>> tasks) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ListTile(
          title: Text(task['title']),
          subtitle: Text(task['description']),
          trailing: Checkbox(
            value: task['isCompleted'],
            onChanged: (bool? value) {
              setState(() {
                task['isCompleted'] = value ?? false;
              });
            },
          ),
          onTap: () => _showEditTaskDialog(context, task),
        );
      },
    );
  }

  // Dummy methods for demo purposes
  List<Map<String, dynamic>> _getCompletedTasks() => _tasks.where((task) => task['isCompleted']).toList();
  List<Map<String, dynamic>> _getRepeatedTasks() => _tasks.where((task) => task['repeatDays'] != null).toList();

  

// Show dialog to add a new task
void _showAddTaskDialog(BuildContext context) {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController dueDateController = TextEditingController();
  String? selectedRepeat = 'None';

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Add Task"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Task Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Task Description'),
              ),
              TextField(
                controller: dueDateController,
                decoration: InputDecoration(labelText: 'Due Date (YYYY-MM-DD HH:MM)'),
              ),
              DropdownButtonFormField<String>(
                value: selectedRepeat,
                decoration: InputDecoration(labelText: 'Repeat'),
                items: ['None', 'Daily', 'Weekly', 'Monthly'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedRepeat = newValue;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _tasks.add({
                  'id': _tasks.length + 1, // Simple unique ID for each task
                  'title': titleController.text,
                  'description': descriptionController.text,
                  'dueDate': dueDateController.text,
                  'isCompleted': false,
                  'repeatDays': selectedRepeat,
                });
              });
              Navigator.of(context).pop();
            },
            child: Text("Add"),
          ),
        ],
      );
    },
  );
}

// Show dialog to edit an existing task
void _showEditTaskDialog(BuildContext context, Map<String, dynamic> task) {
  final TextEditingController titleController = TextEditingController(text: task['title']);
  final TextEditingController descriptionController = TextEditingController(text: task['description']);
  final TextEditingController dueDateController = TextEditingController(text: task['dueDate']);
  String? selectedRepeat = task['repeatDays'];

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Edit Task"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Task Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Task Description'),
              ),
              TextField(
                controller: dueDateController,
                decoration: InputDecoration(labelText: 'Due Date (YYYY-MM-DD HH:MM)'),
              ),
              DropdownButtonFormField<String>(
                value: selectedRepeat,
                decoration: InputDecoration(labelText: 'Repeat'),
                items: ['None', 'Daily', 'Weekly', 'Monthly'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedRepeat = newValue;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                task['title'] = titleController.text;
                task['description'] = descriptionController.text;
                task['dueDate'] = dueDateController.text;
                task['repeatDays'] = selectedRepeat;
              });
              Navigator.of(context).pop();
            },
            child: Text("Save"),
          ),
        ],
      );
    },
  );
}
}