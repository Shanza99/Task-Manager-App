import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'task_exporter.dart'; // Import TaskExporter

class TaskHomePage extends StatefulWidget {
  @override
  _TaskHomePageState createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage> with TickerProviderStateMixin {
  late List<Map<String, dynamic>> _tasks;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDummyTasks();
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

  Widget _buildTaskList(List<Map<String, dynamic>> tasks) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        var task = tasks[index];
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.purpleAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            title: Text(
              task['title'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.deepPurple,
                fontFamily: 'Lobster', // Playful custom font
              ),
            ),
            subtitle: Text(
              task['description'],
              style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedIcon(
                  icon: AnimatedIcons.menu_close,
                  progress: AlwaysStoppedAnimation(0.5),
                  color: Colors.blueAccent,
                  size: 30,
                ),
                IconButton(
                  icon: Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () {
                    setState(() {
                      task['isCompleted'] = true;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Delete Task'),
                          content: Text('Are you sure you want to delete this task?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
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
          ),
        );
      },
    );
  }

  void _showEditTaskDialog(BuildContext context, Map<String, dynamic> task) {
    final titleController = TextEditingController(text: task['title']);
    final descriptionController = TextEditingController(text: task['description']);
    DateTime selectedDate = DateTime.parse(task['dueDate']);
    bool isRepeating = task['isRepeating'];
    String repeatInterval = task['repeatInterval'];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: AnimatedPadding(
            padding: EdgeInsets.all(20.0),
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: AlertDialog(
              title: Text('Edit Task', style: TextStyle(fontFamily: 'Lobster')),
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
                          if (pickedDate != null) {
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
                  CheckboxListTile(
                    title: Text("Repeating Task"),
                    value: isRepeating,
                    onChanged: (value) {
                      setState(() {
                        isRepeating = value!;
                      });
                    },
                  ),
                  if (isRepeating)
                    DropdownButton<String>(
                      value: repeatInterval,
                      onChanged: (String? newValue) {
                        setState(() {
                          repeatInterval = newValue!;
                        });
                      },
                      items: <String>['None', 'Daily', 'Weekly', 'Monthly']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.purple)),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _tasks.add({
                        'id': _tasks.length + 1,
                        'title': titleController.text,
                        'description': descriptionController.text,
                        'dueDate': selectedDate.toIso8601String(),
                        'isCompleted': false,
                        'isRepeating': isRepeating,
                        'repeatInterval': repeatInterval,
                      });
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Add', style: TextStyle(color: Colors.green)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purpleAccent[100],
      appBar: AppBar(
        title: Text('Task Manager', style: TextStyle(fontFamily: 'Lobster', fontSize: 24)),
        backgroundColor: Colors.deepPurpleAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: () {
              TaskExporter.showExportDialog(context, _tasks);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.greenAccent,
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
        onPressed: () => _showEditTaskDialog(context, {}),
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.greenAccent,
      ),
    );
  }
}
