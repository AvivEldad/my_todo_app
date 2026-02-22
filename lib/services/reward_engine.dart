import '../models/todo_item.dart';

class RewardEngine {
  static const int baseXP = 10;
  static const double goldenMultiplier = 1.5;

  static int calculateXP(TodoItem task) {
    double xp = baseXP * task.level.toDouble();
    if (task.isGolden) xp *= goldenMultiplier;
    return xp.toInt();
  }
}
