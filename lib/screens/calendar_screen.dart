// lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format header kalender
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/todo.dart';
import '../providers/todo_list_provider.dart';
import 'todo_detail_screen.dart'; // Untuk navigasi ke detail tugas

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  late Map<DateTime, List<Todo>> _events; // Map untuk menyimpan event/tugas per tanggal
  List<Todo> _selectedEvents = [];       // List tugas untuk tanggal yang dipilih
  CalendarFormat _calendarFormat = CalendarFormat.month; // Format kalender (bulan, 2 minggu, minggu)
  DateTime _focusedDay = DateTime.now();   // Tanggal yang sedang difokuskan (default hari ini)
  DateTime? _selectedDay;                 // Tanggal yang dipilih oleh pengguna

  DateTime? get selectedDay => _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay; // Awalnya, hari yang dipilih adalah hari ini
    _events = {}; // Inisialisasi map events
    // Tidak perlu memuat event di sini jika kita pakai context.watch di build
  }

  // Fungsi untuk mendapatkan daftar tugas untuk hari tertentu
  List<Todo> _getEventsForDay(DateTime day, List<Todo> allTodos) {
    // Normalisasi 'day' ke tengah malam untuk perbandingan yang konsisten
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return allTodos.where((todo) {
      // Cek deadline
      if (todo.deadline != null) {
        final normalizedDeadline = DateTime(todo.deadline!.year, todo.deadline!.month, todo.deadline!.day);
        if (isSameDay(normalizedDeadline, normalizedDay)) {
          return true;
        }
      }
      // Cek reminder (jika ingin ditampilkan juga di kalender)
      // if (todo.reminderDateTime != null) {
      //   final normalizedReminder = DateTime(todo.reminderDateTime!.year, todo.reminderDateTime!.month, todo.reminderDateTime!.day);
      //   if (isSameDay(normalizedReminder, normalizedDay)) {
      //     return true;
      //   }
      // }
      return false;
    }).toList();
  }

  // Fungsi untuk membangun map events dari semua todos
  Map<DateTime, List<Todo>> _groupTodosByDate(List<Todo> allTodos) {
    Map<DateTime, List<Todo>> data = {};
    for (var todo in allTodos) {
      // Proses deadline
      if (todo.deadline != null) {
        final normalizedDeadline = DateTime(todo.deadline!.year, todo.deadline!.month, todo.deadline!.day);
        data.update(
          normalizedDeadline,
          (list) => list..add(todo),
          ifAbsent: () => [todo],
        );
      }
      // Proses reminder (jika ingin ditampilkan juga)
      // if (todo.reminderDateTime != null) {
      //   final normalizedReminder = DateTime(todo.reminderDateTime!.year, todo.reminderDateTime!.month, todo.reminderDateTime!.day);
      //   data.update(
      //     normalizedReminder,
      //     (list) => list..add(todo),
      //     ifAbsent: () => [todo],
      //   );
      // }
    }
    return data;
  }


  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay; // Update focusedDay juga
        // Dapatkan tugas untuk hari yang dipilih dari provider
        final allTodos = Provider.of<TodoListProvider>(context, listen: false).todos;
        _selectedEvents = _getEventsForDay(selectedDay, allTodos);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dapatkan semua tugas dari provider
    final todoProvider = context.watch<TodoListProvider>();
    final allTodos = todoProvider.todos;

    // Bangun map events setiap kali build (atau bisa dioptimasi dengan listen: false dan manual update)
    _events = _groupTodosByDate(allTodos);
    // Perbarui _selectedEvents jika _selectedDay sudah ada
    if (_selectedDay != null) {
       _selectedEvents = _getEventsForDay(_selectedDay!, allTodos);
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender Tugas'),
        elevation: 0.5,
        // Tombol aksi jika diperlukan (misal: filter, tambah event langsung)
        actions: [
           IconButton(
             icon: const Icon(Icons.today_outlined),
             onPressed: () { // Kembali ke hari ini
               setState(() {
                 _focusedDay = DateTime.now();
                 _selectedDay = _focusedDay;
                 _selectedEvents = _getEventsForDay(_selectedDay!, allTodos);
               });
             },
             tooltip: 'Hari Ini',
           ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<Todo>(
            locale: 'id_ID', // Untuk format Bahasa Indonesia (perlu intl setup di main.dart)
            firstDay: DateTime.utc(2020, 1, 1),  // Tanggal awal yang bisa ditampilkan
            lastDay: DateTime.utc(2030, 12, 31), // Tanggal akhir yang bisa ditampilkan
            focusedDay: _focusedDay,             // Tanggal yang sedang difokuskan
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day), // Menandai hari yang dipilih
            calendarFormat: _calendarFormat,     // Format tampilan (bulan, 2 minggu, minggu)
            eventLoader: (day) { // Fungsi untuk memuat event/tugas untuk suatu hari
               final normalizedDay = DateTime(day.year, day.month, day.day);
               return _events[normalizedDay] ?? [];
            },
            startingDayOfWeek: StartingDayOfWeek.monday, // Mulai minggu dari hari Senin
            calendarStyle: CalendarStyle(
              // Kustomisasi tampilan kalender
              todayDecoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              // Kustomisasi marker event
              markerDecoration: BoxDecoration(
                color: Colors.blue[400],
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1, // Hanya tampilkan satu marker per hari (bisa disesuaikan)
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true, // Tombol untuk ganti format (bulan/minggu)
              titleCentered: true,
              titleTextStyle: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              // Format judul header (misal: "MEI 2025")
              titleTextFormatter: (date, locale) => DateFormat.yMMMM(locale).format(date).toUpperCase(),
              leftChevronIcon: const Icon(Icons.chevron_left),
              rightChevronIcon: const Icon(Icons.chevron_right),
            ),
            onDaySelected: _onDaySelected, // Fungsi saat hari dipilih
            onFormatChanged: (format) { // Fungsi saat format kalender diubah
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) { // Fungsi saat halaman kalender diganti (bulan/minggu)
              _focusedDay = focusedDay;
            },
            // Kustomisasi tampilan hari (DaysOfWeekStyle, DayBuilder, dll. jika perlu)
            calendarBuilders: CalendarBuilders(
              // Contoh kustomisasi marker
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: _buildEventsMarker(date, events),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 8.0),
          // Tampilkan daftar tugas untuk hari yang dipilih
          Expanded(
            child: _selectedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/break.png', height: 150, color: Colors.grey[300]), // Ganti dengan path aset Anda
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada tugas pada tanggal ini.',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                         const SizedBox(height: 8),
                         Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 40.0),
                           child: Text(
                             _selectedDay == DateTime.now()
                               ? 'Rencanakan hari Anda dengan jelas!'
                               : 'Klik "+" untuk membuat tugas baru pada tanggal ini.',
                             textAlign: TextAlign.center,
                             style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                           ),
                         ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = _selectedEvents[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        child: ListTile(
                          leading: Icon(
                             event.isDone ? Icons.check_circle_outline : Icons.radio_button_unchecked_outlined,
                             color: event.isDone ? Colors.green : Theme.of(context).primaryColor,
                          ),
                          title: Text(event.title),
                          subtitle: Text('Deadline: ${DateFormat('HH:mm').format(event.deadline!)} - ${event.category}'),
                          onTap: () {
                            // Navigasi ke halaman detail tugas
                            Navigator.push(
                              context,
                              MaterialPageRoute(
builder: (_) => TodoDetailScreen(todoId: event.id),
                              ),
                            );
                          },
                           // Tambahkan aksi lain jika perlu (misal: tandai selesai dari sini)
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigasi ke halaman tambah tugas, dengan tanggal terpilih sebagai default
          // (Perlu modifikasi halaman tambah tugas untuk menerima tanggal default)
          print('FAB ditekan, tanggal terpilih: $_selectedDay');
          // TODO: Navigasi ke halaman tambah tugas dengan _selectedDay sebagai parameter
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Fitur tambah tugas dari kalender (tanggal: ${DateFormat('yyyy-MM-dd').format(_selectedDay ?? DateTime.now())}) belum diimplementasi penuh.'))
           );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Widget kustom untuk marker event
  Widget _buildEventsMarker(DateTime date, List events) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue[400],
      ),
      width: 7.0, // Ukuran marker
      height: 7.0,
      // child: Center( // Jika ingin ada angka di marker (membutuhkan lebih banyak ruang)
      //   child: Text(
      //     '${events.length}',
      //     style: TextStyle().copyWith(
      //       color: Colors.white,
      //       fontSize: 12.0,
      //     ),
      //   ),
      // ),
    );
  }
}