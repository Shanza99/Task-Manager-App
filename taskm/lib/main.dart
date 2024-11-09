import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

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
              isCompleted INTEGER
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

  Future<void> _addTask(String title, String description, DateTime dueDate) async {
    final newTask = {
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': 0,
    };

    if (_isWeb) {
      _tasks.add(newTask);
      await _saveTasksToSharedPreferences();
    } else if (_database != null) {
      await _database!.insert('tasks', newTask);
    }
    _fetchTasks();
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

    if (!mounted) return;  // Check if the widget is still in the tree

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
                  _addTask(title, description, selectedDate);
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

  Future<void> _editTask(int index) async {
    final titleController = TextEditingController(text: _tasks[index]['title']);
    final descriptionController = TextEditingController(text: _tasks[index]['description']);
    DateTime selectedDate = DateTime.parse(_tasks[index]['dueDate']);

    if (!mounted) return;  // Check if the widget is still in the tree

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Task'),
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
                  _updateTask(index, title, description, selectedDate);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Update Task'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateTask(int index, String title, String description, DateTime dueDate) async {
    final updatedTask = {
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': _tasks[index]['isCompleted'],
    };

    if (_isWeb) {
      _tasks[index] = updatedTask;
      await _saveTasksToSharedPreferences();
    } else if (_database != null) {
      int id = _tasks[index]['id'];
      await _database!.update('tasks', updatedTask, where: 'id = ?', whereArgs: [id]);
    }
    _fetchTasks();
  }

  Future<void> _toggleTaskCompletion(int index) async {
    final task = _tasks[index];
    final updatedTask = {
      'title': task['title'],
      'description': task['description'],
      'dueDate': task['dueDate'],
      'isCompleted': task['isCompleted'] == 0 ? 1 : 0,
    };

    if (_isWeb) {
      _tasks[index] = updatedTask;
      await _saveTasksToSharedPreferences();
    } else if (_database != null) {
      int id = task['id'];
      await _database!.update('tasks', updatedTask, where: 'id = ?', whereArgs: [id]);
    }
    _fetchTasks();
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

  Widget _buildTaskList(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) {
      return Center(child: Text('No tasks available'));
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ListTile(
          title: Text(task['title']),
          subtitle: Text(task['description']),
          trailing: Checkbox(
            value: task['isCompleted'] == 1,
            onChanged: (bool? value) {
              _toggleTaskCompletion(index);
            },
          ),
          onTap: () => _editTask(index),
          onLongPress: () => _deleteTask(index),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getTasksForToday() {
    final today = DateTime.now();
    return _tasks.where((task) {
      final taskDate = DateTime.parse(task['dueDate']);
      return taskDate.year == today.year &&
          taskDate.month == today.month &&
          taskDate.day == today.day;
    }).toList();
  }

  List<Map<String, dynamic>> _getCompletedTasks() {
    return _tasks.where((task) => task['isCompleted'] == 1).toList();
  }

  List<Map<String, dynamic>> _getRepeatedTasks() {
    return _tasks.where((task) => task['isCompleted'] == 0).toList();
  }
}
