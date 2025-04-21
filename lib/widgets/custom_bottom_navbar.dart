// lib/widgets/custom_bottom_navbar.dart
import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex; // Indeks item yang sedang aktif
  final ValueChanged<int> onTap; // Callback saat item di-tap

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Definisikan item-item navbar di sini
    const List<BottomNavigationBarItem> navBarItems = [
      BottomNavigationBarItem(
        icon: Icon(Icons.task_alt_outlined),
        activeIcon: Icon(Icons.task_alt),
        label: 'Tugas',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today_outlined),
        activeIcon: Icon(Icons.calendar_today),
        label: 'Kalender',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Milikku',
      ),
    ];

    // Return widget BottomNavigationBar
    return BottomNavigationBar(
      items: navBarItems, // Gunakan list item yang sudah didefinisikan
      currentIndex: currentIndex, // Gunakan indeks dari parameter
      selectedItemColor: Colors.blue[700],
      unselectedItemColor: Colors.grey[600],
      onTap: onTap, // Panggil callback dari parameter saat di-tap
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      backgroundColor: Colors.white,
      elevation: 8.0,
      selectedFontSize: 12,
      unselectedFontSize: 12,
    );
  }
}
