import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

void main() {
  runApp(TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
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
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isWeb = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _isWeb = !Platform.isAndroid && !Platform.isIOS;
    _initDatabase();
    _initNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initDatabase() async {
    if (_isWeb) {
      print("Using shared_preferences for web storage");
      _fetchTasksFromPrefs();
    } else {
      try {
        String path = join(await getDatabasesPath(), 'tasks.db');
        _database = await openDatabase(
          path,
          version: 1,
          onCreate: (db, version) {
            db.execute('''
              CREATE TABLE IF NOT EXISTS tasks (
                id INTEGER PRIMARY KEY,
                title TEXT,
                description TEXT,
                dueDate TEXT,
                repeatDays TEXT,
                isCompleted INTEGER
              )
            ''');
          },
        );
        print("Database initialized at: $path");
        _fetchTasks();
      } catch (e) {
        print("Database initialization error: $e");
      }
    }
  }

  Future<void> _fetchTasks() async {
    if (_database != null) {
      final tasks = await _database!.query('tasks');
      print("Fetched tasks: $tasks");
      setState(() {
        _tasks = tasks;
      });
    }
  }

  Future<void> _fetchTasksFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksString = prefs.getString('tasks') ?? '[]';
    final tasks = List<Map<String, dynamic>>.from(await jsonDecode(tasksString));
    setState(() {
      _tasks = tasks;
    });
  }

  Future<void> _addTask(String title, String description, DateTime dueDate) async {
    final task = {
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'repeatDays': '',
      'isCompleted': 0,
    };
    if (_isWeb) {
      await _addTaskToPrefs(task);
    } else if (_database != null) {
      await _database!.insert('tasks', task);
      _fetchTasks();
    }
  }

  Future<void> _addTaskToPrefs(Map<String, dynamic> task) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksString = prefs.getString('tasks') ?? '[]';
    final tasks = List<Map<String, dynamic>>.from(await jsonDecode(tasksString));
    tasks.add(task);
    await prefs.setString('tasks', jsonEncode(tasks));
    _fetchTasksFromPrefs();
  }

  Future<void> _deleteTask(int id) async {
    if (_isWeb) {
      await _deleteTaskFromPrefs(id);
    } else if (_database != null) {
      await _database!.delete('tasks', where: 'id = ?', whereArgs: [id]);
      _fetchTasks();
    }
  }

  Future<void> _deleteTaskFromPrefs(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksString = prefs.getString('tasks') ?? '[]';
    final tasks = List<Map<String, dynamic>>.from(await jsonDecode(tasksString));
    tasks.removeWhere((task) => task['id'] == id);
    await prefs.setString('tasks', jsonEncode(tasks));
    _fetchTasksFromPrefs();
  }

  Future<void> _initNotifications() async {
    final android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final settings = InitializationSettings(android: android);
    await _notificationsPlugin.initialize(settings);
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

  // Remaining code unchanged...

}
