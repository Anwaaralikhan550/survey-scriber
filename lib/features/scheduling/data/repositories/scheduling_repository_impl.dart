import '../../domain/entities/availability.dart';
import '../../domain/entities/availability_exception.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/booking_status.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/repositories/scheduling_repository.dart';
import '../datasources/scheduling_remote_datasource.dart';

class SchedulingRepositoryImpl implements SchedulingRepository {
  const SchedulingRepositoryImpl(this._remoteDataSource);

  final SchedulingRemoteDataSource _remoteDataSource;

  // ===========================
  // AVAILABILITY
  // ===========================

  @override
  Future<List<Availability>> getMyAvailability() async {
    final models = await _remoteDataSource.getMyAvailability();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Availability>> getAvailability(String userId) async {
    final models = await _remoteDataSource.getAvailability(userId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Availability>> setAvailability(
    List<DayAvailabilityInput> availability,
  ) async {
    final models = await _remoteDataSource.setAvailability(availability);
    return models.map((m) => m.toEntity()).toList();
  }

  // ===========================
  // EXCEPTIONS
  // ===========================

  @override
  Future<List<AvailabilityException>> getMyExceptions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final models = await _remoteDataSource.getMyExceptions(
      startDate: startDate,
      endDate: endDate,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<AvailabilityException>> getExceptions(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final models = await _remoteDataSource.getExceptions(
      userId,
      startDate: startDate,
      endDate: endDate,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<AvailabilityException> createException({
    required DateTime date,
    required bool isAvailable,
    String? startTime,
    String? endTime,
    String? reason,
  }) async {
    final model = await _remoteDataSource.createException(
      date: date,
      isAvailable: isAvailable,
      startTime: startTime,
      endTime: endTime,
      reason: reason,
    );
    return model.toEntity();
  }

  @override
  Future<AvailabilityException> updateException(
    String id, {
    bool? isAvailable,
    String? startTime,
    String? endTime,
    String? reason,
  }) async {
    final model = await _remoteDataSource.updateException(
      id,
      isAvailable: isAvailable,
      startTime: startTime,
      endTime: endTime,
      reason: reason,
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteException(String id) async {
    await _remoteDataSource.deleteException(id);
  }

  // ===========================
  // SLOTS
  // ===========================

  @override
  Future<SlotsResponse> getSlots({
    required String surveyorId,
    required DateTime startDate,
    required DateTime endDate,
    int slotDuration = 60,
  }) async {
    final model = await _remoteDataSource.getSlots(
      surveyorId: surveyorId,
      startDate: startDate,
      endDate: endDate,
      slotDuration: slotDuration,
    );
    return model.toEntity();
  }

  // ===========================
  // BOOKINGS
  // ===========================

  @override
  Future<List<Booking>> listBookings({
    String? surveyorId,
    BookingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _remoteDataSource.listBookings(
      surveyorId: surveyorId,
      status: status,
      startDate: startDate,
      endDate: endDate,
      page: page,
      limit: limit,
    );
    return response.data.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Booking>> getMyBookings({
    BookingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _remoteDataSource.getMyBookings(
      status: status,
      startDate: startDate,
      endDate: endDate,
      page: page,
      limit: limit,
    );
    return response.data.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Booking> getBooking(String id) async {
    final model = await _remoteDataSource.getBooking(id);
    return model.toEntity();
  }

  @override
  Future<Booking> createBooking({
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
    final model = await _remoteDataSource.createBooking(
      surveyorId: surveyorId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      clientName: clientName,
      clientPhone: clientPhone,
      clientEmail: clientEmail,
      propertyAddress: propertyAddress,
      notes: notes,
    );
    return model.toEntity();
  }

  @override
  Future<Booking> updateBooking(
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
    final model = await _remoteDataSource.updateBooking(
      id,
      date: date,
      startTime: startTime,
      endTime: endTime,
      clientName: clientName,
      clientPhone: clientPhone,
      clientEmail: clientEmail,
      propertyAddress: propertyAddress,
      notes: notes,
    );
    return model.toEntity();
  }

  @override
  Future<Booking> updateBookingStatus(String id, BookingStatus status) async {
    final model = await _remoteDataSource.updateBookingStatus(id, status);
    return model.toEntity();
  }

  @override
  Future<Booking> cancelBooking(String id) async {
    final model = await _remoteDataSource.cancelBooking(id);
    return model.toEntity();
  }
}
