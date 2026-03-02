import 'package:flutter/material.dart';
import '../models/todo_item.dart';
import '../widgets/todo_card.dart';

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  final List<TodoItem> _tasks = [];

  void _showTaskDialog({TodoItem? todo}) {
    final isEditing = todo != null;
    final controller = TextEditingController(text: todo?.title ?? '');
    int level = todo?.level ?? 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'עריכת משימה' : 'משימה חדשה'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(hintText: 'מה המשימה?'),
              ),
              const SizedBox(height: 20),
              Text('רמה: $level'),
              Slider(
                value: level.toDouble(), min: 1, max: 5, divisions: 4,
                onChanged: (v) => setDialogState(() => level = v.toInt()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ביטול')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (isEditing) {
                    todo.title = controller.text;
                    todo.level = level;
                  } else {
                    _tasks.insert(0, TodoItem(
                      id: DateTime.now().toString(),
                      title: controller.text,
                      level: level,
                    ));
                  }
                });
                Navigator.pop(context);
              },
              child: Text(isEditing ? 'שמור' : 'צור'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('רשימת משימות'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => setState(() => _tasks.sort((a, b) => b.level.compareTo(a.level))),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        itemCount: _tasks.length,
        onReorder: (oldIdx, newIdx) {
          setState(() {
            if (newIdx > oldIdx) newIdx -= 1;
            _tasks.insert(newIdx, _tasks.removeAt(oldIdx));
          });
        },
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return ReorderableDragStartListener(
            key: ValueKey(task.id),
            index: index,
            child: TodoCard(
              todo: task,
              onToggle: () => setState(() => task.isCompleted = !task.isCompleted),
              onEdit: () => _showTaskDialog(todo: task),
              onDelete: () => setState(() => _tasks.remove(task)),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}