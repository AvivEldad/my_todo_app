class TodoItem {
  final String id;
  String title;
  int level;
  bool isCompleted;

  TodoItem({
    required this.id,
    required this.title,
    this.level = 1,
    this.isCompleted = false,
  });
}