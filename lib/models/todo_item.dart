enum TaskType { dailyRitual, weeklyRitual, quest }

class TodoItem {
  final String id;
  String title;
  TaskType type;
  int level;
  bool isCompleted;
  bool isGolden;

  TodoItem({
    required this.id,
    required this.title,
    this.type = TaskType.quest,
    this.level = 1,
    this.isCompleted = false,
    this.isGolden = false,
  });
}
