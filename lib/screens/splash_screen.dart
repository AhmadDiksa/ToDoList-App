// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart'; // Import HomeScreen Anda

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Timer untuk durasi splash screen
    Timer(const Duration(seconds: 3), () { // Atur durasi (misal 3 detik)
      // Navigasi ke HomeScreen dan hapus SplashScreen dari stack
      if (mounted) { // Pastikan widget masih ada di tree sebelum navigasi
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple, // Contoh warna background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Tampilkan logo Anda
            Image.asset(
              'assets/images/logo.png', // Ganti dengan path logo Anda
              width: 150, // Sesuaikan ukuran logo
              height: 150,
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome To Todos', // Nama aplikasi Anda
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // --- CircularProgressIndicator DIHAPUS dari sini ---
            // const SizedBox(height: 16), // SizedBox ini juga bisa dihapus jika tidak perlu jarak tambahan
            // const CircularProgressIndicator(
            //   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            // ),
          ],
        ),
      ),
    );
  }
}