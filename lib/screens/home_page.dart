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

  void _sortByLevel() {
    setState(() {
      _tasks.sort((a, b) => b.level.compareTo(a.level));
    });
  }

  void _sortByDate() {
    setState(() {
      _tasks.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) {
          return b.level.compareTo(a.level); 
        }
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;

        int dateCompare = a.dueDate!.compareTo(b.dueDate!);
        
        // שובר שוויון: אם התאריך זהה, המשימה עם הרמה הגבוהה יותר תהיה ראשונה
        if (dateCompare == 0) {
          return b.level.compareTo(a.level);
        }
        
        return dateCompare;
      });
    });
  }

  void _showTaskDialog({TodoItem? todo}) {
    final isEditing = todo != null;
    final titleController = TextEditingController(text: todo?.title ?? '');
    final descController = TextEditingController(text: todo?.description ?? '');
    DateTime? selectedDate = todo?.dueDate;
    int level = todo?.level ?? 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'עריכת משימה' : 'משימה חדשה'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(hintText: 'כותרת המשימה'),
                ),
                TextField(
                  controller: descController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(hintText: 'תיאור (אופציונלי)'),
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(selectedDate == null 
                    ? 'בחר תאריך סיום' 
                    : 'תאריך: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 10),
                Text('רמת עדיפות: $level'),
                Slider(
                  value: level.toDouble(), min: 1, max: 5, divisions: 4,
                  activeColor: Colors.amber,
                  onChanged: (v) => setDialogState(() => level = v.toInt()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ביטול')),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty) return;
                setState(() {
                  if (isEditing) {
                    todo.title = titleController.text;
                    todo.description = descController.text;
                    todo.dueDate = selectedDate;
                    todo.level = level;
                  } else {
                    _tasks.insert(0, TodoItem(
                      id: DateTime.now().toString(),
                      title: titleController.text,
                      description: descController.text,
                      dueDate: selectedDate,
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              if (value == 'level') _sortByLevel();
              if (value == 'date') _sortByDate();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'level', child: Text('מיון לפי רמה')),
              const PopupMenuItem(value: 'date', child: Text('מיון לפי תאריך')),
            ],
          ),
        ],
      ),
      body: ReorderableListView.builder(
        buildDefaultDragHandles: false,
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
          return ReorderableDragStartListener(
            key: ValueKey(task.id),
            index: index,
            child: TodoCard(
              todo: task,
              onToggle: () => setState(() => task.isCompleted = !task.isCompleted),
              onEdit: () => _showTaskDialog(todo: task),
              onDelete: () => setState(() => _tasks.removeAt(index)),
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