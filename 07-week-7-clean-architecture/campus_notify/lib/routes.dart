import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection.dart';
import 'features/announcements/presentation/pages/announcement_page.dart';
import 'features/announcements/presentation/pages/home_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/notes/presentation/pages/notes_page.dart';

final fcmTokenProvider = NotifierProvider<FcmTokenNotifier, String>(
  FcmTokenNotifier.new,
);

class FcmTokenNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setToken(String token) {
    state = token;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final pushService = ref.watch(pushServiceProvider);

  // ValueNotifier bridge to react to authStateProvider without rebuilding GoRouter
  final authNotifierListenable = ValueNotifier<bool>(
    ref.read(authStateProvider).value ?? false,
  );

  ref.listen<AsyncValue<bool>>(authStateProvider, (_, next) {
    authNotifierListenable.value = next.value ?? false;
  });

  ref.onDispose(authNotifierListenable.dispose);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifierListenable,
    redirect: (context, state) {
      final loggedIn = ref.read(authStateProvider).value ?? false;
      final goingToLogin = state.matchedLocation == '/login';

      if (!loggedIn && !goingToLogin) return '/login';
      if (loggedIn && goingToLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/',
        builder: (context, state) => Consumer(
          builder: (context, ref, child) {
            final token = ref.watch(fcmTokenProvider);
            return HomePage(truncatedToken: token);
          },
        ),
      ),
      GoRoute(
        path: '/pengumuman/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '1';
          return AnnouncementPage(id: id);
        },
      ),
      GoRoute(path: '/notes', builder: (context, state) => const NotesPage()),
    ],
  );

  // Wire PushService navigation directly to this persistent GoRouter instance
  pushService.setNavigationHandler((route) {
    router.go(route);
  });

  return router;
});
