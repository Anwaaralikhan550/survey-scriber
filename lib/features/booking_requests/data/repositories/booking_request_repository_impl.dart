import '../../domain/entities/booking_request.dart';
import '../../domain/repositories/booking_request_repository.dart';
import '../datasources/booking_request_remote_datasource.dart';

/// Implementation of BookingRequestRepository
class BookingRequestRepositoryImpl implements BookingRequestRepository {
  const BookingRequestRepositoryImpl(this._remoteDataSource);

  final BookingRequestRemoteDataSource _remoteDataSource;

  String _formatDate(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  // ===========================
  // Client Methods
  // ===========================

  @override
  Future<BookingRequest> createBookingRequest({
    required String propertyAddress,
    required DateTime preferredStartDate,
    required DateTime preferredEndDate,
    String? notes,
  }) => _remoteDataSource.createBookingRequest(
      propertyAddress: propertyAddress,
      preferredStartDate: _formatDate(preferredStartDate),
      preferredEndDate: _formatDate(preferredEndDate),
      notes: notes,
    );

  @override
  Future<BookingRequestsResult> getClientBookingRequests({
    BookingRequestStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _remoteDataSource.getClientBookingRequests(
      status: status,
      page: page,
      limit: limit,
    );
    return BookingRequestsResult(
      requests: response.requests,
      page: response.page,
      limit: response.limit,
      total: response.total,
      totalPages: response.totalPages,
    );
  }

  @override
  Future<BookingRequest> getClientBookingRequest(String id) => _remoteDataSource.getClientBookingRequest(id);

  // ===========================
  // Staff Methods
  // ===========================

  @override
  Future<BookingRequestsResult> getStaffBookingRequests({
    BookingRequestStatus? status,
    String? clientId,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _remoteDataSource.getStaffBookingRequests(
      status: status,
      clientId: clientId,
      page: page,
      limit: limit,
    );
    return BookingRequestsResult(
      requests: response.requests,
      page: response.page,
      limit: response.limit,
      total: response.total,
      totalPages: response.totalPages,
    );
  }

  @override
  Future<BookingRequest> getStaffBookingRequest(String id) => _remoteDataSource.getStaffBookingRequest(id);

  @override
  Future<BookingRequest> approveBookingRequest(String id) => _remoteDataSource.approveBookingRequest(id);

  @override
  Future<BookingRequest> rejectBookingRequest(String id, {String? reason}) => _remoteDataSource.rejectBookingRequest(id, reason: reason);
}
