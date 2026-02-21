import 'package:equatable/equatable.dart';

import '../../domain/entities/user.dart';

enum AuthStatus {
  /// Initial state - auth check not yet performed
  initial,

  /// Loading - auth operation in progress
  loading,

  /// User is authenticated (valid token exists)
  authenticated,

  /// User is not authenticated (no token, or explicitly logged out)
  unauthenticated,

  /// Error occurred but does NOT invalidate auth
  /// (e.g., network error while fetching user profile)
  error,
}

/// Type of auth-related failure for UX handling
enum AuthFailureType {
  /// No failure
  none,

  /// Invalid credentials (wrong email/password)
  invalidCredentials,

  /// Network/API unreachable - does NOT invalidate existing auth
  networkError,

  /// Server error (5xx) - does NOT invalidate existing auth
  serverError,

  /// Session expired or token invalid - requires re-login
  sessionExpired,

  /// Validation error (400 Bad Request) - server rejected data
  validationError,

  /// Unknown/other error
  unknown,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.failureType = AuthFailureType.none,
    this.hasValidToken = false,
  });

  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final AuthFailureType failureType;

  /// Whether a valid token exists in local storage.
  /// This is independent of network state - if true, user should
  /// be considered authenticated even if API is unreachable.
  final bool hasValidToken;

  /// User is authenticated if:
  /// 1. Status is explicitly authenticated, OR
  /// 2. A valid token exists (even if there's a network error)
  bool get isAuthenticated =>
      status == AuthStatus.authenticated ||
      (hasValidToken && failureType == AuthFailureType.networkError) ||
      (hasValidToken && failureType == AuthFailureType.serverError);

  bool get isLoading => status == AuthStatus.loading;
  bool get isInitial => status == AuthStatus.initial;

  /// Whether the failure is a network/server error (non-auth failure)
  bool get isNetworkError =>
      failureType == AuthFailureType.networkError ||
      failureType == AuthFailureType.serverError;

  /// Whether the failure requires user action (re-login)
  bool get requiresReLogin =>
      failureType == AuthFailureType.invalidCredentials ||
      failureType == AuthFailureType.sessionExpired;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    AuthFailureType? failureType,
    bool? hasValidToken,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        errorMessage: errorMessage,
        failureType: failureType ?? this.failureType,
        hasValidToken: hasValidToken ?? this.hasValidToken,
      );

  @override
  List<Object?> get props => [
        status,
        user,
        errorMessage,
        failureType,
        hasValidToken,
      ];
}
