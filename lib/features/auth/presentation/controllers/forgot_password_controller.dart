import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';

enum ForgotPasswordStatus { initial, loading, success, error }

class ForgotPasswordState {
  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.initial,
    this.email = '',
    this.errorMessage,
  });

  final ForgotPasswordStatus status;
  final String email;
  final String? errorMessage;

  bool get isValid => email.isNotEmpty && _isValidEmail(email);

  bool get canSubmit => isValid && status != ForgotPasswordStatus.loading;

  String? get emailError {
    if (email.isEmpty) return null;
    if (!_isValidEmail(email)) return 'Please enter a valid email';
    return null;
  }

  static bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  ForgotPasswordState copyWith({
    ForgotPasswordStatus? status,
    String? email,
    String? errorMessage,
  }) =>
      ForgotPasswordState(
        status: status ?? this.status,
        email: email ?? this.email,
        errorMessage: errorMessage,
      );
}

final forgotPasswordControllerProvider = StateNotifierProvider.autoDispose<
    ForgotPasswordController, ForgotPasswordState>(ForgotPasswordController.new);

class ForgotPasswordController extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordController(this._ref) : super(const ForgotPasswordState());

  final Ref _ref;

  void setEmail(String value) {
    state = state.copyWith(email: value.trim());
  }

  Future<bool> submit() async {
    if (!state.canSubmit) return false;

    state = state.copyWith(status: ForgotPasswordStatus.loading);

    final result = await _ref
        .read(forgotPasswordUseCaseProvider)
        .call(email: state.email);

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: ForgotPasswordStatus.error,
          errorMessage: failure.message ?? 'Failed to send reset email',
        );
        return false;
      },
      (_) {
        state = state.copyWith(status: ForgotPasswordStatus.success);
        return true;
      },
    );
  }

  void reset() {
    state = const ForgotPasswordState();
  }
}
