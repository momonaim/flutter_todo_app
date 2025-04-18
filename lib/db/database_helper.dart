import 'dart:convert';
import 'dart:io'; // For checking platform
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // For desktop
import '../models/todo.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    // Use the correct database factory based on platform
    if (Platform.isAndroid || Platform.isIOS) {
      return await _initMobileDB();
    } else {
      return await _initDesktopDB();
    }
  }

  // Initialize for mobile platforms (Android/iOS)
  Future<Database> _initMobileDB() async {
    Directory documentsDir = await getApplicationDocumentsDirectory();
    String path = join(documentsDir.path, 'todos.db');

    return await openDatabase(path, version: 2, // Updated version for migration
        onCreate: (db, version) async {
      await db.execute('''CREATE TABLE todos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            text TEXT,
            completed INTEGER
          )''');
    }, onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute('''ALTER TABLE todos ADD COLUMN priority INTEGER''');
      }
    });
  }

  // Initialize for desktop platforms (Windows/macOS/Linux)
  Future<Database> _initDesktopDB() async {
    // Initialize sqflite_common_ffi (use ffi factory)
    sqfliteFfiInit();
    Directory documentsDir = await getApplicationDocumentsDirectory();
    String path = join(documentsDir.path, 'todos.db');

    return await databaseFactoryFfi.openDatabase(path,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
            await db.execute('''CREATE TABLE todos(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT,
              text TEXT,
              completed INTEGER
            )''');
          },
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 2) {
              await db
                  .execute('''ALTER TABLE todos ADD COLUMN priority INTEGER''');
            }
          },
        ));
  }

  Future<void> insertTodo(Todo todo) async {
    final db = await database;
    await db.insert('todos', todo.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Todo>> getTodosByDate(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('todos', where: 'date = ?', whereArgs: [date]);

    return List.generate(maps.length, (i) => Todo.fromMap(maps[i]));
  }

  Future<void> updateTodo(Todo todo) async {
    final db = await database;
    await db
        .update('todos', todo.toMap(), where: 'id = ?', whereArgs: [todo.id]);
  }

  Future<void> deleteTodo(int id) async {
    final db = await database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> exportAllTodosAsJson() async {
    final db = await database;
    final maps = await db.query('todos');
    final jsonList = maps.map((e) => Todo.fromMap(e).toMap()).toList();
    return jsonEncode(jsonList);
  }
}
