import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

class _TaskHomePageState extends State<TaskHomePage> {
  Database? _database;
  List<Map<String, dynamic>> _tasks = [];
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initDatabase();
    _initNotifications();
  }

  Future<void> _initDatabase() async {
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
            repeatDays TEXT,
            isCompleted INTEGER
          )
        ''');
      },
    );
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    if (_database != null) {
      final tasks = await _database!.query('tasks');
      setState(() {
        _tasks = tasks;
      });
    }
  }

  Future<void> _addTask(String title, String description) async {
    if (_database != null) {
      await _database!.insert('tasks', {
        'title': title,
        'description': description,
        'dueDate': DateTime.now().toString(),
        'repeatDays': '',
        'isCompleted': 0,
      });
      _fetchTasks();
    }
  }

  Future<void> _deleteTask(int id) async {
    if (_database != null) {
      await _database!.delete('tasks', where: 'id = ?', whereArgs: [id]);
      _fetchTasks();
    }
  }

  Future<void> _initNotifications() async {
    final android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final settings = InitializationSettings(android: android);
    await _notificationsPlugin.initialize(settings);
  }

  Future<void> _showNotification(String title, String body) async {
    final android = AndroidNotificationDetails(
      'task_channel', // Channel ID
      'Task Notifications', // Channel name
      channelDescription: 'Channel for task notifications', // Fixed parameter
    );
    final details = NotificationDetails(android: android);
    await _notificationsPlugin.show(0, title, body, details);
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

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
                  _addTask(title, description);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Manager'),
      ),
      body: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return ListTile(
            title: Text(task['title']),
            subtitle: Text(task['description']),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteTask(task['id']),
            ),
            onTap: () => _showNotification(task['title'], task['description']),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context), // Pass the context here
        child: Icon(Icons.add),
      ),
    );
  }
}
