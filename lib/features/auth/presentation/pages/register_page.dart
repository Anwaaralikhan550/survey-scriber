import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/utils/responsive.dart';
import '../controllers/register_controller.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final controller = ref.read(registerControllerProvider.notifier);
    final registerState = ref.read(registerControllerProvider);
    final success = await controller.submit();

    if (success && mounted) {
      // Auto-login with the same credentials
      final (loginSuccess, _) = await ref
          .read(authNotifierProvider.notifier)
          .login(
            email: registerState.email,
            password: registerState.password,
          );

      if (!mounted) return;

      if (loginSuccess) {
        // Successfully logged in - navigate to dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Welcome! Account created successfully.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        context.go(Routes.dashboard);
      } else {
        // Auto-login failed - navigate to login page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Account created! Please sign in.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        context.go(Routes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(registerControllerProvider);
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;

    // Listen to AuthNotifier for error states (more reliable)
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        _showErrorSnackBar(context, theme, next.errorMessage!);
      }
    });

    // Also listen to RegisterController for error states (backup)
    ref.listen<RegisterState>(registerControllerProvider, (previous, next) {
      if (next.status == RegisterStatus.error && next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        _showErrorSnackBar(context, theme, next.errorMessage!);
      }
    });

    // Responsive values
    final horizontalPadding = context.responsive<double>(
      mobile: 24,
      tablet: 48,
      desktop: 64,
    );
    final verticalPadding = context.responsive<double>(
      mobile: isKeyboardVisible ? 16 : 32,
      tablet: isKeyboardVisible ? 24 : 48,
      desktop: 64,
    );
    final maxWidth = context.responsive<double>(
      mobile: 400,
      tablet: 500,
      desktop: 540,
    );
    final spacing = context.responsive<double>(
      mobile: 16,
      tablet: 20,
      desktop: 24,
    );
    final useRowForNames = context.isTabletOrLarger;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header section
                      const AuthHeader(
                        title: 'Create account',
                        subtitle: 'Sign up to get started with SurveyScriber',
                      ),

                      SizedBox(height: spacing * 2),

                      // First Name and Last Name - Row on tablet+
                      if (useRowForNames)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AuthTextField(
                                label: 'First Name',
                                hint: 'First name',
                                controller: _firstNameController,
                                keyboardType: TextInputType.name,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.givenName],
                                prefixIcon: const Icon(Icons.person_outline_rounded),
                                errorText: state.firstNameError,
                                enabled: state.status != RegisterStatus.loading,
                                onChanged: ref
                                    .read(registerControllerProvider.notifier)
                                    .setFirstName,
                              ),
                            ),
                            SizedBox(width: spacing),
                            Expanded(
                              child: AuthTextField(
                                label: 'Last Name',
                                hint: 'Last name',
                                controller: _lastNameController,
                                keyboardType: TextInputType.name,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.familyName],
                                prefixIcon: const Icon(Icons.person_outline_rounded),
                                errorText: state.lastNameError,
                                enabled: state.status != RegisterStatus.loading,
                                onChanged: ref
                                    .read(registerControllerProvider.notifier)
                                    .setLastName,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        // Stack on mobile
                        AuthTextField(
                          label: 'First Name',
                          hint: 'Enter your first name',
                          controller: _firstNameController,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.givenName],
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          errorText: state.firstNameError,
                          enabled: state.status != RegisterStatus.loading,
                          onChanged: ref
                              .read(registerControllerProvider.notifier)
                              .setFirstName,
                        ),
                        SizedBox(height: spacing),
                        AuthTextField(
                          label: 'Last Name',
                          hint: 'Enter your last name',
                          controller: _lastNameController,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.familyName],
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          errorText: state.lastNameError,
                          enabled: state.status != RegisterStatus.loading,
                          onChanged: ref
                              .read(registerControllerProvider.notifier)
                              .setLastName,
                        ),
                      ],

                      SizedBox(height: spacing),

                      // Email field
                      AuthTextField(
                        label: 'Email',
                        hint: 'Enter your email address',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        prefixIcon: const Icon(Icons.mail_outline_rounded),
                        errorText: state.emailError,
                        enabled: state.status != RegisterStatus.loading,
                        onChanged: ref
                            .read(registerControllerProvider.notifier)
                            .setEmail,
                      ),

                      SizedBox(height: spacing),

                      // Password field
                      AuthTextField(
                        label: 'Password',
                        hint: 'Create a password (min 8 characters)',
                        controller: _passwordController,
                        obscureText: state.obscurePassword,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            state.obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: ref
                              .read(registerControllerProvider.notifier)
                              .togglePasswordVisibility,
                          splashRadius: 20,
                        ),
                        errorText: state.passwordError,
                        enabled: state.status != RegisterStatus.loading,
                        onChanged: ref
                            .read(registerControllerProvider.notifier)
                            .setPassword,
                      ),

                      SizedBox(height: spacing),

                      // Confirm Password field
                      AuthTextField(
                        label: 'Confirm Password',
                        hint: 'Re-enter your password',
                        controller: _confirmPasswordController,
                        obscureText: state.obscureConfirmPassword,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            state.obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: ref
                              .read(registerControllerProvider.notifier)
                              .toggleConfirmPasswordVisibility,
                          splashRadius: 20,
                        ),
                        errorText: state.confirmPasswordError,
                        enabled: state.status != RegisterStatus.loading,
                        onChanged: ref
                            .read(registerControllerProvider.notifier)
                            .setConfirmPassword,
                        onSubmitted: (_) => _handleRegister(),
                      ),

                      SizedBox(height: spacing * 1.5),

                      // Sign up button
                      AuthButton(
                        label: 'Create Account',
                        isLoading: state.status == RegisterStatus.loading,
                        onPressed: state.canSubmit ? _handleRegister : null,
                      ),

                      SizedBox(height: spacing * 2),

                      // Divider
                      _buildDivider(theme),

                      SizedBox(height: spacing * 2),

                      // Login link
                      _buildLoginLink(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, ThemeData theme, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: theme.colorScheme.onError,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) => Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.outlineVariant.withOpacity(0),
                    theme.colorScheme.outlineVariant.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'or',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.outlineVariant.withOpacity(0.6),
                    theme.colorScheme.outlineVariant.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  Widget _buildLoginLink(ThemeData theme) => Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Already have an account?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            TextButton(
              onPressed: () => context.go(Routes.login),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Sign in',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}
