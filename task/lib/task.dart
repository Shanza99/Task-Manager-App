class Task {
  String title;
  String description;
  DateTime dueDate;
  bool isCompleted;
  bool isRepeated;

  Task({
    required this.title,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.isRepeated = false,
  });
}
