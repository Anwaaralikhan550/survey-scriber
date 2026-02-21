import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../utils/logger.dart';

/// Result of a biometric authentication attempt.
enum BiometricResult {
  /// Authentication succeeded.
  success,

  /// User cancelled authentication.
  cancelled,

  /// Biometric hardware not available on device.
  notAvailable,

  /// No biometrics enrolled on device.
  notEnrolled,

  /// Device passcode/PIN not set (required for biometrics).
  passcodeNotSet,

  /// Authentication failed (wrong fingerprint/face).
  failed,

  /// Too many failed attempts, temporarily locked out.
  lockedOut,

  /// Permanently locked out - requires device unlock.
  permanentlyLockedOut,

  /// Another authentication is already in progress.
  otherOperationInProgress,

  /// Platform error.
  error,
}

/// Detailed biometric availability status.
class BiometricStatus {
  const BiometricStatus({
    required this.isHardwareAvailable,
    required this.isDeviceSupported,
    required this.hasEnrolledBiometrics,
    required this.availableTypes,
    this.errorMessage,
  });

  /// Whether the device has biometric hardware.
  final bool isHardwareAvailable;

  /// Whether the device supports local authentication.
  final bool isDeviceSupported;

  /// Whether any biometrics are enrolled.
  final bool hasEnrolledBiometrics;

  /// List of available biometric types (fingerprint, face, iris).
  final List<BiometricType> availableTypes;

  /// Error message if check failed.
  final String? errorMessage;

  /// Whether biometric authentication can be used.
  bool get canAuthenticate =>
      isHardwareAvailable && isDeviceSupported && hasEnrolledBiometrics;

  /// Human-readable description of available biometrics.
  String get biometricDescription {
    if (availableTypes.isEmpty) return 'None';
    final types = availableTypes.map((t) {
      switch (t) {
        case BiometricType.fingerprint:
          return 'Fingerprint';
        case BiometricType.face:
          return 'Face';
        case BiometricType.iris:
          return 'Iris';
        case BiometricType.strong:
          return 'Strong biometric';
        case BiometricType.weak:
          return 'Weak biometric';
      }
    }).toList();
    return types.join(', ');
  }

  @override
  String toString() => 'BiometricStatus('
      'hardware=$isHardwareAvailable, '
      'supported=$isDeviceSupported, '
      'enrolled=$hasEnrolledBiometrics, '
      'types=$availableTypes'
      '${errorMessage != null ? ', error=$errorMessage' : ''})';
}

/// Service for biometric authentication using local_auth.
///
/// This service provides a unified API for biometric authentication across
/// Android and iOS, with proper error handling and user-friendly messages.
class BiometricService {
  BiometricService._();

  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  static const String _tag = 'BiometricService';

  /// Cached status to avoid repeated platform calls.
  BiometricStatus? _cachedStatus;
  DateTime? _statusCacheTime;
  static const Duration _cacheValidity = Duration(seconds: 30);

  /// Gets detailed biometric availability status.
  ///
  /// Results are cached for 30 seconds to avoid repeated platform calls.
  Future<BiometricStatus> getStatus({bool forceRefresh = false}) async {
    // Return cached status if valid
    if (!forceRefresh &&
        _cachedStatus != null &&
        _statusCacheTime != null &&
        DateTime.now().difference(_statusCacheTime!) < _cacheValidity) {
      return _cachedStatus!;
    }

    try {
      // Check hardware capability
      final canCheck = await _auth.canCheckBiometrics;
      AppLogger.d(_tag, 'canCheckBiometrics: $canCheck');

      // Check device support (includes passcode capability)
      final isSupported = await _auth.isDeviceSupported();
      AppLogger.d(_tag, 'isDeviceSupported: $isSupported');

      // Get enrolled biometrics
      final availableBiometrics = await _auth.getAvailableBiometrics();
      AppLogger.d(_tag, 'availableBiometrics: $availableBiometrics');

      _cachedStatus = BiometricStatus(
        isHardwareAvailable: canCheck,
        isDeviceSupported: isSupported,
        hasEnrolledBiometrics: availableBiometrics.isNotEmpty,
        availableTypes: availableBiometrics,
      );
      _statusCacheTime = DateTime.now();

      AppLogger.d(_tag, 'Status: $_cachedStatus');
      return _cachedStatus!;
    } on PlatformException catch (e) {
      AppLogger.e(_tag, 'Failed to get biometric status: ${e.code} - ${e.message}');
      _cachedStatus = BiometricStatus(
        isHardwareAvailable: false,
        isDeviceSupported: false,
        hasEnrolledBiometrics: false,
        availableTypes: [],
        errorMessage: _getPlatformErrorMessage(e),
      );
      _statusCacheTime = DateTime.now();
      return _cachedStatus!;
    }
  }

  /// Checks if biometric authentication is available on this device.
  Future<bool> isAvailable() async {
    final status = await getStatus();
    return status.canAuthenticate;
  }

  /// Gets the list of available biometric types.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    final status = await getStatus();
    return status.availableTypes;
  }

  /// Checks if any biometrics are enrolled on the device.
  Future<bool> hasEnrolledBiometrics() async {
    final status = await getStatus();
    return status.hasEnrolledBiometrics;
  }

  /// Clears the cached status, forcing a refresh on next check.
  void clearCache() {
    _cachedStatus = null;
    _statusCacheTime = null;
  }

  /// Authenticates the user with biometrics.
  ///
  /// [reason] is displayed to the user explaining why authentication is needed.
  /// [allowDeviceCredential] if true, allows PIN/password as fallback.
  ///
  /// Returns [BiometricResult.success] if authentication succeeded.
  Future<BiometricResult> authenticate({
    String reason = 'Please authenticate to continue',
    bool allowDeviceCredential = true,
  }) async {
    AppLogger.d(_tag, 'Starting authentication (allowCredential=$allowDeviceCredential)');

    try {
      // First check status
      final status = await getStatus(forceRefresh: true);
      AppLogger.d(_tag, 'Pre-auth status: $status');

      if (!status.isHardwareAvailable) {
        AppLogger.w(_tag, 'Biometric hardware not available');
        return BiometricResult.notAvailable;
      }

      if (!status.isDeviceSupported) {
        AppLogger.w(_tag, 'Device not supported for local auth');
        return BiometricResult.notAvailable;
      }

      if (!status.hasEnrolledBiometrics && !allowDeviceCredential) {
        AppLogger.w(_tag, 'No biometrics enrolled and device credential not allowed');
        return BiometricResult.notEnrolled;
      }

      // Attempt authentication
      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: !allowDeviceCredential,
        ),
      );

      AppLogger.d(_tag, 'Authentication result: $didAuthenticate');
      return didAuthenticate ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException catch (e) {
      AppLogger.e(_tag, 'Authentication error: ${e.code} - ${e.message}');
      return _mapPlatformException(e);
    } catch (e) {
      AppLogger.e(_tag, 'Unexpected authentication error: $e');
      return BiometricResult.error;
    }
  }

  /// Maps platform exceptions to BiometricResult.
  ///
  /// Error codes from local_auth package:
  /// - 'LockedOut' / 'lockedOut': Temporarily locked out
  /// - 'PermanentlyLockedOut' / 'permanentlyLockedOut': Requires device unlock
  /// - 'NotAvailable' / 'notAvailable': Biometrics not available
  /// - 'NotEnrolled' / 'notEnrolled': No biometrics enrolled
  /// - 'PasscodeNotSet' / 'passcodeNotSet': Device passcode not set
  /// - 'OtherOperatingSystem' / 'otherOperatingSystem': Another auth in progress
  /// - 'no_fragment_activity': Android config error (MainActivity must extend FlutterFragmentActivity)
  BiometricResult _mapPlatformException(PlatformException e) {
    final code = e.code;
    final codeLower = code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();

    AppLogger.d(_tag, 'Mapping exception - code: $code, message: ${e.message}');

    // CRITICAL: Android configuration error - MainActivity must extend FlutterFragmentActivity
    // This should never happen in production if Android config is correct
    if (codeLower == 'no_fragment_activity' ||
        message.contains('fragmentactivity') ||
        message.contains('fragment activity')) {
      AppLogger.e(
        _tag,
        'CONFIGURATION ERROR: MainActivity must extend FlutterFragmentActivity. '
        'See: https://pub.dev/packages/local_auth#android-integration',
      );
      return BiometricResult.notAvailable;
    }

    // User cancelled - check various platform representations
    if (codeLower.contains('cancel') ||
        codeLower == 'usercanceled' ||
        message.contains('cancel') ||
        message.contains('user canceled')) {
      return BiometricResult.cancelled;
    }

    // Locked out states
    if (codeLower == 'permanentlylockedout' ||
        codeLower == 'permanently_locked_out' ||
        message.contains('permanently locked')) {
      return BiometricResult.permanentlyLockedOut;
    }
    if (codeLower == 'lockedout' ||
        codeLower == 'locked_out' ||
        message.contains('locked out') ||
        message.contains('too many')) {
      return BiometricResult.lockedOut;
    }

    // Not available
    if (codeLower == 'notavailable' ||
        codeLower == 'not_available' ||
        message.contains('not available') ||
        message.contains('no hardware')) {
      return BiometricResult.notAvailable;
    }

    // Not enrolled
    if (codeLower == 'notenrolled' ||
        codeLower == 'not_enrolled' ||
        message.contains('not enrolled') ||
        message.contains('no biometric') ||
        message.contains('no fingerprint')) {
      return BiometricResult.notEnrolled;
    }

    // Passcode not set
    if (codeLower == 'passcodenotset' ||
        codeLower == 'passcode_not_set' ||
        message.contains('passcode') ||
        message.contains('screen lock')) {
      return BiometricResult.passcodeNotSet;
    }

    // Other operation in progress
    if (codeLower == 'otheroperatingsystem' ||
        codeLower == 'other_operating_system' ||
        message.contains('in progress') ||
        message.contains('already')) {
      return BiometricResult.otherOperationInProgress;
    }

    // Log unknown error for debugging
    AppLogger.w(_tag, 'Unhandled biometric error - code: $code, message: ${e.message}');
    if (kDebugMode) {
      print('Unknown biometric error code: $code, message: ${e.message}');
    }
    return BiometricResult.error;
  }

  /// Gets a platform-specific error message.
  String _getPlatformErrorMessage(PlatformException e) => e.message ?? 'Platform error: ${e.code}';

  /// Returns a user-friendly message for a biometric result.
  String getResultMessage(BiometricResult result) {
    switch (result) {
      case BiometricResult.success:
        return 'Authentication successful';
      case BiometricResult.cancelled:
        return 'Authentication was cancelled';
      case BiometricResult.notAvailable:
        return 'Biometric authentication is not available on this device';
      case BiometricResult.notEnrolled:
        return 'No biometrics enrolled. Please set up fingerprint or face in your device settings';
      case BiometricResult.passcodeNotSet:
        return 'Please set up a screen lock (PIN, pattern, or password) in your device settings first';
      case BiometricResult.failed:
        return 'Authentication failed. Please try again';
      case BiometricResult.lockedOut:
        return 'Too many failed attempts. Please wait and try again';
      case BiometricResult.permanentlyLockedOut:
        return 'Biometrics locked. Please unlock your device with PIN/password first';
      case BiometricResult.otherOperationInProgress:
        return 'Another authentication is in progress. Please wait';
      case BiometricResult.error:
        return 'Authentication error. Please try again or use device passcode';
    }
  }

  /// Returns a short status message for display in settings.
  Future<String> getStatusMessage() async {
    final status = await getStatus();

    if (status.errorMessage != null) {
      return 'Error: ${status.errorMessage}';
    }

    if (!status.isHardwareAvailable) {
      return 'Biometric hardware not detected';
    }

    if (!status.isDeviceSupported) {
      return 'Device does not support biometric auth';
    }

    if (!status.hasEnrolledBiometrics) {
      return 'No biometrics enrolled on this device';
    }

    return 'Available: ${status.biometricDescription}';
  }
}
