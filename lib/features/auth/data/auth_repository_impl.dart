import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_tokens.dart';
import '../domain/user.dart';

/// Concrete implementation of [AuthRepository] consuming FastAPI endpoints.
class AuthRepositoryImpl implements AuthRepository {
  final ApiClient apiClient;
  final SecureStorageService storage;

  AuthRepositoryImpl({
    required this.apiClient,
    required this.storage,
  });

  @override
  Future<AuthTokens> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final payload = <String, dynamic>{
      'full_name': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    };
    if (phone != null && phone.trim().isNotEmpty) {
      payload['phone'] = phone.trim();
    }

    final response = await apiClient.post(
      ApiEndpoints.register,
      data: payload,
    );

    final tokens = AuthTokens.fromJson(response.data as Map<String, dynamic>);
    await _persistTokens(tokens);
    return tokens;
  }

  @override
  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    final tokens = AuthTokens.fromJson(response.data as Map<String, dynamic>);
    await _persistTokens(tokens);
    return tokens;
  }

  @override
  Future<AuthTokens> refreshToken(String refreshToken) async {
    final response = await apiClient.post(
      ApiEndpoints.refresh,
      data: {'refresh_token': refreshToken},
    );

    final tokens = AuthTokens.fromJson(response.data as Map<String, dynamic>);
    await _persistTokens(tokens);
    return tokens;
  }

  @override
  Future<void> logout() async {
    try {
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken != null) {
        await apiClient.post(
          ApiEndpoints.logout,
          data: {'refresh_token': refreshToken},
        );
      }
    } finally {
      await storage.clearAuthSession();
    }
  }

  @override
  Future<User> getCurrentUser() async {
    final response = await apiClient.get(ApiEndpoints.usersMe);
    final user = User.fromJson(response.data as Map<String, dynamic>);
    await storage.write('fem_user_id', user.id);
    return user;
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await storage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> _persistTokens(AuthTokens tokens) async {
    await storage.setAccessToken(tokens.accessToken);
    await storage.setRefreshToken(tokens.refreshToken);
  }
}

/// Riverpod provider for [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    storage: ref.watch(secureStorageProvider),
  );
});
