import 'package:flutter/material.dart';
import 'screens/home_page.dart';

void main() => runApp(const TaskApp());

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark, 
        useMaterial3: true,
        primarySwatch: Colors.amber,
      ),
      home: const TodoHomePage(),
    );
  }
}