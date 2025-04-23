// lib/models/todo.dart

class Todo {
  final String id;
  String title;
  String date; // Tanggal info umum
  DateTime? deadline; // Deadline tugas (bisa null)
  bool isDone;
  bool isStarred;
  String category;

  Todo({
    required this.id,
    required this.title,
    required this.date,
    this.deadline, // Tambahkan deadline di constructor
    this.isDone = false,
    this.isStarred = false,
    required this.category,
  });

  // Konversi Todo ke Map untuk database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      // Simpan DateTime sebagai string ISO 8601 jika tidak null
      'deadline': deadline?.toIso8601String(),
      'isDone': isDone ? 1 : 0, // boolean ke integer
      'isStarred': isStarred ? 1 : 0, // boolean ke integer
      'category': category,
    };
  }

  // Buat Todo dari Map database
  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as String,
      title: map['title'] as String,
      date: map['date'] as String,
      // Parse string ISO 8601 kembali ke DateTime jika tidak null
      deadline:
          map['deadline'] == null
              ? null
              : DateTime.tryParse(map['deadline'] as String),
      isDone: map['isDone'] == 1, // integer ke boolean
      isStarred: map['isStarred'] == 1, // integer ke boolean
      category: map['category'] as String,
    );
  }

  @override
  String toString() {
    // Memudahkan debugging
    return 'Todo{id: $id, title: $title, date: $date, deadline: $deadline, isDone: $isDone, isStarred: $isStarred, category: $category}';
  }
}
