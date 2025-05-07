// lib/providers/todo_list_provider.dart
import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import '../helpers/database_helper.dart';
import '../services/notification_service.dart'; // Pastikan path ini benar
import 'dart:collection';

class TodoListProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();
  List<Todo> _todos = [];
  bool _isLoading = false;

  // Public getter untuk todos
  UnmodifiableListView<Todo> get todos => UnmodifiableListView(_todos);
  // Public getter untuk loading state
  bool get isLoading => _isLoading;

  TodoListProvider() {
    // Load todos saat provider dibuat
    loadTodos();
  }

  /// Memuat semua todos dari database
  Future<void> loadTodos() async {
    _isLoading = true;
    notifyListeners(); // Beritahu UI loading dimulai (opsional, tergantung UI)
    try {
      _todos = await _dbHelper.getTodos();
      // Panggilan ke _resyncAllNotifications() dihapus dari sini
    } catch (e) {
      print("Error loading todos: $e");
      _todos = []; // Reset ke list kosong jika error
    } finally {
      _isLoading = false;
      notifyListeners(); // Beritahu UI loading selesai
    }
  }

  // --- Method _resyncAllNotifications DIHAPUS ---
  // Future<void> _resyncAllNotifications() async { ... } // <-- HAPUS SEMUA METHOD INI

  /// Getter untuk mendapatkan list todos yang sudah difilter
  List<Todo> getFilteredTodos(String category) {
    if (_isLoading) return [];
    if (category == 'Semua') {
      return List.unmodifiable(_todos);
    }
    return List.unmodifiable(_todos.where((todo) => todo.category == category));
  }

  // === METODE CRUD (Tetap sama seperti sebelumnya) ===

  /// Menambahkan Todo baru
  Future<void> addTodo(String title, String category) async {
    if (title.trim().isEmpty) return;
    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      date: 'Hari ini',
      category: category,
    );
    try {
      await _dbHelper.insertTodo(newTodo);
      _todos.insert(0, newTodo);
      notifyListeners();
    } catch (e) {
      print("Error adding todo: $e");
    }
  }

  /// Menghapus Todo berdasarkan ID
  Future<Todo?> removeTodo(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    Todo? removedTodo;
    if (index != -1) removedTodo = _todos[index];
    try {
      final deletedRows = await _dbHelper.deleteTodo(id);
      if (deletedRows > 0 && removedTodo != null) {
        _todos.removeWhere((todo) => todo.id == id);
        await _notificationService.cancelDeadlineNotification(
          id,
        ); // Batalkan deadline
        await _notificationService.cancelReminderNotification(
          id,
        ); // Batalkan reminder
        notifyListeners();
        return removedTodo;
      }
    } catch (e) {
      print("Error removing todo $id: $e");
    }
    return null;
  }

  /// Mengembalikan Todo yang dihapus (Undo)
  Future<void> undoRemove(int index, Todo todo) async {
    try {
      await _dbHelper.insertTodo(todo);
      if (index < 0) index = 0;
      if (index > _todos.length) index = _todos.length;
      _todos.insert(index, todo);
      // Jadwalkan ulang notifikasi
      await _notificationService.scheduleDeadlineNotification(todo);
      await _notificationService.scheduleReminderNotification(todo);
      notifyListeners();
    } catch (e) {
      print("Error undoing remove for ${todo.id}: $e");
    }
  }

  /// Toggle status selesai/belum selesai
  Future<void> toggleDone(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final todo = _todos[index];
      final oldStatus = todo.isDone;
      todo.isDone = !todo.isDone;
      notifyListeners();
      try {
        await _dbHelper.updateTodo(todo);
        // Logika cancel/reschedule notifikasi jika 'done' (opsional)
      } catch (e) {
        print("Error toggling done for $id: $e");
        todo.isDone = oldStatus;
        notifyListeners(); // Revert
      }
    }
  }

  /// Toggle status bintang
  Future<void> toggleStar(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final todo = _todos[index];
      final oldStatus = todo.isStarred;
      todo.isStarred = !todo.isStarred;
      notifyListeners();
      try {
        await _dbHelper.updateTodo(todo);
      } catch (e) {
        print("Error toggling star for $id: $e");
        todo.isStarred = oldStatus;
        notifyListeners(); // Revert
      }
    }
  }

  /// Update judul Todo
  Future<void> updateTodoTitle(String id, String newTitle) async {
    if (newTitle.trim().isEmpty) return;
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final todo = _todos[index];
      if (todo.title == newTitle.trim()) return;
      final oldTitle = todo.title;
      todo.title = newTitle.trim();
      notifyListeners();
      try {
        await _dbHelper.updateTodo(todo);
        // Reschedule notifikasi karena judul berubah
        await _notificationService.scheduleDeadlineNotification(todo);
        await _notificationService.scheduleReminderNotification(todo);
      } catch (e) {
        print("Error updating title for $id: $e");
        todo.title = oldTitle;
        notifyListeners(); // Revert
      }
    }
  }

  /// Update deadline Todo
  Future<void> updateTodoDeadline(String id, DateTime? newDeadline) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final todo = _todos[index];
      if (todo.deadline == newDeadline) return;
      final oldDeadline = todo.deadline;
      todo.deadline = newDeadline;
      notifyListeners();
      try {
        await _dbHelper.updateTodo(todo);
        if (newDeadline != null) {
          await _notificationService.scheduleDeadlineNotification(todo);
        } else {
          await _notificationService.cancelDeadlineNotification(todo.id);
        }
      } catch (e) {
        print("Error updating deadline for $id: $e");
        todo.deadline = oldDeadline;
        notifyListeners(); // Revert
      }
    }
  }

  /// Update waktu reminder Todo
  Future<void> updateTodoReminder(String id, DateTime? newReminderTime) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final todo = _todos[index];
      if (todo.reminderDateTime == newReminderTime) return;
      final oldReminder = todo.reminderDateTime;
      todo.reminderDateTime = newReminderTime;
      notifyListeners();
      try {
        await _dbHelper.updateTodo(todo);
        if (newReminderTime != null) {
          await _notificationService.scheduleReminderNotification(todo);
        } else {
          await _notificationService.cancelReminderNotification(todo.id);
        }
      } catch (e) {
        print("Error updating reminder for $id: $e");
        todo.reminderDateTime = oldReminder;
        notifyListeners(); // Revert
      }
    }
  }

  /// Update catatan Todo
  Future<void> updateTodoNotes(String id, String? newNotes) async {
    final notesToSave =
        (newNotes != null && newNotes.trim().isEmpty) ? null : newNotes?.trim();
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final todo = _todos[index];
      if (todo.notes == notesToSave) return;
      final oldNotes = todo.notes;
      todo.notes = notesToSave;
      notifyListeners();
      try {
        await _dbHelper.updateTodo(todo);
      } catch (e) {
        print("Error updating notes for $id: $e");
        todo.notes = oldNotes;
        notifyListeners();
      }
    }
  }

  /// Update kategori Todo
  Future<void> updateTodoCategory(String id, String newCategory) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final todo = _todos[index];
      if (todo.category == newCategory) return;
      final oldCategory = todo.category;
      todo.category = newCategory;
      notifyListeners();
      try {
        await _dbHelper.updateTodo(todo);
      } catch (e) {
        print("Error updating category for $id: $e");
        todo.category = oldCategory;
        notifyListeners();
      }
    }
  }

  /// Update aturan pengulangan Todo
  Future<void> updateTodoRepeatRule(String id, String? newRule) async {
    final ruleToSave =
        (newRule != null && newRule.trim().isEmpty) ? null : newRule?.trim();
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final todo = _todos[index];
      if (todo.repeatRule == ruleToSave) return;
      final oldRule = todo.repeatRule;
      todo.repeatRule = ruleToSave;
      notifyListeners();
      try {
        await _dbHelper.updateTodo(todo);
        print("Repeat rule updated for $id. TODO: Reschedule notifications.");
      } catch (e) {
        print("Error updating repeat rule for $id: $e");
        todo.repeatRule = oldRule;
        notifyListeners(); // Revert
      }
    }
  }
  /// Update entire Todo object
  Future<void> updateTodo(Todo updatedTodo) async {
    final index = _todos.indexWhere((todo) => todo.id == updatedTodo.id);
    if (index != -1) {
      final oldTodo = _todos[index];
      _todos[index] = updatedTodo;
      notifyListeners();
      try {
        await _dbHelper.updateTodo(updatedTodo);
        // Optionally reschedule notifications if needed
        await _notificationService.scheduleDeadlineNotification(updatedTodo);
        await _notificationService.scheduleReminderNotification(updatedTodo);
      } catch (e) {
        print("Error updating todo ${updatedTodo.id}: $e");
        _todos[index] = oldTodo;
        notifyListeners(); // Revert
      }
    }
  }
} // Akhir class TodoListProvider
