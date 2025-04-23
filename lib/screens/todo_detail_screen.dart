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
  late TextEditingController _titleController; // Untuk mengedit judul nanti
  late Todo _currentTodo; // State lokal untuk menampung todo yg mungkin diedit

  @override
  void initState() {
    super.initState();
    // Inisialisasi state lokal dengan data todo yang diterima
    _currentTodo = widget.todo;
    _titleController = TextEditingController(text: _currentTodo.title);
    // Listener bisa ditambahkan jika ingin save otomatis saat edit judul
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // Fungsi untuk menampilkan Date Picker lalu Time Picker
  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _currentTodo.deadline ?? DateTime.now(),
      firstDate: DateTime.now().subtract(
        const Duration(days: 1),
      ), // Tidak bisa pilih kemarin
      lastDate: DateTime(2101),
      helpText: 'Pilih Tanggal Deadline',
      cancelText: 'Batal',
      confirmText: 'Pilih Waktu',
    );

    if (pickedDate != null && context.mounted) {
      // Cek context.mounted setelah await
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _currentTodo.deadline ?? DateTime.now(),
        ),
        helpText: 'Pilih Waktu Deadline',
        cancelText: 'Batal',
        confirmText: 'Simpan',
      );

      if (pickedTime != null && context.mounted) {
        // Cek context.mounted lagi
        // Gabungkan tanggal dan waktu
        final DateTime combinedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // Cek jika waktu yang dipilih sudah lewat
        if (combinedDateTime.isBefore(DateTime.now())) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Waktu deadline tidak boleh di masa lalu.'),
              ),
            );
          }
          return; // Hentikan proses jika sudah lewat
        }

        // Update Provider (tidak perlu await jika tidak butuh hasil langsung)
        context.read<TodoListProvider>().updateTodoDeadline(
          _currentTodo.id,
          combinedDateTime,
        );

        // Update state lokal untuk tampilan langsung (opsional, provider akan rebuild)
        setState(() {
          _currentTodo.deadline = combinedDateTime;
        });
      }
    }
  }

  // Fungsi untuk menghapus deadline
  void _clearDeadline() {
    // Panggil provider untuk menghapus & batal notif
    context.read<TodoListProvider>().updateTodoDeadline(_currentTodo.id, null);
    // Update UI lokal
    setState(() {
      _currentTodo.deadline = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dengarkan perubahan dari provider agar UI update jika data berubah dari sumber lain
    // Gunakan Selector jika ingin lebih spesifik pada perubahan deadline saja
    final todoFromProvider = context.watch<TodoListProvider>().todos.firstWhere(
      (t) => t.id == widget.todo.id,
      orElse:
          () =>
              _currentTodo, // Fallback ke state lokal jika tidak ditemukan (seharusnya tidak terjadi)
    );
    // Update state lokal jika ada perubahan dari provider (misal dari notifikasi atau sync)
    // Cukup aman dilakukan di build jika tidak terlalu kompleks
    _currentTodo = todoFromProvider;

    // Format untuk menampilkan deadline
    final DateFormat deadlineFormatter = DateFormat('yyyy/MM/dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).scaffoldBackgroundColor, // Samakan dgn background
        elevation: 0.5, // Garis tipis pemisah
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Detail Tugas',
          style: TextStyle(color: Colors.black87, fontSize: 18),
        ), // Judul AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onPressed: () {
              // TODO: Tampilkan menu opsi (Hapus, Bagikan, dll.)
            },
          ),
        ],
      ),
      body: ListView(
        // Gunakan ListView agar bisa scroll jika konten panjang
        padding: const EdgeInsets.all(16.0),
        children: [
          // -- Kategori (Contoh Placeholder) --
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.label_outline, color: Colors.grey),
            title: Text(
              _currentTodo.category,
              style: const TextStyle(fontSize: 14),
            ),
            trailing: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            onTap: () {
              // TODO: Implementasi pemilihan kategori
            },
          ),
          const Divider(height: 1),

          // -- Judul Tugas (Bisa diedit nanti) --
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              maxLines: null, // Biarkan bisa multiline
              decoration: const InputDecoration(
                hintText: 'Judul Tugas',
                border: InputBorder.none, // Hilangkan border
              ),
              onSubmitted: (newTitle) {
                // Simpan saat enter ditekan
                if (newTitle.trim() != _currentTodo.title) {
                  context.read<TodoListProvider>().updateTodoTitle(
                    _currentTodo.id,
                    newTitle.trim(),
                  );
                  setState(() {
                    _currentTodo.title = newTitle.trim(); // Update lokal juga
                  });
                }
              },
              onTapOutside: (event) {
                // Simpan saat klik di luar TextField
                final newTitle = _titleController.text;
                if (newTitle.trim() != _currentTodo.title) {
                  context.read<TodoListProvider>().updateTodoTitle(
                    _currentTodo.id,
                    newTitle.trim(),
                  );
                  setState(() {
                    _currentTodo.title = newTitle.trim();
                  });
                }
                FocusScope.of(context).unfocus(); // Tutup keyboard
              },
            ),
          ),

          // -- Tambahkan Tugas Sampingan (Placeholder) --
          InkWell(
            onTap: () {
              /* TODO: Implementasi tambah subtask */
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.add, color: Colors.blue, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Tambahkan tugas sampingan',
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:
                    _currentTodo.deadline != null
                        ? Colors.blue[50]
                        : Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                _currentTodo.deadline != null
                    ? deadlineFormatter.format(
                      _currentTodo.deadline!,
                    ) // Tampilkan deadline
                    : 'Tidak diatur', // Teks jika null
                style: TextStyle(
                  color:
                      _currentTodo.deadline != null
                          ? Colors.blue[800]
                          : Colors.black54,
                  fontSize: 13,
                ),
              ),
            ),
            onTap: () => _selectDeadline(context), // Panggil date picker
          ),
          // Tombol Hapus Deadline (jika ada deadline)
          if (_currentTodo.deadline != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _clearDeadline,
                child: const Text(
                  'Hapus Batas Waktu',
                  style: TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 0,
                  ),
                ),
              ),
            ),

          const Divider(height: 1),

          // -- Waktu & Pengingat (Placeholder) --
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time, color: Colors.grey),
            title: const Text('Waktu & Pengingat'),
            trailing: Container(
              // Style mirip batas waktu
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                'Tidak',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ),
            onTap: () {
              // TODO: Implementasi set reminder (bisa pakai notifikasi juga)
            },
          ),
          const Divider(height: 1),

          // -- Ulangi Tugas (Placeholder) --
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.repeat, color: Colors.grey),
            title: const Text('Ulangi tugas'),
            trailing: Container(
              // Style mirip batas waktu
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                'Tidak',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ),
            onTap: () {
              // TODO: Implementasi pengulangan tugas
            },
          ),
          const Divider(height: 1),

          // -- Catatan (Placeholder) --
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.note_alt_outlined, color: Colors.grey),
            title: const Text('Catatan'),
            trailing: Text(
              'TAMBAH',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            onTap: () {
              // TODO: Buka halaman/dialog untuk menambah/edit catatan
            },
          ),
          const Divider(height: 1),

          // -- Lampiran (Placeholder) --
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.attachment_outlined, color: Colors.grey),
            title: const Text('Lampiran'),
            trailing: Text(
              'TAMBAH',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            onTap: () {
              // TODO: Implementasi tambah lampiran (file picker)
            },
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
