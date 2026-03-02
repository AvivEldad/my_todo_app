import 'package:flutter/material.dart';
import '../models/todo_item.dart';

class TodoCard extends StatelessWidget {
  final TodoItem todo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TodoCard({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onEdit, // לחיצה על כל הכרטיסייה תפתח עריכה
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todo.description != null && todo.description!.isNotEmpty)
              Text(
                todo.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            Row(
              children: [
                Text('רמה: ${todo.level}', style: const TextStyle(fontSize: 12)),
                if (todo.dueDate != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.calendar_today, size: 12, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '${todo.dueDate!.day}/${todo.dueDate!.month}/${todo.dueDate!.year}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: onEdit),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}