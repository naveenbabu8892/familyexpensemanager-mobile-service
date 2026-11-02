import '../../family/domain/family.dart';
import 'user.dart';

/// Distinct lifecycle states of authentication.
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Immutable state holder for application authentication.
class AuthState {
  final AuthStatus status;
  final User? user;
  final Family? family;
  final String? errorMessage;
  final Map<String, String>? fieldErrors;

  const AuthState({
    required this.status,
    this.user,
    this.family,
    this.errorMessage,
    this.fieldErrors,
  });

  const AuthState.initial() : this(status: AuthStatus.initial);

  const AuthState.loading() : this(status: AuthStatus.loading);

  const AuthState.authenticated({
    required User user,
    Family? family,
  }) : this(
          status: AuthStatus.authenticated,
          user: user,
          family: family,
        );

  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);

  const AuthState.error({
    required String message,
    Map<String, String>? fieldErrors,
  }) : this(
          status: AuthStatus.error,
          errorMessage: message,
          fieldErrors: fieldErrors,
        );

  // Status conveniences
  bool get isInitial => status == AuthStatus.initial;
  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isError => status == AuthStatus.error;

  /// True if authenticated user belongs to an active family
  bool get hasFamily => family != null;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    Family? family,
    String? errorMessage,
    Map<String, String>? fieldErrors,
    bool clearFamily = false,
    bool clearErrors = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      family: clearFamily ? null : (family ?? this.family),
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      fieldErrors: clearErrors ? null : (fieldErrors ?? this.fieldErrors),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          user == other.user &&
          family == other.family &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(status, user, family, errorMessage);
}
