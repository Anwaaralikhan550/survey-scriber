import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_manager.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

enum LoginStatus { initial, loading, success, error }

class LoginState {
  const LoginState({
    this.status = LoginStatus.initial,
    this.email = '',
    this.password = '',
    this.obscurePassword = true,
    this.errorMessage,
    this.failureType = AuthFailureType.none,
  });

  final LoginStatus status;
  final String email;
  final String password;
  final bool obscurePassword;
  final String? errorMessage;
  final AuthFailureType failureType;

  bool get isValid =>
      email.isNotEmpty &&
      _isValidEmail(email) &&
      password.isNotEmpty &&
      password.length >= 8;

  bool get canSubmit => isValid && status != LoginStatus.loading;

  /// Whether the error is a network error (allows retry)
  bool get isNetworkError =>
      failureType == AuthFailureType.networkError ||
      failureType == AuthFailureType.serverError;

  String? get emailError {
    if (email.isEmpty) return null;
    if (!_isValidEmail(email)) return 'Please enter a valid email';
    return null;
  }

  String? get passwordError {
    if (password.isEmpty) return null;
    if (password.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  LoginState copyWith({
    LoginStatus? status,
    String? email,
    String? password,
    bool? obscurePassword,
    String? errorMessage,
    AuthFailureType? failureType,
  }) =>
      LoginState(
        status: status ?? this.status,
        email: email ?? this.email,
        password: password ?? this.password,
        obscurePassword: obscurePassword ?? this.obscurePassword,
        errorMessage: errorMessage,
        failureType: failureType ?? this.failureType,
      );
}

final loginControllerProvider =
    StateNotifierProvider.autoDispose<LoginController, LoginState>(LoginController.new);

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._ref) : super(const LoginState());

  final Ref _ref;

  void setEmail(String value) {
    state = state.copyWith(
      email: value.trim(),
      failureType: AuthFailureType.none,
    );
  }

  void setPassword(String value) {
    state = state.copyWith(
      password: value,
      failureType: AuthFailureType.none,
    );
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  Future<bool> submit() async {
    if (!state.canSubmit) {
      return false;
    }

    state = state.copyWith(
      status: LoginStatus.loading,
      failureType: AuthFailureType.none,
    );

    final (success, failureType) = await _ref
        .read(authNotifierProvider.notifier)
        .login(email: state.email, password: state.password);

    // Guard: Don't update state if controller was disposed during async operation
    if (!mounted) {
      return success;
    }

    if (success) {
      state = state.copyWith(
        status: LoginStatus.success,
        failureType: AuthFailureType.none,
      );

      // Trigger initial pull from server after login.
      // _ref.read() ensures the provider is initialized (runs _init()),
      // and pullNow() explicitly starts a pull even if the provider was
      // already alive from a prior session (where it may have run without
      // valid auth). The dashboard shows a restoration overlay while
      // isInitialSyncing is true, then auto-refreshes via afterBulkMutation.
      try {
        _ref.read(syncStateProvider.notifier).pullNow();
      } catch (_) {}

      return true;
    } else {
      // Get actual server error message from auth state
      final authState = _ref.read(authNotifierProvider);
      final errorMessage = _getErrorMessage(failureType, authState.errorMessage);

      state = state.copyWith(
        status: LoginStatus.error,
        errorMessage: errorMessage,
        failureType: failureType,
      );
      return false;
    }
  }

  /// Retry login (for network errors)
  Future<bool> retry() async => submit();

  void clearError() {
    state = state.copyWith(
      status: LoginStatus.initial,
      failureType: AuthFailureType.none,
    );
  }

  /// Get user-friendly error message based on failure type
  /// For validation errors, returns the actual server message
  String _getErrorMessage(AuthFailureType failureType, [String? serverMessage]) {
    switch (failureType) {
      case AuthFailureType.validationError:
        // Use the actual server message for validation errors
        return serverMessage ?? 'Invalid login data. Please check your input.';
      case AuthFailureType.invalidCredentials:
        return serverMessage ?? 'Invalid email or password. Please try again.';
      case AuthFailureType.networkError:
        return 'Unable to connect to server. Please check your internet connection and try again.';
      case AuthFailureType.serverError:
        return serverMessage ?? 'Server is temporarily unavailable. Please try again later.';
      case AuthFailureType.sessionExpired:
        return 'Your session has expired. Please log in again.';
      case AuthFailureType.unknown:
        return serverMessage ?? 'An unexpected error occurred. Please try again.';
      case AuthFailureType.none:
        return 'Login failed. Please try again.';
    }
  }
}
