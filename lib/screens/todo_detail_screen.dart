// lib/screens/todo_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal/waktu
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../providers/todo_list_provider.dart';

class TodoDetailScreen extends StatefulWidget {
  final Todo todo; // Terima objek Todo dari HomeScreen

  const TodoDetailScreen({super.key, required this.todo});

  @override
  State<TodoDetailScreen> createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends State<TodoDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  // Tidak perlu state _currentTodo lagi jika kita pakai context.select
  // late Todo _currentTodo;
  late String _selectedCategory;

  // Pastikan list ini sinkron dengan yang ada di HomeScreen atau sumber data utama
  final List<String> _categories = ['Kerja', 'Pribadi', 'Wishlist'];

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan data awal dari widget.todo
    _titleController = TextEditingController(text: widget.todo.title);
    _notesController = TextEditingController(text: widget.todo.notes ?? '');
    _selectedCategory = widget.todo.category;

    // Validasi kategori awal
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory =
          _categories.isNotEmpty ? _categories.first : 'Pribadi'; // Fallback
      // Pertimbangkan untuk update provider jika kategori awal tidak valid
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   context.read<TodoListProvider>().updateTodoCategory(widget.todo.id, _selectedCategory);
      // });
    }
  }

  @override
  void dispose() {
    // Simpan perubahan terakhir sebelum dispose jika perlu (opsional)
    // _saveTitleChanges();
    // _saveNotesChanges(); // Jika notes diedit langsung tanpa dialog
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // --- Fungsi Pilih Deadline ---
  Future<void> _selectDeadline(BuildContext context, Todo currentTodo) async {
    final DateTime initialDate = currentTodo.deadline ?? DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          initialDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))
              ? DateTime.now()
              : initialDate, // Jangan set initial ke masa lalu
      firstDate: DateTime.now().subtract(const Duration(days: 1)), // Kemarin
      lastDate: DateTime(2101),
      helpText: 'Pilih Tanggal Deadline',
      cancelText: 'Batal',
      confirmText: 'Pilih Waktu',
    );

    if (pickedDate != null && context.mounted) {
      final TimeOfDay initialTime = TimeOfDay.fromDateTime(
        currentTodo.deadline ?? DateTime.now(),
      );
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
        helpText: 'Pilih Waktu Deadline',
        cancelText: 'Batal',
        confirmText: 'Simpan',
      );

      if (pickedTime != null && context.mounted) {
        final DateTime combinedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (combinedDateTime.isBefore(DateTime.now())) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Waktu deadline tidak boleh di masa lalu.'),
              ),
            );
          }
          return;
        }
        context.read<TodoListProvider>().updateTodoDeadline(
          currentTodo.id,
          combinedDateTime,
        );
      }
    }
  }

  void _clearDeadline(String todoId) {
    context.read<TodoListProvider>().updateTodoDeadline(todoId, null);
  }

  // --- Fungsi Pilih Reminder ---
  Future<void> _selectReminder(BuildContext context, Todo currentTodo) async {
    final DateTime initialReminder =
        currentTodo.reminderDateTime ?? currentTodo.deadline ?? DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          initialReminder.isBefore(
                DateTime.now().subtract(const Duration(days: 1)),
              )
              ? DateTime.now()
              : initialReminder,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2101),
      helpText: 'Pilih Tanggal Pengingat',
      cancelText: 'Batal',
      confirmText: 'Pilih Waktu',
    );

    if (pickedDate != null && context.mounted) {
      final TimeOfDay initialTime = TimeOfDay.fromDateTime(initialReminder);
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
        helpText: 'Pilih Waktu Pengingat',
        cancelText: 'Batal',
        confirmText: 'Simpan',
      );

      if (pickedTime != null && context.mounted) {
        final DateTime combinedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        if (combinedDateTime.isBefore(DateTime.now())) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Waktu pengingat tidak boleh di masa lalu.'),
              ),
            );
          }
          return;
        }
        context.read<TodoListProvider>().updateTodoReminder(
          currentTodo.id,
          combinedDateTime,
        );
      }
    }
  }

  void _clearReminder(String todoId) {
    context.read<TodoListProvider>().updateTodoReminder(todoId, null);
  }

  // --- Fungsi Edit Notes via Dialog ---
  void _editNotes(Todo currentTodo) {
    _notesController.text = currentTodo.notes ?? ''; // Set teks awal dialog
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text("Catatan Tugas"),
            content: TextField(
              controller: _notesController,
              maxLines: 5,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Tambahkan catatan...",
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            actions: [
              TextButton(
                child: const Text("Batal"),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              TextButton(
                child: const Text("Simpan"),
                onPressed: () {
                  final newNotes = _notesController.text.trim();
                  // Gunakan provider langsung dari context utama (bukan dialogContext)
                  context.read<TodoListProvider>().updateTodoNotes(
                    currentTodo.id,
                    newNotes.isEmpty ? null : newNotes,
                  );
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
    );
  }

  // --- Fungsi Simpan Judul (dipanggil saat fokus hilang) ---
  void _saveTitleChanges(Todo currentTodo) {
    final newTitle = _titleController.text.trim();
    if (newTitle.isNotEmpty && newTitle != currentTodo.title) {
      context.read<TodoListProvider>().updateTodoTitle(
        currentTodo.id,
        newTitle,
      );
      // Tidak perlu setState karena provider akan update
    } else if (newTitle.isEmpty) {
      // Kembalikan ke judul lama jika dikosongkan
      _titleController.text = currentTodo.title;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul tidak boleh kosong.')),
      );
    }
  }

  // --- Fungsi Hapus Tugas ---
  Future<void> _deleteTodo(Todo currentTodo) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Tugas?'),
          content: Text('Yakin ingin menghapus "${currentTodo.title}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true && context.mounted) {
      final todoTitle = currentTodo.title; // Simpan judul untuk snackbar
      await context.read<TodoListProvider>().removeTodo(currentTodo.id);
      if (context.mounted) {
        Navigator.of(context).pop(); // Kembali ke HomeScreen
        // Tampilkan SnackBar di HomeScreen setelah pop
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Tugas "$todoTitle" dihapus')));
      }
    }
  }

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    // Gunakan Selector untuk efisiensi: hanya rebuild jika Todo ini berubah
    final Todo currentTodo = context.select<TodoListProvider, Todo>(
      (provider) => provider.todos.firstWhere(
        (t) => t.id == widget.todo.id,
        // Fallback jika Todo tidak ditemukan (misal sudah dihapus)
        // Sebaiknya navigasi kembali jika ini terjadi
        orElse: () {
          // Coba cegah error build dgn state sementara
          // Idealnya, kita harus pop() jika todo asli hilang
          print("WARNING: Todo ${widget.todo.id} not found in provider!");
          return widget.todo; // Return todo awal sbg fallback sementara
        },
      ),
    );

    // Update selectedCategory jika berubah dari provider
    // (Misalnya jika ada fitur edit kategori di tempat lain)
    if (_selectedCategory != currentTodo.category &&
        _categories.contains(currentTodo.category)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedCategory = currentTodo.category;
          });
        }
      });
    }

    // Formatters
    final DateFormat deadlineFormatter = DateFormat('yyyy/MM/dd HH:mm');
    final DateFormat reminderFormatter = DateFormat('dd MMM, HH:mm');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            // Simpan judul saat tombol back ditekan (jika berubah)
            _saveTitleChanges(currentTodo);
            Navigator.of(context).pop();
          },
        ),
        // title: Text(currentTodo.title), // Tampilkan judul di AppBar juga?
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onSelected: (String result) {
              if (result == 'delete') _deleteTodo(currentTodo);
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      'Hapus Tugas',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  // Tambahkan opsi lain jika perlu
                ],
          ),
        ],
      ),
      body: GestureDetector(
        // Tutup keyboard saat klik di luar textfield
        onTap: () {
          FocusScope.of(context).unfocus();
          _saveTitleChanges(currentTodo); // Simpan judul saat fokus hilang
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // -- Kategori Dropdown --
            DropdownButtonFormField<String>(
              value: _selectedCategory, // Gunakan state lokal
              items:
                  _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null && newValue != currentTodo.category) {
                  context.read<TodoListProvider>().updateTodoCategory(
                    currentTodo.id,
                    newValue,
                  );
                  // Update state lokal agar dropdown langsung berubah
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
              decoration: const InputDecoration(
                // labelText: 'Kategori', // Label bisa opsional
                prefixIcon: Icon(Icons.label_outline, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const Divider(height: 1),

            // -- Judul Tugas Editable --
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Judul Tugas',
                  border: InputBorder.none,
                ),
                textCapitalization: TextCapitalization.sentences,
                // onSubmitted: (s) => _saveTitleChanges(currentTodo), // Bisa juga simpan saat enter
              ),
            ),

            // -- Tugas Sampingan Placeholder --
            ListTile(
              leading: const Icon(Icons.add, color: Colors.blue, size: 20),
              title: Text(
                'Tambahkan tugas sampingan',
                style: TextStyle(color: Colors.blue[700]),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Fitur tugas sampingan belum diimplementasi.',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),

            // -- Batas Waktu (Deadline) --
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.calendar_today_outlined,
                color: Colors.grey,
              ),
              title: const Text('Batas waktu'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      currentTodo.deadline != null
                          ? Colors.blue[50]
                          : Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  currentTodo.deadline != null
                      ? deadlineFormatter.format(currentTodo.deadline!)
                      : 'Tidak diatur',
                  style: TextStyle(
                    color:
                        currentTodo.deadline != null
                            ? Colors.blue[800]
                            : Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ),
              onTap: () => _selectDeadline(context, currentTodo),
            ),
            if (currentTodo.deadline != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _clearDeadline(currentTodo.id),
                  child: const Text(
                    'Hapus Batas Waktu',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(0, 30),
                  ), // Atur padding & size
                ),
              ),
            const Divider(height: 1),

            // -- Waktu & Pengingat --
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time, color: Colors.grey),
              title: const Text('Waktu & Pengingat'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      currentTodo.reminderDateTime != null
                          ? Colors.orange[50]
                          : Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  currentTodo.reminderDateTime != null
                      ? reminderFormatter.format(currentTodo.reminderDateTime!)
                      : 'Tidak diatur',
                  style: TextStyle(
                    color:
                        currentTodo.reminderDateTime != null
                            ? Colors.orange[900]
                            : Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ),
              onTap: () => _selectReminder(context, currentTodo),
            ),
            if (currentTodo.reminderDateTime != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _clearReminder(currentTodo.id),
                  child: const Text(
                    'Hapus Pengingat',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(0, 30),
                  ),
                ),
              ),
            const Divider(height: 1),

            // -- Ulangi Tugas Placeholder --
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.repeat, color: Colors.grey),
              title: const Text('Ulangi tugas'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  currentTodo.repeatRule ?? 'Tidak',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur ulangi tugas belum diimplementasi.'),
                  ),
                );
                // TODO: Tampilkan pilihan repeat rule
              },
            ),
            const Divider(height: 1),

            // -- Catatan --
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.note_alt_outlined, color: Colors.grey),
              title: const Text('Catatan'),
              subtitle: Text(
                currentTodo.notes ?? 'Tidak ada catatan',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              trailing: Text(
                (currentTodo.notes?.isNotEmpty ?? false) ? 'EDIT' : 'TAMBAH',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              onTap: () => _editNotes(currentTodo),
            ),
            const Divider(height: 1),

            // -- Lampiran Placeholder --
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.attachment_outlined,
                color: Colors.grey,
              ),
              title: const Text('Lampiran'),
              trailing: Text(
                'TAMBAH',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur lampiran belum diimplementasi.'),
                  ),
                );
                // TODO: Panggil file picker
              },
            ),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }
}
