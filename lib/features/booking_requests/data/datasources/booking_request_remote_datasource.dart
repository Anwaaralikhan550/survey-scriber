import '../../../../core/network/api_client.dart';
import '../../domain/entities/booking_request.dart';
import '../models/booking_request_model.dart';

/// Remote data source for Booking Request API
class BookingRequestRemoteDataSource {
  const BookingRequestRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  // ===========================
  // Client APIs
  // ===========================

  /// Create a new booking request (client)
  Future<BookingRequestModel> createBookingRequest({
    required String propertyAddress,
    required String preferredStartDate,
    required String preferredEndDate,
    String? notes,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      'client/booking-requests',
      data: {
        'propertyAddress': propertyAddress,
        'preferredStartDate': preferredStartDate,
        'preferredEndDate': preferredEndDate,
        if (notes != null) 'notes': notes,
      },
    );
    return BookingRequestModel.fromJson(response.data!);
  }

  /// Get client's booking requests
  Future<BookingRequestsResponseModel> getClientBookingRequests({
    BookingRequestStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) {
      queryParams['status'] = status.name.toUpperCase();
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      'client/booking-requests',
      queryParameters: queryParams,
    );
    return BookingRequestsResponseModel.fromJson(response.data!);
  }

  /// Get a specific booking request (client)
  Future<BookingRequestModel> getClientBookingRequest(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      'client/booking-requests/$id',
    );
    return BookingRequestModel.fromJson(response.data!);
  }

  // ===========================
  // Staff APIs
  // ===========================

  /// Get all booking requests (staff)
  Future<BookingRequestsResponseModel> getStaffBookingRequests({
    BookingRequestStatus? status,
    String? clientId,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) {
      queryParams['status'] = status.name.toUpperCase();
    }
    if (clientId != null) {
      queryParams['clientId'] = clientId;
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      'booking-requests',
      queryParameters: queryParams,
    );
    return BookingRequestsResponseModel.fromJson(response.data!);
  }

  /// Get a specific booking request (staff)
  Future<BookingRequestModel> getStaffBookingRequest(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      'booking-requests/$id',
    );
    return BookingRequestModel.fromJson(response.data!);
  }

  /// Approve a booking request (staff)
  Future<BookingRequestModel> approveBookingRequest(String id) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      'booking-requests/$id/approve',
      data: {},
    );
    return BookingRequestModel.fromJson(response.data!);
  }

  /// Reject a booking request (staff)
  Future<BookingRequestModel> rejectBookingRequest(
    String id, {
    String? reason,
  }) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      'booking-requests/$id/reject',
      data: {
        if (reason != null) 'reason': reason,
      },
    );
    return BookingRequestModel.fromJson(response.data!);
  }
}
