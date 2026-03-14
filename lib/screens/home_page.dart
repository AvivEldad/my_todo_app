import 'package:flutter/material.dart';
import '../models/todo_item.dart';
import '../models/project_item.dart';
import '../widgets/todo_card.dart';
//import '../services/notification_service.dart';

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  final List<TodoItem> _tasks = [];
  final List<ProjectItem> _projects = [];
  int _selectedIndex = 0;

  // Tracks which project cards are expanded
  final Set<String> _expandedProjects = <String>{};

  // ─── Toggle golden (tasks only) ──────────────────────────────────
  void _toggleGolden(TodoItem todo) {
    setState(() {
      if (todo.isGolden) {
        todo.isGolden = false;
      } else {
        for (var t in _tasks) t.isGolden = false;
        todo.isGolden = true;
      }
    });
  }

  // ─── Delete ──────────────────────────────────────────────────────
  void _deleteTask(TodoItem todo) {
    setState(() {
      if (todo.recurrence != RecurrenceType.none) {
        //NotificationService.cancelNotification(todo.id);
      }
      _tasks.removeWhere((t) => t.id == todo.id);
    });
  }

  void _deleteProject(ProjectItem project) {
    setState(() {
      _expandedProjects.remove(project.id);
      _projects.removeWhere((p) => p.id == project.id);
    });
  }

  // ─── Regular task dialog ─────────────────────────────────────────
  void _showRegularTaskDialog({TodoItem? todo}) {
    final isEditing = todo != null;
    final titleController = TextEditingController(text: todo?.title ?? '');
    final descController = TextEditingController(text: todo?.description ?? '');
    DateTime? selectedDate = todo?.dueDate;
    int level = todo?.level ?? 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'עריכת משימה' : 'משימה רגילה חדשה'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, textAlign: TextAlign.right, decoration: const InputDecoration(hintText: 'כותרת')),
                TextField(controller: descController, textAlign: TextAlign.right, decoration: const InputDecoration(hintText: 'תיאור')),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(selectedDate == null ? 'תאריך יעד (אופציונלי)' : '${selectedDate!.day}/${selectedDate!.month}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  },
                ),
                Slider(value: level.toDouble(), min: 1, max: 5, divisions: 4, activeColor: Colors.amber, onChanged: (v) => setDialogState(() => level = v.toInt())),
              ],
            ),
          ),
          actions: [
            if (isEditing) IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () { _deleteTask(todo); Navigator.pop(context); }),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ביטול')),
            ElevatedButton(
              onPressed: titleController.text.isEmpty ? null : () {
                setState(() {
                  if (isEditing) {
                    todo.title = titleController.text;
                    todo.description = descController.text;
                    todo.dueDate = selectedDate;
                    todo.level = level;
                  } else {
                    _tasks.insert(0, TodoItem(id: DateTime.now().toString(), title: titleController.text, description: descController.text, dueDate: selectedDate, level: level));
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

  // ─── Recurring task dialog ───────────────────────────────────────
  void _showRecurringTaskDialog({TodoItem? todo}) {
    final isEditing = todo != null;
    final titleController = TextEditingController(text: todo?.title ?? '');
    RecurrenceType type = todo?.recurrence ?? RecurrenceType.daily;
    TimeOfDay? time = todo?.reminderTime;
    int? repeatValue = todo?.repeatValue ?? 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'עריכת טקס' : 'טקס מחזורי חדש'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, textAlign: TextAlign.right, decoration: const InputDecoration(hintText: 'כותרת')),
              const SizedBox(height: 15),
              DropdownButton<RecurrenceType>(
                value: type,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: RecurrenceType.daily, child: Text('כל יום')),
                  DropdownMenuItem(value: RecurrenceType.weekly, child: Text('כל שבוע')),
                  DropdownMenuItem(value: RecurrenceType.monthly, child: Text('כל חודש')),
                ],
                onChanged: (v) => setDialogState(() { type = v!; repeatValue = 1; }),
              ),
              if (type == RecurrenceType.weekly)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    int dayNum = index + 1;
                    bool isSelected = repeatValue == dayNum;
                    return GestureDetector(
                      onTap: () => setDialogState(() => repeatValue = dayNum),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: isSelected ? Colors.amber : Colors.grey[700],
                        child: Text(['א','ב','ג','ד','ה','ו','ש'][index], style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 12)),
                      ),
                    );
                  }),
                ),
              ListTile(
                title: Text(time == null ? 'חובה לבחור שעה' : 'תזכורת ב: ${time!.format(context)}'),
                trailing: const Icon(Icons.access_time, color: Colors.amber),
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(context: context, initialTime: time ?? TimeOfDay.now());
                  if (picked != null) setDialogState(() => time = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ביטול')),
            ElevatedButton(
              onPressed: (titleController.text.isEmpty || time == null) ? null : () {
                setState(() {
                  if (isEditing) {
                    todo.title = titleController.text;
                    todo.recurrence = type;
                    todo.reminderTime = time;
                    todo.repeatValue = repeatValue;
                    //NotificationService.scheduleNotification(todo);
                  } else {
                    final newTask = TodoItem(
                      id: DateTime.now().toString(),
                      title: titleController.text,
                      recurrence: type,
                      reminderTime: time,
                      repeatValue: repeatValue,
                    );
                    _tasks.insert(0, newTask);
                    //NotificationService.scheduleNotification(newTask);
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('אישור'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Project dialog (create / edit project metadata) ─────────────
  void _showProjectDialog({ProjectItem? project}) {
    final isEditing = project != null;
    final titleController = TextEditingController(text: project?.title ?? '');
    final descController = TextEditingController(text: project?.description ?? '');
    DateTime? selectedDate = project?.dueDate;
    int level = project?.level ?? 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'עריכת פרויקט' : 'פרויקט חדש'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, textAlign: TextAlign.right, decoration: const InputDecoration(hintText: 'כותרת')),
                TextField(controller: descController, textAlign: TextAlign.right, decoration: const InputDecoration(hintText: 'תיאור')),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(selectedDate == null ? 'תאריך יעד (אופציונלי)' : '${selectedDate!.day}/${selectedDate!.month}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  },
                ),
                Slider(value: level.toDouble(), min: 1, max: 5, divisions: 4, activeColor: Colors.amber, onChanged: (v) => setDialogState(() => level = v.toInt())),
              ],
            ),
          ),
          actions: [
            if (isEditing) IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () { _deleteProject(project); Navigator.pop(context); }),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ביטול')),
            ElevatedButton(
              onPressed: titleController.text.isEmpty ? null : () {
                setState(() {
                  if (isEditing) {
                    project.title = titleController.text;
                    project.description = descController.text;
                    project.dueDate = selectedDate;
                    project.level = level;
                  } else {
                    _projects.insert(0, ProjectItem(
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

  // ─── Subtask dialog (identical fields to regular task) ───────────
  void _showSubtaskDialog({required ProjectItem project, TodoItem? todo}) {
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
                TextField(controller: titleController, textAlign: TextAlign.right, decoration: const InputDecoration(hintText: 'כותרת')),
                TextField(controller: descController, textAlign: TextAlign.right, decoration: const InputDecoration(hintText: 'תיאור')),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(selectedDate == null ? 'תאריך יעד (אופציונלי)' : '${selectedDate!.day}/${selectedDate!.month}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  },
                ),
                Slider(value: level.toDouble(), min: 1, max: 5, divisions: 4, activeColor: Colors.amber, onChanged: (v) => setDialogState(() => level = v.toInt())),
              ],
            ),
          ),
          actions: [
            if (isEditing)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () {
                  setState(() => project.subtasks.removeWhere((t) => t.id == todo.id));
                  Navigator.pop(context);
                },
              ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ביטול')),
            ElevatedButton(
              onPressed: titleController.text.isEmpty ? null : () {
                setState(() {
                  if (isEditing) {
                    todo.title = titleController.text;
                    todo.description = descController.text;
                    todo.dueDate = selectedDate;
                    todo.level = level;
                  } else {
                    project.subtasks.add(TodoItem(
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

  // ─── Projects tab ─────────────────────────────────────────────────
  Widget _buildProjectsTab() {
    if (_projects.isEmpty) {
      return Center(
        child: Text(
          'אין פרויקטים עדיין\nלחץ + כדי להוסיף',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }
    return ReorderableListView.builder(
      itemCount: _projects.length,
      onReorder: (oldIdx, newIdx) {
        setState(() {
          if (newIdx > oldIdx) newIdx -= 1;
          final item = _projects.removeAt(oldIdx);
          _projects.insert(newIdx, item);
        });
      },
      itemBuilder: (context, index) => ReorderableDragStartListener(
        key: ValueKey(_projects[index].id),
        index: index,
        child: _buildProjectCard(_projects[index]),
      ),
    );
  }

  Widget _buildProjectCard(ProjectItem project) {
    final isExpanded = _expandedProjects.contains(project.id);
    final activeIdx = project.activeSubtaskIndex;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          // ── Project header ──
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedProjects.remove(project.id);
              } else {
                _expandedProjects.add(project.id);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: chevron + edit + delete + add subtask
                      Row(
                        children: [
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.grey[400],
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _showProjectDialog(project: project),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                            onPressed: () => _deleteProject(project),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'מחק פרויקט',
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.add_task, size: 18, color: Colors.amber),
                            onPressed: () => _showSubtaskDialog(project: project),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'הוסף משימה',
                          ),
                        ],
                      ),
                      // Right: title + counter
                      Row(
                        children: [
                          Text(
                            '${project.completedCount}/${project.subtasks.length}',
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            project.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (project.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 6),
                      child: Text(
                        project.description,
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: project.progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        project.progress == 1.0 ? Colors.green : Colors.amber,
                      ),
                    ),
                  ),
                  if (project.dueDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'יעד: ${project.dueDate!.day}/${project.dueDate!.month}/${project.dueDate!.year}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Expanded subtask list ──
          if (isExpanded) ...[
            if (project.subtasks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('אין משימות עדיין', style: TextStyle(color: Colors.grey[500])),
              )
            else ...[
              const Divider(height: 1),
              ...List.generate(project.subtasks.length, (i) {
                final subtask = project.subtasks[i];
                final isActive = i == activeIdx;
                final isLocked = !subtask.isCompleted && !isActive;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading: isLocked
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.lock, size: 18, color: Colors.grey),
                        )
                      : Checkbox(
                          value: subtask.isCompleted,
                          activeColor: Colors.amber,
                          onChanged: (_) => setState(() => subtask.isCompleted = !subtask.isCompleted),
                        ),
                  title: Text(
                    subtask.title,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                      color: isLocked
                          ? Colors.grey[600]
                          : subtask.isCompleted
                              ? Colors.grey
                              : null,
                    ),
                  ),
                  subtitle: (subtask.description?.isNotEmpty ?? false) || subtask.dueDate != null
                      ? Text(
                          [
                            if (subtask.description?.isNotEmpty ?? false) subtask.description!,
                            if (subtask.dueDate != null) '${subtask.dueDate!.day}/${subtask.dueDate!.month}',
                          ].join(' · '),
                          textAlign: TextAlign.right,
                          style: TextStyle(color: isLocked ? Colors.grey[700] : null),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isActive)
                        const Icon(Icons.play_arrow, size: 16, color: Colors.amber),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        onPressed: () => _showSubtaskDialog(project: project, todo: subtask),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 16, color: Colors.redAccent),
                        onPressed: () => setState(() => project.subtasks.removeWhere((t) => t.id == subtask.id)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final currentTasks = _tasks
        .where((t) => _selectedIndex == 0
            ? t.recurrence == RecurrenceType.none
            : t.recurrence != RecurrenceType.none)
        .toList();
    final goldenTask = currentTasks.where((t) => t.isGolden).toList();
    final otherTasks = currentTasks.where((t) => !t.isGolden).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(['המשימות שלי', 'הטקסים שלי', 'הפרויקטים שלי'][_selectedIndex]),
        ),
        body: _selectedIndex == 2
            ? _buildProjectsTab()
            : Column(
                children: [
                  if (_selectedIndex == 0 && goldenTask.isNotEmpty) ...[
                    TodoCard(
                      todo: goldenTask.first,
                      onToggle: () => setState(() => goldenTask.first.isCompleted = !goldenTask.first.isCompleted),
                      onEdit: () => _showRegularTaskDialog(todo: goldenTask.first),
                      onDelete: () => _deleteTask(goldenTask.first),
                      onToggleGolden: () => _toggleGolden(goldenTask.first),
                    ),
                    const Divider(),
                  ],
                  Expanded(
                    child: ReorderableListView.builder(
                      itemCount: otherTasks.length,
                      onReorder: (oldIdx, newIdx) {
                        setState(() {
                          if (newIdx > oldIdx) newIdx -= 1;
                          final item = otherTasks.removeAt(oldIdx);
                          _tasks.remove(item);
                          _tasks.insert(newIdx, item);
                        });
                      },
                      itemBuilder: (context, index) => ReorderableDragStartListener(
                        key: ValueKey(otherTasks[index].id),
                        index: index,
                        child: TodoCard(
                          todo: otherTasks[index],
                          onToggle: () => setState(() => otherTasks[index].isCompleted = !otherTasks[index].isCompleted),
                          onEdit: () => _selectedIndex == 0
                              ? _showRegularTaskDialog(todo: otherTasks[index])
                              : _showRecurringTaskDialog(todo: otherTasks[index]),
                          onDelete: () => _deleteTask(otherTasks[index]),
                          onToggleGolden: () => _toggleGolden(otherTasks[index]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.list), label: 'משימות'),
            BottomNavigationBarItem(icon: Icon(Icons.sync), label: 'טקסים'),
            BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), label: 'פרויקטים'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (_selectedIndex == 0) _showRegularTaskDialog();
            else if (_selectedIndex == 1) _showRecurringTaskDialog();
            else _showProjectDialog();
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}