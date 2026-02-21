import '../../../../core/network/api_client.dart';
import '../../domain/entities/booking_change_request.dart';
import '../models/booking_change_request_model.dart';

/// Remote data source for Booking Change Request API
class BookingChangeRequestRemoteDataSource {
  const BookingChangeRequestRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  // ===========================
  // Client APIs
  // ===========================

  /// Create a new change request (client)
  Future<BookingChangeRequestModel> createChangeRequest({
    required String bookingId,
    required BookingChangeRequestType type,
    DateTime? proposedDate,
    String? proposedStartTime,
    String? proposedEndTime,
    String? reason,
  }) async {
    final data = <String, dynamic>{
      'bookingId': bookingId,
      'type': type.name.toUpperCase(),
    };
    if (proposedDate != null) {
      data['proposedDate'] = proposedDate.toIso8601String().split('T').first;
    }
    if (proposedStartTime != null) {
      data['proposedStartTime'] = proposedStartTime;
    }
    if (proposedEndTime != null) {
      data['proposedEndTime'] = proposedEndTime;
    }
    if (reason != null) {
      data['reason'] = reason;
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      'client/booking-changes',
      data: data,
    );
    return BookingChangeRequestModel.fromJson(response.data!);
  }

  /// Get client's change requests
  Future<BookingChangeRequestsResultModel> getClientChangeRequests({
    int page = 1,
    int limit = 20,
    BookingChangeRequestStatus? status,
    BookingChangeRequestType? type,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) {
      queryParams['status'] = status.name.toUpperCase();
    }
    if (type != null) {
      queryParams['type'] = type.name.toUpperCase();
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      'client/booking-changes',
      queryParameters: queryParams,
    );
    return BookingChangeRequestsResultModel.fromJson(response.data!);
  }

  /// Get a specific change request (client)
  Future<BookingChangeRequestModel> getClientChangeRequest(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      'client/booking-changes/$id',
    );
    return BookingChangeRequestModel.fromJson(response.data!);
  }

  // ===========================
  // Staff APIs
  // ===========================

  /// Get all change requests (staff)
  Future<BookingChangeRequestsResultModel> getStaffChangeRequests({
    int page = 1,
    int limit = 20,
    BookingChangeRequestStatus? status,
    BookingChangeRequestType? type,
    String? clientId,
    String? bookingId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) {
      queryParams['status'] = status.name.toUpperCase();
    }
    if (type != null) {
      queryParams['type'] = type.name.toUpperCase();
    }
    if (clientId != null) {
      queryParams['clientId'] = clientId;
    }
    if (bookingId != null) {
      queryParams['bookingId'] = bookingId;
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      'booking-changes',
      queryParameters: queryParams,
    );
    return BookingChangeRequestsResultModel.fromJson(response.data!);
  }

  /// Get a specific change request (staff)
  Future<BookingChangeRequestModel> getStaffChangeRequest(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      'booking-changes/$id',
    );
    return BookingChangeRequestModel.fromJson(response.data!);
  }

  /// Approve a change request (staff)
  Future<BookingChangeRequestModel> approveChangeRequest(String id) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      'booking-changes/$id/approve',
      data: {},
    );
    return BookingChangeRequestModel.fromJson(response.data!);
  }

  /// Reject a change request (staff)
  Future<BookingChangeRequestModel> rejectChangeRequest(
    String id, {
    String? reason,
  }) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      'booking-changes/$id/reject',
      data: {
        if (reason != null) 'reason': reason,
      },
    );
    return BookingChangeRequestModel.fromJson(response.data!);
  }
}
