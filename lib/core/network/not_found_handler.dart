import 'dart:async';

import 'package:flutter/material.dart';

/// Represents a resource that was not found (404).
/// Used to communicate stale data events across the app.
class StaleResource {
  const StaleResource({
    required this.resourceType,
    required this.resourceId,
    this.message,
  });

  /// Type of resource (e.g., 'booking', 'survey', 'report')
  final String resourceType;

  /// ID of the resource that no longer exists
  final String resourceId;

  /// Optional message from the server
  final String? message;

  @override
  String toString() => 'StaleResource($resourceType: $resourceId)';
}

/// Global handler for 404 Not Found errors.
/// Provides user-friendly feedback and navigation handling.
///
/// Usage:
/// 1. Set up the handler in main.dart/app.dart
/// 2. Use [scaffoldMessengerKey] for the MaterialApp
/// 3. Use [navigatorKey] for the MaterialApp's navigator
/// 4. Call [handleNotFound] when a 404 is detected
class NotFoundHandler {
  NotFoundHandler._();
  static final NotFoundHandler instance = NotFoundHandler._();

  /// Global scaffold messenger key for showing snackbars from anywhere.
  /// Share this with SessionExpiryHandler or use separate keys.
  GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;

  /// Global navigator key for navigation from outside widget tree.
  GlobalKey<NavigatorState>? navigatorKey;

  /// Stream controller for stale resource events.
  /// Providers can listen to this to remove stale items from their state.
  final _staleResourceController = StreamController<StaleResource>.broadcast();

  /// Stream of stale resource events.
  /// Listen to this in your providers to react to 404s.
  Stream<StaleResource> get staleResourceStream => _staleResourceController.stream;

  /// Emits a stale resource event.
  /// Call this after handling a 404 to notify providers.
  void emitStaleResource(StaleResource resource) {
    _staleResourceController.add(resource);
  }

  /// Handles a 404 Not Found error.
  ///
  /// [resourceType] - Type of resource (e.g., 'booking', 'survey')
  /// [resourceId] - ID of the resource that wasn't found
  /// [message] - Optional custom message
  /// [shouldPop] - Whether to pop the current route (default: true for detail screens)
  void handleNotFound({
    required String resourceType,
    required String resourceId,
    String? message,
    bool shouldPop = true,
  }) {
    // Show user-friendly snackbar
    _showNotFoundSnackbar(resourceType, message);

    // Emit stale resource event for providers to clean up
    emitStaleResource(StaleResource(
      resourceType: resourceType,
      resourceId: resourceId,
      message: message,
    ),);

    // Pop back if on a detail screen
    if (shouldPop) {
      _popIfPossible();
    }
  }

  void _showNotFoundSnackbar(String resourceType, String? message) {
    final messenger = scaffoldMessengerKey?.currentState;
    if (messenger == null) return;

    final displayMessage = message ??
        'This ${_humanize(resourceType)} no longer exists.';

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange.shade700,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _popIfPossible() {
    final navigator = navigatorKey?.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    }
  }

  /// Converts resource type to human-readable string.
  String _humanize(String resourceType) {
    // Convert camelCase or snake_case to readable format
    return resourceType
        .replaceAllMapped(
          RegExp('([A-Z])'),
          (match) => ' ${match.group(0)?.toLowerCase()}',
        )
        .replaceAll('_', ' ')
        .trim()
        .toLowerCase();
  }

  /// Dispose the handler (call on app shutdown if needed)
  void dispose() {
    _staleResourceController.close();
  }
}
