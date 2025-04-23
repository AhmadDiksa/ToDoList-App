// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // State Management
import '../widgets/todo_list_item.dart'; // Widget untuk item list
import '../widgets/custom_bottom_navbar.dart'; // Widget Bottom Nav Bar kustom
import '../providers/todo_list_provider.dart'; // Provider untuk state ToDo
import '../models/todo.dart'; // Model data ToDo
import 'todo_detail_screen.dart'; // Layar detail tugas

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State lokal untuk UI HomeScreen itu sendiri
  int _selectedBottomNavIndex = 0; // Index tab navigasi bawah yang aktif
  int _selectedChipIndex = 0; // Index chip filter kategori yang aktif

  // Daftar label untuk filter chip
  final List<String> _filterChips = ['Semua', 'Kerja', 'Pribadi', 'Wishlist'];

  // --- Handler Aksi UI ---

  // Dipanggil saat tab navigasi bawah di-tap
  void _onBottomNavItemTapped(int index) {
    setState(() {
      _selectedBottomNavIndex = index;
      // Di sini bisa ditambahkan logika navigasi ke layar lain jika index bukan 0
      print("Bottom Nav Tab index $index ditekan");
      // if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => CalendarScreen()));
    });
  }

  // Dipanggil saat filter chip di-tap
  void _onFilterChipTapped(int index) {
    setState(() {
      _selectedChipIndex = index;
      print("Filter Chip '${_filterChips[index]}' dipilih");
    });
  }

  // Menampilkan dialog untuk menambah tugas baru
  void _showAddTodoDialog() {
    final TextEditingController todoController = TextEditingController();
    // Tentukan kategori default berdasarkan chip yang sedang aktif
    String selectedCategory = 'Pribadi'; // Default jika 'Semua' dipilih
    if (_selectedChipIndex > 0 && _selectedChipIndex < _filterChips.length) {
      selectedCategory = _filterChips[_selectedChipIndex];
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Gunakan context dialog terpisah
        return AlertDialog(
          title: const Text('Tugas Baru'),
          content: TextField(
            controller: todoController,
            autofocus: true, // Langsung fokus ke input field
            decoration: const InputDecoration(
              hintText: 'Masukkan judul tugas...',
            ),
            textCapitalization:
                TextCapitalization.sentences, // Huruf pertama kapital
            // Tambah tugas saat tombol Enter/Submit di keyboard ditekan
            onSubmitted: (value) {
              final title = value.trim();
              if (title.isNotEmpty) {
                // Panggil provider untuk menambah tugas (tanpa await dari UI)
                // Gunakan context.read karena di dalam callback
                Provider.of<TodoListProvider>(
                  context,
                  listen: false,
                ).addTodo(title, selectedCategory);
              }
              Navigator.of(dialogContext).pop(); // Tutup dialog
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed:
                  () => Navigator.of(dialogContext).pop(), // Tutup dialog
            ),
            TextButton(
              child: const Text('Simpan'),
              onPressed: () {
                final title = todoController.text.trim();
                if (title.isNotEmpty) {
                  // Panggil provider untuk menambah tugas
                  Provider.of<TodoListProvider>(
                    context,
                    listen: false,
                  ).addTodo(title, selectedCategory);
                }
                Navigator.of(dialogContext).pop(); // Tutup dialog
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ), // Sudut dialog rounded
        );
      },
    );
  }

  // Menangani aksi Undo setelah menghapus tugas
  void _handleUndoDelete(int originalIndex, Todo removedTodo) {
    // Panggil provider untuk mengembalikan tugas (tanpa await dari UI)
    Provider.of<TodoListProvider>(
      context,
      listen: false,
    ).undoRemove(originalIndex, removedTodo);
    print('Undo delete for: ${removedTodo.title}');
  }

  // --- Build Method Utama ---
  @override
  Widget build(BuildContext context) {
    // --- Mengakses Provider ---
    // context.watch akan membuat widget ini rebuild saat provider memanggil notifyListeners()
    final todoProvider = context.watch<TodoListProvider>();

    // Tentukan kategori filter yang sedang dipilih
    final selectedCategory = _filterChips[_selectedChipIndex];

    // Dapatkan daftar tugas yang sudah difilter dari provider
    final List<Todo> displayedTodos = todoProvider.getFilteredTodos(
      selectedCategory,
    );

    // Log untuk debugging (bisa dihapus nanti)
    print(
      "Rebuilding HomeScreen. Loading: ${todoProvider.isLoading}, Filter: $selectedCategory, Count: ${displayedTodos.length}",
    );

    return Scaffold(
      body: SafeArea(
        // Menghindari notch dan area sistem lainnya
        child: Column(
          // Layout vertikal utama
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Baris Filter Chips ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: SizedBox(
                height: 38, // Tinggi baris chip
                child: ListView.separated(
                  scrollDirection: Axis.horizontal, // Scroll horizontal
                  itemCount:
                      _filterChips.length + 1, // Tambah 1 untuk ikon 'more'
                  separatorBuilder:
                      (context, index) =>
                          const SizedBox(width: 8), // Jarak antar chip
                  itemBuilder: (context, index) {
                    // Item terakhir adalah ikon 'more'
                    if (index == _filterChips.length) {
                      return IconButton(
                        icon: Icon(Icons.more_horiz, color: Colors.grey[600]),
                        onPressed: () {
                          print("Tombol More Chips ditekan");
                          // TODO: Tampilkan menu atau dialog filter tambahan
                        },
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        constraints:
                            const BoxConstraints(), // Hapus constraint default
                        tooltip: 'Filter lainnya',
                      );
                    }
                    // Tampilkan ChoiceChip untuk filter
                    return ChoiceChip(
                      label: Text(_filterChips[index]),
                      selected:
                          _selectedChipIndex == index, // Tandai jika terpilih
                      // Panggil handler saat chip dipilih
                      onSelected: (selected) {
                        if (selected) {
                          _onFilterChipTapped(index);
                        }
                      },
                      // Styling diambil dari ThemeData (chipTheme)
                    );
                  },
                ),
              ),
            ),

            // --- Header "Masa mendatang" (atau header bagian lainnya) ---
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
                    // TODO: Buat teks ini dinamis atau sesuai bagian list
                    'Masa mendatang',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // TODO: Ikon ini bisa untuk expand/collapse bagian list
                  Icon(Icons.arrow_drop_up, color: Colors.grey[600], size: 20),
                ],
              ),
            ),

            // --- Area Daftar Tugas (Dengan Loading & Empty State) ---
            Expanded(
              // Agar mengisi sisa ruang vertikal
              child:
                  todoProvider
                          .isLoading // Cek apakah sedang loading?
                      // Tampilkan indikator loading jika true
                      ? const Center(child: CircularProgressIndicator())
                      // Jika tidak loading, cek apakah daftar tugas kosong?
                      : displayedTodos.isEmpty
                      // Tampilkan pesan jika kosong
                      ? Center(
                        child: Text(
                          'Tidak ada tugas di kategori "$selectedCategory".\nCoba tambah tugas baru!',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                      // Jika tidak loading dan tidak kosong, tampilkan list
                      : ListView.separated(
                        itemCount: displayedTodos.length, // Jumlah item
                        separatorBuilder:
                            (context, index) => Divider(
                              // Garis pemisah
                              height: 1, // Tinggi divider
                              indent:
                                  56, // Jarak dari kiri (setelah ikon check)
                              endIndent: 16, // Jarak dari kanan
                              color: Colors.grey[200], // Warna divider
                            ),
                        itemBuilder: (context, index) {
                          // Ambil data todo untuk item saat ini
                          final todo = displayedTodos[index];
                          // Cari index asli di list lengkap (PENTING untuk Undo)
                          final originalIndex = todoProvider.todos.indexWhere(
                            (item) => item.id == todo.id,
                          );

                          // Buat widget TodoListItem
                          return TodoListItem(
                            key: ValueKey(
                              todo.id,
                            ), // Key unik untuk performa & animasi
                            todo: todo, // Kirim data todo ke item
                            // --- Callback yang diteruskan ke TodoListItem ---
                            // 1. onTap: Untuk navigasi ke halaman detail
                            onTap: () {
                              // Navigasi ke TodoDetailScreen, kirim objek todo
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TodoDetailScreen(todo: todo),
                                ),
                              );
                            },
                            // 2. onDelete: Aksi saat tombol hapus di slide ditekan
                            onDelete: () async {
                              // Jadikan async karena removeTodo async
                              // Panggil provider untuk hapus, tunggu hasilnya (Todo yg dihapus)
                              final removedTodo = await context
                                  .read<TodoListProvider>()
                                  .removeTodo(todo.id);

                              // Jika berhasil dihapus (removedTodo tidak null) dan widget masih mounted
                              if (removedTodo != null && context.mounted) {
                                // Simpan index asli sebelum menampilkan SnackBar
                                final indexToRemove = originalIndex;
                                // Tampilkan SnackBar setelah frame selesai build
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (context.mounted) {
                                    // Cek lagi jika mounted
                                    ScaffoldMessenger.of(
                                      context,
                                    ).hideCurrentSnackBar(); // Sembunyikan snackbar lama
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${removedTodo.title} dihapus',
                                        ),
                                        duration: const Duration(seconds: 3),
                                        action: SnackBarAction(
                                          label: 'UNDO',
                                          // Panggil handler undo dengan index asli dan data yg dihapus
                                          onPressed:
                                              () => _handleUndoDelete(
                                                indexToRemove,
                                                removedTodo,
                                              ),
                                        ),
                                      ),
                                    );
                                  }
                                });
                              }
                            },
                            // 3. onToggleStar: Aksi saat tombol bintang di slide ditekan
                            onToggleStar:
                                () => context
                                    .read<TodoListProvider>()
                                    .toggleStar(todo.id),
                            // 4. onSetDate: Aksi saat tombol tanggal/detail di slide ditekan (Navigasi)
                            onSetDate: () {
                              // Navigasi ke detail screen (sama seperti onTap utama)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TodoDetailScreen(todo: todo),
                                ),
                              );
                              print(
                                "Slide menu 'Detail' ditekan untuk: ${todo.title}",
                              );
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),

      // --- Floating Action Button (Tombol Tambah) ---
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog, // Panggil dialog tambah
        tooltip: 'Tambah Tugas', // Teks saat ditahan lama
        child: const Icon(Icons.add, color: Colors.white), // Ikon tambah
        // Styling FAB diambil dari ThemeData (floatingActionButtonTheme)
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // Posisi di kanan bawah
      // --- Bottom Navigation Bar ---
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedBottomNavIndex, // Kirim index aktif
        onTap: _onBottomNavItemTapped, // Kirim handler tap
      ),
    );
  }
}
