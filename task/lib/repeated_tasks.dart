import 'package:flutter/material.dart';
import 'task.dart'; // Import the Task model

class RepeatedTasks extends StatelessWidget {
  final List<Task> tasks;

  RepeatedTasks({required this.tasks});

  @override
  Widget build(BuildContext context) {
    // Filter tasks that are marked as repeated
    final repeatedTasks = tasks.where((task) => task.isRepeated).toList();

    return ListView.builder(
      itemCount: repeatedTasks.length,
      itemBuilder: (context, index) {
        final task = repeatedTasks[index];
        return ListTile(
          title: Text(task.title),
          subtitle: Text(task.description),
        );
      },
    );
  }
}
