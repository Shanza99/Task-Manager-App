import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:html' as html;

import 'package:timezone/timezone.dart';

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
  Database? _database;
  List<Map<String, dynamic>> _tasks = [];
  late TabController _tabController;
  bool _isWeb = false;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _isWeb = kIsWeb;
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initDatabase();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _initDatabase() async {
    if (_isWeb) {
      await _loadTasksFromSharedPreferences();
    } else {
      String path = join(await getDatabasesPath(), 'tasks.db');
      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) {
          db.execute('''
            CREATE TABLE tasks (
              id INTEGER PRIMARY KEY,
              title TEXT,
              description TEXT,
              dueDate TEXT,
              isCompleted INTEGER,
              repeatDays TEXT
            )
          ''');
        },
      );
      _fetchTasks();
    }
  }

  Future<void> _fetchTasks() async {
    if (_isWeb) {
      await _loadTasksFromSharedPreferences();
    } else if (_database != null) {
      final tasks = await _database!.query('tasks');
      setState(() {
        _tasks = tasks;
      });
    }
  }

  Future<void> _addTask(String title, String description, DateTime dueDate, String repeatDays) async {
    final newTask = {
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': 0,
      'repeatDays': repeatDays,
    };

    if (_isWeb) {
      _tasks.add(newTask);
      await _saveTasksToSharedPreferences();
    } else if (_database != null) {
      await _database!.insert('tasks', newTask);
    }
    _fetchTasks();
    _scheduleNotification(newTask); // Schedule notification for the new task
  }

  Future<void> _deleteTask(int index) async {
    if (_isWeb) {
      _tasks.removeAt(index);
      await _saveTasksToSharedPreferences();
    } else if (_database != null) {
      int id = _tasks[index]['id'];
      await _database!.delete('tasks', where: 'id = ?', whereArgs: [id]);
    }
    _fetchTasks();
  }

  Future<void> _saveTasksToSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> taskList = _tasks.map((task) => jsonEncode(task)).toList();
    await prefs.setStringList('tasks', taskList);
  }

  Future<void> _loadTasksFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? taskList = prefs.getStringList('tasks');
    
    setState(() {
      _tasks = taskList != null 
        ? taskList.map((task) => Map<String, dynamic>.from(jsonDecode(task))).toList() 
        : [];
    });
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String repeatDays = 'Once';

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
                value: repeatDays,
                onChanged: (String? newValue) {
                  setState(() {
                    repeatDays = newValue!;
                  });
                },
                items: <String>['Once', 'Daily', 'Weekly', 'Monthly', 'Yearly']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
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
                  _addTask(title, description, selectedDate, repeatDays);
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

  void _markTaskAsCompleted(Map<String, dynamic> task) {
    setState(() {
      if (task['isCompleted'] == 0) {
        task['isCompleted'] = 1; // Mark as completed
      }
    });
  }

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

  List<Map<String, dynamic>> _getRepeatedTasks() {
    return _tasks.where((task) => task['repeatDays'] != null && task['repeatDays'] != 'Once').toList();
  }

  Future<void> _scheduleNotification(Map<String, dynamic> task) async {
    DateTime dueDate = DateTime.parse(task['dueDate']);
    if (dueDate.isBefore(DateTime.now())) return;  // Don't schedule for past dates

    var androidDetails = AndroidNotificationDetails(
      'task_channel_id',
      'Task Notifications',
      channelDescription: 'This channel is used for task notifications.',
      importance: Importance.high,
      priority: Priority.high,
    );
    var notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      task['id'], // Unique id for the task
      task['title'],
      task['description'],
      TZDateTime.from(dueDate, (await FlutterTimezone.getLocalTimezone()) as Location), // Use correct timezone
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Manager'),
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

  Widget _buildTaskListView(List<Map<String, dynamic>> tasks) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ListTile(
          title: Text(task['title']),
          subtitle: Text(task['description']),
          trailing: task['isCompleted'] == 1
              ? Icon(Icons.check_circle, color: Colors.green)
              : Icon(Icons.circle_outlined),
          onTap: () => _markTaskAsCompleted(task),
        );
      },
    );
  }
}
