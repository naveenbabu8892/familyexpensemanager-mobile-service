import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/user_repository_impl.dart';
import '../domain/user_repository.dart';

/// State of Profile screen operations.
@immutable
class ProfileViewState {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const ProfileViewState({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  ProfileViewState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
  }) {
    return ProfileViewState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

/// Profile controller managing editing profile info (name, phone, avatar) via `PUT /users/me`.
class ProfileController extends Notifier<ProfileViewState> {
  final UserRepository? _injectedUserRepo;

  ProfileController({UserRepository? userRepository})
      : _injectedUserRepo = userRepository;

  UserRepository get _userRepository =>
      _injectedUserRepo ?? ref.read(userRepositoryProvider);

  @override
  ProfileViewState build() {
    return const ProfileViewState();
  }

  /// Updates current user profile details via `PUT /users/me`
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);
    try {
      await _userRepository.updateCurrentUser(
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
      );

      // Also sync back to authStateProvider so all screens (Dashboard, Shell, etc.) reflect latest details immediately
      final authController = ref.read(authControllerProvider.notifier);
      final currentAuth = ref.read(authStateProvider);
      if (currentAuth.isAuthenticated) {
        // Refresh auth state with new user object
        await authController.refreshProfile();
      }

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Profile updated successfully!',
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'An unexpected error occurred while updating profile.',
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

/// Provider for ProfileController
final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileViewState>(() {
  return ProfileController();
});
