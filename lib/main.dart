// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // <-- 1. Import package provider
import 'screens/home_screen.dart'; // Import halaman utama
import 'providers/todo_list_provider.dart'; // <-- 2. Import kelas provider Anda

void main() {
  // Pastikan Flutter binding terinisialisasi jika menggunakan SystemChrome sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();
  // Atur gaya status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Buat status bar transparan
      statusBarIconBrightness:
          Brightness
              .dark, // Ikon status bar gelap (cocok untuk background terang)
      statusBarBrightness: Brightness.light, // Untuk iOS (jika perlu)
    ),
  );

  // 3. Bungkus pemanggilan runApp dengan ChangeNotifierProvider
  runApp(
    ChangeNotifierProvider(
      // Fungsi 'create' ini akan membuat instance TodoListProvider
      // saat pertama kali dibutuhkan dan menyediakannya ke widget tree di bawahnya.
      create: (context) => TodoListProvider(),
      // Widget MyApp (dan seluruh aplikasinya) menjadi anak (child) dari Provider.
      // Artinya, semua widget di dalam MyApp bisa mengakses TodoListProvider.
      child: const MyApp(),
    ),
  );
}

// Widget root aplikasi Anda
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MyApp sekarang dibuat *di dalam* lingkup ChangeNotifierProvider.
    return MaterialApp(
      title: 'To-Do List App',
      theme: ThemeData(
        // Pengaturan tema dasar
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50], // Background umum scaffold
        fontFamily: 'Roboto', // Font default (opsional)
        visualDensity: VisualDensity.adaptivePlatformDensity,

        // Tema khusus untuk widget Chip (filter)
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

        // Tema khusus untuk Divider (pemisah list)
        dividerTheme: DividerThemeData(color: Colors.grey[200], thickness: 1),

        // Tema default untuk Icon
        iconTheme: IconThemeData(color: Colors.grey[600]),

        // Tema untuk TextButton (digunakan di AlertDialog)
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue[700], // Warna teks tombol
          ),
        ),

        // Tema untuk FloatingActionButton
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blueAccent, // Warna FAB
          elevation: 4.0, // Shadow FAB
        ),
      ),
      // Halaman awal aplikasi
      // HomeScreen akan dibuat sebagai turunan dari MaterialApp,
      // yang berarti juga turunan dari ChangeNotifierProvider di atasnya,
      // sehingga HomeScreen bisa mengakses TodoListProvider.
      home: const HomeScreen(),
      // Hilangkan banner debug di sudut kanan atas
      debugShowCheckedModeBanner: false,
    );
  }
}
