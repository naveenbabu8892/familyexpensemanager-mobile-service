import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/domain/user.dart';
import '../domain/profile_repository.dart';

export 'user_repository_impl.dart';

/// Concrete implementation of [ProfileRepository] & [UserRepository].
class ProfileRepositoryImpl implements ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepositoryImpl(this._apiClient);

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
    final response = await _apiClient.put(
      ApiEndpoints.usersMe,
      data: {
        if (fullName != null) 'full_name': fullName.trim(),
        if (phone != null) 'phone': phone.trim(),
        if (avatarUrl != null) 'avatar_url': avatarUrl.trim(),
      },
    );
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<User> getProfile() => getCurrentUser();

  @override
  Future<User> updateProfile({String? fullName, String? phone, String? avatarUrl}) =>
      updateCurrentUser(fullName: fullName, phone: phone, avatarUrl: avatarUrl);
}

/// Riverpod provider for [ProfileRepository].
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(apiClientProvider));
});

/// Riverpod FutureProvider for user profile.
final userProfileProvider = FutureProvider<User>((ref) async {
  return ref.watch(profileRepositoryProvider).getProfile();
});
