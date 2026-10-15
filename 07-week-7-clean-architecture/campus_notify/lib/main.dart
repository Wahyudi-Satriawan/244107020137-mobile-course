import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/format.dart';
import 'core/services/push_service.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await PushService.requestNotificationPermission();
  await PushService.initLocalNotifications();

  final container = ProviderContainer();

  await PushService.initFcmToken(
    onToken: (token) async {
      final truncated = truncateToken(token);
      container.read(fcmTokenProvider.notifier).setToken(truncated);
    },
  );

  final router = container.read(routerProvider);
  PushService.listenForeground((route) => router.go(route));
  PushService.handleTerminated((route) => router.go(route));

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CampusNotifyApp(),
    ),
  );
}

class CampusNotifyApp extends ConsumerWidget {
  const CampusNotifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Campus Notify',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
