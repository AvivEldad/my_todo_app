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
          title: Text(isEditing ? 'Edit Task' : 'New Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller, 
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Task Title'),
              ),
              const SizedBox(height: 20),
              Text('Level: $level'),
              Slider(
                value: level.toDouble(), min: 1, max: 5, divisions: 4,
                onChanged: (v) => setDialogState(() => level = v.toInt()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (isEditing) {
                    todo.title = controller.text;
                    todo.level = level;
                  } else {
                    // NEW TASKS ADDED TO INDEX 0 (TOP)
                    _tasks.insert(0, TodoItem(
                      id: DateTime.now().toString(), 
                      title: controller.text, 
                      level: level,
                    ));
                  }
                });
                Navigator.pop(context);
              },
              child: Text(isEditing ? 'Save' : 'Create'),
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
        title: const Text('Task List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => setState(() => _tasks.sort((a, b) => b.level.compareTo(a.level))),
            tooltip: 'Sort by Level',
          ),
        ],
      ),
      body: ReorderableListView.builder(
        buildDefaultDragHandles: false, // Disables the default right-side icon
        itemCount: _tasks.length,
        onReorder: (oldIdx, newIdx) {
          setState(() {
            if (newIdx > oldIdx) newIdx -= 1;
            final item = _tasks.removeAt(oldIdx);
            _tasks.insert(newIdx, item);
          });
        },
        itemBuilder: (context, index) {
          final task = _tasks[index];
          // Wrapping in listener makes the entire child a drag handle
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