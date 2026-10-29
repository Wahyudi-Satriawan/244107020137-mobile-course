import '../../../../core/storage/token_store.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final TokenStore _tokenStore;

  AuthRepositoryImpl({TokenStore? tokenStore})
    : _tokenStore = tokenStore ?? TokenStore();

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final session = AuthSession(
      access: 'mock-access-for-$email',
      refresh: 'mock-refresh-for-$email',
    );

    await _tokenStore.save(access: session.access, refresh: session.refresh);

    return session;
  }

  @override
  Future<String> refresh(String refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (refreshToken.isEmpty) {
      throw Exception('Refresh token hilang');
    }

    final renewed =
        'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}';
    final currentRefresh = await _tokenStore.readRefresh() ?? refreshToken;
    await _tokenStore.save(access: renewed, refresh: currentRefresh);
    return renewed;
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _tokenStore.readAccess();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> logout() async {
    await _tokenStore.clear();
  }
}
