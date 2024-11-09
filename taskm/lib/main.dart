import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasksFromSharedPreferences();
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

  Future<void> _saveTasksToSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> taskList = _tasks.map((task) => jsonEncode(task)).toList();
    await prefs.setStringList('tasks', taskList);
  }

  Future<void> _addTask(String title, String description, DateTime dueDate) async {
    setState(() {
      _tasks.add({
        'title': title,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        'isCompleted': 0,
        'repeatDays': '',
      });
    });
    _saveTasksToSharedPreferences();
  }

  Future<void> _editTask(int index, String title, String description, DateTime dueDate) async {
    setState(() {
      _tasks[index]['title'] = title;
      _tasks[index]['description'] = description;
      _tasks[index]['dueDate'] = dueDate.toIso8601String();
    });
    _saveTasksToSharedPreferences();
  }

  void _showEditTaskDialog(BuildContext context, int index) {
    final titleController = TextEditingController(text: _tasks[index]['title']);
    final descriptionController = TextEditingController(text: _tasks[index]['description']);
    DateTime selectedDate = DateTime.parse(_tasks[index]['dueDate']);

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
                  _editTask(index, title, description, selectedDate);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaskList() {
    if (_tasks.isEmpty) {
      return Center(child: Text('No tasks available.'));
    }
    return ListView.builder(
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return ListTile(
          title: Text(task['title']),
          subtitle: Text(task['description']),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => _showEditTaskDialog(context, index),
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _tasks.removeAt(index);
                  });
                  _saveTasksToSharedPreferences();
                },
              ),
            ],
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
      ),
      body: _buildTaskList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Code to open the add task dialog
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
