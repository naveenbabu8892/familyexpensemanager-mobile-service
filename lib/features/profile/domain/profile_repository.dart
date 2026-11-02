import '../../auth/domain/user.dart';
import 'user_repository.dart';

export 'user_repository.dart';

/// Abstract contract for Profile repository (specialization / alias of UserRepository).
abstract class ProfileRepository implements UserRepository {
  Future<User> getProfile();
  Future<User> updateProfile({String? fullName, String? phone, String? avatarUrl});
}
