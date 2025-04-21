// lib/providers/todo_list_provider.dart
import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import '../helpers/database_helper.dart'; // Import helper
import 'dart:collection';

class TodoListProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper(); // Instance of the helper
  List<Todo> _todos = []; // Start with an empty list
  bool _isLoading = false; // Flag to indicate loading state

  // Public getter for todos
  UnmodifiableListView<Todo> get todos => UnmodifiableListView(_todos);
  // Public getter for loading state
  bool get isLoading => _isLoading;

  TodoListProvider() {
    // Load todos when the provider is created
    loadTodos();
  }

  // Method to load todos from the database
  Future<void> loadTodos() async {
    _isLoading = true;
    notifyListeners(); // Notify UI that loading has started

    try {
      _todos = await _dbHelper.getTodos();
    } catch (e) {
       print("Error loading todos: $e");
       // Handle error appropriately, maybe set an error state
       _todos = []; // Reset to empty on error
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify UI that loading has finished (success or fail)
    }
  }


  // Getter for filtered todos (no change needed here)
  List<Todo> getFilteredTodos(String category) {
     if (_isLoading) return []; // Return empty list while loading
    if (category == 'Semua') {
      return List.unmodifiable(_todos);
    }
    return List.unmodifiable(_todos.where((todo) => todo.category == category));
  }

  // === UPDATED CRUD Methods ===

  Future<void> addTodo(String title, String category) async {
    if (title.trim().isEmpty) return;
    final newTodo = Todo(
      // Use a simple timestamp for ID or UUID package for more robust IDs
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      date: 'Hari ini',
      category: category,
    );

    try {
        await _dbHelper.insertTodo(newTodo);
        // Optimistic UI update (add immediately) or reload list
        _todos.insert(0, newTodo); // Add to local cache
        notifyListeners();
        // Atau: await loadTodos(); // Reload full list (safer but less performant)
    } catch(e) {
        print("Error adding todo: $e");
        // Handle error (e.g., show error message)
    }
  }

  // Remove todo - now returns the removed Todo for Undo
  Future<Todo?> removeTodo(String id) async {
    // Find the todo in the current list *before* deleting from DB
     final index = _todos.indexWhere((todo) => todo.id == id);
     Todo? removedTodo;
     if (index != -1) {
       removedTodo = _todos[index];
     }

    try {
        final deletedRows = await _dbHelper.deleteTodo(id);
        if (deletedRows > 0 && removedTodo != null) {
          // Update local cache only if DB delete was successful
          _todos.removeWhere((todo) => todo.id == id);
          notifyListeners();
          return removedTodo; // Return for Undo
        }
    } catch(e) {
         print("Error removing todo: $e");
    }
    return null; // Return null if delete failed or item not found
  }

  // Undo remove - inserts back into DB and local cache
  Future<void> undoRemove(int index, Todo todo) async {
    try {
      await _dbHelper.insertTodo(todo); // Re-insert into DB
       // Make sure index is valid
       if (index < 0) index = 0;
       if (index > _todos.length) index = _todos.length;
       _todos.insert(index, todo); // Re-insert into local cache
       notifyListeners();
    } catch(e) {
       print("Error undoing remove: $e");
    }
  }

  Future<void> toggleDone(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final todo = _todos[index];
      todo.isDone = !todo.isDone; // Toggle state locally first (optimistic)
       notifyListeners(); // Update UI immediately

      try {
        await _dbHelper.updateTodo(todo); // Update database
      } catch(e) {
         print("Error toggling done: $e");
         // Revert UI change on error?
         todo.isDone = !todo.isDone; // Revert local change
         notifyListeners();
      }
    }
  }

  Future<void> toggleStar(String id) async {
     final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final todo = _todos[index];
      todo.isStarred = !todo.isStarred; // Toggle locally
      notifyListeners(); // Update UI

      try {
        await _dbHelper.updateTodo(todo); // Update DB
      } catch(e) {
         print("Error toggling star: $e");
         // Revert UI change on error?
         todo.isStarred = !todo.isStarred; // Revert
         notifyListeners();
      }
    }
  }

  Future<void> updateTodoDate(String id, String newDate) async {
     final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
       final todo = _todos[index];
       final oldDate = todo.date; // Store old date for potential revert
       todo.date = newDate; // Update locally
       notifyListeners(); // Update UI

      try {
        await _dbHelper.updateTodo(todo); // Update DB
      } catch(e) {
          print("Error updating date: $e");
          // Revert UI change on error
          todo.date = oldDate;
          notifyListeners();
      }
    }
  }
}