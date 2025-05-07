import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Digunakan untuk memformat tanggal dan waktu pada tampilan
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../providers/todo_list_provider.dart';

class TodoDetailScreen extends StatefulWidget {
  final Todo todo; // Menerima objek Todo dari layar utama (HomeScreen)

  const TodoDetailScreen({super.key, required this.todo});

  @override
  State<TodoDetailScreen> createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends State<TodoDetailScreen> {
  late TextEditingController _titleController; // Controller untuk input judul tugas
  late TextEditingController _notesController; // Controller untuk input catatan tugas
  // Tidak perlu menyimpan state _currentTodo jika menggunakan context.select
  // late Todo _currentTodo;
  late String _selectedCategory; // Kategori tugas yang dipilih

  // Daftar kategori yang tersedia, harus sinkron dengan sumber data utama
  final List<String> _categories = ['Kerja', 'Pribadi', 'Wishlist'];

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan data awal dari objek Todo yang diterima
    _titleController = TextEditingController(text: widget.todo.title);
    _notesController = TextEditingController(text: widget.todo.notes ?? '');
    _selectedCategory = widget.todo.category;

    // Validasi kategori awal, jika tidak valid, set ke kategori default
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory =
          _categories.isNotEmpty ? _categories.first : 'Pribadi'; // Kategori fallback
      // Pertimbangkan untuk memperbarui provider jika kategori awal tidak valid
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   context.read<TodoListProvider>().updateTodoCategory(widget.todo.id, _selectedCategory);
      // });
    }
  }

  @override
  void dispose() {
    // Simpan perubahan terakhir sebelum dispose jika diperlukan (opsional)
    // _saveTitleChanges();
    // _saveNotesChanges(); // Jika catatan diedit langsung tanpa dialog
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // --- Fungsi untuk memilih tanggal deadline tugas ---
