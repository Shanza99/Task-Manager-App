import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'task.dart';
import 'today_tasks.dart';
import 'completed_tasks.dart';
import 'repeated_tasks.dart';

void main() => runApp(TaskManagementApp());

class TaskManagementApp extends StatefulWidget {
  @override
  _TaskManagementAppState createState() => _TaskManagementAppState();
}

class _TaskManagementAppState extends State<TaskManagementApp> {
  bool _isDarkMode = false;
  final List<Task> tasks = [];
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    var initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _scheduleNotification(Task task) async {
    var androidDetails = AndroidNotificationDetails(
      'task_channel_id',
      'Task Notifications',
      'Channel for task reminders',
    );
    var notificationDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.schedule(
      task.hashCode,
      task.title,
      task.description,
      task.dueDate,
      notificationDetails,
    );
  }

  void _addTask(Task task) {
    setState(() {
      tasks.add(task);
    });
    _scheduleNotification(task);
  }

  void _showAddTaskDialog(BuildContext context) {
    final _taskTitleController = TextEditingController();
    final _taskDescriptionController = TextEditingController();
    DateTime? _selectedDate;
    bool _isCompleted = false;
    bool _isRepeated = false;
    List<String> _subtasks = [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: _taskTitleController,
                  decoration: InputDecoration(labelText: 'Task Title'),
                ),
                TextField(
                  controller: _taskDescriptionController,
                  decoration: InputDecoration(labelText: 'Task Description'),
                ),
                TextField(
                  readOnly: true,
                  decoration: InputDecoration(labelText: 'Due Date'),
                  onTap: () async {
                    _selectedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                  },
                ),
                CheckboxListTile(
                  title: Text("Mark as Completed"),
                  value: _isCompleted,
                  onChanged: (bool? value) {
                    setState(() {
                      _isCompleted = value ?? false;
                    });
                  },
                ),
                CheckboxListTile(
                  title: Text("Set as Repeated Task"),
                  value: _isRepeated,
                  onChanged: (bool? value) {
                    setState(() {
                      _isRepeated = value ?? false;
                    });
                  },
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Add Subtask'),
                  onSubmitted: (subtask) {
                    setState(() {
                      _subtasks.add(subtask);
                    });
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                if (_taskTitleController.text.isNotEmpty && _selectedDate != null) {
                  _addTask(Task(
                    title: _taskTitleController.text,
                    description: _taskDescriptionController.text,
                    dueDate: _selectedDate!,
                    isCompleted: _isCompleted,
                    isRepeated: _isRepeated,
                    subtasks: _subtasks,
                    completedSubtasks: 0,
                  ));
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void exportToCSV() async {
    List<List<String>> rows = [
      ["Title", "Description", "Due Date", "Status"],
    ];

    for (Task task in tasks) {
      List<String> row = [];
      row.add(task.title);
      row.add(task.description);
      row.add(task.dueDate.toString());
      row.add(task.isCompleted ? "Completed" : "Incomplete");
      rows.add(row);
    }

    String csv = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/tasks.csv";
    final file = File(path);
    await file.writeAsString(csv);

    print("Tasks exported to $path");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Management App',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Task Management App'),
          actions: [
            IconButton(
              icon: Icon(Icons.brightness_6),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.download),
              onPressed: exportToCSV,
            ),
          ],
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Expanded(child: TodayTasks(tasks: tasks)),
              Expanded(child: CompletedTasks(tasks: tasks)),
              Expanded(child: RepeatedTasks(tasks: tasks)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddTaskDialog(context),
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
