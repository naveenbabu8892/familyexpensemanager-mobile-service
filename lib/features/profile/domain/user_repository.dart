import '../../auth/domain/user.dart';

/// Abstract contract for User and Profile management repository.
abstract class UserRepository {
  Future<User> getCurrentUser();
  Future<User> updateCurrentUser({
    String? fullName,
    String? phone,
    String? avatarUrl,
  });
}

/// Backward compatibility alias
typedef ProfileRepository = UserRepository;
