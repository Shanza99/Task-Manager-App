import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart'; // Only import this for the date-time picker widget.
import 'package:flutter_datetime_picker/src/datetime_picker_theme.dart';

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
  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
    _loadDummyTasks();
    _scheduleTodayTaskNotifications();
  }
Future<void> _initializeNotifications() async {
  const initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

  // Initialize notifications without manually requesting permissions
  await _flutterLocalNotificationsPlugin?.initialize(initializationSettings);
}

  Future<void> _scheduleNotification(Map<String, dynamic> task) async {
    DateTime dueDate = DateTime.parse(task['dueDate']);
    var scheduledTime = dueDate.subtract(Duration(minutes: 10));

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
      'Your task "${task['title']}" is due soon!',
      scheduledTime,
      platformDetails,
    );
  }

  void _loadDummyTasks() {
    _tasks = [
      {
        'id': 1,
        'title': 'Task 1',
        'description': 'Complete project report',
        'dueDate': DateTime.now().add(Duration(hours: 1)).toIso8601String(),
        'isCompleted': false,
        'repeatDays': 'None',
      },
      {
        'id': 2,
        'title': 'Task 2',
        'description': 'Call client',
        'dueDate': DateTime.now().add(Duration(days: 1)).toIso8601String(),
        'isCompleted': false,
        'repeatDays': 'Daily',
      },
    ];
  }

  void _scheduleTodayTaskNotifications() {
    DateTime now = DateTime.now();
    for (var task in _tasks) {
      DateTime taskDueDate = DateTime.parse(task['dueDate']);
      if (taskDueDate.year == now.year &&
          taskDueDate.month == now.month &&
          taskDueDate.day == now.day &&
          task['isCompleted'] == false) {
        _scheduleNotification(task);
      }
    }
  }

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

  void _exportToEmail() {
    final String email = "example@example.com"; 
    final String subject = Uri.encodeComponent("Task List");
    final String body = Uri.encodeComponent(_generateTaskListForEmail());

    final String url = "mailto:$email?subject=$subject&body=$body";
    launch(url);
  }

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

  List<Map<String, dynamic>> _getTasksForToday() {
    return _tasks.where((task) {
      DateTime taskDate = DateTime.parse(task['dueDate']);
      return taskDate.year == DateTime.now().year && taskDate.month == DateTime.now().month && taskDate.day == DateTime.now().day;
    }).toList();
  }

  List<Map<String, dynamic>> _getCompletedTasks() {
    return _tasks.where((task) => task['isCompleted'] == true).toList();
  }

  List<Map<String, dynamic>> _getRepeatedTasks() {
    return _tasks.where((task) => task['repeatDays'] != 'None').toList();
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedRepeat = 'None';
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
              TextField(controller: descriptionController, decoration: InputDecoration(labelText: 'Description')),
              GestureDetector(
                onTap: () {
                  DatePicker.showDateTimePicker(
                    context,
                    showTitleActions: true,
                    onConfirm: (date) {
                      setState(() {
                        dueDate = date;
                      });
                    },
                    currentTime: DateTime.now(),
                    locale: LocaleType.en,
                  );
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: TextEditingController(text: dueDate == null ? "" : dueDate!.toString()),
                    decoration: InputDecoration(labelText: 'Due Date'),
                  ),
                ),
              ),
              DropdownButtonFormField<String>(
                value: selectedRepeat,
                items: ['None', 'Daily', 'Weekly', 'Monthly']
                    .map((repeat) => DropdownMenuItem(value: repeat, child: Text(repeat)))
                    .toList(),
                onChanged: (newValue) => selectedRepeat = newValue,
                decoration: InputDecoration(labelText: 'Repeat'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text("Cancel")),
            TextButton(
              onPressed: () {
                setState(() {
                  _tasks.add({
                    'id': _tasks.length + 1,
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'dueDate': dueDate?.toIso8601String(),
                    'isCompleted': false,
                    'repeatDays': selectedRepeat,
                  });
                });
                Navigator.of(context).pop();
                if (selectedRepeat == 'None') {
                  _scheduleNotification({
                    'id': _tasks.length,
                    'title': titleController.text,
                    'dueDate': dueDate?.toIso8601String(),
                  });
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _showEditTaskDialog(BuildContext context, Map<String, dynamic> task) {
    final titleController = TextEditingController(text: task['title']);
    final descriptionController = TextEditingController(text: task['description']);
    String? selectedRepeat = task['repeatDays'];
    DateTime? dueDate = DateTime.parse(task['dueDate']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
              TextField(controller: descriptionController, decoration: InputDecoration(labelText: 'Description')),
              GestureDetector(
                onTap: () {
                  DatePicker.showDateTimePicker(
                    context,
                    showTitleActions: true,
                    onConfirm: (date) {
                      setState(() {
                        dueDate = date;
                      });
                    },
                    currentTime: dueDate,
                    locale: LocaleType.en,
                  );
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: TextEditingController(text: dueDate?.toString() ?? ""),
                    decoration: InputDecoration(labelText: 'Due Date'),
                  ),
                ),
              ),
              DropdownButtonFormField<String>(
                value: selectedRepeat,
                items: ['None', 'Daily', 'Weekly', 'Monthly']
                    .map((repeat) => DropdownMenuItem(value: repeat, child: Text(repeat)))
                    .toList(),
                onChanged: (newValue) => selectedRepeat = newValue,
                decoration: InputDecoration(labelText: 'Repeat'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text("Cancel")),
            TextButton(
              onPressed: () {
                setState(() {
                  task['title'] = titleController.text;
                  task['description'] = descriptionController.text;
                  task['dueDate'] = dueDate?.toIso8601String();
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
