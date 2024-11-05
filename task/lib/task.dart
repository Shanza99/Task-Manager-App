class Task {
  String title;
  String description;
  DateTime dueDate;
  bool isCompleted;
  bool isRepeated;
  List<String> subtasks;
  int completedSubtasks;

  Task({
    required this.title,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.isRepeated = false,
    this.subtasks = const [],
    this.completedSubtasks = 0,
  });

  double get progress => (completedSubtasks / subtasks.length).clamp(0, 1);
}
