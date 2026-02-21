import '../entities/booking_request.dart';

/// Repository interface for booking requests
abstract class BookingRequestRepository {
  // ===========================
  // Client Methods
  // ===========================

  /// Create a new booking request
  Future<BookingRequest> createBookingRequest({
    required String propertyAddress,
    required DateTime preferredStartDate,
    required DateTime preferredEndDate,
    String? notes,
  });

  /// Get client's booking requests
  Future<BookingRequestsResult> getClientBookingRequests({
    BookingRequestStatus? status,
    int page = 1,
    int limit = 20,
  });

  /// Get a specific booking request (client)
  Future<BookingRequest> getClientBookingRequest(String id);

  // ===========================
  // Staff Methods
  // ===========================

  /// Get all booking requests (staff)
  Future<BookingRequestsResult> getStaffBookingRequests({
    BookingRequestStatus? status,
    String? clientId,
    int page = 1,
    int limit = 20,
  });

  /// Get a specific booking request (staff)
  Future<BookingRequest> getStaffBookingRequest(String id);

  /// Approve a booking request
  Future<BookingRequest> approveBookingRequest(String id);

  /// Reject a booking request
  Future<BookingRequest> rejectBookingRequest(String id, {String? reason});
}
