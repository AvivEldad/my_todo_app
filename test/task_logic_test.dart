import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:my_todo_app/models/todo_item.dart';
import 'package:my_todo_app/services/task_service.dart';

void main() {
  group('Advanced Task Operations & Sorting', () {
    
    // 1. עריכת משימה ומיון מחדש
    test('Edit a task and sort again', () {
      var tasks = [
        TodoItem(id: '1', title: 'Task A', level: 1),
        TodoItem(id: '2', title: 'Task B', level: 3),
      ];
      
      // עריכה: שינוי רמה של משימה A מרמה 1 לרמה 5
      tasks[0].level = 5;
      
      var sorted = TaskService.sortByLevel(tasks);
      expect(sorted.first.title, 'Task A');
    });

    // 2. מחיקת משימה
    test('Delete a task', () {
      var tasks = [
        TodoItem(id: '1', title: 'To Delete'),
        TodoItem(id: '2', title: 'To Keep'),
      ];
      
      tasks.removeWhere((t) => t.id == '1');
      expect(tasks.length, 1);
      expect(tasks.first.title, 'To Keep');
    });

    // 3, 4, 5. יצירת משימות מחזוריות (יומי, שבועי, חודשי)
    test('Create recurring tasks (Daily, Weekly, Monthly)', () {
      final daily = TodoItem(
        id: 'd1', title: 'Daily', recurrence: RecurrenceType.daily, 
        reminderTime: const TimeOfDay(hour: 8, minute: 0)
      );
      final weekly = TodoItem(
        id: 'w1', title: 'Weekly', recurrence: RecurrenceType.weekly, 
        repeatValue: 1, // יום א'
        reminderTime: const TimeOfDay(hour: 10, minute: 0)
      );
      final monthly = TodoItem(
        id: 'm1', title: 'Monthly', recurrence: RecurrenceType.monthly, 
        repeatValue: 15, // ב-15 לחודש
        reminderTime: const TimeOfDay(hour: 12, minute: 0)
      );

      expect(daily.recurrence, RecurrenceType.daily);
      expect(weekly.repeatValue, 1);
      expect(monthly.repeatValue, 15);
    });

    // 7. עריכת משימה חודשית
    test('Edit a monthly task', () {
      var monthlyTask = TodoItem(
        id: 'm1', title: 'Rent', recurrence: RecurrenceType.monthly, repeatValue: 1
      );
      
      // שינוי יום התשלום מה-1 לחודש ל-10 לחודש
      monthlyTask.repeatValue = 10;
      monthlyTask.title = 'Updated Rent';

      expect(monthlyTask.repeatValue, 10);
      expect(monthlyTask.title, 'Updated Rent');
    });

    // 9. שינוי משימת הזהב
    test('Change the golden task', () {
      var tasks = [
        TodoItem(id: '1', title: 'Old Gold', isGolden: true),
        TodoItem(id: '2', title: 'New Gold', isGolden: false),
      ];
      
      // לוגיקת החלפה (ממש כמו ב-HomePage)
      for (var t in tasks) t.isGolden = false;
      tasks[1].isGolden = true;

      var sorted = TaskService.sortByLevel(tasks);
      expect(sorted.first.title, 'New Gold');
      expect(tasks[0].isGolden, false);
    });
  });
}