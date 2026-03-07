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
  int _selectedIndex = 0;

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

  void _sortByLevel() {
    setState(() {
      _tasks.sort((a, b) {
        if (a.isGolden) return -1;
        if (b.isGolden) return 1;
        return b.level.compareTo(a.level);
      });
    });
  }

  void _sortByDueDate() {
    setState(() {
      _tasks.sort((a, b) {
        if (a.isGolden) return -1;
        if (b.isGolden) return 1;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    });
  }

  void _handleEdit(TodoItem todo) {
    if (todo.recurrence == RecurrenceType.none) {
      _showRegularTaskDialog(todo: todo);
    } else {
      _showRecurringTaskDialog(todo: todo);
    }
  }

 // --- דיאלוג משימה רגילה (מתוקן) ---
  void _showRegularTaskDialog({TodoItem? todo}) {
    final isEditing = todo != null;
    final titleController = TextEditingController(text: todo?.title ?? '');
    final descController = TextEditingController(text: todo?.description ?? '');
    DateTime? selectedDate = todo?.dueDate;
    
    // הגדרת רמה 1 כברירת מחדל קבועה
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
                TextField(
                  controller: titleController, 
                  textAlign: TextAlign.right, 
                  decoration: const InputDecoration(hintText: 'כותרת')
                ),
                TextField(
                  controller: descController, 
                  textAlign: TextAlign.right, 
                  decoration: const InputDecoration(hintText: 'תיאור')
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(selectedDate == null 
                    ? 'תאריך יעד' 
                    : '${selectedDate!.day}/${selectedDate!.month}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context, 
                      initialDate: selectedDate ?? DateTime.now(), 
                      firstDate: DateTime.now(), 
                      lastDate: DateTime(2100)
                    );
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  },
                ),
                const SizedBox(height: 10),
                Text('רמת קושי: $level'), // תצוגת הרמה הנוכחית
                Slider(
                  value: level.toDouble(), 
                  min: 1, 
                  max: 5, 
                  divisions: 4, 
                  activeColor: Colors.amber, 
                  // עדכון הרמה בזמן אמת בתוך הדיאלוג
                  onChanged: (v) => setDialogState(() => level = v.toInt()),
                ),
              ],
            ),
          ),
          actions: [
            if (isEditing) 
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent), 
                onPressed: () { 
                  setState(() => _tasks.remove(todo)); 
                  Navigator.pop(context); 
                }
              ),
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('ביטול')
            ),
            ElevatedButton(
              // הכפתור פעיל תמיד אם יש כותרת, הרמה כבר מוגדרת כ-1 מראש
              onPressed: titleController.text.isEmpty ? null : () {
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
                      level: level // ישלח 1 אם לא שונה
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

  // --- דיאלוג משימה מחזורית ---
  void _showRecurringTaskDialog({TodoItem? todo}) {
    final isEditing = todo != null;
    final titleController = TextEditingController(text: todo?.title ?? '');
    final descController = TextEditingController(text: todo?.description ?? '');
    RecurrenceType type = todo?.recurrence ?? RecurrenceType.daily;
    TimeOfDay? time = todo?.reminderTime;
    int? repeatValue = todo?.repeatValue ?? 1;
    int level = todo?.level ?? 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'עריכת משימה מחזורית' : 'משימה מחזורית חדשה'),
          content: SingleChildScrollView(
            child: Column(
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
                  onChanged: (v) => setDialogState(() { 
                    type = v!; 
                    repeatValue = 1;
                  }),
                ),
                const SizedBox(height: 15),
                
                // בחירת ימי השבוע בעיגולים (RTL)
                if (type == RecurrenceType.weekly) ...[
                  const Align(alignment: Alignment.centerRight, child: Text("בחר יום בשבוע:", style: TextStyle(fontSize: 12))),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      int dayNum = index + 1;
                      List<String> dayNames = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'];
                      bool isSelected = repeatValue == dayNum;
                      return GestureDetector(
                        onTap: () => setDialogState(() => repeatValue = dayNum),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: isSelected ? Colors.amber : Colors.grey[800],
                          child: Text(
                            dayNames[index],
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // בחירת יום בחודש
                if (type == RecurrenceType.monthly)
                  DropdownButton<int>(
                    value: (repeatValue == null || repeatValue! > 31) ? 1 : repeatValue,
                    isExpanded: true,
                    items: List.generate(31, (i) => DropdownMenuItem(value: i + 1, child: Text('ב-${i + 1} לחודש'))),
                    onChanged: (v) => setDialogState(() => repeatValue = v),
                  ),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(time == null ? 'חובה לבחור שעה' : 'תזכורת ב: ${time!.format(context)}'),
                  trailing: const Icon(Icons.access_time, color: Colors.amber),
                  onTap: () async {
                    TimeOfDay? picked = await showTimePicker(context: context, initialTime: time ?? TimeOfDay.now());
                    if (picked != null) setDialogState(() => time = picked);
                  },
                ),
                Slider(value: level.toDouble(), min: 1, max: 5, divisions: 4, activeColor: Colors.amber, onChanged: (v) => setDialogState(() => level = v.toInt())),
              ],
            ),
          ),
          actions: [
            if (isEditing) IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () { setState(() => _tasks.remove(todo)); Navigator.pop(context); }),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ביטול')),
            ElevatedButton(
              onPressed: (titleController.text.isEmpty || time == null) ? null : () {
                setState(() {
                  if (isEditing) {
                    todo.title = titleController.text;
                    todo.recurrence = type;
                    todo.reminderTime = time;
                    todo.repeatValue = repeatValue;
                    todo.level = level;
                  } else {
                    _tasks.insert(0, TodoItem(id: DateTime.now().toString(), title: titleController.text, recurrence: type, reminderTime: time, repeatValue: repeatValue, level: level));
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
    final currentTasks = _tasks.where((t) {
      if (_selectedIndex == 0) return t.recurrence == RecurrenceType.none;
      return t.recurrence != RecurrenceType.none;
    }).toList();

    final goldenTask = currentTasks.where((t) => t.isGolden).toList();
    final otherTasks = currentTasks.where((t) => !t.isGolden).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'המשימות שלי' : 'הטקסים שלי'),
        actions: [
          if (_selectedIndex == 0)
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              onSelected: (val) => val == 'level' ? _sortByLevel() : _sortByDueDate(),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'level', child: Text('מיין לפי רמה')),
                const PopupMenuItem(value: 'date', child: Text('מיין לפי תאריך')),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedIndex == 0 && goldenTask.isNotEmpty) ...[
            const Padding(padding: EdgeInsets.only(top: 10, right: 20), child: Align(alignment: Alignment.centerRight, child: Text("פוקוס זהב", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)))),
            TodoCard(todo: goldenTask.first, onToggle: () => setState(() => goldenTask.first.isCompleted = !goldenTask.first.isCompleted), onEdit: () => _handleEdit(goldenTask.first), onDelete: () => setState(() => _tasks.remove(goldenTask.first)), onToggleGolden: () => _toggleGolden(goldenTask.first)),
            const SizedBox(height: 20),
            const Divider(),
          ],
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: otherTasks.length,
              onReorder: (oldIdx, newIdx) {
                setState(() {
                  if (newIdx > oldIdx) newIdx -= 1;
                  final task = otherTasks.removeAt(oldIdx);
                  _tasks.remove(task);
                  _tasks.insert(newIdx, task);
                });
              },
              itemBuilder: (context, index) {
                final task = otherTasks[index];
                return ReorderableDragStartListener(
                  key: ValueKey(task.id),
                  index: index,
                  child: TodoCard(todo: task, onToggle: () => setState(() => task.isCompleted = !task.isCompleted), onEdit: () => _handleEdit(task), onDelete: () => setState(() => _tasks.remove(task)), onToggleGolden: () => _toggleGolden(task)),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'משימות'),
          BottomNavigationBarItem(icon: Icon(Icons.sync), label: 'טקסים'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _selectedIndex == 0 ? _showRegularTaskDialog() : _showRecurringTaskDialog(),
        backgroundColor: _selectedIndex == 0 ? Colors.amber : Colors.blueGrey,
        child: const Icon(Icons.add),
      ),
    );
  }
}