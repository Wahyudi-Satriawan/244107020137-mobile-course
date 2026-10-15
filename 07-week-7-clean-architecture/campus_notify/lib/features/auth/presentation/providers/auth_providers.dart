import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/token_store.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';

// DI Data layer
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());
final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepositoryImpl());

// DI Domain layer (Use Case)
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

// Presentation layer state
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await ref.watch(tokenStoreProvider).readAccess();
    return token != null && token.isNotEmpty;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final session = await ref.read(loginUseCaseProvider).call(
            email: email,
            password: password,
          );
      await ref.read(tokenStoreProvider).save(
            access: session.access,
            refresh: session.refresh,
          );
      return true;
    });
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    ref.invalidateSelf();
  }
}
