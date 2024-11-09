import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';  // Import this for kIsWeb
import 'dart:io' show Platform;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _isWeb = kIsWeb;
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    if (_isWeb) {
      _fetchTasksFromPrefs();
    } else {
      String path = join(await getDatabasesPath(), 'tasks.db');
      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE tasks (id INTEGER PRIMARY KEY, title TEXT, description TEXT, dueDate TEXT, isCompleted INTEGER)',
          );
        },
      );
      _fetchTasks();
    }
  }

  Future<void> _fetchTasks() async {
    if (_database != null) {
      final tasks = await _database!.query('tasks');
      setState(() {
        _tasks = tasks;
      });
    }
  }

  Future<void> _fetchTasksFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksString = prefs.getString('tasks') ?? '[]';
    final tasks = List<Map<String, dynamic>>.from(jsonDecode(tasksString));
    setState(() {
      _tasks = tasks;
    });
  }

  Future<void> _addTask(String title, String description, DateTime dueDate) async {
    final task = {
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
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
    final tasks = List<Map<String, dynamic>>.from(jsonDecode(tasksString));
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
    final tasks = List<Map<String, dynamic>>.from(jsonDecode(tasksString));
    tasks.removeWhere((task) => task['id'] == id);
    await prefs.setString('tasks', jsonEncode(tasks));
    _fetchTasksFromPrefs();
  }

  // Placeholder for getting tasks for today
  List<Map<String, dynamic>> _getTasksForToday() {
    return _tasks.where((task) {
      final dueDate = DateTime.parse(task['dueDate']);
      return dueDate.day == DateTime.now().day &&
          dueDate.month == DateTime.now().month &&
          dueDate.year == DateTime.now().year;
    }).toList();
  }

  // Placeholder for getting completed tasks
  List<Map<String, dynamic>> _getCompletedTasks() {
    return _tasks.where((task) => task['isCompleted'] == 1).toList();
  }

  // Placeholder for getting repeated tasks
  List<Map<String, dynamic>> _getRepeatedTasks() {
    // Define your repeated task logic here, if necessary
    return [];
  }

  // Updated buildTaskList function
  Widget _buildTaskList(List<Map<String, dynamic>> tasks) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ListTile(
          title: Text(task['title']),
          subtitle: Text(task['description']),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deleteTask(task['id']),
          ),
        );
      },
    );
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
    );
  }
}
