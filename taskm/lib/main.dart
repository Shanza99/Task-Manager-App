import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(MaterialApp(home: TaskHomePage()));
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
    _tabController = TabController(length: 5, vsync: this);
    isWeb = (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS);

    if (!isWeb) {
      _initializeNotifications();
      _requestNotificationPermission();
    }
    _loadDummyTasks();
  }

  // Initialize notifications
  void _initializeNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    
    flutterLocalNotificationsPlugin!.initialize(initializationSettings,
        onSelectNotification: (String? payload) async {
          print("Notification tapped: $payload");
        }).then((_) {
      print("Notification plugin initialized.");
    }).catchError((error) {
      print("Error initializing notifications: $error");
    });
  }

  // Request notification permission (for iOS)
  void _requestNotificationPermission() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      flutterLocalNotificationsPlugin!.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      print("Notification permissions requested for iOS.");
    }
  }

  // Dummy function to load tasks (for testing purposes)
  void _loadDummyTasks() {
    _tasks = [
      {
        'id': 1,
        'title': 'Task 1',
        'description': 'Complete project report',
        'dueDate': DateTime.now().add(Duration(seconds: 10)).toIso8601String(),
        'isCompleted': false,
        'isRepeating': false,
        'repeatInterval': null, // No repeating interval
      },
      {
        'id': 2,
        'title': 'Task 2',
        'description': 'Call client',
        'dueDate': DateTime.now().add(Duration(seconds: 20)).toIso8601String(),
        'isCompleted': false,
        'isRepeating': true,
        'repeatInterval': 'Daily', // Repeating task
      },
    ];
  }

  // Fetch tasks for different tabs
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

  List<Map<String, dynamic>> _getRepeatedTasks() {
    return _tasks.where((task) => task['isRepeating'] == true).toList();
  }

  // Show a notification when a task is created
  void _showNotification(String taskTitle) async {
    var androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    var platformDetails = NotificationDetails(android: androidDetails);

    // Make sure notification is showing
    await flutterLocalNotificationsPlugin!.show(
      0,
      'New Task Created',
      'You have a new task: $taskTitle',
      platformDetails,
      payload: 'Task details here', // Optional payload
    ).catchError((error) {
      print("Error showing notification: $error");
    });
    print("Notification shown for task: $taskTitle");
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
            Tab(text: 'Repeated Tasks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(_tasks),
          _buildTaskList(_getTasksForToday()),
          _buildTaskList(_getCompletedTasks()),
          _buildTaskList(_getRepeatedTasks()), // Show repeated tasks in this tab
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  // Function to build task list
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
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => _showEditTaskDialog(context, task),
              ),
              IconButton(
                icon: Icon(Icons.check),
                onPressed: () {
                  setState(() {
                    task['isCompleted'] = true; // Mark as completed
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _tasks.removeAt(index); // Remove task from list
                  });
                },
              ),
            ],
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
                    items: ['None', 'Daily', 'Weekly', 'Monthly', 'Yearly']
                        .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        repeatInterval = value!;
                        isRepeating = repeatInterval != 'None';  // Set isRepeating flag
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
                  var newTask = {
                    'id': _tasks.length + 1,
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'dueDate': selectedDate.toIso8601String(),
                    'isCompleted': false,
                    'isRepeating': isRepeating,
                    'repeatInterval': repeatInterval,
                  };
                  _tasks.add(newTask);
                  if (isRepeating) {
                    _showNotification(titleController.text); // Show notification if repeating
                  }
                });
                Navigator.pop(context);
              },
              child: Text('Save Task'),
            ),
          ],
        );
      },
    );
  }

  // Dialog to edit an existing task
  void _showEditTaskDialog(BuildContext context, Map<String, dynamic> task) {
    final titleController = TextEditingController(text: task['title']);
    final descriptionController = TextEditingController(text: task['description']);
    DateTime selectedDate = DateTime.parse(task['dueDate']);
    bool isRepeating = task['isRepeating'];
    String repeatInterval = task['repeatInterval'] ?? 'None';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Task'),
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
                    items: ['None', 'Daily', 'Weekly', 'Monthly', 'Yearly']
                        .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        repeatInterval = value!;
                        isRepeating = repeatInterval != 'None';  // Set isRepeating flag
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
                  task['title'] = titleController.text;
                  task['description'] = descriptionController.text;
                  task['dueDate'] = selectedDate.toIso8601String();
                  task['isRepeating'] = isRepeating;
                  task['repeatInterval'] = repeatInterval;
                });
                Navigator.pop(context);
              },
              child: Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }
}
