// lib/models/todo.dart

class Todo {
  final String id; // Keep String ID for consistency with previous example
  String title;
  String date;
  bool isDone;
  bool isStarred;
  String category;

  Todo({
    required this.id,
    required this.title,
    required this.date,
    this.isDone = false,
    this.isStarred = false,
    required this.category,
  });

  // Convert a Todo object into a Map. Keys must correspond to column names.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'isDone': isDone ? 1 : 0, // Store bool as integer
      'isStarred': isStarred ? 1 : 0, // Store bool as integer
      'category': category,
    };
  }

  // Create a Todo object from a Map.
  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as String,
      title: map['title'] as String,
      date: map['date'] as String,
      // Convert integer back to bool
      isDone: map['isDone'] == 1,
      isStarred: map['isStarred'] == 1,
      category: map['category'] as String,
    );
  }

  // Optional: Override toString for easy debugging
  @override
  String toString() {
    return 'Todo{id: $id, title: $title, date: $date, isDone: $isDone, isStarred: $isStarred, category: $category}';
  }
}
