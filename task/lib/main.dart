import 'package:flutter/material.dart';
import 'today_tasks.dart';
import 'completed_tasks.dart';
import 'repeated_tasks.dart';
import 'task.dart';

void main() {
  runApp(TaskManagementApp());
}

class TaskManagementApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Management App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TaskManagementHomePage(),
    );
  }
}

class TaskManagementHomePage extends StatefulWidget {
  @override
  _TaskManagementHomePageState createState() => _TaskManagementHomePageState();
}

class _TaskManagementHomePageState extends State<TaskManagementHomePage> {
  List<Task> tasks = []; // List to store tasks
  int _selectedIndex = 0;

  late List<Widget> _pages; // Initialize the pages list later

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      TodayTasks(tasks: tasks),
      CompletedTasks(tasks: tasks),
      RepeatedTasks(tasks: tasks),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAddTaskDialog(BuildContext context) {
    final _taskTitleController = TextEditingController();
    final _taskDescriptionController = TextEditingController();
    DateTime? _selectedDate;
    bool _isCompleted = false;
    bool _isRepeated = false;

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
                  setState(() {
                    tasks.add(Task(
                      title: _taskTitleController.text,
                      description: _taskDescriptionController.text,
                      dueDate: _selectedDate!,
                      isCompleted: _isCompleted,
                      isRepeated: _isRepeated,
                    ));
                  });
                }
                Navigator.of(context).pop();
              },
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
        title: Text('Task Management App'),
      ),
      body: _pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Completed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.repeat),
            label: 'Repeated',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
