import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

enum RegisterStatus { initial, loading, success, error }

class RegisterState {
  const RegisterState({
    this.status = RegisterStatus.initial,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
    this.errorMessage,
    this.failureType = AuthFailureType.none,
  });

  final RegisterStatus status;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String confirmPassword;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final String? errorMessage;
  final AuthFailureType failureType;

  bool get isValid =>
      firstName.isNotEmpty &&
      lastName.isNotEmpty &&
      email.isNotEmpty &&
      _isValidEmail(email) &&
      password.isNotEmpty &&
      password.length >= 8 &&
      confirmPassword.isNotEmpty &&
      password == confirmPassword;

  bool get canSubmit => isValid && status != RegisterStatus.loading;

  /// Whether the error is a network error (allows retry)
  bool get isNetworkError =>
      failureType == AuthFailureType.networkError ||
      failureType == AuthFailureType.serverError;

  String? get firstNameError {
    if (firstName.isEmpty) return null;
    if (firstName.length < 2) return 'First name must be at least 2 characters';
    return null;
  }

  String? get lastNameError {
    if (lastName.isEmpty) return null;
    if (lastName.length < 2) return 'Last name must be at least 2 characters';
    return null;
  }

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

  String? get confirmPasswordError {
    if (confirmPassword.isEmpty) return null;
    if (password != confirmPassword) return 'Passwords do not match';
    return null;
  }

  static bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  RegisterState copyWith({
    RegisterStatus? status,
    String? firstName,
    String? lastName,
    String? email,
    String? password,
    String? confirmPassword,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
    String? errorMessage,
    AuthFailureType? failureType,
  }) =>
      RegisterState(
        status: status ?? this.status,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        password: password ?? this.password,
        confirmPassword: confirmPassword ?? this.confirmPassword,
        obscurePassword: obscurePassword ?? this.obscurePassword,
        obscureConfirmPassword:
            obscureConfirmPassword ?? this.obscureConfirmPassword,
        errorMessage: errorMessage,
        failureType: failureType ?? this.failureType,
      );
}

final registerControllerProvider =
    StateNotifierProvider.autoDispose<RegisterController, RegisterState>(RegisterController.new);

class RegisterController extends StateNotifier<RegisterState> {
  RegisterController(this._ref) : super(const RegisterState());

  final Ref _ref;

  void setFirstName(String value) {
    state = state.copyWith(
      firstName: value.trim(),
      failureType: AuthFailureType.none,
    );
  }

  void setLastName(String value) {
    state = state.copyWith(
      lastName: value.trim(),
      failureType: AuthFailureType.none,
    );
  }

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

  void setConfirmPassword(String value) {
    state = state.copyWith(
      confirmPassword: value,
      failureType: AuthFailureType.none,
    );
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(
        obscureConfirmPassword: !state.obscureConfirmPassword,);
  }

  Future<bool> submit() async {
    if (!state.canSubmit) return false;

    state = state.copyWith(
      status: RegisterStatus.loading,
      failureType: AuthFailureType.none,
    );

    final (success, failureType) = await _ref
        .read(authNotifierProvider.notifier)
        .register(
          email: state.email,
          password: state.password,
          firstName: state.firstName,
          lastName: state.lastName,
        );

    // Guard: Don't update state if controller was disposed during async operation
    if (!mounted) return success;

    if (success) {
      state = state.copyWith(
        status: RegisterStatus.success,
        failureType: AuthFailureType.none,
      );
      return true;
    } else {
      // Get user-friendly error message based on failure type
      // Get actual server error message from auth state
      final authState = _ref.read(authNotifierProvider);
      final errorMessage = _getErrorMessage(failureType, authState.errorMessage);

      state = state.copyWith(
        status: RegisterStatus.error,
        errorMessage: errorMessage,
        failureType: failureType,
      );
      return false;
    }
  }

  /// Retry registration (for network errors)
  Future<bool> retry() async => submit();

  void clearError() {
    state = state.copyWith(
      status: RegisterStatus.initial,
      failureType: AuthFailureType.none,
    );
  }

  /// Get user-friendly error message based on failure type
  /// For validation errors, returns the actual server message
  String _getErrorMessage(AuthFailureType failureType, [String? serverMessage]) {
    switch (failureType) {
      case AuthFailureType.validationError:
        // Use the actual server message for validation errors
        return serverMessage ?? 'Invalid registration data. Please check your input.';
      case AuthFailureType.invalidCredentials:
        return serverMessage ?? 'Email already registered. Please use a different email.';
      case AuthFailureType.networkError:
        return 'Unable to connect to server. Please check your internet connection and try again.';
      case AuthFailureType.serverError:
        return serverMessage ?? 'Server is temporarily unavailable. Please try again later.';
      case AuthFailureType.sessionExpired:
        return 'Session expired. Please try again.';
      case AuthFailureType.unknown:
        return serverMessage ?? 'An unexpected error occurred. Please try again.';
      case AuthFailureType.none:
        return 'Registration failed. Please try again.';
    }
  }
}
