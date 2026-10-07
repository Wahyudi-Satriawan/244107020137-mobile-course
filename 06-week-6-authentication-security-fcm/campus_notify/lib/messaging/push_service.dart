import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/route_parser.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handler terisolasi untuk background/terminated isolate
}

class PushService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static String? pendingDeepLink;

  static Future<bool> requestNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  static Future<void> initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          pendingDeepLink = response.payload;
        }
      },
    );
  }

  static Future<void> initFcmToken({
    required Future<void> Function(String token) onToken,
  }) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await onToken(token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await onToken(newToken);
    });

    await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
  }

  static void listenForeground(void Function(String route) navigateTo) {
    FirebaseMessaging.onMessage.listen((message) async {
      final route = routeFromMessage(message.data);

      const androidDetails = AndroidNotificationDetails(
        'campus_channel',
        'Pengumuman Kampus',
        importance: Importance.high,
        priority: Priority.high,
      );

      await _localNotifications.show(
        id: message.hashCode,
        title: message.notification?.title ?? 'Pengumuman Baru',
        body: message.notification?.body ?? 'Ketuk untuk melihat detail pengumuman.',
        notificationDetails: const NotificationDetails(android: androidDetails),
        payload: route,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final route = routeFromMessage(message.data);
      navigateTo(route);
    });
  }

  static Future<void> handleTerminated(
      void Function(String route) navigateTo) async {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      final route = routeFromMessage(initial.data);
      navigateTo(route);
    } else if (pendingDeepLink != null) {
      navigateTo(pendingDeepLink!);
      pendingDeepLink = null;
    }
  }
}