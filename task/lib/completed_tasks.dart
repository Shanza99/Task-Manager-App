import 'package:flutter/material.dart';
import 'task.dart'; // Import the Task model

class CompletedTasks extends StatelessWidget {
  final List<Task> tasks;

  CompletedTasks({required this.tasks});

  @override
  Widget build(BuildContext context) {
    // Filter tasks that are marked as completed
    final completedTasks = tasks.where((task) => task.isCompleted).toList();

    return ListView.builder(
      itemCount: completedTasks.length,
      itemBuilder: (context, index) {
        final task = completedTasks[index];
        return ListTile(
          title: Text(task.title),
          subtitle: Text(task.description),
        );
      },
    );
  }
}
