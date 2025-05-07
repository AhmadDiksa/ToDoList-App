// lib/screens/my_tasks_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart
import 'dart:math'; // Import for max function
import '../models/todo.dart';
import '../providers/todo_list_provider.dart';
import 'todo_detail_screen.dart'; // Untuk navigasi jika item tugas diklik

// Helper function to check if two dates are the same day
bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class MyTasksSummaryScreen extends StatelessWidget {
  const MyTasksSummaryScreen({super.key});

  // Helper untuk mendapatkan warna kategori (bisa diperluas)
  Color _getCategoryColor(String category, int index) {
    // Daftar warna dasar untuk kategori
    final List<Color> categoryColors = [
      Colors.blue, Colors.green, Colors.orange, Colors.purple,
      Colors.red, Colors.teal, Colors.pink, Colors.amber,
    ];
    if (category == 'Kerja') return categoryColors[0];
    if (category == 'Pribadi') return categoryColors[1];
    if (category == 'Wishlist') return categoryColors[2];
    // Fallback jika kategori lain atau untuk kategori 'Tidak Ada Kategori'
    return categoryColors[index % categoryColors.length];
  }


  @override
  Widget build(BuildContext context) {
    final todoProvider = context.watch<TodoListProvider>();
    final allTodos = todoProvider.todos;
    final now = DateTime.now();

    // --- Hitung Statistik ---
    final int tasksSelesai = allTodos.where((todo) => todo.isDone).length;
    final int tasksTertunda = allTodos.where((todo) => !todo.isDone && todo.deadline != null && todo.deadline!.isBefore(DateTime(now.year, now.month, now.day))).length; // Deadline kemarin & belum selesai

    // --- Data untuk Grafik Batang (Penyelesaian Tugas Harian - 7 hari terakhir) ---
    // Kita akan hitung berapa banyak tugas yg DISELESAIKAN pada masing-masing 7 hari terakhir.
    // Ini contoh sederhana, bisa lebih kompleks dgn tanggal pembuatan vs. tanggal penyelesaian.
    // Asumsi: kita hitung tugas yg 'isDone' dan deadline-nya ada di 7 hari terakhir.
    List<BarChartGroupData> barGroups = [];
    Map<int, int> dailyCompletion = {}; // 0: Hari ini, 1: Kemarin, dst.
    final todayWeekday = now.weekday; // Senin = 1, Minggu = 7

    for (int i = 0; i < 7; i++) { // 7 hari dari sekarang ke belakang
        final dayToCheck = DateTime(now.year, now.month, now.day - i);
        int count = allTodos.where((todo) =>
            todo.isDone &&
            todo.deadline != null && // Hanya jika ada deadline
            isSameDay(DateTime(todo.deadline!.year, todo.deadline!.month, todo.deadline!.day), dayToCheck)
        ).length;
        dailyCompletion[i] = count; // i=0 (hari ini), i=1 (kemarin), dst.
    }

    // Susun data untuk BarChart (Minggu, Sen, Sel, Rab, Kam, Jum, Sab)
    final List<String> dayAbbreviations = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    for (int i = 6; i >= 0; i--) { // Mulai dari 6 hari lalu sampai hari ini
        // Tentukan indeks hari (0=Min, 1=Sen, ..., 6=Sab) untuk label
        final dayOfWeekForLabel = DateTime(now.year, now.month, now.day - i).weekday % 7; // Minggu jadi 0
        barGroups.add(
            BarChartGroupData(
                x: 6 - i, // x: 0 (Minggu), 1 (Senin), ..., 6 (Sabtu) dari kiri ke kanan
                barRods: [
                    BarChartRodData(
                        toY: dailyCompletion[i]?.toDouble() ?? 0.0, // Nilai dari map
                        color: Theme.of(context).primaryColor,
                        width: 16, // Lebar batang
                        borderRadius: BorderRadius.circular(4),
                    ),
                ],
            ),
        );
    }


    // --- Data untuk Diagram Donat (Klasifikasi Tugas Belum Selesai) ---
    final List<Todo> incompleteTodos = allTodos.where((todo) => !todo.isDone).toList();
    Map<String, int> categoryCounts = {};
    for (var todo in incompleteTodos) {
      categoryCounts.update(todo.category, (value) => value + 1, ifAbsent: () => 1);
    }
    // Jika tidak ada kategori sama sekali, tambahkan satu dummy
    if (incompleteTodos.isNotEmpty && categoryCounts.isEmpty) {
        categoryCounts['Tidak Ada Kategori'] = incompleteTodos.length;
    } else if (incompleteTodos.isEmpty) {
        categoryCounts['Tidak ada tugas belum selesai'] = 1; // Untuk visualisasi kosong
    }


    List<PieChartSectionData> pieSections = [];
    int colorIndex = 0;
    double totalIncomplete = incompleteTodos.length.toDouble();
    if (totalIncomplete == 0) totalIncomplete = 1; // Hindari pembagian dengan nol

    categoryCounts.forEach((category, count) {
      final isTouched = false; // Bisa di-handle dengan state jika ingin interaktif
      final fontSize = isTouched ? 16.0 : 14.0;
      final radius = isTouched ? 60.0 : 50.0;
      final value = (count / totalIncomplete * 100); // Persentase

      pieSections.add(PieChartSectionData(
        color: category == 'Tidak ada tugas belum selesai' ? Colors.grey[300] : _getCategoryColor(category, colorIndex++),
        value: value, // Persentase
        title: '${value.toStringAsFixed(0)}%', // Tampilkan persentase
        radius: radius,
        titleStyle: TextStyle(
            fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 2)]),
        // badgeWidget: Text(category), // Bisa juga badge
        // badgePositionPercentageOffset: .98,
      ));
    });

    // --- Data untuk Daftar Tugas dalam 7 Hari ke Depan ---
    final sevenDaysFromNow = now.add(const Duration(days: 7));
    final upcomingTasks = allTodos.where((todo) =>
        !todo.isDone && // Hanya yang belum selesai
        todo.deadline != null &&
        todo.deadline!.isAfter(DateTime(now.year, now.month, now.day -1)) && // Mulai dari hari ini
        todo.deadline!.isBefore(sevenDaysFromNow)
    ).toList();
    // Urutkan berdasarkan deadline
    upcomingTasks.sort((a, b) => a.deadline!.compareTo(b.deadline!));


    return Scaffold(
      appBar: AppBar(
        title: const Text('Ringkasan Tugas'),
        // actions: [IconButton(icon: Icon(Icons.help_outline), onPressed: () {})], // Tombol ?
      ),
      body: todoProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView( // Gunakan ListView agar bisa scroll
              padding: const EdgeInsets.all(16.0),
              children: [
                // --- Kartu Statistik Atas ---
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text('$tasksSelesai', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Tugas Selesai', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text('$tasksTertunda', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Tugas Tertunda', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- Grafik Batang: Penyelesaian Tugas Harian ---
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Penyelesaian tugas harian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('Minggu Ini', style: TextStyle(color: Colors.grey[600], fontSize: 12)), // Placeholder navigasi minggu
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (dailyCompletion.values.isEmpty ? 0 : dailyCompletion.values.reduce(max)) + 2, // Max Y dinamis + buffer
                              barTouchData: BarTouchData(enabled: true), // Interaksi sentuh
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                       // value: 0 (hari ini - 6), 1 (hari ini - 5) ... 6 (hari ini)
                                       // Kita ingin label dari Minggu ke Sabtu
                                       final dayIndex = value.toInt(); // Indeks 0-6
                                       // Label disesuaikan dengan urutan barGroups (Minggu ke Sabtu)
                                       return SideTitleWidget(axisSide: meta.axisSide, space: 4, child: Text(dayAbbreviations[dayIndex]));
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                    interval: 2, // Interval angka di sumbu Y
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                       if (value == 0) return Container(); // Jangan tampilkan 0
                                       return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false), // Hilangkan border chart
                              barGroups: barGroups, // Data batang dari state
                              gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false, // Hilangkan garis grid vertikal
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1);
                                  },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- Daftar Tugas dalam 7 Hari ke Depan ---
                if (upcomingTasks.isNotEmpty) ...[
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tugas dalam 7 hari ke depan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true, // Penting di dalam ListView utama
                            physics: const NeverScrollableScrollPhysics(), // Agar tidak ada scroll internal
                            itemCount: upcomingTasks.length > 3 ? 3 : upcomingTasks.length, // Batasi tampilan
                            itemBuilder: (context, index) {
                              final todo = upcomingTasks[index];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.calendar_month_outlined, color: Theme.of(context).primaryColor, size: 20),
                                title: Text(todo.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: Text(
                                  DateFormat('dd MMM HH:mm').format(todo.deadline!),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                ),
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => TodoDetailScreen(todoId: todo.id)));
                                },
                              );
                            },
                          ),
                          if (upcomingTasks.length > 3)
                             Align(
                               alignment: Alignment.centerRight,
                               child: TextButton(
                                 onPressed: (){ /* TODO: Navigasi ke halaman list semua upcoming task */},
                                 child: const Text("Lihat Semua", style: TextStyle(fontSize: 12))
                               ),
                             )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],


                // --- Diagram Donat: Klasifikasi Tugas Belum Selesai ---
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Klasifikasi tugas belum selesai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            // Text('Dalam 30 hari', style: TextStyle(color: Colors.grey[600], fontSize: 12)), // Placeholder filter waktu
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200, // Tinggi untuk diagram donat dan legenda
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2, // Beri ruang lebih untuk chart
                                child: PieChart(
                                  PieChartData(
                                    pieTouchData: PieTouchData(
                                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                        // setState(() { // Perlu StatefulWidget untuk interaksi sentuh
                                        //   if (!event.isInterestedForInteractions ||
                                        //       pieTouchResponse == null ||
                                        //       pieTouchResponse.touchedSection == null) {
                                        //     touchedIndex = -1;
                                        //     return;
                                        //   }
                                        //   touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                        // });
                                      },
                                    ),
                                    borderData: FlBorderData(show: false),
                                    sectionsSpace: 2, // Jarak antar section
                                    centerSpaceRadius: 40, // Radius lubang tengah
                                    sections: pieSections, // Data section dari state
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // --- Legenda untuk Diagram Donat ---
                              Expanded(
                                flex: 1, // Ruang untuk legenda
                                child: ListView( // Jika kategori banyak, bisa scroll
                                  shrinkWrap: true,
                                  children: categoryCounts.entries.map((entry) {
                                     final categoryName = entry.key;
                                     final count = entry.value;
                                     final color = categoryName == 'Tidak ada tugas belum selesai'
                                                    ? Colors.grey[300]!
                                                    : _getCategoryColor(categoryName, categoryCounts.keys.toList().indexOf(categoryName));
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                      child: Row(
                                        children: [
                                          Container(width: 12, height: 12, color: color),
                                          const SizedBox(width: 6),
                                          Expanded(
                                              child: Text(
                                                 '$categoryName ${categoryName == 'Tidak ada tugas belum selesai' ? "" : count}',
                                                 style: const TextStyle(fontSize: 12),
                                                 overflow: TextOverflow.ellipsis,
                                              )
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}