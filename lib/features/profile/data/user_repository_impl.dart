import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/domain/user.dart';
import '../domain/user_repository.dart';

/// Concrete implementation of [UserRepository] consuming FastAPI endpoints.
class UserRepositoryImpl implements UserRepository {
  final ApiClient _apiClient;

  UserRepositoryImpl(this._apiClient);

  @override
  Future<User> getCurrentUser() async {
    final response = await _apiClient.get(ApiEndpoints.usersMe);
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<User> updateCurrentUser({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final payload = <String, dynamic>{};
    if (fullName != null) payload['full_name'] = fullName.trim();
    if (phone != null) payload['phone'] = phone.trim();
    if (avatarUrl != null) payload['avatar_url'] = avatarUrl.trim();

    final response = await _apiClient.put(
      ApiEndpoints.usersMe,
      data: payload,
    );
    return User.fromJson(response.data as Map<String, dynamic>);
  }
}

/// Backward compatibility alias
typedef ProfileRepositoryImpl = UserRepositoryImpl;

/// Riverpod provider for [UserRepository].
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(apiClientProvider));
});

/// Backward compatibility provider alias
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ref.watch(userRepositoryProvider);
});
