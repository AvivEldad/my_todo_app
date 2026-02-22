import 'package:flutter/material.dart';

import '../models/todo_item.dart';

class TodoCard extends StatelessWidget {
  final TodoItem todo;
  final VoidCallback onToggleTodo;
  final VoidCallback onToggleGolden;

  const TodoCard({
    super.key,
    required this.todo,
    required this.onToggleTodo,
    required this.onToggleGolden,
  });

  @override
  Widget build(BuildContext context) {
    IconData typeIcon = Icons.help_outline;
    if (todo.type == TaskType.dailyRitual) typeIcon = Icons.calendar_view_day;
    if (todo.type == TaskType.weeklyRitual) typeIcon = Icons.calendar_view_week;
    if (todo.type == TaskType.quest) typeIcon = Icons.shutter_speed;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: todo.isGolden ? const BorderSide(color: Colors.amber, width: 2) : BorderSide.none,
      ),
      child: ListTile(
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (_) => onToggleTodo(),
          activeColor: Colors.amber,
        ),
        title: Text(
          todo.title,
          style: TextStyle(decoration: todo.isCompleted ? TextDecoration.lineThrough : null),
        ),
        subtitle: Row(
          children: [
            Icon(typeIcon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('LVL ${todo.level}'),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            todo.isGolden ? Icons.monetization_on : Icons.monetization_on_outlined,
            color: todo.isGolden ? Colors.amber : (todo.type == TaskType.quest ? Colors.grey : Colors.grey[800]),
          ),
          onPressed: onToggleGolden,
        ),
      ),
    );
  }
}
