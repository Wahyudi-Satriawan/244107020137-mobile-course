import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/injection.dart';
import 'core/format.dart';
import 'core/services/push_service.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final container = ProviderContainer();
  final pushService = container.read(pushServiceProvider);

  await pushService.requestNotificationPermission();
  await pushService.initLocalNotifications();
  pushService.initPushListeners();

  await pushService.initFcmToken(
    onToken: (token) async {
      final truncated = truncateToken(token);
      container.read(fcmTokenProvider.notifier).setToken(truncated);
    },
  );

  // Eagerly read routerProvider so the navigation handler is registered
  container.read(routerProvider);

  // Handle launch from terminated state via remote message or local notification
  await pushService.handleInitialMessage();

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
