// lib/services/notification_service.dart
import 'package:flutter/foundation.dart'; // Untuk defaultTargetPlatform
import 'package:flutter/material.dart'; // Diperlukan oleh @pragma
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzl;
// Flutter native timezone import dihapus
import '../models/todo.dart'; // Sesuaikan path jika model Todo Anda di lokasi berbeda
// import 'dart:math'; // Untuk fallback ID generator

class NotificationService {
  // Singleton pattern setup
  static final NotificationService _notificationService =
      NotificationService._internal();
  factory NotificationService() => _notificationService;
  NotificationService._internal();

  // Instance plugin notifikasi
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Konstanta untuk Channel Android
  static const String _androidChannelId = 'todo_deadline_channel_v1';
  static const String _androidChannelName =
      'Pengingat Tugas & Deadline'; // Nama diperbaiki
  static const String _androidChannelDesc =
      'Notifikasi untuk deadline dan pengingat tugas ToDo'; // Deskripsi diperbaiki

  /// Menginisialisasi service notifikasi, timezone, dan meminta izin.
  Future<void> initialize() async {
    try {
      // 1. Inisialisasi Database Zona Waktu
      tzl.initializeTimeZones();

      // 2. Dapatkan dan Set Zona Waktu Lokal
      await _configureLocalTimeZone();

      // 3. Setting Inisialisasi Spesifik Platform
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@drawable/app_icon');

      // Setting untuk iOS/macOS
      final DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
            requestAlertPermission: false, // Izin diminta terpisah
            requestBadgePermission: false,
            requestSoundPermission: false,
          );

      // 4. Gabungkan Setting Platform
      final InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
            macOS: initializationSettingsDarwin,
          );

      // 5. Inisialisasi Plugin dengan handler tap notifikasi
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      // 6. Buat Channel Notifikasi Android (Penting untuk Android 8+)
      await _createAndroidNotificationChannel();

      // 7. Minta Izin Notifikasi
      await requestPermissions();
    } catch (e) {
      print('Error during initialization: $e');
    }
  }

  /// Konfigurasi zona waktu lokal menggunakan DateTime bulit-in
  Future<void> _configureLocalTimeZone() async {
    String timeZoneName;
    try {
      // Menggunakan DateTime built-in untuk mendapatkan timezone
      timeZoneName = DateTime.now().timeZoneName;
      print('Timezone detected by DateTime: $timeZoneName');

      // Jika timezone nama pendek (seperti WIB, GMT, dll) gunakan fallback
      if (timeZoneName.length <= 4) {
        timeZoneName = 'Asia/Jakarta'; // Default untuk Indonesia
        print('Using fallback timezone: $timeZoneName');
      }
    } catch (e) {
      print("Error getting timezone: $e. Using default fallback.");
      timeZoneName = 'Asia/Jakarta'; // Ganti default jika perlu
    }

    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print('Timezone for scheduling set to: $timeZoneName');
    } catch (e) {
      print(
        "Error setting timezone location for '$timeZoneName': $e. Using ultimate fallback.",
      );
      const String ultimateFallbackTimeZone =
          'Asia/Jakarta'; // Fallback darurat
      tz.setLocalLocation(tz.getLocation(ultimateFallbackTimeZone));
      print(
        'Timezone for scheduling set using ultimate fallback: $ultimateFallbackTimeZone',
      );
    }
  }

  /// Membuat Channel Notifikasi Android
  Future<void> _createAndroidNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDesc,
      importance: Importance.max,
      playSound: true,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    print(
      "Android Notification Channel '$_androidChannelId' created or updated.",
    );
  }

  /// Meminta izin notifikasi kepada pengguna (iOS & Android 13+)
  Future<bool> requestPermissions() async {
    bool result = false; // Default ke false

    // iOS & macOS Permissions
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Coba minta izin iOS
      final bool? iosResult = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      result = iosResult ?? false; // Gunakan hasil iOS jika ada
      print("iOS Permission Request Result: $result");
    }
    // Penanganan macOS secara terpisah
    else if (defaultTargetPlatform == TargetPlatform.macOS) {
      final bool? macOsResult = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      result = macOsResult ?? false; // Gunakan hasil macOS jika ada
      print("macOS Permission Request Result: $result");
    }
    // Android Permissions (Android 13+)
    else if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      if (androidImplementation != null) {
        // requestNotificationsPermission() sudah diperkenalkan di versi baru untuk API 33+
        final bool? androidResult =
            await androidImplementation.requestNotificationsPermission();
        result = androidResult ?? false;
        print("Android Permission Request Result: $result");
      }
    }

    return result;
  }

  /// Handler saat notifikasi di-tap (app di foreground/background/terminated)
  Future<void> onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    final String? payload = notificationResponse.payload;
    print('NOTIFICATION TAPPED (Response): Payload: $payload');
    if (payload != null) {
      if (payload.startsWith('todo_id=')) {
        final todoId = payload.substring('todo_id='.length);
        print('Tapped DEADLINE notification for Todo ID: $todoId');
        // TODO: Implementasikan navigasi atau aksi berdasarkan todoId
      } else if (payload.startsWith('reminder_todo_id=')) {
        final todoId = payload.substring('reminder_todo_id='.length);
        print('Tapped REMINDER notification for Todo ID: $todoId');
        // TODO: Implementasikan navigasi atau aksi berdasarkan todoId
      }
    }
  }

  /// Handler notifikasi di-tap saat app di background/terminated (Android primarily)
  /// Harus top-level function atau static method
  @pragma('vm:entry-point')
  static void notificationTapBackground(
    NotificationResponse notificationResponse,
  ) {
    print(
      'NOTIFICATION TAPPED (Background): Payload: ${notificationResponse.payload}',
    );
    // Aksi terbatas di sini
  }

  /// Helper untuk generate ID notifikasi integer 32-bit dari ID Todo string
  /// dengan parameter prefix untuk membedakan jenis notifikasi
  int _generateNotificationId(String todoId, {String prefix = 'd'}) {
    // Tentukan kode awalan berdasarkan jenis notifikasi
    int prefixCode = (prefix == 'r') ? 2000000 : 1000000;

    // Ekstrak digit dari todoId
    var numericPart = todoId.replaceAll(RegExp(r'[^0-9]'), '');

    // Proses numerik atau hashcode
    int baseId;
    if (numericPart.isEmpty) {
      // Tidak ada digit numerik, gunakan hashcode
      baseId = todoId.hashCode.abs() % 1000000;
    } else {
      // Ada digit numerik, ambil 6 digit terakhir jika perlu
      if (numericPart.length > 6) {
        numericPart = numericPart.substring(numericPart.length - 6);
      }
      baseId = int.tryParse(numericPart) ?? todoId.hashCode.abs() % 1000000;
    }

    // Gabungkan prefixCode dengan baseId
    int notificationId = prefixCode + baseId;

    // Pastikan dalam range valid integer 32-bit
    return notificationId.abs() % 2147483647;
  }

  /// Menjadwalkan notifikasi DEADLINE untuk sebuah Todo
  /// Fungsi ini menggantikan scheduleNotification untuk konsistensi penamaan
  Future<void> scheduleDeadlineNotification(Todo todo) async {
    if (todo.deadline == null || todo.deadline!.isBefore(DateTime.now())) {
      await cancelDeadlineNotification(todo.id);
      print("Skipping schedule for DEADLINE ${todo.title}: No valid deadline.");
      return;
    }

    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      todo.deadline!,
      tz.local,
    );
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      print(
        "Attempted to schedule DEADLINE notification in the past for ${todo.title}. Cancelling any existing.",
      );
      await cancelDeadlineNotification(todo.id);
      return;
    }

    // Detail Notifikasi
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDesc,
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'Pengingat Tugas',
          playSound: true,
          icon: '@drawable/app_icon',
        );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    final int notificationId = _generateNotificationId(todo.id, prefix: 'd');

    // Lakukan penjadwalan
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Deadline: ${todo.title}',
        'Jangan lupa selesaikan tugas "${todo.title}"!',
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'todo_id=${todo.id}',
      );
      print(
        "Scheduled DEADLINE notification for ${todo.title} at $scheduledDate (Notif ID: $notificationId, Todo ID: ${todo.id})",
      );
    } catch (e) {
      print(
        "Error scheduling DEADLINE notification ID $notificationId for ${todo.title}: $e",
      );
    }
  }

  /// Membatalkan notifikasi DEADLINE terjadwal berdasarkan ID Todo
  Future<void> cancelDeadlineNotification(String todoId) async {
    final int notificationId = _generateNotificationId(todoId, prefix: 'd');
    try {
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      print(
        "Cancelled DEADLINE notification for Todo ID: $todoId (Notif ID: $notificationId)",
      );
    } catch (e) {
      print(
        "Error cancelling DEADLINE notification $todoId (Notif ID: $notificationId): $e",
      );
    }
  }

  /// Menjadwalkan notifikasi REMINDER untuk sebuah Todo
  Future<void> scheduleReminderNotification(Todo todo) async {
    if (todo.reminderDateTime == null ||
        todo.reminderDateTime!.isBefore(DateTime.now())) {
      await cancelReminderNotification(todo.id);
      print(
        "Skipping schedule REMINDER for ${todo.title}: No valid reminder time.",
      );
      return;
    }

    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      todo.reminderDateTime!,
      tz.local,
    );
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      print("Attempted to schedule REMINDER in the past for ${todo.title}.");
      await cancelReminderNotification(todo.id);
      return;
    }

    // Detail Notifikasi
    const AndroidNotificationDetails reminderAndroidDetails =
        AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDesc,
          importance: Importance.high,
          priority: Priority.defaultPriority,
          playSound: true,
          icon: '@drawable/app_icon',
        );
    const DarwinNotificationDetails reminderIosDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
    const NotificationDetails reminderPlatformDetails = NotificationDetails(
      android: reminderAndroidDetails,
      iOS: reminderIosDetails,
      macOS: reminderIosDetails,
    );

    final int notificationId = _generateNotificationId(todo.id, prefix: 'r');

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Pengingat: ${todo.title}',
        'Jangan lupa tentang tugas "${todo.title}".',
        scheduledDate,
        reminderPlatformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'reminder_todo_id=${todo.id}',
      );
      print(
        "Scheduled REMINDER notification for ${todo.title} at $scheduledDate (Notif ID: $notificationId, Todo ID: ${todo.id})",
      );
    } catch (e) {
      print(
        "Error scheduling REMINDER notification ID $notificationId for ${todo.title}: $e",
      );
    }
  }

  /// Membatalkan notifikasi REMINDER terjadwal berdasarkan ID Todo
  Future<void> cancelReminderNotification(String todoId) async {
    final int notificationId = _generateNotificationId(todoId, prefix: 'r');
    try {
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      print(
        "Cancelled REMINDER notification for Todo ID: $todoId (Notif ID: $notificationId)",
      );
    } catch (e) {
      print(
        "Error cancelling REMINDER notification $todoId (Notif ID: $notificationId): $e",
      );
    }
  }

  /// Untuk kompatibilitas dengan kode lama - panggil scheduleDeadlineNotification
  Future<void> scheduleNotification(Todo todo) async {
    await scheduleDeadlineNotification(todo);
  }

  /// Untuk kompatibilitas dengan kode lama - panggil cancelDeadlineNotification
  Future<void> cancelNotification(String todoId) async {
    await cancelDeadlineNotification(todoId);
  }

  /// Membatalkan semua notifikasi terjadwal (gunakan hati-hati)
  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      print("Cancelled ALL scheduled notifications (Deadlines and Reminders)");
    } catch (e) {
      print("Error cancelling all notifications: $e");
    }
  }
} // Akhir Class NotificationService
