import '../entities/booking_change_request.dart';

/// Repository interface for booking change requests
abstract class BookingChangeRequestRepository {
  /// Create a new change request (client)
  Future<BookingChangeRequest> createChangeRequest({
    required String bookingId,
    required BookingChangeRequestType type,
    DateTime? proposedDate,
    String? proposedStartTime,
    String? proposedEndTime,
    String? reason,
  });

  /// Get client's change requests
  Future<BookingChangeRequestsResult> getClientChangeRequests({
    int page = 1,
    int limit = 20,
    BookingChangeRequestStatus? status,
    BookingChangeRequestType? type,
  });

  /// Get a specific change request (client)
  Future<BookingChangeRequest> getClientChangeRequest(String id);

  /// Get all change requests (staff)
  Future<BookingChangeRequestsResult> getStaffChangeRequests({
    int page = 1,
    int limit = 20,
    BookingChangeRequestStatus? status,
    BookingChangeRequestType? type,
    String? clientId,
    String? bookingId,
  });

  /// Get a specific change request (staff)
  Future<BookingChangeRequest> getStaffChangeRequest(String id);

  /// Approve a change request (staff)
  Future<BookingChangeRequest> approveChangeRequest(String id);

  /// Reject a change request (staff)
  Future<BookingChangeRequest> rejectChangeRequest(String id, {String? reason});
}
