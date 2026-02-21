import '../../domain/entities/booking_change_request.dart';
import '../../domain/repositories/booking_change_request_repository.dart';
import '../datasources/booking_change_request_remote_datasource.dart';

/// Implementation of BookingChangeRequestRepository
class BookingChangeRequestRepositoryImpl
    implements BookingChangeRequestRepository {
  const BookingChangeRequestRepositoryImpl(this._remoteDataSource);

  final BookingChangeRequestRemoteDataSource _remoteDataSource;

  // ===========================
  // Client Methods
  // ===========================

  @override
  Future<BookingChangeRequest> createChangeRequest({
    required String bookingId,
    required BookingChangeRequestType type,
    DateTime? proposedDate,
    String? proposedStartTime,
    String? proposedEndTime,
    String? reason,
  }) async {
    final result = await _remoteDataSource.createChangeRequest(
      bookingId: bookingId,
      type: type,
      proposedDate: proposedDate,
      proposedStartTime: proposedStartTime,
      proposedEndTime: proposedEndTime,
      reason: reason,
    );
    return result.toEntity();
  }

  @override
  Future<BookingChangeRequestsResult> getClientChangeRequests({
    int page = 1,
    int limit = 20,
    BookingChangeRequestStatus? status,
    BookingChangeRequestType? type,
  }) async {
    final result = await _remoteDataSource.getClientChangeRequests(
      page: page,
      limit: limit,
      status: status,
      type: type,
    );
    return result.toEntity();
  }

  @override
  Future<BookingChangeRequest> getClientChangeRequest(String id) async {
    final result = await _remoteDataSource.getClientChangeRequest(id);
    return result.toEntity();
  }

  // ===========================
  // Staff Methods
  // ===========================

  @override
  Future<BookingChangeRequestsResult> getStaffChangeRequests({
    int page = 1,
    int limit = 20,
    BookingChangeRequestStatus? status,
    BookingChangeRequestType? type,
    String? clientId,
    String? bookingId,
  }) async {
    final result = await _remoteDataSource.getStaffChangeRequests(
      page: page,
      limit: limit,
      status: status,
      type: type,
      clientId: clientId,
      bookingId: bookingId,
    );
    return result.toEntity();
  }

  @override
  Future<BookingChangeRequest> getStaffChangeRequest(String id) async {
    final result = await _remoteDataSource.getStaffChangeRequest(id);
    return result.toEntity();
  }

  @override
  Future<BookingChangeRequest> approveChangeRequest(String id) async {
    final result = await _remoteDataSource.approveChangeRequest(id);
    return result.toEntity();
  }

  @override
  Future<BookingChangeRequest> rejectChangeRequest(
    String id, {
    String? reason,
  }) async {
    final result = await _remoteDataSource.rejectChangeRequest(
      id,
      reason: reason,
    );
    return result.toEntity();
  }
}
