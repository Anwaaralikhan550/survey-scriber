import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../utils/logger.dart';

/// Certificate pinning configuration for production HTTPS connections.
///
/// This implementation provides defense-in-depth against MITM attacks by
/// validating that the server's certificate matches known-good fingerprints.
///
/// Features:
/// - SHA-256 fingerprint validation (industry standard)
/// - Multiple fingerprint support for certificate rotation
/// - Automatic bypass for development (HTTP/debug builds)
/// - Clear logging for debugging and security audits
///
/// SECURITY NOTES:
/// 1. Fingerprints MUST be updated before certificate expiration
/// 2. Always add the new certificate fingerprint BEFORE rotation
/// 3. Keep the old fingerprint for 1-2 weeks after rotation
/// 4. Test thoroughly in staging before production deployment
///
/// To get your certificate's SHA-256 fingerprint:
/// ```bash
/// # For a live server:
/// echo | openssl s_client -connect api.surveyscriber.com:443 -servername api.surveyscriber.com 2>/dev/null | \
///   openssl x509 -noout -fingerprint -sha256
///
/// # For a certificate file:
/// openssl x509 -in certificate.pem -noout -fingerprint -sha256
/// ```
abstract final class CertificatePinning {
  // ===========================================================================
  // CONFIGURATION - Update these fingerprints for your production certificates
  // ===========================================================================

  /// SHA-256 fingerprints of trusted leaf certificates.
  ///
  /// Format: Uppercase hex with colons (e.g., "AA:BB:CC:DD:...")
  /// Include multiple fingerprints to support seamless certificate rotation.
  ///
  /// IMPORTANT: Before certificate expiration:
  /// 1. Generate/obtain new certificate
  /// 2. Add new fingerprint to this list
  /// 3. Deploy app update
  /// 4. Rotate certificate on server
  /// 5. Remove old fingerprint after grace period (1-2 weeks)
  static const List<String> trustedFingerprints = [
    // =========================================================================
    // TODO: Add your production certificate SHA-256 fingerprints here
    // =========================================================================
    //
    // Example (replace with real fingerprints):
    // 'E3:B0:C4:42:98:FC:1C:14:9A:FB:F4:C8:99:6F:B9:24:27:AE:41:E4:64:9B:93:4C:A4:95:99:1B:78:52:B8:55',
    //
    // For Let's Encrypt certificates, you may also want to pin the intermediate:
    // 'R3 Intermediate': '67:AD:D1:16:6B:02:0A:E6:1B:8F:5F:C9:68:13:C0:4C:2A:A5:89:96:07:96:86:55:72:A3:C7:E7:37:61:3D:FD',
  ];

  /// Whether to allow connections when no fingerprints are configured.
  ///
  /// When `false` (default), release builds will reject all HTTPS connections
  /// until valid fingerprints are added — this forces proper configuration
  /// before production deployment.
  /// When `true`, a warning is logged but connections are allowed (dev only).
  static const bool allowWithoutFingerprints = false;

  // ===========================================================================
  // IMPLEMENTATION
  // ===========================================================================

  /// Whether certificate pinning should be active.
  ///
  /// Returns `true` only when:
  /// - Running in release mode (kReleaseMode)
  /// - Base URL uses HTTPS
  /// - Fingerprints are configured (or allowWithoutFingerprints is false)
  static bool get isEnabled {
    // Never pin in debug/profile builds - allows local development
    if (!kReleaseMode) {
      return false;
    }

    // Only pin HTTPS connections
    final baseUrl = AppConstants.baseUrl;
    if (!baseUrl.startsWith('https://')) {
      AppLogger.w(
        '[CertificatePinning] Non-HTTPS URL detected in release build: $baseUrl. '
        'Certificate pinning disabled. Consider using HTTPS in production.',
      );
      return false;
    }

    // Check if fingerprints are configured
    if (trustedFingerprints.isEmpty) {
      if (allowWithoutFingerprints) {
        AppLogger.w(
          '[CertificatePinning] SECURITY WARNING: No certificate fingerprints configured. '
          'Certificate pinning is DISABLED. Add fingerprints to CertificatePinning.trustedFingerprints',
        );
        return false;
      } else {
        // In strict mode, we still return true to force configuration
        return true;
      }
    }

    return true;
  }

  /// Configures the Dio instance with certificate pinning.
  ///
  /// Call this immediately after creating the Dio instance:
  /// ```dart
  /// final dio = Dio(baseOptions);
  /// CertificatePinning.configure(dio);
  /// dio.interceptors.addAll([...]);
  /// ```
  static void configure(Dio dio) {
    if (!isEnabled) {
      if (kDebugMode) {
        AppLogger.d('[CertificatePinning] Certificate pinning disabled (debug mode or non-HTTPS URL)');
      }
      return;
    }

    AppLogger.i('[CertificatePinning] Enabling certificate pinning with ${trustedFingerprints.length} trusted fingerprint(s)');

    // Configure the HTTP client adapter with certificate validation
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();

        // Reject certificates that fail basic validation
        client.badCertificateCallback = (cert, host, port) {
          AppLogger.e('[CertificatePinning] Bad certificate rejected for $host:$port - Certificate failed system validation');
          return false;
        };

        return client;
      },
      validateCertificate: _validateCertificate,
    );
  }

  /// Validates a certificate against trusted fingerprints.
  static bool _validateCertificate(
    X509Certificate? certificate,
    String host,
    int port,
  ) {
    // No certificate provided
    if (certificate == null) {
      AppLogger.e('[CertificatePinning] PINNING FAILED: No certificate provided by $host:$port');
      return false;
    }

    // No fingerprints configured (strict mode)
    if (trustedFingerprints.isEmpty) {
      AppLogger.e('[CertificatePinning] PINNING FAILED: No fingerprints configured. Add fingerprints to CertificatePinning.trustedFingerprints');
      return false;
    }

    // Calculate the certificate's SHA-256 fingerprint
    final fingerprint = _calculateSha256Fingerprint(certificate);

    // Check against trusted fingerprints
    final isValid = _matchesAnyFingerprint(fingerprint);

    if (isValid) {
      AppLogger.d('[CertificatePinning] Certificate validated for $host (fingerprint matched)');
    } else {
      AppLogger.e(
        '[CertificatePinning] CERTIFICATE PINNING FAILED for $host:$port | '
        'Received: $fingerprint | '
        'Expected one of: ${trustedFingerprints.join(", ")} | '
        'Possible causes: MITM attack, certificate rotation without app update, incorrect config',
      );
    }

    return isValid;
  }

  /// Calculates the SHA-256 fingerprint of an X509 certificate.
  ///
  /// Returns the fingerprint in uppercase hex format with colons.
  /// Example: "E3:B0:C4:42:98:FC:1C:14:..."
  static String _calculateSha256Fingerprint(X509Certificate certificate) {
    // Get the DER-encoded certificate bytes
    final derBytes = certificate.der;

    // Calculate SHA-256 hash
    final digest = sha256.convert(derBytes);

    // Format as uppercase hex with colons
    return digest.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }

  /// Checks if a fingerprint matches any of the trusted fingerprints.
  static bool _matchesAnyFingerprint(String fingerprint) {
    // Normalize for comparison (lowercase, no colons/spaces)
    final normalizedFingerprint = _normalizeFingerprint(fingerprint);

    for (final trusted in trustedFingerprints) {
      final normalizedTrusted = _normalizeFingerprint(trusted);
      if (normalizedFingerprint == normalizedTrusted) {
        return true;
      }
    }

    return false;
  }

  /// Normalizes a fingerprint for comparison.
  ///
  /// Converts to lowercase and removes colons, spaces, and other separators.
  static String _normalizeFingerprint(String fingerprint) => fingerprint
        .toLowerCase()
        .replaceAll(':', '')
        .replaceAll(' ', '')
        .replaceAll('-', '');
}

/// Exception thrown when certificate pinning validation fails.
///
/// This exception provides detailed information for debugging and logging.
class CertificatePinningException implements Exception {
  const CertificatePinningException({
    required this.host,
    required this.port,
    this.receivedFingerprint,
    this.message,
  });

  final String host;
  final int port;
  final String? receivedFingerprint;
  final String? message;

  @override
  String toString() {
    final buffer = StringBuffer('CertificatePinningException: ');
    buffer.write('Certificate validation failed for $host:$port.');
    if (message != null) {
      buffer.write(' $message');
    }
    if (receivedFingerprint != null) {
      buffer.write(' Received fingerprint: $receivedFingerprint');
    }
    return buffer.toString();
  }
}
