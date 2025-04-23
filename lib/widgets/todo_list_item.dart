// lib/widgets/todo_list_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // Untuk aksi geser
import 'package:provider/provider.dart'; // Untuk memanggil aksi provider
import 'package:intl/intl.dart'; // Untuk format tanggal/waktu
import '../models/todo.dart'; // Model data tugas
import '../providers/todo_list_provider.dart'; // Provider state management

class TodoListItem extends StatelessWidget {
  // Menerima objek Todo lengkap sebagai data utama
  final Todo todo;

  // Callbacks untuk aksi yang di-handle oleh parent (HomeScreen)
  final VoidCallback?
  onTap; // Aksi saat area utama item di-tap (biasanya navigasi)
  final VoidCallback? onDelete; // Aksi saat tombol hapus di slide menu ditekan
  final VoidCallback?
  onToggleStar; // Aksi saat tombol bintang di slide menu ditekan
  final VoidCallback?
  onSetDate; // Aksi saat tombol tanggal/detail di slide menu ditekan (bisa navigasi juga)

  const TodoListItem({
    // Key sangat penting untuk performa list dan animasi Slidable
    super.key,
    required this.todo,
    this.onTap,
    this.onDelete,
    this.onToggleStar,
    this.onSetDate,
  });

  @override
  Widget build(BuildContext context) {
    // Helper untuk menutup panel slide setelah aksi (opsional)
    void handleSlideAction(BuildContext context, VoidCallback? action) {
      // Panggil callback aksi jika ada
      action?.call();
      // Tutup panel slide setelah beberapa saat agar user melihat feedback
      Future.delayed(const Duration(milliseconds: 300), () {
        // Pastikan widget masih ada sebelum memanggil Slidable.of
        if (context.mounted) {
          Slidable.of(context)?.close();
        }
      });
    }

    // Format tanggal deadline untuk ditampilkan di subtitle
    String subtitleText = todo.date; // Subtitle default adalah tanggal info
    if (todo.deadline != null) {
      // Jika ada deadline, tambahkan ke subtitle
      // Format: 'Info Tanggal • Deadline: 25 Des 14:30'
      subtitleText +=
          ' • Deadline: ${DateFormat('dd MMM HH:mm', 'id_ID').format(todo.deadline!)}';
    }

    return Slidable(
      key: key, // Gunakan key dari constructor
      // Panel aksi yang muncul saat digeser ke KIRI
      endActionPane: ActionPane(
        motion: const BehindMotion(), // Efek muncul dari belakang
        extentRatio: 0.65, // Lebar panel aksi (65% dari lebar item)
        children: [
          // Aksi Bintang
          SlidableAction(
            // Panggil helper handleSlideAction untuk menutup panel
            onPressed: (ctx) => handleSlideAction(ctx, onToggleStar),
            backgroundColor: const Color(0xFF2196F3), // Biru
            foregroundColor: Colors.white,
            // Ikon dan label berubah sesuai status isStarred
            icon: todo.isStarred ? Icons.star : Icons.star_border,
            label: todo.isStarred ? 'Batal Bintang' : 'Bintang',
            flex: 2, // Proporsi lebar relatif terhadap aksi lain
          ),
          // Aksi Tanggal/Detail
          SlidableAction(
            // Panggil callback onSetDate yang diteruskan dari HomeScreen
            // (HomeScreen akan handle navigasi ke detail)
            onPressed:
                (ctx) =>
                    onSetDate?.call(), // Tidak perlu auto-close karena navigasi
            backgroundColor: const Color(0xFF1976D2), // Biru Tua
            foregroundColor: Colors.white,
            icon: Icons.calendar_today_outlined,
            label: 'Detail', // Label lebih cocok 'Detail' sekarang
            flex: 2,
          ),
          // Aksi Hapus
          SlidableAction(
            // Panggil callback onDelete langsung (SnackBar Undo di handle HomeScreen)
            onPressed: (ctx) => onDelete?.call(),
            backgroundColor: const Color(0xFFF44336), // Merah
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Hapus',
            flex: 2,
          ),
        ],
      ),

      // Konten utama item list yang terlihat
      child: Material(
        // Bungkus dengan Material untuk background dan efek ripple
        color: Colors.white,
        child: InkWell(
          // Membuat seluruh area item bisa di-tap
          onTap:
              onTap, // Panggil callback onTap dari HomeScreen (untuk navigasi)
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 16.0,
            ), // Padding item
            child: Row(
              // Layout utama horizontal
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align vertikal ke atas
              children: [
                // --- Leading Icon (Checkbox/Radio Button) ---
                Padding(
                  padding: const EdgeInsets.only(
                    right: 16.0,
                    top: 2.0,
                  ), // Spasi kanan & sedikit turun
                  child: InkWell(
                    // Area tap terpisah untuk ikon check
                    // --- Panggil toggleDone langsung dari Provider ---
                    onTap: () {
                      // Gunakan context.read karena ini di dalam callback
                      context.read<TodoListProvider>().toggleDone(todo.id);
                    },
                    borderRadius: BorderRadius.circular(
                      24,
                    ), // Efek ripple bulat
                    child: Icon(
                      // Ikon berubah berdasarkan status isDone
                      todo.isDone
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      // Warna ikon berubah berdasarkan status isDone
                      color: todo.isDone ? Colors.blue : Colors.grey[400],
                      size: 24,
                    ),
                  ),
                ),

                // --- Konten Tengah (Judul & Subtitle) ---
                Expanded(
                  // Agar mengisi sisa ruang horizontal
                  child: Column(
                    // Susun Judul dan Subtitle secara vertikal
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Align teks ke kiri
                    children: [
                      // Judul Tugas
                      Text(
                        todo.title,
                        style: TextStyle(
                          fontSize: 15,
                          // Coret teks jika sudah selesai
                          decoration:
                              todo.isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                          // Warna teks lebih pudar jika sudah selesai
                          color:
                              todo.isDone ? Colors.grey[500] : Colors.black87,
                          decorationColor: Colors.grey[500], // Warna coretan
                          fontWeight: FontWeight.w500, // Sedikit tebal
                        ),
                        maxLines: 3, // Batasi maksimal 3 baris
                        overflow:
                            TextOverflow
                                .ellipsis, // Tampilkan '...' jika terlalu panjang
                      ),
                      // Subtitle (Tanggal Info & Deadline)
                      if (subtitleText
                          .isNotEmpty) // Tampilkan jika subtitle ada isinya
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 4.0,
                          ), // Spasi atas dari judul
                          child: Text(
                            subtitleText, // Tampilkan subtitle yang sudah diformat
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            maxLines: 1, // Batasi 1 baris
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

                // --- Trailing Icon (Bookmark/Bintang) ---
                Padding(
                  padding: const EdgeInsets.only(
                    left: 12.0,
                    top: 2.0,
                  ), // Spasi kiri & sedikit turun
                  child: Icon(
                    // Ikon berubah berdasarkan status isStarred
                    todo.isStarred
                        ? Icons.bookmark
                        : Icons.bookmark_border_outlined,
                    // Warna ikon berubah berdasarkan status isStarred
                    color:
                        todo.isStarred ? Colors.orange[700] : Colors.grey[400],
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
