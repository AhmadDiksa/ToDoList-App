// lib/helpers/database_helper.dart
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/todo.dart'; // Pastikan path ke model Todo benar

class DatabaseHelper {
  // Pola Singleton untuk memastikan hanya ada satu instance DatabaseHelper
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // Instance database (nullable, diinisialisasi saat pertama kali diakses)
  static Database? _database;

  // Konstanta untuk nama database dan tabel
  static const String _dbName = 'todo_database.db';
  static const String _tableName = 'todos';

  // Konstanta untuk nama-nama kolom di tabel 'todos'
  static const String _colId = 'id'; // Primary Key (TEXT karena ID kita String)
  static const String _colTitle = 'title'; // TEXT NOT NULL
  static const String _colDate = 'date'; // TEXT (tanggal info, bukan deadline)
  static const String _colDeadline =
      'deadline'; // TEXT NULL (Simpan sbg ISO8601 String)
  static const String _colReminderDateTime =
      'reminderDateTime'; // TEXT NULL (Simpan sbg ISO8601 String)
  static const String _colRepeatRule =
      'repeatRule'; // TEXT NULL (String aturan pengulangan)
  static const String _colNotes = 'notes'; // TEXT NULL (Catatan tugas)
  static const String _colIsDone = 'isDone'; // INTEGER NOT NULL (0 atau 1)
  static const String _colIsStarred =
      'isStarred'; // INTEGER NOT NULL (0 atau 1)
  static const String _colCategory = 'category'; // TEXT NOT NULL

  // Getter untuk instance database, menginisialisasi jika belum ada
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Fungsi internal untuk menginisialisasi database
  Future<Database> _initDatabase() async {
    // Dapatkan path direktori database di perangkat
    String path = join(await getDatabasesPath(), _dbName);

    // Buka database. Jika belum ada, onCreate akan dipanggil.
    // Jika sudah ada dan versi berbeda, onUpgrade akan dipanggil.
    return await openDatabase(
      path,
      version:
          3, // <-- VERSI DATABASE TERBARU (naikkan setiap ada perubahan skema)
      onCreate: _onCreate, // Fungsi saat database dibuat pertama kali
      onUpgrade: _onUpgrade, // Fungsi saat versi database dinaikkan
    );
  }

  // Fungsi yang dipanggil saat database dibuat untuk pertama kalinya (version 1)
  // atau jika DB dihapus dan dibuat ulang.
  Future _onCreate(Database db, int version) async {
    print("Creating database table for the first time (version $version)...");
    // Panggil fungsi untuk membuat struktur tabel awal
    await _createTable(db);
  }

  // Fungsi yang dipanggil saat versi database di `openDatabase` lebih tinggi
  // dari versi database yang ada di perangkat.
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Upgrading database from version $oldVersion to $newVersion...");
    // Jalankan skrip upgrade secara bertahap
    if (oldVersion < 2) {
      // Jika upgrade dari v1 ke v2 (atau lebih tinggi dari v1)
      print("Applying upgrade v1 to v2 (Adding deadline column)...");
      // Tambahkan kolom 'deadline' jika belum ada
      await db.execute(
        'ALTER TABLE $_tableName ADD COLUMN $_colDeadline TEXT NULL',
      );
      print("Deadline column added.");
    }
    if (oldVersion < 3) {
      // Jika upgrade dari v2 ke v3 (atau lebih tinggi dari v2)
      print(
        "Applying upgrade v2 to v3 (Adding reminder, repeat, notes columns)...",
      );
      // Tambahkan kolom 'reminderDateTime', 'repeatRule', dan 'notes' jika belum ada
      await db.execute(
        'ALTER TABLE $_tableName ADD COLUMN $_colReminderDateTime TEXT NULL',
      );
      await db.execute(
        'ALTER TABLE $_tableName ADD COLUMN $_colRepeatRule TEXT NULL',
      );
      await db.execute(
        'ALTER TABLE $_tableName ADD COLUMN $_colNotes TEXT NULL',
      );
      print("Reminder, Repeat, and Notes columns added.");
    }
    // Tambahkan blok 'if (oldVersion < X)' untuk upgrade selanjutnya di masa depan
    print("Database upgrade complete to version $newVersion.");
  }

  // Fungsi terpisah untuk membuat struktur tabel (mengandung semua kolom terbaru)
  Future<void> _createTable(Database db) async {
    await db.execute('''
          CREATE TABLE $_tableName (
            $_colId TEXT PRIMARY KEY,
            $_colTitle TEXT NOT NULL,
            $_colDate TEXT,
            $_colDeadline TEXT NULL,         -- Ditambah di v2
            $_colReminderDateTime TEXT NULL, -- Ditambah di v3
            $_colRepeatRule TEXT NULL,       -- Ditambah di v3
            $_colNotes TEXT NULL,            -- Ditambah di v3
            $_colIsDone INTEGER NOT NULL,
            $_colIsStarred INTEGER NOT NULL,
            $_colCategory TEXT NOT NULL
          )
          ''');
    print("Table '$_tableName' created with all columns.");
  }

  // === Operasi CRUD (Create, Read, Update, Delete) ===
  // Mapping antara objek Todo dan Map ditangani oleh Model Todo (toMap/fromMap)

  // CREATE: Memasukkan Todo baru ke database
  Future<int> insertTodo(Todo todo) async {
    Database db = await database;
    // Menggunakan conflictAlgorithm.replace berarti jika ID sudah ada, data lama akan ditimpa.
    // Alternatif: ConflictAlgorithm.ignore (abaikan insert jika ID ada)
    // atau ConflictAlgorithm.fail (lemparkan error jika ID ada).
    int result = await db.insert(
      _tableName,
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("Inserted Todo ID: ${todo.id}, Result: $result");
    return result;
  }

  // READ: Mengambil semua Todo dari database
  Future<List<Todo>> getTodos() async {
    Database db = await database;
    // Query semua baris dari tabel, bisa ditambahkan `where`, `limit`, dll. jika perlu
    // Mengurutkan berdasarkan deadline (null di akhir), lalu ID terbaru di atas
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy:
          '$_colDeadline ASC, $_colId DESC', // NULLS LAST untuk ASC adalah default SQLite
    );

    // Konversi List<Map<String, dynamic>> menjadi List<Todo>
    List<Todo> todos = List.generate(maps.length, (i) {
      return Todo.fromMap(maps[i]);
    });
    print("Fetched ${todos.length} todos from database.");
    return todos;
  }

  // READ: Mengambil satu Todo berdasarkan ID (opsional, berguna untuk detail/update)
  Future<Todo?> getTodoById(String id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: '$_colId = ?', // Gunakan placeholder '?' untuk keamanan
      whereArgs: [id], // Masukkan argumen di whereArgs
      limit: 1, // Hanya butuh satu hasil
    );
    if (maps.isNotEmpty) {
      print("Fetched Todo by ID: $id");
      return Todo.fromMap(maps.first);
    }
    print("Todo not found for ID: $id");
    return null;
  }

  // UPDATE: Memperbarui Todo yang ada di database
  Future<int> updateTodo(Todo todo) async {
    Database db = await database;
    int result = await db.update(
      _tableName,
      todo.toMap(), // Data baru dari objek Todo
      where: '$_colId = ?', // Kondisi update berdasarkan ID
      whereArgs: [todo.id],
    );
    print("Updated Todo ID: ${todo.id}, Rows affected: $result");
    return result;
  }

  // DELETE: Menghapus Todo dari database berdasarkan ID
  Future<int> deleteTodo(String id) async {
    Database db = await database;
    int result = await db.delete(
      _tableName,
      where: '$_colId = ?', // Kondisi delete berdasarkan ID
      whereArgs: [id],
    );
    print("Deleted Todo ID: $id, Rows affected: $result");
    return result;
  }

  // Fungsi untuk menutup koneksi database (opsional, biasanya tidak perlu dipanggil manual)
  Future close() async {
    Database db = await database;
    if (db.isOpen) {
      await db.close();
      _database =
          null; // Reset instance agar bisa diinisialisasi ulang jika perlu
      print("Database connection closed.");
    }
  }
}
