import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> login({required String email, required String password});
  Future<String> refresh(String refreshToken);
  Future<bool> isLoggedIn();
  Future<void> logout();
}
