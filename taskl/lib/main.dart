import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(MyApp());
}

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = true;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: HomeScreen(toggleTheme: _toggleTheme),
    );
  }
}

class Task {
  String title;
  String description;
  DateTime date;
  bool isFavorite;
  bool isRepeated;
  bool isCompleted;

  Task({
    required this.title,
    required this.description,
    required this.date,
    this.isFavorite = false,
    this.isRepeated = false,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'isFavorite': isFavorite,
      'isRepeated': isRepeated,
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      isFavorite: json['isFavorite'],
      isRepeated: json['isRepeated'],
      isCompleted: json['isCompleted'],
    );
  }

  // Method to update task properties
  void updateTask(String newTitle, String newDescription) {
    this.title = newTitle;
    this.description = newDescription;
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  HomeScreen({required this.toggleTheme});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> _tasks = [];
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _requestNotificationPermission();
    _loadTasks().then((_) {
      _showNotificationForTodaysTasks();
    });
  }

  Future<void> _initializeNotifications() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.notification.request();
      if (!status.isGranted) {
        print("Notification permission not granted");
      }
    }
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString('tasks');
    if (tasksJson != null) {
      List<dynamic> taskList = jsonDecode(tasksJson);
      setState(() {
        _tasks = taskList.map((taskData) => Task.fromJson(taskData)).toList();
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> tasksJson = _tasks.map((task) => task.toJson()).toList();
    await prefs.setString('tasks', jsonEncode(tasksJson));
  }

  void _addTask(String title, String description, DateTime date, bool isRepeated) {
    setState(() {
      _tasks.add(Task(
        title: title,
        description: description,
        date: date,
        isRepeated: isRepeated,
      ));
    });
    _saveTasks();
  }

  void _toggleFavorite(Task task) {
    setState(() {
      task.isFavorite = !task.isFavorite;
    });
    _saveTasks();
  }

  void _markTaskAsCompleted(Task task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
    });
    _saveTasks();
  }

  void _deleteTask(Task task) {
    setState(() {
      _tasks.remove(task);
    });
    _saveTasks();
  }

  Future<void> _showNotificationForTodaysTasks() async {
    DateTime today = DateTime.now();
    List<Task> todaysTasks = _tasks.where((task) {
      return task.date.day == today.day &&
             task.date.month == today.month &&
             task.date.year == today.year;
    }).toList();

    for (var task in todaysTasks) {
      var androidDetails = AndroidNotificationDetails(
        'task_channel_id',
        'Task Notifications',
        channelDescription: 'Notifications for tasks due today',
        importance: Importance.max, // High importance for urgent notifications
        priority: Priority.high,
        playSound: true,
      );
      var notificationDetails = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        task.date.hashCode,
        task.title,
        task.description,
        notificationDetails,
        payload: jsonEncode(task.toJson()),
      );
    }
  }

  List<Task> _getFilteredTasks() {
    DateTime today = DateTime.now();
    if (_selectedTabIndex == 0) {
      return _tasks.where((task) => task.date.day == today.day && task.date.month == today.month && task.date.year == today.year).toList();
    } else if (_selectedTabIndex == 1) {
      return _tasks;
    } else if (_selectedTabIndex == 2) {
      return _tasks.where((task) => task.isFavorite).toList();
    } else if (_selectedTabIndex == 3) {
      return _tasks.where((task) => task.isRepeated).toList();
    } else if (_selectedTabIndex == 4) {
      return _tasks.where((task) => task.isCompleted).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks'),
        backgroundColor: Colors.black87,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') {
                _requestPermission();
              } else if (value == 'theme') {
                widget.toggleTheme();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(value: 'export', child: Text('Export Tasks to PDF')),
              PopupMenuItem<String>(value: 'theme', child: Text('Toggle Dark/Light Mode')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTabButton("Today", 0),
              _buildTabButton("Progress", 1),
              _buildTabButton("Favorites", 2),
              _buildTabButton("Repeated", 3),
              _buildTabButton("Completed", 4),
            ],
          ),
          Expanded(
            child: _getFilteredTasks().isEmpty
                ? Center(child: Text('No tasks available', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _getFilteredTasks().length,
                    itemBuilder: (context, index) {
                      final task = _getFilteredTasks()[index];
                      return ListTile(
                        onTap: () => _markTaskAsCompleted(task),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            color: task.isCompleted ? Colors.green : Colors.white,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                        ),
                        subtitle: Text(task.description, style: TextStyle(color: Colors.grey)),
                        tileColor: Colors.black54,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                task.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: task.isFavorite ? Colors.red : Colors.white,
                              ),
                              onPressed: () => _toggleFavorite(task),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _deleteTask(task),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditTaskDialog(task),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.grey,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: _showAddTaskDialog,
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    return TextButton(
      onPressed: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Text(
        label,
        style: TextStyle(
          color: _selectedTabIndex == index ? Colors.white : Colors.grey,
          fontWeight: _selectedTabIndex == index ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Future<void> _showAddTaskDialog() async {
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool isRepeated = false;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add New Task"),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: "Description"),
              ),
              Row(
                children: [
                  Text("Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}"),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: isRepeated,
                    onChanged: (value) {
                      setState(() {
                        isRepeated = value!;
                      });
                    },
                  ),
                  Text("Repeat Task"),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _addTask(
                  titleController.text,
                  descriptionController.text,
                  selectedDate,
                  isRepeated,
                );
                Navigator.pop(context);
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditTaskDialog(Task task) async {
    TextEditingController titleController = TextEditingController(text: task.title);
    TextEditingController descriptionController = TextEditingController(text: task.description);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Task"),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: "Description"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  task.updateTask(titleController.text, descriptionController.text);
                });
                _saveTasks();
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestPermission() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      _exportToPdf();
    } else {
      print('Permission denied');
    }
  }

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();
    final outputDir = await getExternalStorageDirectory();
    final outputFile = File('${outputDir!.path}/tasks.pdf');

    pdf.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          children: [
            pw.Text('Tasks List', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return pw.Text('${task.title} - ${task.description}');
              },
            ),
          ],
        );
      },
    ));

    await outputFile.writeAsBytes(await pdf.save());
    print("PDF saved to: ${outputFile.path}");
  }
}
