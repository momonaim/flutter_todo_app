import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:todo_app/main.dart';
import '../db/database_helper.dart';
import '../models/todo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dbHelper = DatabaseHelper();
  final _controller = TextEditingController();
  List<Todo> _todos = [];
  DateTime selectedDate = DateTime.now();
  final _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadTodos();
    _showPendingTasksNotification(); // immédiat à l'ouverture
    scheduleDailyReminder(); // ⏰ tous les jours à 23h
  }

  Future<void> _loadTodos() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final todos = await _dbHelper.getTodosByDate(dateStr);
    setState(() {
      _todos = todos
          .where((todo) =>
              todo.text.toLowerCase().contains(_searchText.toLowerCase()))
          .toList();
    });
  }

  Future<void> _addTodo() async {
    if (_controller.text.trim().isEmpty) return;

    final newTodo = Todo(
      date: DateFormat('yyyy-MM-dd').format(selectedDate),
      text: _controller.text.trim(),
      completed: false,
    );
    await _dbHelper.insertTodo(newTodo);
    _controller.clear();
    _loadTodos();
  }

  Future<void> _toggleTodo(Todo todo) async {
    final updatedTodo = Todo(
      id: todo.id,
      date: todo.date,
      text: todo.text,
      completed: !todo.completed,
    );
    await _dbHelper.updateTodo(updatedTodo);
    _loadTodos();
  }

  Future<void> _deleteTodo(int id) async {
    await _dbHelper.deleteTodo(id);
    _loadTodos();
  }

  Future<void> _exportTodosToJson() async {
    String json = await _dbHelper.exportAllTodosAsJson();
    final output = await FilePicker.platform.getDirectoryPath();

    // Vérification du "mounted" pour s'assurer que le widget est toujours là
    if (!mounted) return;

    if (output != null) {
      final file = File('$output/todos_export.json');
      await file.writeAsString(json);

      // Utilisation du context après la vérification "mounted"
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exported todos_export.json')),
        );
      }
    }
  }

  Future<void> _loadTodosFromJson() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null) {
      final file = File(result.files.single.path!);

      final contents = await file.readAsString();

      List<dynamic> jsonList = json.decode(contents);
      setState(() {
        _todos = jsonList.map((e) => Todo.fromMap(e)).toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todos loaded successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
      _loadTodos();
    }
  }

  Future<void> _showPendingTasksNotification() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final todos = await _dbHelper.getTodosByDate(dateStr);
    final pendingCount = todos.where((t) => !t.isDone).length;

    if (pendingCount == 0) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      channelDescription: 'Notification for today\'s tasks',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Tâches du jour',
      'Tu as $pendingCount tâche(s) à faire aujourd\'hui.',
      platformChannelSpecifics,
    );
  }

  Future<void> scheduleDailyReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      channelDescription: 'Rappel quotidien à 23h',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'Rappel quotidien',
      'Vérifie si tu as terminé toutes tes tâches !',
      _nextInstanceOf23h(),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.time, // 📅 Répéter chaque jour
    );
  }

  tz.TZDateTime _nextInstanceOf23h() {
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 23);

    return scheduled.isBefore(now)
        ? scheduled.add(const Duration(days: 1))
        : scheduled;
  }

  @override
  Widget build(BuildContext context) {
    DateFormat('yyyy-MM-dd').format(selectedDate);
    final completedCount = _todos.where((todo) => todo.completed).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 Daily To-Do',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Export Todos to JSON
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export JSON',
            onPressed: _exportTodosToJson,
          ),
          // Load Todos from JSON
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'Load JSON',
            onPressed: _loadTodosFromJson,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left_rounded,
                      size: 30, color: Colors.blueAccent),
                  onPressed: () {
                    setState(() {
                      selectedDate =
                          selectedDate.subtract(const Duration(days: 1));
                    });
                    _loadTodos();
                  },
                  splashColor: Colors.blueAccent.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                Text(
                  DateFormat('yyyy-MM-dd').format(selectedDate),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right_rounded,
                      size: 30, color: Colors.blueAccent),
                  onPressed: () {
                    setState(() {
                      selectedDate = selectedDate.add(const Duration(days: 1));
                    });
                    _loadTodos();
                  },
                  splashColor: Colors.blueAccent.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today_rounded,
                      size: 30, color: Colors.blueAccent),
                  tooltip: 'Pick a date',
                  onPressed: _pickDate,
                  splashColor: Colors.blueAccent.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Tâches complétées : $completedCount',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter a new task',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      fillColor: Colors.grey[100],
                      filled: true,
                    ),
                    onSubmitted: (_) => _addTodo(), // Ajouter par "Entrée"
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _addTodo,
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.add, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Add',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
                _loadTodos();
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _todos.isEmpty
                  ? const Center(child: Text('No tasks for this day.'))
                  : ListView.builder(
                      itemCount: _todos.length,
                      itemBuilder: (context, index) {
                        final todo = _todos[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          color: todo.completed
                              ? Colors.green[100]
                              : Colors
                                  .white, // Changer la couleur de la Card ici
                          child: ListTile(
                            leading: Checkbox(
                              value: todo.completed,
                              onChanged: (_) => _toggleTodo(todo),
                            ),
                            title: Text(
                              todo.text,
                              style: TextStyle(
                                color: todo.completed
                                    ? Colors.green[800]
                                    : Colors
                                        .black, // Changer la couleur du texte ici si besoin
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTodo(todo.id!),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
