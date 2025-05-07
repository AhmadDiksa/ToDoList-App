// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import untuk locale DateFormat
// import 'screens/home_screen.dart';
import 'providers/todo_list_provider.dart';
import 'services/notification_service.dart'; // <-- Import Notification Service
import 'screens/splash_screen.dart';  

// Fungsi main menjadi async
Future<void> main() async {
  // Pastikan Flutter binding siap
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale untuk DateFormat (PENTING!)
  await initializeDateFormatting(
    'id_ID',
    null,
  ); // Ganti 'id_ID' jika perlu locale lain

  // Inisialisasi Notification Service (termasuk timezone)
  await NotificationService().initialize();

  // Setup System UI Overlay (Status bar style)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          Brightness.dark, // Ikon gelap untuk background terang
      statusBarBrightness: Brightness.light, // Untuk iOS
    ),
  );

  // Jalankan aplikasi dengan Provider
  runApp(
    ChangeNotifierProvider(
      create: (context) => TodoListProvider(), // Buat instance TodoListProvider
      child: const MyApp(), // Root widget aplikasi
    ),
  );
}

// Widget MyApp (Root Aplikasi)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List App',
      theme: ThemeData(
        // Tema aplikasi (seperti sebelumnya)
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        chipTheme: ChipThemeData(
          backgroundColor: Colors.grey[200],
          disabledColor: Colors.grey.shade300,
          selectedColor: Colors.blue[100]?.withOpacity(0.8),
          secondarySelectedColor: Colors.blue[100],
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          labelStyle: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          secondaryLabelStyle: TextStyle(
            color: Colors.blue[800],
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          brightness: Brightness.light,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 0,
          pressElevation: 2,
        ),
        dividerTheme: DividerThemeData(color: Colors.grey[200], thickness: 1),
        iconTheme: IconThemeData(color: Colors.grey[600]),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.blue[700]),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blueAccent,
          elevation: 4.0,
        ),
        // Tambahkan tema untuk Time Picker jika perlu
        timePickerTheme: TimePickerThemeData(
          backgroundColor: Colors.white,
          // ... styling lain
        ),
        // Tambahkan tema untuk Date Picker jika perlu
        datePickerTheme: DatePickerThemeData(
          backgroundColor: Colors.white,
          // ... styling lain
        ),
      ),
      home: const SplashScreen(), // Halaman utama
      debugShowCheckedModeBanner: false, // Hilangkan banner debug
    );
  }
}
