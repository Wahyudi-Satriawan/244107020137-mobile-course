import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'messaging/push_service.dart';
import 'pages/announcement_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';

String globalTruncatedToken = '';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await PushService.requestNotificationPermission();
  await PushService.initLocalNotifications();

  await PushService.initFcmToken(
    onToken: (token) async {
      globalTruncatedToken =
          token.length > 12 ? '${token.substring(0, 12)}...' : token;
    },
  );

  runApp(const ProviderScope(child: CampusNotifyApp()));
}

class CampusNotifyApp extends ConsumerWidget {
  const CampusNotifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final loggedIn = ref.watch(authStateProvider).value ?? false;
        final goingToLogin = state.matchedLocation == '/login';

        if (!loggedIn && !goingToLogin) return '/login';
        if (loggedIn && goingToLogin) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) =>
              HomePage(truncatedToken: globalTruncatedToken),
        ),
        GoRoute(
          path: '/pengumuman/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '1';
            return AnnouncementPage(id: id);
          },
        ),
      ],
    );

    PushService.listenForeground((route) => router.go(route));
    PushService.handleTerminated((route) => router.go(route));

    return MaterialApp.router(
      title: 'Campus Notify',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}