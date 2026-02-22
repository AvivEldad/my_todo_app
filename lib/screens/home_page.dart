import 'package:flutter/material.dart';

import '../models/todo_item.dart';
import '../services/reward_engine.dart';
import '../widgets/todo_card.dart';
import '../widgets/xp_bar.dart';

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  final List<TodoItem> _todos = [];
  int _xp = 0;
  int _level = 1;
  final int _xpPerLevel = 100;

  void _addTodo(String title, TaskType type, int level) {
    if (title.trim().isEmpty) return;
    setState(() {
      _todos.add(TodoItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.trim(),
        type: type,
        level: level,
      ));
    });
  }

  void _toggleGolden(TodoItem todo) {
    if (todo.type != TaskType.quest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only Quests can be Golden Tasks!')),
      );
      return;
    }

    setState(() {
      if (!todo.isGolden) {
        for (var item in _todos) {
          item.isGolden = false;
        }
        todo.isGolden = true;
      } else {
        todo.isGolden = false;
      }
    });
  }

  void _toggleTodo(TodoItem todo) {
    setState(() {
      final earnedXP = RewardEngine.calculateXP(todo);
      if (todo.isCompleted) {
        todo.isCompleted = false;
        _xp = (_xp - earnedXP).clamp(0, 999999);
      } else {
        todo.isCompleted = true;
        _xp += earnedXP;
        while (_xp >= _xpPerLevel) {
          _xp -= _xpPerLevel;
          _level++;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final goldenTask = _todos.where((t) => t.isGolden).toList();
    final regularTasks = _todos.where((t) => !t.isGolden).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('QuestLog XP')),
      drawer: _buildSidebar(),
      body: Column(
        children: [
          XpBar(level: _level, xp: _xp, xpPerLevel: _xpPerLevel),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (goldenTask.isNotEmpty) ...[
                  const Text(
                    "FOCUS / GOLDEN TASK",
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TodoCard(
                    todo: goldenTask.first,
                    onToggleTodo: () => _toggleTodo(goldenTask.first),
                    onToggleGolden: () => _toggleGolden(goldenTask.first),
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 16),
                ],
                const Text(
                  "OTHER TASKS",
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...regularTasks.map(
                  (t) => TodoCard(
                    todo: t,
                    onToggleTodo: () => _toggleTodo(t),
                    onToggleGolden: () => _toggleGolden(t),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A24),
      child: Column(
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF2D2D3A)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.amber,
              child: Icon(Icons.person, color: Colors.black),
            ),
            accountName: Text('Aviv', style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text('System Integration Engineer'),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today, color: Colors.amber),
            title: const Text('Daily Rituals'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.date_range, color: Colors.orange),
            title: const Text('Weekly Rituals'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.whatshot, color: Colors.deepOrange),
            title: const Text('Quests'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.account_tree, color: Colors.blueAccent),
            title: const Text('Projects'),
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showAddTodoDialog() {
    final controller = TextEditingController();
    int selectedLevel = 1;
    TaskType selectedType = TaskType.quest;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF2D2D3A),
          title: const Text('Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller, autofocus: true),
              const SizedBox(height: 20),
              DropdownButton<TaskType>(
                value: selectedType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: TaskType.dailyRitual, child: Text("Daily Ritual")),
                  DropdownMenuItem(value: TaskType.weeklyRitual, child: Text("Weekly Ritual")),
                  DropdownMenuItem(value: TaskType.quest, child: Text("Quest")),
                ],
                onChanged: (val) => setDialogState(() => selectedType = val!),
              ),
              Slider(
                value: selectedLevel.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: (val) => setDialogState(() => selectedLevel = val.toInt()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                _addTodo(controller.text, selectedType, selectedLevel);
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
