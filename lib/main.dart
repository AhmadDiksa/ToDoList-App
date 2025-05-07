// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/splash_screen.dart'; // Layar awal
import 'providers/todo_list_provider.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  // Pastikan Flutter binding siap sebelum plugin/async
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Notification Service (termasuk timezone)
  await NotificationService().initialize();

  // Setup System UI Overlay
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:
          Colors.transparent, // Transparan agar background body terlihat
      statusBarIconBrightness:
          Brightness.dark, // Ikon status bar gelap (untuk background terang)
      statusBarBrightness: Brightness.light, // Untuk iOS
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => TodoListProvider(), // Buat instance provider
      child: const MyApp(), // Child-nya adalah aplikasi utama kita
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List App',
      // --- Setup Localizations untuk Bahasa Indonesia ---
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', ''), // Bahasa Indonesia
        Locale('en', ''), // Bahasa Inggris (sebagai fallback)
      ],
      locale: const Locale('id', ''), // Set default locale ke Indonesia
      // --- Akhir Setup Localizations ---
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          // Tema default untuk AppBar
          backgroundColor: Colors.grey[50],
          foregroundColor: Colors.black87, // Warna ikon dan teks di AppBar
          elevation: 0.5,
          systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
            // Pastikan status bar tetap gelap
            statusBarColor: Colors.transparent,
          ),
          titleTextStyle: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w500, // Sedikit tebal untuk judul AppBar
          ),
          iconTheme: const IconThemeData(
            color: Colors.black54,
          ), // Warna ikon di AppBar
        ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 0,
        ),
        dividerTheme: DividerThemeData(color: Colors.grey[200], thickness: 1),
        iconTheme: IconThemeData(color: Colors.grey[600]),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.blue[700]),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blueAccent,
          elevation: 4.0,
          foregroundColor: Colors.white,
        ),
        listTileTheme: const ListTileThemeData(
          // Tema default untuk ListTile
          dense: true, // Membuat ListTile lebih rapat
          contentPadding: EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 0,
          ), // Hapus padding default jika perlu
        ),
      ),
      home: const SplashScreen(), // Mulai dari SplashScreen
      debugShowCheckedModeBanner: false,
    );
  }
}
