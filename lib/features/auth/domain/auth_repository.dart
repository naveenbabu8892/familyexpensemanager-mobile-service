import 'auth_tokens.dart';
import 'user.dart';

/// Abstract contract for Authentication repository.
abstract class AuthRepository {
  Future<AuthTokens> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  });

  Future<AuthTokens> login({
    required String email,
    required String password,
  });

  Future<AuthTokens> refreshToken(String refreshToken);

  Future<void> logout();

  Future<User> getCurrentUser();

  Future<bool> isAuthenticated();
}
