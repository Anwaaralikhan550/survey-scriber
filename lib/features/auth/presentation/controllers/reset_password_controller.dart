import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';

enum ResetPasswordStatus { initial, loading, success, error }

class ResetPasswordState {
  const ResetPasswordState({
    this.status = ResetPasswordStatus.initial,
    this.token = '',
    this.password = '',
    this.confirmPassword = '',
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
    this.errorMessage,
  });

  final ResetPasswordStatus status;
  final String token;
  final String password;
  final String confirmPassword;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final String? errorMessage;

  bool get isValid =>
      token.isNotEmpty &&
      password.isNotEmpty &&
      password.length >= 8 &&
      password == confirmPassword;

  bool get canSubmit => isValid && status != ResetPasswordStatus.loading;

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

  ResetPasswordState copyWith({
    ResetPasswordStatus? status,
    String? token,
    String? password,
    String? confirmPassword,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
    String? errorMessage,
  }) =>
      ResetPasswordState(
        status: status ?? this.status,
        token: token ?? this.token,
        password: password ?? this.password,
        confirmPassword: confirmPassword ?? this.confirmPassword,
        obscurePassword: obscurePassword ?? this.obscurePassword,
        obscureConfirmPassword:
            obscureConfirmPassword ?? this.obscureConfirmPassword,
        errorMessage: errorMessage,
      );
}

final resetPasswordControllerProvider = StateNotifierProvider.autoDispose<
    ResetPasswordController, ResetPasswordState>(ResetPasswordController.new);

class ResetPasswordController extends StateNotifier<ResetPasswordState> {
  ResetPasswordController(this._ref) : super(const ResetPasswordState());

  final Ref _ref;

  void setToken(String value) {
    state = state.copyWith(token: value.trim());
  }

  void setPassword(String value) {
    state = state.copyWith(password: value);
  }

  void setConfirmPassword(String value) {
    state = state.copyWith(confirmPassword: value);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(
      obscureConfirmPassword: !state.obscureConfirmPassword,
    );
  }

  Future<bool> submit() async {
    if (!state.canSubmit) return false;

    state = state.copyWith(status: ResetPasswordStatus.loading);

    final result = await _ref.read(resetPasswordUseCaseProvider).call(
          token: state.token,
          newPassword: state.password,
        );

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: ResetPasswordStatus.error,
          errorMessage: failure.message ?? 'Failed to reset password',
        );
        return false;
      },
      (_) {
        state = state.copyWith(status: ResetPasswordStatus.success);
        return true;
      },
    );
  }

  void reset() {
    state = const ResetPasswordState();
  }
}
