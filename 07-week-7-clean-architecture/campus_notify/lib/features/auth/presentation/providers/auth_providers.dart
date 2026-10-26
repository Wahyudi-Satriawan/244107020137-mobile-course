import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';

// Presentation layer state
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final repository = ref.watch(authRepositoryProvider);
    return repository.isLoggedIn();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(loginUseCaseProvider).call(
            email: email,
            password: password,
          );
      return true;
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.invalidateSelf();
  }
}
