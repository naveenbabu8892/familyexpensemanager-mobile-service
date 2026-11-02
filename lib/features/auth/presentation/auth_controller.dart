import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../family/data/family_repository_impl.dart';
import '../../family/domain/family.dart';
import '../../family/domain/family_repository.dart';
import '../../profile/data/user_repository_impl.dart';
import '../../profile/domain/user_repository.dart';
import '../data/auth_repository_impl.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_state.dart';

/// Riverpod NotifierProvider managing the authentication lifecycle.
final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});

/// Riverpod convenience selector for current AuthState.
final authStateProvider = Provider<AuthState>((ref) {
  return ref.watch(authControllerProvider);
});

/// Riverpod 3 Notifier responsible for authentication flows, validation, and session coordination.
class AuthController extends Notifier<AuthState> {
  // Direct dependencies (can be overridden in tests via provider overrides or optional constructor)
  final AuthRepository? _injectedAuthRepo;
  final UserRepository? _injectedUserRepo;
  final FamilyRepository? _injectedFamilyRepo;
  final SecureStorageService? _injectedStorage;

  AuthController({
    AuthRepository? authRepository,
    UserRepository? userRepository,
    FamilyRepository? familyRepository,
    SecureStorageService? storage,
  })  : _injectedAuthRepo = authRepository,
        _injectedUserRepo = userRepository,
        _injectedFamilyRepo = familyRepository,
        _injectedStorage = storage;

  @override
  AuthState build() {
    return const AuthState.initial();
  }

  AuthRepository get _authRepository =>
      _injectedAuthRepo ?? ref.read(authRepositoryProvider);
  UserRepository get _userRepository =>
      _injectedUserRepo ?? ref.read(userRepositoryProvider);
  FamilyRepository get _familyRepository =>
      _injectedFamilyRepo ?? ref.read(familyRepositoryProvider);
  SecureStorageService get _storage =>
      _injectedStorage ?? ref.read(secureStorageProvider);

  /// Checks existing stored tokens on startup, validates credentials with backend,
  /// resolves the user's family membership, and updates state.
  Future<AuthState> checkAuthStatus() async {
    state = const AuthState.loading();
    try {
      final token = await _storage.getAccessToken();
      if (token == null || token.isEmpty) {
        state = const AuthState.unauthenticated();
        return state;
      }

      // Fetch user profile
      final user = await _userRepository.getCurrentUser();

      // Determine family membership
      Family? family;
      try {
        family = await _familyRepository.getCurrentFamily();
      } catch (e) {
        debugPrint('Family resolution note: $e');
        family = null;
      }

      state = AuthState.authenticated(user: user, family: family);
      return state;
    } on UnauthorizedException {
      // Invalid or expired token that could not be refreshed
      await _storage.clearAuthSession();
      state = const AuthState.unauthenticated();
      return state;
    } catch (e) {
      debugPrint('Startup checkAuthStatus error: $e');
      final message = e is ApiException
          ? e.message
          : 'Could not connect to server. Please try again.';
      state = AuthState.error(message: message);
      return state;
    }
  }

  /// Authenticate user credentials, fetch profile and family status.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    try {
      await _authRepository.login(
        email: email.trim(),
        password: password,
      );

      final user = await _userRepository.getCurrentUser();

      Family? family;
      try {
        family = await _familyRepository.getCurrentFamily();
      } catch (_) {
        family = null;
      }

      state = AuthState.authenticated(user: user, family: family);
      return true;
    } on ApiException catch (e) {
      Map<String, String>? fieldErrors;
      if (e is ValidationException && e.fieldErrors != null) {
        fieldErrors = e.fieldErrors!.map((k, v) => MapEntry(k, v.toString()));
      }
      state = AuthState.error(
        message: e.message,
        fieldErrors: fieldErrors,
      );
      return false;
    } catch (e) {
      state = const AuthState.error(
        message: 'An unexpected error occurred during login. Please try again.',
      );
      return false;
    }
  }

  /// Register a new account, validate profile, and initiate family setup.
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = const AuthState.loading();
    try {
      await _authRepository.register(
        fullName: fullName.trim(),
        email: email.trim(),
        password: password,
        phone: phone?.trim(),
      );

      final user = await _userRepository.getCurrentUser();
      // Fresh user has no family initially
      state = AuthState.authenticated(user: user, family: null);
      return true;
    } on ApiException catch (e) {
      Map<String, String>? fieldErrors;
      if (e is ValidationException && e.fieldErrors != null) {
        fieldErrors = e.fieldErrors!.map((k, v) => MapEntry(k, v.toString()));
      }
      state = AuthState.error(
        message: e.message,
        fieldErrors: fieldErrors,
      );
      return false;
    } catch (e) {
      state = const AuthState.error(
        message: 'Registration failed. Please check your information and try again.',
      );
      return false;
    }
  }

  /// Revoke session tokens and return to unauthenticated state.
  Future<void> logout() async {
    state = const AuthState.loading();
    try {
      await _authRepository.logout();
    } catch (e) {
      debugPrint('Logout error (clearing local session anyway): $e');
      await _storage.clearAuthSession();
    } finally {
      state = const AuthState.unauthenticated();
    }
  }

  /// Called by AuthInterceptor when refresh fails or session is revoked.
  void handleSessionExpired() {
    _storage.clearAuthSession();
    state = const AuthState.unauthenticated();
  }

  /// Update active family after creation or accepting an invite.
  void setFamily(Family family) {
    if (state.isAuthenticated && state.user != null) {
      state = state.copyWith(family: family);
    }
  }

  /// Refreshes current user and family status from API.
  Future<void> refreshProfile() async {
    if (!state.isAuthenticated) return;
    try {
      final user = await _userRepository.getCurrentUser();
      final family = await _familyRepository.getCurrentFamily();
      state = state.copyWith(user: user, family: family);
    } catch (e) {
      debugPrint('Failed to refresh profile: $e');
    }
  }

  /// Clears any transient error message.
  void clearError() {
    if (state.isError) {
      state = const AuthState.unauthenticated();
    }
  }
}
