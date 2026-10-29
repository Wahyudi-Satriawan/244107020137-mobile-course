import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/route_parser.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handler terisolasi untuk background/terminated isolate
}

class PushService {
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  void Function(String route)? _onNavigate;
  String? _pendingRoute;

  PushService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  void setNavigationHandler(void Function(String route) onNavigate) {
    _onNavigate = onNavigate;
    if (_pendingRoute != null) {
      final route = _pendingRoute!;
      _pendingRoute = null;
      onNavigate(route);
    }
  }

  void _navigateTo(String route) {
    if (_onNavigate != null) {
      _onNavigate!(route);
    } else {
      _pendingRoute = route;
    }
  }

  Future<bool> requestNotificationPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.trim().isNotEmpty) {
          _navigateTo(payload.trim());
        }
      },
    );

    // Create Android Notification Channel for Android 8.0+
    const androidChannel = AndroidNotificationChannel(
      'campus_channel',
      'Pengumuman Kampus',
      description: 'Saluran notifikasi resmi pengumuman kampus',
      importance: Importance.high,
    );

    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(androidChannel);
    }
  }

  Future<void> initFcmToken({
    required Future<void> Function(String token) onToken,
  }) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await onToken(token);
    }

    _messaging.onTokenRefresh.listen((newToken) async {
      await onToken(newToken);
    });

    await _messaging.subscribeToTopic('pengumuman-kampus');
  }

  void initPushListeners() {
    // 1. Foreground FCM message -> Display local notification
    FirebaseMessaging.onMessage.listen((message) async {
      final route = routeFromMessage(message.data);

      const androidDetails = AndroidNotificationDetails(
        'campus_channel',
        'Pengumuman Kampus',
        channelDescription: 'Saluran notifikasi resmi pengumuman kampus',
        importance: Importance.high,
        priority: Priority.high,
      );

      await _localNotifications.show(
        id: message.hashCode,
        title: message.notification?.title ?? 'Pengumuman Baru',
        body:
            message.notification?.body ??
            'Ketuk untuk melihat detail pengumuman.',
        notificationDetails: const NotificationDetails(android: androidDetails),
        payload: route,
      );
    });

    // 2. Background -> Opened app by tapping FCM notification tray
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final route = routeFromMessage(message.data);
      _navigateTo(route);
    });
  }

  Future<void> handleInitialMessage() async {
    // 1. Terminated -> Launched via FCM remote notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      final route = routeFromMessage(initial.data);
      _navigateTo(route);
      return;
    }

    // 2. Terminated -> Launched via Local notification tap
    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null && payload.trim().isNotEmpty) {
        _navigateTo(payload.trim());
      }
    }
  }
}
