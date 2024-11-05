import 'package:flutter/material.dart';
import 'task.dart';

class TodayTasks extends StatelessWidget {
  final List<Task> tasks;

  TodayTasks({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayOnlyDate = DateTime(today.year, today.month, today.day);

    final todayTasks = tasks.where((task) {
      final taskDateOnly = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      return taskDateOnly == todayOnlyDate && !task.isCompleted && !task.isRepeated;
    }).toList();

    return ListView.builder(
      itemCount: todayTasks.length,
      itemBuilder: (context, index) {
        final task = todayTasks[index];
        return ListTile(
          title: Text(task.title),
          subtitle: Text(task.description),
        );
      },
    );
  }
}
