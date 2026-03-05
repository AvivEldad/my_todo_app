import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_todo_app/main.dart'; // <--- שנה לשם האפליקציה שלך

void main() {
  // פונקציית עזר ליצירת משימה בטסט
  Future<void> createNewTask(WidgetTester tester, String title, String desc, int level) async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle(); // מחכה שהדיאלוג ייפתח

    await tester.enterText(find.widgetWithText(TextField, 'כותרת'), title);
    await tester.enterText(find.widgetWithText(TextField, 'תיאור'), desc);
    
    // בחירת רמה (מניח שיש Slider או Dropdown עם הטקסט של הרמה)
    await tester.tap(find.text('רמה $level')); 
    
    await tester.tap(find.text('שמור'));
    await tester.pumpAndSettle(); // מחכה שהדיאלוג ייסגר והרשימה תתעדכן
  }

  group('סדרת טסטים למערכת המשימות וה-Gamification', () {
    
    testWidgets('1. בדיקת שדות יצירת משימה ואייקונים', (WidgetTester tester) async {
      await tester.pumpWidget(const TaskApp());
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('כותרת'), findsOneWidget);
      expect(find.text('תיאור'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget); // אייקון לוח שנה
      expect(find.text('בחירת רמה'), findsOneWidget);
    });

    testWidgets('2. יצירת משימה ברמה 4 עם תאריך', (WidgetTester tester) async {
      await tester.pumpWidget(const TaskApp());
      await createNewTask(tester, 'משימה חשובה', 'תיאור מפורט', 4);

      expect(find.text('משימה חשובה'), findsOneWidget);
      expect(find.text('רמה: 4'), findsOneWidget);
    });

    testWidgets('3. מיון לפי רמה ותאריך', (WidgetTester tester) async {
      await tester.pumpWidget(const TaskApp());
      
      // יצירת שתי משימות ברמות שונות
      await createNewTask(tester, 'רמה נמוכה', 'desc', 1);
      await createNewTask(tester, 'רמה גבוהה', 'desc', 5);

      // לחיצה על כפתור המיון (מניח שיש PopupMenuButton או כפתור ייעודי)
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();
      await tester.tap(find.text('לפי רמה'));
      await tester.pumpAndSettle();

      // בדיקה שהמשימה עם רמה 5 מופיעה מעל רמה 1
      final taskItems = find.byType(ListTile);
      expect(tester.widget<ListTile>(taskItems.at(0)).title.toString(), contains('רמה גבוהה'));
    });

    testWidgets('4. עריכה ומחיקה של משימה', (WidgetTester tester) async {
      await tester.pumpWidget(const TaskApp());
      await createNewTask(tester, 'משימה למחיקה', 'desc', 2);

      // עריכה
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'כותרת'), 'משימה מעודכנת');
      await tester.tap(find.text('עדכן'));
      await tester.pumpAndSettle();
      expect(find.text('משימה מעודכנת'), findsOneWidget);

      // מחיקה
      await tester.drag(find.text('משימה מעודכנת'), const Offset(-500, 0)); // סלייד למחיקה
      await tester.pumpAndSettle();
      expect(find.text('משימה מעודכנת'), findsNothing);
    });

    testWidgets('5. לוגיקת משימת זהב (Golden Task)', (WidgetTester tester) async {
      await tester.pumpWidget(const TaskApp());
      await createNewTask(tester, 'משימה א', 'desc', 3);
      await createNewTask(tester, 'משימה ב', 'desc', 3);

      // סימון משימה א' כזהב
      await tester.tap(find.byIcon(Icons.star_border).at(0));
      await tester.pumpAndSettle();
      
      // בדיקה שהיא הפכה לזהב (אייקון מלא)
      expect(find.byIcon(Icons.star), findsOneWidget);

      // החלפת משימת זהב למשימה ב'
      await tester.tap(find.byIcon(Icons.star_border).at(0)); 
      await tester.pumpAndSettle();

      // וודא שעדיין יש רק משימת זהב אחת פעילה
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });
}