import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/push_service.dart';
import '../storage/token_store.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';

// Services / Core
final pushServiceProvider = Provider<PushService>((ref) {
  return PushService();
});

// Storage / Core
final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore();
});

// Auth Feature - Data Layer
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(tokenStore: ref.watch(tokenStoreProvider));
});

// Auth Feature - Domain Layer (Use Cases)
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});
