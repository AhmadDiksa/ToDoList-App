// lib/helpers/database_helper.dart
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/todo.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  // Database constants
  static const String _dbName = 'todo_database.db';
  static const String _tableName = 'todos';
  static const String _colId = 'id';
  static const String _colTitle = 'title';
  static const String _colDate = 'date';
  static const String _colIsDone = 'isDone';
  static const String _colIsStarred = 'isStarred';
  static const String _colCategory = 'category';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $_tableName (
            $_colId TEXT PRIMARY KEY,
            $_colTitle TEXT NOT NULL,
            $_colDate TEXT,
            $_colIsDone INTEGER NOT NULL,
            $_colIsStarred INTEGER NOT NULL,
            $_colCategory TEXT NOT NULL
          )
          ''');
  }

  // === CRUD Operations ===

  // Insert a todo into the database
  Future<int> insertTodo(Todo todo) async {
    Database db = await database;
    // Use conflictAlgorithm replace to handle potential duplicate IDs if needed
    return await db.insert(
      _tableName,
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Retrieve all todos from the database
  Future<List<Todo>> getTodos() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: '$_colId DESC', // Example: order by ID descending (newest first)
    );

    // Convert the List<Map<String, dynamic>> into a List<Todo>.
    return List.generate(maps.length, (i) {
      return Todo.fromMap(maps[i]);
    });
  }

  // Update a todo in the database
  Future<int> updateTodo(Todo todo) async {
    Database db = await database;
    return await db.update(
      _tableName,
      todo.toMap(),
      where: '$_colId = ?',
      whereArgs: [todo.id],
    );
  }

  // Delete a todo from the database
  Future<int> deleteTodo(String id) async {
    Database db = await database;
    return await db.delete(_tableName, where: '$_colId = ?', whereArgs: [id]);
  }

  // Optional: Get a single todo by ID (useful for update/delete confirmation)
  Future<Todo?> getTodoById(String id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: '$_colId = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Todo.fromMap(maps.first);
    }
    return null;
  }

  // Close the database (optional, usually managed by sqflite)
  Future close() async {
    Database db = await database;
    db.close();
    _database = null; // Reset instance
  }
}
