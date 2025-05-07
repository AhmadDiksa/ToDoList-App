// lib/models/todo.dart
// import 'package:flutter/foundation.dart';

class Todo {
  final String id;
  String title;
  String date;
  DateTime? deadline;
  DateTime? reminderDateTime; // <-- Field Baru: Waktu Pengingat
  String? repeatRule;       // <-- Field Baru: Aturan Pengulangan (String sederhana)
  String? notes;            // <-- Field Baru: Catatan
  bool isDone;
  bool isStarred;
  String category;
  // List<String> subtasks; // Contoh jika ingin subtask (kompleks, simpan sbg JSON?)
  // List<String> attachments; // Contoh jika ingin lampiran (kompleks)

  Todo({
    required this.id,
    required this.title,
    required this.date,
    this.deadline,
    this.reminderDateTime, // <-- Tambah di constructor
    this.repeatRule,       // <-- Tambah di constructor
    this.notes,            // <-- Tambah di constructor
    this.isDone = false,
    this.isStarred = false,
    required this.category,
  });

  // Convert a Todo object into a Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'deadline': deadline?.toIso8601String(),
      'reminderDateTime': reminderDateTime?.toIso8601String(), // <-- Konversi ke String
      'repeatRule': repeatRule,                             // <-- Simpan String
      'notes': notes,                                       // <-- Simpan String
      'isDone': isDone ? 1 : 0,
      'isStarred': isStarred ? 1 : 0,
      'category': category,
    };
  }

  // Create a Todo object from a Map.
  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as String,
      title: map['title'] as String,
      date: map['date'] as String,
      deadline: map['deadline'] == null ? null : DateTime.tryParse(map['deadline'] as String),
      // <-- Parse dari String, handle null
      reminderDateTime: map['reminderDateTime'] == null ? null : DateTime.tryParse(map['reminderDateTime'] as String),
      repeatRule: map['repeatRule'] as String?, // <-- Ambil String, bisa null
      notes: map['notes'] as String?,           // <-- Ambil String, bisa null
      isDone: map['isDone'] == 1,
      isStarred: map['isStarred'] == 1,
      category: map['category'] as String,
    );
  }

  @override
  String toString() {
    // Tambahkan field baru ke toString untuk debug
    return 'Todo{id: $id, title: $title, deadline: $deadline, reminder: $reminderDateTime, repeat: $repeatRule, notes: $notes, ...}';
  }

  Todo copyWith({
    String? id,
    String? title,
    String? date,
    DateTime? deadline,
    DateTime? reminderDateTime,
    String? repeatRule,
    String? notes,
    bool? isDone,
    bool? isStarred,
    String? category,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      deadline: deadline ?? this.deadline,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      repeatRule: repeatRule ?? this.repeatRule,
      notes: notes ?? this.notes,
      isDone: isDone ?? this.isDone,
      isStarred: isStarred ?? this.isStarred,
      category: category ?? this.category,
    );
  }
}
