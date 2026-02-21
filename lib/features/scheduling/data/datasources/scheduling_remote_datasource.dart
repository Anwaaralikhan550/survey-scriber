import 'package:intl/intl.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/availability.dart';
import '../../domain/entities/booking_status.dart';
import '../models/availability_model.dart';
import '../models/booking_model.dart';
import '../models/exception_model.dart';
import '../models/slot_model.dart';

class SchedulingRemoteDataSource {
  const SchedulingRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  static const _basePath = 'scheduling';
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  // ===========================
  // AVAILABILITY
  // ===========================

  Future<List<AvailabilityModel>> getMyAvailability() async {
    final response = await _apiClient.get<List<dynamic>>(
      '$_basePath/availability',
    );
    return (response.data ?? [])
        .map((e) => AvailabilityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AvailabilityModel>> getAvailability(String userId) async {
    final response = await _apiClient.get<List<dynamic>>(
      '$_basePath/availability/$userId',
    );
    return (response.data ?? [])
        .map((e) => AvailabilityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AvailabilityModel>> setAvailability(
    List<DayAvailabilityInput> availability,
  ) async {
    final response = await _apiClient.put<List<dynamic>>(
      '$_basePath/availability',
      data: {
        'availability': availability.map((a) => a.toJson()).toList(),
      },
    );
    return (response.data ?? [])
        .map((e) => AvailabilityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ===========================
  // EXCEPTIONS
  // ===========================

  Future<List<ExceptionModel>> getMyExceptions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) {
      queryParams['startDate'] = _dateFormat.format(startDate);
    }
    if (endDate != null) {
      queryParams['endDate'] = _dateFormat.format(endDate);
    }

    try {
      final response = await _apiClient.get<List<dynamic>>(
        '$_basePath/availability/exceptions',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return (response.data ?? [])
          .map((e) => ExceptionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ValidationException {
      // API returns 400 when no exceptions exist - treat as empty list
      return [];
    }
  }

  Future<List<ExceptionModel>> getExceptions(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) {
      queryParams['startDate'] = _dateFormat.format(startDate);
    }
    if (endDate != null) {
      queryParams['endDate'] = _dateFormat.format(endDate);
    }

    try {
      final response = await _apiClient.get<List<dynamic>>(
        '$_basePath/availability/exceptions/$userId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return (response.data ?? [])
          .map((e) => ExceptionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ValidationException {
      // API returns 400 when no exceptions exist - treat as empty list
      return [];
    }
  }

  Future<ExceptionModel> createException({
    required DateTime date,
    required bool isAvailable,
    String? startTime,
    String? endTime,
    String? reason,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_basePath/availability/exceptions',
      data: {
        'date': _dateFormat.format(date),
        'isAvailable': isAvailable,
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (reason != null) 'reason': reason,
      },
    );
    return ExceptionModel.fromJson(response.data!);
  }

  Future<ExceptionModel> updateException(
    String id, {
    bool? isAvailable,
    String? startTime,
    String? endTime,
    String? reason,
  }) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '$_basePath/availability/exceptions/item/$id',
      data: {
        if (isAvailable != null) 'isAvailable': isAvailable,
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (reason != null) 'reason': reason,
      },
    );
    return ExceptionModel.fromJson(response.data!);
  }

  Future<void> deleteException(String id) async {
    await _apiClient.delete('$_basePath/availability/exceptions/item/$id');
  }

  // ===========================
  // SLOTS
  // ===========================

  Future<SlotsResponseModel> getSlots({
    required String surveyorId,
    required DateTime startDate,
    required DateTime endDate,
    int slotDuration = 60,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/slots',
      queryParameters: {
        'surveyorId': surveyorId,
        'startDate': _dateFormat.format(startDate),
        'endDate': _dateFormat.format(endDate),
        'slotDuration': slotDuration,
      },
    );
    return SlotsResponseModel.fromJson(response.data!);
  }

  // ===========================
  // BOOKINGS
  // ===========================

  Future<BookingListResponse> listBookings({
    String? surveyorId,
    BookingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (surveyorId != null) queryParams['surveyorId'] = surveyorId;
    if (status != null) queryParams['status'] = status.toBackendString();
    if (startDate != null) {
      queryParams['startDate'] = _dateFormat.format(startDate);
    }
    if (endDate != null) {
      queryParams['endDate'] = _dateFormat.format(endDate);
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/bookings',
      queryParameters: queryParams,
    );
    return BookingListResponse.fromJson(response.data!);
  }

  Future<BookingListResponse> getMyBookings({
    BookingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) queryParams['status'] = status.toBackendString();
    if (startDate != null) {
      queryParams['startDate'] = _dateFormat.format(startDate);
    }
    if (endDate != null) {
      queryParams['endDate'] = _dateFormat.format(endDate);
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/bookings/my',
      queryParameters: queryParams,
    );
    return BookingListResponse.fromJson(response.data!);
  }

  Future<BookingModel> getBooking(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/bookings/$id',
    );
    return BookingModel.fromJson(response.data!);
  }

  Future<BookingModel> createBooking({
    required String surveyorId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    String? propertyAddress,
    String? notes,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_basePath/bookings',
      data: {
        'surveyorId': surveyorId,
        'date': _dateFormat.format(date),
        'startTime': startTime,
        'endTime': endTime,
        if (clientName != null) 'clientName': clientName,
        if (clientPhone != null) 'clientPhone': clientPhone,
        if (clientEmail != null) 'clientEmail': clientEmail,
        if (propertyAddress != null) 'propertyAddress': propertyAddress,
        if (notes != null) 'notes': notes,
      },
    );
    return BookingModel.fromJson(response.data!);
  }

  Future<BookingModel> updateBooking(
    String id, {
    DateTime? date,
    String? startTime,
    String? endTime,
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    String? propertyAddress,
    String? notes,
  }) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '$_basePath/bookings/$id',
      data: {
        if (date != null) 'date': _dateFormat.format(date),
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (clientName != null) 'clientName': clientName,
        if (clientPhone != null) 'clientPhone': clientPhone,
        if (clientEmail != null) 'clientEmail': clientEmail,
        if (propertyAddress != null) 'propertyAddress': propertyAddress,
        if (notes != null) 'notes': notes,
      },
    );
    return BookingModel.fromJson(response.data!);
  }

  Future<BookingModel> updateBookingStatus(
    String id,
    BookingStatus status,
  ) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '$_basePath/bookings/$id/status',
      data: {'status': status.toBackendString()},
    );
    return BookingModel.fromJson(response.data!);
  }

  Future<BookingModel> cancelBooking(String id) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      '$_basePath/bookings/$id',
    );
    return BookingModel.fromJson(response.data!);
  }
}
