import Flutter
import UIKit
import UserNotifications // <-- 1. Import UserNotifications framework

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // --- 2. Tambahkan Konfigurasi Notifikasi Lokal iOS di sini ---
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
      print("AppDelegate: UNUserNotificationCenter delegate set.") // Opsional: Logging
    } else {
      // Fallback untuk versi iOS < 10 (jika masih perlu didukung)
      // Biasanya tidak perlu lagi
    }
    // ---------------------------------------------------------

    GeneratedPluginRegistrant.register(with: self) // Registrasi plugin Flutter
    return super.application(application, didFinishLaunchingWithOptions: launchOptions) // Panggil implementasi superclass
  }

  // Opsional: Jika Anda perlu menangani notifikasi foreground secara native
  // (Biasanya sudah ditangani oleh plugin melalui method channel)
  /*
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                         willPresent notification: UNNotification,
                                         withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
      // Tentukan bagaimana notifikasi ditampilkan saat app di foreground
      // [.alert, .badge, .sound] akan menampilkan alert, badge, dan memainkan suara
      completionHandler([.alert, .badge, .sound])
  }
  */
}