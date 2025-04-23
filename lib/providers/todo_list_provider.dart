// lib/providers/todo_list_provider.dart
import 'package:flutter/foundation.dart'; // Untuk ChangeNotifier
import '../models/todo.dart'; // Model data Todo
import '../helpers/database_helper.dart'; // Helper untuk interaksi SQLite
import '../services/notification_service.dart'; // Service untuk notifikasi
import 'dart:collection'; // Untuk UnmodifiableListView

class TodoListProvider with ChangeNotifier {
  // Instance helper dan service
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();

  // State internal
  List<Todo> _todos = []; // Daftar tugas utama
  bool _isLoading = false; // Status loading data dari DB

  // Getter publik untuk UI
  // Memberikan akses read-only ke daftar todos
  UnmodifiableListView<Todo> get todos => UnmodifiableListView(_todos);
  // Memberikan status loading saat ini
  bool get isLoading => _isLoading;

  // Konstruktor: Langsung load data saat provider dibuat
  TodoListProvider() {
    loadTodos();
  }

  // Method untuk memuat semua tugas dari database
  Future<void> loadTodos() async {
    // Set status loading true dan notifikasi UI
    _isLoading = true;
    notifyListeners();

    try {
      // Ambil data dari database helper
      _todos = await _dbHelper.getTodos();
      print("Todos loaded from database: ${_todos.length} items");
      // Opsional: Anda bisa melakukan sinkronisasi notifikasi di sini jika diperlukan
      // Misalnya, memastikan notifikasi yang terjadwal sesuai dengan data DB terbaru.
      // for (var todo in _todos) {
      //   _notificationService.scheduleNotification(todo);
      // }
    } catch (e) {
      print("Error loading todos from database: $e");
      _todos = []; // Kosongkan list jika ada error
    } finally {
      // Set status loading false setelah selesai (baik sukses maupun gagal)
      _isLoading = false;
      notifyListeners(); // Notifikasi UI bahwa loading selesai
    }
  }

  // Method untuk mendapatkan daftar tugas yang sudah difilter berdasarkan kategori
  // (Logika filter bisa juga ditaruh di UI jika lebih sesuai)
  List<Todo> getFilteredTodos(String category) {
    if (_isLoading) return []; // Kembalikan list kosong jika masih loading
    if (category == 'Semua') {
      // Kembalikan copy yg tidak bisa dimodifikasi
      return List.unmodifiable(_todos);
    }
    // Filter berdasarkan kategori dan kembalikan copy
    return List.unmodifiable(_todos.where((todo) => todo.category == category));
  }

  // === Metode CRUD dan Update ===

  // Menambahkan tugas baru
  Future<void> addTodo(String title, String category) async {
    // Validasi judul tidak kosong
    if (title.trim().isEmpty) return;

    // Buat objek Todo baru
    final newTodo = Todo(
      id:
          DateTime.now().millisecondsSinceEpoch
              .toString(), // ID sementara berbasis timestamp
      title: title.trim(),
      date: 'Hari ini', // Tanggal info default
      category: category,
      deadline: null, // Deadline null saat dibuat
      isDone: false,
      isStarred: false,
    );

    try {
      // 1. Simpan ke database
      await _dbHelper.insertTodo(newTodo);
      // 2. Tambahkan ke state lokal (di awal list agar muncul teratas)
      _todos.insert(0, newTodo);
      // 3. Notifikasi UI (tidak perlu await)
      notifyListeners();
      print("Added todo: ${newTodo.title}");
      // 4. Tidak perlu schedule notifikasi karena deadline null
    } catch (e) {
      print("Error adding todo '${newTodo.title}': $e");
      // Handle error (misalnya tampilkan pesan ke user)
    }
  }

  // Menghapus tugas
  // Mengembalikan objek Todo yang dihapus agar bisa di-Undo oleh UI
  Future<Todo?> removeTodo(String id) async {
    // Cari index dan objek todo di state lokal *sebelum* menghapus
    final index = _todos.indexWhere((todo) => todo.id == id);
    Todo? removedTodo;
    if (index != -1) {
      removedTodo = _todos[index];
    } else {
      return null; // Tidak ditemukan di state lokal
    }

    try {
      // 1. Hapus dari database
      final deletedRows = await _dbHelper.deleteTodo(id);

      // 2. Jika berhasil hapus dari DB, hapus dari state lokal
      if (deletedRows > 0) {
        _todos.removeAt(index); // Hapus dari state lokal berdasarkan index
        // 3. Batalkan notifikasi yang mungkin terjadwal untuk todo ini
        await _notificationService.cancelNotification(id);
        // 4. Notifikasi UI
        notifyListeners();
        print("Removed todo: ${removedTodo.title}");
        // 5. Kembalikan objek yang dihapus untuk proses Undo di UI
        return removedTodo;
      } else {
        print(
          "Failed to delete todo from DB (ID: $id), rows affected: $deletedRows",
        );
        return null; // Gagal hapus dari DB
      }
    } catch (e) {
      print("Error removing todo '$id': $e");
      return null; // Error saat proses
    }
  }

  // Mengembalikan tugas yang dihapus (Undo)
  Future<void> undoRemove(int index, Todo todo) async {
    // Validasi index agar tidak out of bounds
    if (index < 0) index = 0;
    if (index > _todos.length) index = _todos.length;

    try {
      // 1. Masukkan kembali ke database
      await _dbHelper.insertTodo(todo);
      // 2. Masukkan kembali ke state lokal pada index semula
      _todos.insert(index, todo);
      // 3. Jadwalkan ulang notifikasi jika ada deadline
      if (todo.deadline != null) {
        await _notificationService.scheduleNotification(todo);
      }
      // 4. Notifikasi UI
      notifyListeners();
      print("Undo remove for: ${todo.title}");
    } catch (e) {
      print("Error undoing remove for '${todo.title}': $e");
      // Handle error
    }
  }

  // Mengubah status selesai (isDone)
  Future<void> toggleDone(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final todo = _todos[index];
      final originalStatus = todo.isDone; // Simpan status awal

      // 1. Ubah state lokal (Optimistic Update)
      todo.isDone = !todo.isDone;
      notifyListeners(); // Update UI segera

      try {
        // 2. Update database
        await _dbHelper.updateTodo(todo);
        print("Toggled done for ${todo.title} to ${todo.isDone}");
        // 3. Jika ditandai selesai, batalkan notifikasi deadline? (Opsional)
        // if (todo.isDone && todo.deadline != null) {
        //   await _notificationService.cancelNotification(todo.id);
        // }
        // Jika ditandai belum selesai, jadwalkan ulang jika ada deadline?
        // else if (!todo.isDone && todo.deadline != null) {
        //    await _notificationService.scheduleNotification(todo);
        // }
      } catch (e) {
        print("Error toggling done for '$id': $e");
        // 4. Jika update DB gagal, kembalikan state lokal
        todo.isDone = originalStatus;
        notifyListeners(); // Update UI kembali ke state awal
      }
    }
  }

  // Mengubah status bintang (isStarred)
  Future<void> toggleStar(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final todo = _todos[index];
      final originalStatus = todo.isStarred;

      // 1. Ubah state lokal
      todo.isStarred = !todo.isStarred;
      notifyListeners(); // Update UI

      try {
        // 2. Update database
        await _dbHelper.updateTodo(todo);
        print("Toggled star for ${todo.title} to ${todo.isStarred}");
      } catch (e) {
        print("Error toggling star for '$id': $e");
        // 3. Kembalikan state lokal jika gagal
        todo.isStarred = originalStatus;
        notifyListeners();
      }
    }
  }

  // Mengupdate deadline tugas
  Future<void> updateTodoDeadline(String id, DateTime? newDeadline) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final todo = _todos[index];
      final oldDeadline = todo.deadline; // Simpan yg lama untuk revert

      // 1. Update state lokal
      todo.deadline = newDeadline;
      notifyListeners(); // Update UI

      try {
        // 2. Update database
        await _dbHelper.updateTodo(todo);
        print("Updated deadline for ${todo.title} to $newDeadline");

        // 3. Jadwalkan / Batalkan Notifikasi berdasarkan deadline baru
        if (newDeadline != null) {
          // Jadwalkan notifikasi baru
          await _notificationService.scheduleNotification(todo);
        } else {
          // Jika deadline dihapus (null), batalkan notifikasi lama
          await _notificationService.cancelNotification(todo.id);
        }
      } catch (e) {
        print("Error updating deadline for '$id': $e");
        // 4. Kembalikan state lokal jika gagal update DB
        todo.deadline = oldDeadline;
        notifyListeners();
      }
    }
  }

  // Mengupdate judul tugas
  Future<void> updateTodoTitle(String id, String newTitle) async {
    // Validasi judul baru tidak kosong
    if (newTitle.trim().isEmpty) return;

    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final todo = _todos[index];
      final oldTitle = todo.title; // Simpan judul lama

      // 1. Update state lokal
      todo.title = newTitle.trim();
      notifyListeners(); // Update UI

      try {
        // 2. Update database
        await _dbHelper.updateTodo(todo);
        print("Updated title for $id to ${todo.title}");

        // 3. Opsional: Jadwalkan ulang notifikasi dengan judul baru jika deadline ada
        // Ini memastikan notifikasi menampilkan judul yang paling update.
        if (todo.deadline != null) {
          print("Rescheduling notification for title change...");
          await _notificationService.scheduleNotification(todo);
        }
      } catch (e) {
        print("Error updating title for '$id': $e");
        // 4. Kembalikan state lokal jika gagal
        todo.title = oldTitle;
        notifyListeners();
      }
    }
  }

  // Bisa ditambahkan method lain sesuai kebutuhan (update kategori, dll.)
} // Akhir class TodoListProvider
