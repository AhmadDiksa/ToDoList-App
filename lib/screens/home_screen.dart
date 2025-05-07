// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal di FAB Kalender
import 'package:provider/provider.dart';
import '../widgets/todo_list_item.dart';
import '../widgets/custom_bottom_navbar.dart';
import '../providers/todo_list_provider.dart';
import '../models/todo.dart';
import 'todo_detail_screen.dart';
import 'calendar_screen.dart'; // Import CalendarScreen
import 'my_tasks_summary_screen.dart'; // Import MyTasksSummaryScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedBottomNavIndex = 0; // Indeks untuk BottomNavBar

  // --- State untuk filter di TodoListPage ---
  // Ini dipindah ke sini agar bisa diakses oleh TodoListPage
  // Idealnya, jika TodoListPage menjadi StatefulWidget, state ini ada di sana.
  int _selectedChipIndex = 0;
  final List<String> _filterChips = ['Semua', 'Kerja', 'Pribadi', 'Wishlist'];

  // --- Daftar Halaman untuk Bottom Navigation ---
  // Gunakan GlobalKey untuk mengakses state CalendarScreen dari FAB
  final GlobalKey<CalendarScreenState> _calendarScreenKey =
      GlobalKey<CalendarScreenState>();

  late final List<Widget> _pages; // Deklarasikan sebagai late final

  @override
  void initState() {
    super.initState();
    _pages = [
      TodoListPage(
        // TodoListPage sekarang menerima callback untuk update filter
        selectedChipIndex: _selectedChipIndex,
        filterChips: _filterChips,
        onFilterChipTapped: _onFilterChipTapped, // Kirim callback
      ),
      CalendarScreen(key: _calendarScreenKey), // Beri key ke CalendarScreen
      const MyTasksSummaryScreen(),
    ];
  }

  void _onBottomNavItemTapped(int index) {
    setState(() {
      _selectedBottomNavIndex = index;
    });
  }

  // Callback untuk filter chip, dipanggil dari TodoListPage
  void _onFilterChipTapped(int index) {
    setState(() {
      _selectedChipIndex = index;
      // Update TodoListPage dengan index baru
      _pages[0] = TodoListPage(
        selectedChipIndex: _selectedChipIndex,
        filterChips: _filterChips,
        onFilterChipTapped: _onFilterChipTapped,
      );
    });
  }

  // Dialog Tambah Tugas (Tetap di HomeScreen karena FAB utama ada di sini)
  void _showAddTodoDialog({DateTime? defaultDate}) {
    final TextEditingController todoController = TextEditingController();
    String selectedCategory = 'Pribadi'; // Default
    // Jika kita di halaman Tugas dan ada filter aktif (bukan "Semua"), gunakan kategori itu
    if (_selectedBottomNavIndex == 0 &&
        _selectedChipIndex > 0 &&
        _selectedChipIndex < _filterChips.length) {
      selectedCategory = _filterChips[_selectedChipIndex];
    }
    // Jika kita di halaman Kalender, defaultkan ke 'Pribadi' atau kategori lain
    // Atau bisa juga berdasarkan kategori tugas terakhir yg dibuat di tanggal itu.

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Tugas Baru'),
          content: TextField(
            controller: todoController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Masukkan judul tugas...',
              // Tampilkan tanggal default jika ada
              helperText:
                  defaultDate != null
                      ? 'Untuk tanggal: ${DateFormat('dd MMM yyyy').format(defaultDate)}'
                      : null,
            ),
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                final todoProvider = Provider.of<TodoListProvider>(
                  context,
                  listen: false,
                );
                todoProvider.addTodo(value, selectedCategory);
                // Jika ada defaultDate, setelah addTodo, buka detail untuk set deadline
                if (defaultDate != null) {
                  // Cari todo yang baru ditambahkan (berdasarkan judul dan kategori, atau ID jika bisa didapat)
                  // Ini asumsi sederhana, idealnya addTodo bisa return ID
                  final newTodo = todoProvider.todos.firstWhere(
                    (t) =>
                        t.title == value.trim() &&
                        t.category == selectedCategory &&
                        t.deadline == null,
                    orElse: () => todoProvider.todos.first, // fallback kasar
                  );
                  Navigator.of(dialogContext).pop(); // Tutup dialog dulu
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TodoDetailScreen(todoId: newTodo.id),
                    ),
                  ).then((_) {
                    // Saat kembali dari detail, update deadline
                    // Jika defaultDate dari kalender, set sebagai deadline awal di detail
                    Provider.of<TodoListProvider>(
                      context,
                      listen: false,
                    ).updateTodoDeadline(newTodo.id, defaultDate);
                  });
                  return;
                }
              }
              Navigator.of(dialogContext).pop();
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Simpan'),
              onPressed: () {
                final title = todoController.text;
                if (title.trim().isNotEmpty) {
                  final todoProvider = Provider.of<TodoListProvider>(
                    context,
                    listen: false,
                  );
                  todoProvider.addTodo(title, selectedCategory);
                  if (defaultDate != null) {
                    final newTodo = todoProvider.todos.firstWhere(
                      (t) =>
                          t.title == title.trim() &&
                          t.category == selectedCategory &&
                          t.deadline == null,
                      orElse: () => todoProvider.todos.first,
                    );
                    Navigator.of(dialogContext).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TodoDetailScreen(todoId: newTodo.id),
                    ),
                  ).then((_) {
                    Provider.of<TodoListProvider>(
                      context,
                      listen: false,
                    ).updateTodoDeadline(newTodo.id, defaultDate);
                  });
                    return;
                  }
                }
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        // Jaga state halaman saat berpindah tab
        index: _selectedBottomNavIndex,
        children: _pages,
      ),
      floatingActionButton:
          (_selectedBottomNavIndex == 0 || _selectedBottomNavIndex == 1)
              ? FloatingActionButton(
                onPressed: () {
                  DateTime? defaultDateForNewTask;
                  if (_selectedBottomNavIndex == 1) {
                    // Jika di halaman Kalender
                    // Akses _selectedDay dari CalendarScreenState melalui GlobalKey
                    defaultDateForNewTask =
                        _calendarScreenKey.currentState?.selectedDay ??
                        DateTime.now();
                  }
                  _showAddTodoDialog(defaultDate: defaultDateForNewTask);
                },
                tooltip: 'Tambah Tugas',
                child: const Icon(
                  Icons.add,
                ), // Warna foreground diatur di ThemeData
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedBottomNavIndex,
        onTap: _onBottomNavItemTapped,
      ),
    );
  }
}

// --- Widget untuk Isi Halaman Daftar Tugas Utama ---
class TodoListPage extends StatelessWidget {
  final int selectedChipIndex;
  final List<String> filterChips;
  final Function(int) onFilterChipTapped; // Callback untuk update filter

  const TodoListPage({
    super.key,
    required this.selectedChipIndex,
    required this.filterChips,
    required this.onFilterChipTapped,
  });

  @override
  Widget build(BuildContext context) {
    final todoProvider = context.watch<TodoListProvider>();
    final selectedCategory = filterChips[selectedChipIndex];
    final List<Todo> displayedTodos = todoProvider.getFilteredTodos(
      selectedCategory,
    );

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filterChips.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == filterChips.length) {
                    return IconButton(
                      icon: Icon(Icons.more_horiz, color: Colors.grey[600]),
                      onPressed: () {
                        print("Tombol More Chips ditekan");
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      constraints: const BoxConstraints(),
                      tooltip: 'Filter lainnya',
                    );
                  }
                  return ChoiceChip(
                    label: Text(filterChips[index]),
                    selected: selectedChipIndex == index,
                    onSelected: (selected) {
                      if (selected)
                        onFilterChipTapped(index); // Panggil callback
                    },
                  );
                },
              ),
            ),
          ),
          // Header "Masa mendatang"
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 10.0,
              bottom: 8.0,
            ),
            child: Row(
              children: [
                Text(
                  'Masa mendatang', // Bisa diganti sesuai logika filter/sortir
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_up, color: Colors.grey[600], size: 20),
              ],
            ),
          ),
          // List To-Do
          Expanded(
            child:
                todoProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : displayedTodos.isEmpty
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'Tidak ada tugas di kategori "$selectedCategory".\nCoba buat tugas baru atau pilih kategori lain.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    )
                    : ListView.separated(
                      itemCount: displayedTodos.length,
                      separatorBuilder:
                          (context, index) => Divider(
                            height: 1,
                            indent: 56,
                            endIndent: 16,
                            color: Colors.grey[200],
                          ),
                      itemBuilder: (context, index) {
                        final todo = displayedTodos[index];
                        // final originalIndex = todoProvider.todos.indexWhere((item) => item.id == todo.id); // Untuk Undo jika diperlukan

                        return TodoListItem(
                          key: ValueKey(todo.id),
                          todo: todo,
                          onTap: () {
                            // Navigasi ke Detail Screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TodoDetailScreen(todoId: todo.id),
                              ),
                            );
                          },
                          onDelete: () async {
                            // Logika Hapus tetap di sini jika item list bisa dihapus langsung
                            final removedTodo = await context
                                .read<TodoListProvider>()
                                .removeTodo(todo.id);
                            if (removedTodo != null && context.mounted) {
                              final originalIndex = todoProvider.todos
                                  .indexWhere(
                                    (item) => item.id == todo.id,
                                  ); // Ambil index sebelum hilang
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${removedTodo.title} dihapus',
                                      ),
                                      duration: const Duration(seconds: 3),
                                      action: SnackBarAction(
                                        label: 'UNDO',
                                        onPressed: () {
                                          // Perlu index asli dimana item dihapus
                                          // Jika list utama tidak berubah urutannya, index ini bisa dipakai
                                          // Jika list utama bisa berubah urutannya, pendekatan index kurang reliable
                                          // Untuk sederhana:
                                          context
                                              .read<TodoListProvider>()
                                              .undoRemove(
                                                originalIndex == -1
                                                    ? 0
                                                    : originalIndex,
                                                removedTodo,
                                              );
                                        },
                                      ),
                                    ),
                                  );
                                }
                              });
                            }
                          },
                          onToggleStar:
                              () => context.read<TodoListProvider>().toggleStar(
                                todo.id,
                              ),
                          onSetDate: () {
                            // Aksi dari slide menu, navigasi ke detail
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TodoDetailScreen(todoId: todo.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

// --- Widget Placeholder untuk Halaman Lain ---
class PlaceholderWidget extends StatelessWidget {
  final String title;
  const PlaceholderWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        // backgroundColor: Colors.white, // Pastikan konsisten
        // foregroundColor: Colors.black87,
        // elevation: 0.5,
      ),
      body: Center(child: Text('Konten untuk $title akan datang.')),
    );
  }
}
