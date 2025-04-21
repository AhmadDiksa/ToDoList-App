// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/todo_list_item.dart';
import '../widgets/custom_bottom_navbar.dart';
import '../providers/todo_list_provider.dart';
import '../models/todo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedBottomNavIndex = 0;
  int _selectedChipIndex = 0;
  final List<String> _filterChips = ['Semua', 'Kerja', 'Pribadi', 'Wishlist'];

  // Handler tap Bottom Nav Bar (No change)
  void _onBottomNavItemTapped(int index) {
    setState(() {
      _selectedBottomNavIndex = index;
      print("Bottom Nav Tab index $index ditekan");
    });
  }

  // Handler tap Filter Chip (No change)
  void _onFilterChipTapped(int index) {
    setState(() {
      _selectedChipIndex = index;
      print("Filter Chip '${_filterChips[index]}' dipilih");
    });
  }

  // Dialog Tambah Tugas (No change in logic, calls provider)
  void _showAddTodoDialog() {
    final TextEditingController todoController = TextEditingController();
    String selectedCategory = 'Pribadi';
    if (_selectedChipIndex > 0 && _selectedChipIndex < _filterChips.length) {
      selectedCategory = _filterChips[_selectedChipIndex];
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Tugas Baru'),
          content: TextField(
            controller: todoController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Masukkan judul tugas...',
            ),
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                // No await needed here, fire and forget
                Provider.of<TodoListProvider>(
                  context,
                  listen: false,
                ).addTodo(value, selectedCategory);
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
                  // No await needed here
                  Provider.of<TodoListProvider>(
                    context,
                    listen: false,
                  ).addTodo(title, selectedCategory);
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

  // Handler Undo Delete (Calls provider - now async but no await needed from UI)
  void _handleUndoDelete(int originalIndex, Todo removedTodo) {
    // No await needed here
    Provider.of<TodoListProvider>(
      context,
      listen: false,
    ).undoRemove(originalIndex, removedTodo);
    print('Undo delete for: ${removedTodo.title}');
  }

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    // Akses Provider
    final todoProvider = context.watch<TodoListProvider>();
    final selectedCategory = _filterChips[_selectedChipIndex];
    // Filtered list obtained from provider
    final List<Todo> displayedTodos = todoProvider.getFilteredTodos(
      selectedCategory,
    );

    print(
      "Rebuilding HomeScreen. Loading: ${todoProvider.isLoading}, Filter: $selectedCategory, Count: ${displayedTodos.length}",
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Filter Chips (No change)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: SizedBox(
                height: 38, // Sesuaikan tinggi Chip
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filterChips.length + 1, // +1 untuk icon More
                  separatorBuilder:
                      (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == _filterChips.length) {
                      // Tombol More (...)
                      return IconButton(
                        icon: Icon(Icons.more_horiz, color: Colors.grey[600]),
                        onPressed: () {
                          print("Tombol More Chips ditekan");
                          // Tampilkan menu atau dialog untuk filter/label lain
                        },
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                        ), // Kurangi padding
                        constraints: const BoxConstraints(),
                        tooltip: 'Filter lainnya',
                      );
                    }
                    // Chip Filter
                    return ChoiceChip(
                      label: Text(_filterChips[index]),
                      selected: _selectedChipIndex == index,
                      onSelected: (selected) {
                        if (selected) {
                          _onFilterChipTapped(index);
                        }
                      },
                    );
                  },
                ),
              ),
            ),

            // Header "Masa mendatang" (No change)
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
                    'Masa mendatang',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_up,
                    color: Colors.grey[600],
                    size: 20,
                  ), // Atau logic untuk expand/collapse
                ],
              ),
            ),

            // === List To-Do with Loading Indicator ===
            Expanded(
              child:
                  todoProvider
                          .isLoading // Check loading state
                      ? const Center(
                        child: CircularProgressIndicator(),
                      ) // Show loader
                      : displayedTodos
                          .isEmpty // Check if list is empty after loading
                      ? Center(
                        child: Text(
                          'Tidak ada tugas di kategori "$selectedCategory"',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      )
                      : ListView.separated(
                        // Show list if not loading and not empty
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
                          // Find original index for UNDO if needed
                          final originalIndex = todoProvider.todos.indexWhere(
                            (item) => item.id == todo.id,
                          );

                          return TodoListItem(
                            key: ValueKey(todo.id),
                            todo: todo,
                            // --- Callbacks (No async/await needed here) ---
                            onTap:
                                () => context
                                    .read<TodoListProvider>()
                                    .toggleDone(todo.id),
                            onDelete: () async {
                              // Make this specific callback async if needed
                              // Call removeTodo and wait for the result (the removed item)
                              final removedTodo = await context
                                  .read<TodoListProvider>()
                                  .removeTodo(todo.id);

                              // Show SnackBar only if deletion was successful
                              if (removedTodo != null && mounted) {
                                final indexToRemove =
                                    originalIndex; // Capture index
                                // Use addPostFrameCallback to ensure build context is stable
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted) {
                                    // Double check mounted state
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
                            onToggleStar:
                                () => context
                                    .read<TodoListProvider>()
                                    .toggleStar(todo.id),
                            onSetDate: () {
                              print(
                                "Set date action triggered for: ${todo.title}",
                              );
                              // Example: Call provider after date picker result
                              // context.read<TodoListProvider>().updateTodoDate(todo.id, 'New Date');
                              ScaffoldMessenger.of(
                                context,
                              ).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Atur tanggal untuk: ${todo.title}',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        tooltip: 'Tambah Tugas',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedBottomNavIndex,
        onTap: _onBottomNavItemTapped,
      ),
    );
  }
}
