\# Dokumentasi AI Challenge - Refactoring \& Testing FCM Service



\## 1. Prompt Utama yang Digunakan

"Aplikasi Flutter Campus Notification App. Stack: firebase\_messaging, flutter\_local\_notifications, flutter\_secure\_storage, go\_router, Riverpod. Buatkan PushService dengan: requestPermission, getToken, onTokenRefresh (kirim ke POST /devices), onMessage (tampilkan notification manual), onMessageOpenedApp, getInitialMessage (navigasi ke data.route), subscribe/unsubscribe topic pengumuman-kampus, background handler top-level dengan @pragma('vm:entry-point'). Tangani bagian yang BERBEDA untuk Android 13 vs iOS, dan bagian yang tidak boleh mengakses BuildContext."



\## 2. Output Awal AI

AI menghasilkan fungsi parsing route yang menerima instans `RemoteMessage` secara langsung:

```dart

String parseRoute(RemoteMessage message) {

&#x20; return message.data\['route'];

}

