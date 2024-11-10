import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pdf;
import 'package:pdf/pdf.dart';

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
    _tabController = TabController(length: 4, vsync: this);
    isWeb = (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS);

    if (!isWeb) {
      _initializeNotifications();
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        flutterLocalNotificationsPlugin!
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    }
    _loadDummyTasks();
  }

  void _initializeNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin!.initialize(initializationSettings);
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

  void _checkIfTaskIsDueToday(Map<String, dynamic> task) {
    DateTime now = DateTime.now();
    DateTime taskDueDate = DateTime.parse(task['dueDate']);

    if (taskDueDate.year == now.year &&
        taskDueDate.month == now.month &&
        taskDueDate.day == now.day) {
      if (task['isCompleted'] == false) {
        _showNotificationForTask(task);
      }
    }
  }

  void _showNotificationForTask(Map<String, dynamic> task) {
    if (isWeb) {
      showWebNotification(
        "Task Due Today: ${task['title']}",
        "Don't forget to complete: ${task['description']}",
      );
    } else {
      _showDesktopNotification(
        "Task Due Today: ${task['title']}",
        "Don't forget to complete: ${task['description']}",
      );
    }
  }

  void _showDesktopNotification(String title, String body) {
    var androidDetails = AndroidNotificationDetails(
      'task_channel_id',
      'Task Notifications',
      channelDescription: 'Channel for task notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    var generalNotificationDetails = NotificationDetails(android: androidDetails);
    flutterLocalNotificationsPlugin!.show(0, title, body, generalNotificationDetails);
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

  void _exportTasksAsCSV() {
    List<List<String>> csvData = [
      ['ID', 'Title', 'Description', 'Due Date', 'Is Completed', 'Repeat Interval'],
      ..._tasks.map((task) => [
            task['id'].toString(),
            task['title'],
            task['description'],
            task['dueDate'],
            task['isCompleted'] ? 'Yes' : 'No',
            task['repeatInterval'] ?? 'None',
          ])
    ];

    String csvContent = const ListToCsvConverter().convert(csvData);
    final bytes = html.Blob([csvContent]);
    final url = html.Url.createObjectUrlFromBlob(bytes);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "tasks.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _exportTasksAsPDF() async {
    final pdfDocument = pdf.Document();
    pdfDocument.addPage(
      pdf.Page(
        build: (context) {
          return pdf.Column(
            children: [
              pdf.Text('Task List', style: pdf.TextStyle(fontSize: 24)),
              pdf.SizedBox(height: 10),
              ..._tasks.map((task) {
                return pdf.Column(
                  crossAxisAlignment: pdf.CrossAxisAlignment.start,
                  children: [
                    pdf.Text('Title: ${task['title']}', style: pdf.TextStyle(fontSize: 18)),
                    pdf.Text('Description: ${task['description']}'),
                    pdf.Text('Due Date: ${task['dueDate']}'),
                    pdf.Text('Is Completed: ${task['isCompleted'] ? 'Yes' : 'No'}'),
                    pdf.Text('Repeat Interval: ${task['repeatInterval'] ?? 'None'}'),
                    pdf.Divider(),
                  ],
                );
              }).toList(),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdfDocument.save();
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "tasks.pdf")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _sendTasksViaEmail() {
    final emailBody = _tasks.map((task) {
      return '''
        Title: ${task['title']}
        Description: ${task['description']}
        Due Date: ${task['dueDate']}
        Is Completed: ${task['isCompleted'] ? 'Yes' : 'No'}
        Repeat Interval: ${task['repeatInterval'] ?? 'None'}
      ''';
    }).join('\n\n');

    final emailUri = Uri(
      scheme: 'mailto',
      path: '',
      queryParameters: {
        'subject': 'Task List',
        'body': emailBody,
      },
    );

    html.window.open(emailUri.toString(), '_blank');
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
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Export CSV') {
                _exportTasksAsCSV();
              } else if (value == 'Export PDF') {
                _exportTasksAsPDF();
              } else if (value == 'Email Tasks') {
                _sendTasksViaEmail();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'Export CSV', child: Text('Export CSV')),
              PopupMenuItem(value: 'Export PDF', child: Text('Export PDF')),
              PopupMenuItem(value: 'Email Tasks', child: Text('Email Tasks')),
            ],
          ),
        ],
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
          title: Text(task['title']),
          subtitle: Text(task['description']),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              setState(() {
                _tasks.removeAt(index);
              });
            },
          ),
        );
      },
    );
  }



  // Dialog to add a new task
  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool isRepeating = false;
    String repeatInterval = 'None';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Task'),
          content: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              // DateTime Picker
              Row(
                children: [
                  Text("Due Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}"),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null && pickedDate != selectedDate) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Text("Time: ${DateFormat('HH:mm').format(selectedDate)}"),
                  IconButton(
                    icon: Icon(Icons.access_time),
                    onPressed: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedDate = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    },
                  ),
                ],
              ),
              // Repeating task selection
              Row(
                children: [
                  Text("Repeat: "),
                  DropdownButton<String>(
                    value: repeatInterval,
                    items: ['None', 'Daily', 'Weekly', 'Monthly']
                        .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        repeatInterval = value!;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _tasks.add({
                    'id': DateTime.now().millisecondsSinceEpoch,
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'dueDate': selectedDate.toIso8601String(),
                    'isCompleted': false,
                    'isRepeating': isRepeating,
                    'repeatInterval': repeatInterval,
                  });
                  // Check if the newly created task is due today
                  _checkIfTaskIsDueToday(_tasks.last);
                });
                Navigator.pop(context);
              },
              child: Text('Add Task'),
            ),
          ],
        );
      },
    );
  }
}
