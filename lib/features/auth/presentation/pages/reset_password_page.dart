import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../controllers/reset_password_controller.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({
    this.token,
    super.key,
  });

  final String? token;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(resetPasswordControllerProvider.notifier).setToken(
              widget.token!,
            );
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final controller = ref.read(resetPasswordControllerProvider.notifier);
    await controller.submit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(resetPasswordControllerProvider);

    ref.listen<ResetPasswordState>(resetPasswordControllerProvider,
        (previous, next) {
      if (next.status == ResetPasswordStatus.error &&
          next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => context.go(Routes.login),
            style: IconButton.styleFrom(
              backgroundColor:
                  theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: state.status == ResetPasswordStatus.success
                    ? _buildSuccessState(theme)
                    : _buildFormState(theme, state),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormState(ThemeData theme, ResetPasswordState state) => Column(
        key: const ValueKey('form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthHeader(
            title: 'Reset password',
            subtitle: 'Enter your new password below.',
            showLogo: false,
          ),
          const SizedBox(height: 40),
          AuthTextField(
            label: 'New Password',
            hint: 'Enter your new password',
            controller: _passwordController,
            obscureText: state.obscurePassword,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                state.obscurePassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
              onPressed: ref
                  .read(resetPasswordControllerProvider.notifier)
                  .togglePasswordVisibility,
            ),
            errorText: state.passwordError,
            enabled: state.status != ResetPasswordStatus.loading,
            onChanged:
                ref.read(resetPasswordControllerProvider.notifier).setPassword,
          ),
          const SizedBox(height: 20),
          AuthTextField(
            label: 'Confirm Password',
            hint: 'Confirm your new password',
            controller: _confirmPasswordController,
            obscureText: state.obscureConfirmPassword,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                state.obscureConfirmPassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
              onPressed: ref
                  .read(resetPasswordControllerProvider.notifier)
                  .toggleConfirmPasswordVisibility,
            ),
            errorText: state.confirmPasswordError,
            enabled: state.status != ResetPasswordStatus.loading,
            onChanged: ref
                .read(resetPasswordControllerProvider.notifier)
                .setConfirmPassword,
            onSubmitted: (_) => _handleSubmit(),
          ),
          const SizedBox(height: 16),
          _buildPasswordRequirements(theme, state),
          const SizedBox(height: 32),
          AuthButton(
            label: 'Reset Password',
            isLoading: state.status == ResetPasswordStatus.loading,
            onPressed: state.canSubmit ? _handleSubmit : null,
          ),
        ],
      );

  Widget _buildPasswordRequirements(
    ThemeData theme,
    ResetPasswordState state,
  ) {
    final hasMinLength = state.password.length >= 8;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password requirements:',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 10),
          _buildRequirementItem(
            theme,
            'At least 8 characters',
            hasMinLength,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(ThemeData theme, String text, bool isMet) => Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 18,
            color: isMet
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isMet
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );

  Widget _buildSuccessState(ThemeData theme) => Column(
        key: const ValueKey('success'),
        children: [
          const SizedBox(height: 24),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.primaryContainer.withOpacity(0.7),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 44,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Password reset successful',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Your password has been successfully reset.\nYou can now sign in with your new password.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          AuthButton(
            label: 'Sign In',
            onPressed: () => context.go(Routes.login),
          ),
        ],
      );
}
