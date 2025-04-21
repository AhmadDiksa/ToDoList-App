// lib/widgets/todo_list_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/todo.dart'; // <-- Import model Todo

class TodoListItem extends StatelessWidget {
  final Todo todo; // Terima objek Todo
  // Callbacks
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStar;
  final VoidCallback? onSetDate;

  const TodoListItem({
    super.key, // WAJIB ada Key
    required this.todo,
    this.onTap,
    this.onDelete,
    this.onToggleStar,
    this.onSetDate,
  });

  @override
  Widget build(BuildContext context) {
    // Helper untuk menutup Slidable
    void handleAction(BuildContext context, VoidCallback? action) {
      // Panggil aksi jika ada
      action?.call();
      // Tutup slidable setelah aksi (kecuali delete mungkin)
      // Memberi sedikit delay agar user melihat feedback sebelum tertutup
      Future.delayed(const Duration(milliseconds: 300), () {
        if (context.mounted) {
          // Check jika widget masih ada di tree
          Slidable.of(context)?.close();
        }
      });
    }

    return Slidable(
      key: key,
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.65, // Bisa disesuaikan
        children: [
          SlidableAction(
            onPressed: (ctx) => handleAction(ctx, onToggleStar),
            backgroundColor: const Color(0xFF2196F3), // Biru
            foregroundColor: Colors.white,
            icon: todo.isStarred ? Icons.star : Icons.star_border,
            label: todo.isStarred ? 'Unstar' : 'Star',
            flex: 2, // Beri proporsi lebar
          ),
          SlidableAction(
            onPressed: (ctx) => handleAction(ctx, onSetDate),
            backgroundColor: const Color(0xFF1976D2), // Biru Tua
            foregroundColor: Colors.white,
            icon: Icons.calendar_today_outlined,
            label: 'Tanggal',
            flex: 2,
          ),
          SlidableAction(
            // Delete tidak perlu ditutup otomatis oleh handleAction
            onPressed: (ctx) => onDelete?.call(),
            backgroundColor: const Color(0xFFF44336), // Merah
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Hapus',
            flex: 2,
          ),
        ],
      ),
      child: Material(
        // Untuk efek ripple InkWell
        color: Colors.white,
        child: InkWell(
          // Efek tap di seluruh area
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leading icon (Checkbox/Radio)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0, top: 2.0),
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(24),
                    child: Icon(
                      todo.isDone
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: todo.isDone ? Colors.blue : Colors.grey[400],
                      size: 24,
                    ),
                  ),
                ),
                // Title dan Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: TextStyle(
                          fontSize: 15,
                          decoration:
                              todo.isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                          color:
                              todo.isDone ? Colors.grey[500] : Colors.black87,
                          decorationColor: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (todo.date.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            todo.date,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Trailing icon (Bookmark/Star)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 2.0),
                  child: Icon(
                    todo.isStarred
                        ? Icons.bookmark
                        : Icons.bookmark_border_outlined,
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
