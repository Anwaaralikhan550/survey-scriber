import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';

/// Handles session expiry events from the API layer.
/// Uses a callback pattern to notify the auth layer without creating circular dependencies.
class SessionExpiryHandler {
  SessionExpiryHandler._();
  static final SessionExpiryHandler instance = SessionExpiryHandler._();

  /// Callback invoked when a token refresh fails.
  /// Set this to trigger auth state invalidation.
  VoidCallback? onSessionExpired;

  /// Global scaffold messenger key for showing snackbars from anywhere.
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Global navigator key for navigation from outside widget tree.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Called when token refresh fails.
  /// Shows a snackbar, navigates to login, and triggers the session expired callback.
  void handleSessionExpired() {
    // Show snackbar if scaffold messenger is available
    _showSessionExpiredSnackbar();

    // Navigate to login page immediately
    _navigateToLogin();

    // Trigger auth state invalidation
    onSessionExpired?.call();
  }

  void _navigateToLogin() {
    final navigator = navigatorKey.currentContext;
    if (navigator != null && navigator.mounted) {
      // Use GoRouter for navigation to ensure consistent routing
      navigator.go(Routes.login);
    }
  }

  void _showSessionExpiredSnackbar() {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger != null) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Your session has expired. Please sign in again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
