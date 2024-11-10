import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  List<Map<String, dynamic>> _tasks = [];
  late TabController _tabController;
  bool isWeb = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    isWeb = (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS);

    if (!isWeb) {
      _initializeNotifications();
    }
    _loadDummyTasks();
  }

  void _initializeNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin!.initialize(initializationSettings);
  }

  void _loadDummyTasks() {
    _tasks = [
      {
        'id': 1,
        'title': 'Task 1',
        'description': 'Complete project report',
        'dueDate': DateTime.now().add(Duration(seconds: 10)).toIso8601String(),
        'isCompleted': false,
        'isRepeating': false,
        'repeatInterval': null,
      },
      {
        'id': 2,
        'title': 'Task 2',
        'description': 'Call client',
        'dueDate': DateTime.now().add(Duration(seconds: 20)).toIso8601String(),
        'isCompleted': false,
        'isRepeating': false,
        'repeatInterval': null,
      },
    ];
  }

  void _addTask(String title, String description, DateTime dueDate, bool isRepeating) {
    setState(() {
      _tasks.add({
        'id': _tasks.length + 1,
        'title': title,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        'isCompleted': false,
        'isRepeating': isRepeating,
        'repeatInterval': isRepeating ? 'Daily' : 'None',
      });
    });
  }

  void _editTask(int id, String title, String description, DateTime dueDate, bool isRepeating) {
    setState(() {
      var task = _tasks.firstWhere((task) => task['id'] == id);
      task['title'] = title;
      task['description'] = description;
      task['dueDate'] = dueDate.toIso8601String();
      task['isRepeating'] = isRepeating;
      task['repeatInterval'] = isRepeating ? 'Daily' : 'None';
    });
  }

  void _exportTasksToCSV() {
    List<List<dynamic>> rows = [
      ["ID", "Title", "Description", "Due Date", "Completed", "Repeating"]
    ];
    for (var task in _tasks) {
      rows.add([
        task['id'],
        task['title'],
        task['description'],
        task['dueDate'],
        task['isCompleted'] ? "Yes" : "No",
        task['isRepeating'] ? "Yes" : "No"
      ]);
    }
    String csvData = const ListToCsvConverter().convert(rows);
    final blob = html.Blob([csvData], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "tasks.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _exportTasksToPDF() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
        build: (pw.Context context) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("Task List", style: pw.TextStyle(fontSize: 24)),
          pw.SizedBox(height: 10),
          for (var task in _tasks)
            pw.Text(
                "Title: ${task['title']}\nDescription: ${task['description']}\nDue Date: ${task['dueDate']}\nCompleted: ${task['isCompleted'] ? "Yes" : "No"}\nRepeating: ${task['isRepeating'] ? "Yes" : "No"}\n"),
        ],
      );
    }));
    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "tasks.pdf")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _emailTasks() {
    final emailBody = _tasks.map((task) {
      return "Title: ${task['title']}\nDescription: ${task['description']}\nDue Date: ${task['dueDate']}\nCompleted: ${task['isCompleted'] ? "Yes" : "No"}\nRepeating: ${task['isRepeating'] ? "Yes" : "No"}\n";
    }).join("\n\n");
    final mailto = Uri.encodeFull("mailto:?subject=Task List&body=$emailBody");
    html.window.open(mailto, "_blank");
  }

  List<Map<String, dynamic>> _getTasksForToday() {
    final today = DateTime.now();
    return _tasks.where((task) {
      final dueDate = DateTime.parse(task['dueDate']);
      return dueDate.year == today.year &&
          dueDate.month == today.month &&
          dueDate.day == today.day &&
          task['isCompleted'] == false;
    }).toList();
  }

  List<Map<String, dynamic>> _getCompletedTasks() {
    return _tasks.where((task) => task['isCompleted'] == true).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Manager'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Export to CSV') _exportTasksToCSV();
              if (value == 'Export to PDF') _exportTasksToPDF();
              if (value == 'Email Tasks') _emailTasks();
            },
            itemBuilder: (BuildContext context) {
              return {'Export to CSV', 'Export to PDF', 'Email Tasks'}
                  .map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All Tasks'),
            Tab(text: 'Today\'s Tasks'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(_tasks),
          _buildTaskList(_getTasksForToday()),
          _buildTaskList(_getCompletedTasks()),
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
          title: Row(
            children: [
              Text(task['title']),
              if (task['repeatInterval'] != 'None') ...[
                SizedBox(width: 8),
                Text(
                  '(Repeated)',
                  style: TextStyle(color: Colors.blue, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
          subtitle: Text(task['description']),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => _showEditTaskDialog(context, task),
              ),
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
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Delete Task'),
                        content: Text('Are you sure you want to delete this task?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _tasks.removeAt(index);
                              });
                              Navigator.pop(context);
                            },
                            child: Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime dueDate = DateTime.now();
    bool isRepeating = false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              Row(
                children: [
                  Text('Due Date:'),
                  TextButton(
                    child: Text(DateFormat('yyyy-MM-dd').format(dueDate)),
                    onPressed: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (selectedDate != null) {
                        setState(() {
                          dueDate = selectedDate;
                        });
                      }
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Text('Repeating:'),
                  Checkbox(
                    value: isRepeating,
                    onChanged: (value) {
                      setState(() {
                        isRepeating = value!;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addTask(titleController.text, descriptionController.text, dueDate, isRepeating);
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditTaskDialog(BuildContext context, Map<String, dynamic> task) {
    final titleController = TextEditingController(text: task['title']);
    final descriptionController = TextEditingController(text: task['description']);
    DateTime dueDate = DateTime.parse(task['dueDate']);
    bool isRepeating = task['isRepeating'];

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
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              Row(
                children: [
                  Text('Due Date:'),
                  TextButton(
                    child: Text(DateFormat('yyyy-MM-dd').format(dueDate)),
                    onPressed: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (selectedDate != null) {
                        setState(() {
                          dueDate = selectedDate;
                        });
                      }
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Text('Repeating:'),
                  Checkbox(
                    value: isRepeating,
                    onChanged: (value) {
                      setState(() {
                        isRepeating = value!;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _editTask(task['id'], titleController.text, descriptionController.text, dueDate, isRepeating);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
