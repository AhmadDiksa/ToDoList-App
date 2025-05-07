// lib/screens/todo_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal/waktu
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../providers/todo_list_provider.dart';

class TodoDetailScreen extends StatefulWidget {
  final String todoId; // Terima HANYA ID Todo

  const TodoDetailScreen({super.key, required this.todoId});

  @override
  State<TodoDetailScreen> createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends State<TodoDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late String _selectedCategory; // State lokal untuk dropdown kategori

  // Daftar kategori, idealnya konsisten dengan sumber lain (misal: provider atau konstanta)
  final List<String> _categories = ['Kerja', 'Pribadi', 'Wishlist'];

  bool _isInitialized =
      false; // Flag untuk menandai apakah controller sudah diinisialisasi

  @override
  void initState() {
    super.initState();
    // Initialize controllers with empty text to avoid late initialization error
    _titleController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final provider = Provider.of<TodoListProvider>(context, listen: false);
      try {
        final todo = provider.todos.firstWhere((t) => t.id == widget.todoId);
        _initializeFields(todo);
      } catch (e) {
        // Todo not found, do nothing here
      }
    }
  }

  // Inisialisasi controller dan state lokal saat data Todo pertama kali tersedia
  void _initializeFields(Todo todo) {
    if (!_isInitialized) {
      // Hanya inisialisasi sekali
      _titleController = TextEditingController(text: todo.title);
      _notesController = TextEditingController(text: todo.notes ?? '');
      _selectedCategory = todo.category;

      // Validasi kategori awal
      if (!_categories.contains(_selectedCategory)) {
        _selectedCategory =
            _categories.isNotEmpty ? _categories.first : 'Pribadi';
        // Langsung update provider jika kategori awal tidak valid (opsional)
        // context.read<TodoListProvider>().updateTodoCategory(todo.id, _selectedCategory);
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    // Simpan perubahan terakhir judul sebelum dispose (jika user belum tekan back/unfocus)
    // Dapatkan Todo terakhir dari provider sebelum dispose
    // Ini bisa jadi rumit, lebih baik pastikan simpan saat unfocus atau back
    // Todo? lastKnownTodo;
    // try {
    //    lastKnownTodo = Provider.of<TodoListProvider>(context, listen: false)
    //       .todos.firstWhere((t) => t.id == widget.todoId);
    // } catch (e) {
    //    // Todo mungkin sudah dihapus
    // }
    // if (lastKnownTodo != null) _saveTitleChanges(lastKnownTodo);

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
              : initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
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
          if (context.mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Waktu deadline tidak boleh di masa lalu.'),
              ),
            );
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
          if (context.mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Waktu pengingat tidak boleh di masa lalu.'),
              ),
            );
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
    _notesController.text = currentTodo.notes ?? '';
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

  // --- Fungsi Simpan Judul (dipanggil saat fokus hilang atau back) ---
  void _saveTitleChanges(Todo currentTodo) {
    final newTitle = _titleController.text.trim();
    if (newTitle.isNotEmpty && newTitle != currentTodo.title) {
      context.read<TodoListProvider>().updateTodoTitle(
        currentTodo.id,
        newTitle,
      );
    } else if (newTitle.isEmpty && mounted) {
      // Jangan biarkan judul kosong
      _titleController.text = currentTodo.title; // Kembalikan ke judul lama
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
        /* ... Dialog Konfirmasi Hapus ... */
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
      final todoTitle = currentTodo.title;
      await context.read<TodoListProvider>().removeTodo(currentTodo.id);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Tugas "$todoTitle" dihapus')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan Selector untuk hanya rebuild saat Todo spesifik ini berubah
    // atau jika todo tidak ditemukan lagi (misal sudah dihapus dari halaman lain).
    return Consumer<TodoListProvider>(
      // Gunakan Consumer untuk handle kasus todo tidak ada
      builder: (context, provider, child) {
        Todo? currentTodo;
        try {
          currentTodo = provider.todos.firstWhere((t) => t.id == widget.todoId);
        } catch (e) {
          // Todo tidak ditemukan (mungkin sudah dihapus)
          // Kita harus keluar dari halaman ini
          print(
            "TodoDetailScreen: Todo with ID ${widget.todoId} not found. Popping screen.",
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // Pastikan widget masih ada sebelum pop
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tugas yang Anda lihat sudah tidak ada.'),
                ),
              );
            }
          });
          // Tampilkan layar loading atau kosong sementara menunggu pop
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Inisialisasi controller JIKA BELUM dan data sudah ada
        // atau update controller jika data berubah DAN user tidak sedang mengetik
        if (!_isInitialized) {
          _initializeFields(currentTodo);
        } else {
          // Update controller jika perlu (hati-hati agar tidak overwrite user input)
          if (currentTodo.title != _titleController.text &&
              !FocusScope.of(context).hasFocus) {
            _titleController.text = currentTodo.title;
          }
          if ((currentTodo.notes ?? '') != _notesController.text &&
              !FocusScope.of(context).hasFocus) {
            _notesController.text = currentTodo.notes ?? '';
          }
          if (currentTodo.category != _selectedCategory &&
              _categories.contains(currentTodo.category)) {
            // Perlu setState agar DropdownButtonFormField rebuild dengan value baru
            // Ini bisa menyebabkan loop jika tidak hati-hati
            // Lebih baik _selectedCategory disinkronkan di onchanged Dropdown saja
            // dan di initState.
            // Jika ingin update dari provider, pastikan ada mekanisme yg aman.
            // Untuk sekarang, kita biarkan kategori di-set di initState dan diubah oleh user.
            // Jika ada perubahan kategori dari sumber lain, UI Dropdown mungkin tidak langsung update.
          }
        }

        final DateFormat deadlineFormatter = DateFormat('yyyy/MM/dd HH:mm');
        final DateFormat reminderFormatter = DateFormat('dd MMM, HH:mm');

        return WillPopScope(
          // Handle tombol back fisik
          onWillPop: () async {
            _saveTitleChanges(currentTodo!); // Simpan judul saat back
            return true; // Izinkan pop
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _saveTitleChanges(currentTodo!);
                  Navigator.of(context).pop();
                },
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (String result) {
                    if (result == 'delete') _deleteTodo(currentTodo!);
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
                      ],
                ),
              ],
            ),
            body: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                _saveTitleChanges(currentTodo!);
              },
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // -- Kategori Dropdown --
                  DropdownButtonFormField<String>(
                    value:
                        _categories.contains(currentTodo.category)
                            ? currentTodo.category
                            : _selectedCategory,
                    items:
                        _categories
                            .map(
                              (String category) => DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null &&
                          newValue != currentTodo!.category) {
                        context.read<TodoListProvider>().updateTodoCategory(
                          currentTodo!.id,
                          newValue,
                        );
                        setState(() {
                          _selectedCategory = newValue;
                        }); // Update state lokal untuk UI
                      }
                    },
                    decoration: const InputDecoration(
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
                    ),
                  ),

                  // -- Tugas Sampingan Placeholder --
                  ListTile(
                    leading: const Icon(
                      Icons.add,
                      color: Colors.blue,
                      size: 20,
                    ),
                    title: Text(
                      'Tambahkan tugas sampingan',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onTap:
                        () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Fitur tugas sampingan belum diimplementasi.',
                            ),
                          ),
                        ),
                  ),
                  const SizedBox(height: 10), const Divider(height: 1),

                  // -- Batas Waktu (Deadline) --
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.grey,
                    ),
                    title: const Text('Batas waktu'),
                    trailing: /* ... Widget trailing deadline (gunakan currentTodo!) ... */
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                currentTodo!.deadline != null
                                    ? Colors.blue[50]
                                    : Colors.grey[200],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            currentTodo.deadline != null
                                ? deadlineFormatter.format(
                                  currentTodo.deadline!,
                                )
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
                    onTap: () => _selectDeadline(context, currentTodo!),
                  ),
                  if (currentTodo!.deadline != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _clearDeadline(currentTodo!.id),
                        child: const Text(
                          'Hapus Batas Waktu',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 30),
                        ),
                      ),
                    ),
                  const Divider(height: 1),

                  // -- Waktu & Pengingat --
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time, color: Colors.grey),
                    title: const Text('Waktu & Pengingat'),
                    trailing: /* ... Widget trailing reminder (gunakan currentTodo!) ... */
                        Container(
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
                                ? reminderFormatter.format(
                                  currentTodo.reminderDateTime!,
                                )
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
                    onTap: () => _selectReminder(context, currentTodo!),
                  ),
                  if (currentTodo.reminderDateTime != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _clearReminder(currentTodo!.id),
                        child: const Text(
                          'Hapus Pengingat',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 30),
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
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    onTap:
                        () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Fitur ulangi tugas belum diimplementasi.',
                            ),
                          ),
                        ),
                  ),
                  const Divider(height: 1),

                  // -- Catatan --
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.note_alt_outlined,
                      color: Colors.grey,
                    ),
                    title: const Text('Catatan'),
                    subtitle: Text(
                      currentTodo.notes ?? 'Tidak ada catatan',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    trailing: Text(
                      (currentTodo.notes?.isNotEmpty ?? false)
                          ? 'EDIT'
                          : 'TAMBAH',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    onTap: () => _editNotes(currentTodo!),
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
                    onTap:
                        () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Fitur lampiran belum diimplementasi.',
                            ),
                          ),
                        ),
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
