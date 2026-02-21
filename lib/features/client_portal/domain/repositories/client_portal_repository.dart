import '../entities/client.dart';
import '../entities/client_booking.dart';
import '../entities/client_report.dart';

/// Client Portal repository interface
abstract class ClientPortalRepository {
  // ===========================
  // Authentication
  // ===========================

  /// Request a magic link email
  Future<void> requestMagicLink(String email);

  /// Verify magic link token and get auth tokens
  Future<ClientAuthResult> verifyMagicLink(String token);

  /// Refresh access token
  Future<ClientAuthResult> refreshToken(String refreshToken);

  /// Logout (revoke refresh token)
  Future<void> logout(String refreshToken);

  /// Get current client profile
  Future<Client> getProfile();

  // ===========================
  // Bookings
  // ===========================

  /// Get client bookings with optional status filter
  Future<ClientBookingsResult> getBookings({
    ClientBookingStatus? status,
    int page = 1,
    int limit = 20,
  });

  /// Get single booking by ID
  Future<ClientBooking> getBooking(String id);

  // ===========================
  // Reports
  // ===========================

  /// Get client reports (approved only)
  Future<ClientReportsResult> getReports({
    int page = 1,
    int limit = 20,
  });

  /// Get single report by ID
  Future<ClientReport> getReport(String id);

  /// Download report PDF.
  /// Returns the PDF bytes if available, throws if not available.
  Future<List<int>> downloadReportPdf(String id);
}

/// Result of client authentication
class ClientAuthResult {
  const ClientAuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.client,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final Client client;
}

/// Paginated bookings result
class ClientBookingsResult {
  const ClientBookingsResult({
    required this.bookings,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<ClientBooking> bookings;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

/// Paginated reports result
class ClientReportsResult {
  const ClientReportsResult({
    required this.reports,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<ClientReport> reports;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;
}
