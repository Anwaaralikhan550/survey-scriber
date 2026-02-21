import '../entities/availability.dart';
import '../entities/availability_exception.dart';
import '../entities/booking.dart';
import '../entities/booking_status.dart';
import '../entities/time_slot.dart';

/// Repository interface for scheduling operations
abstract class SchedulingRepository {
  // Availability
  Future<List<Availability>> getMyAvailability();
  Future<List<Availability>> getAvailability(String userId);
  Future<List<Availability>> setAvailability(List<DayAvailabilityInput> availability);

  // Exceptions
  Future<List<AvailabilityException>> getMyExceptions({
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<List<AvailabilityException>> getExceptions(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<AvailabilityException> createException({
    required DateTime date,
    required bool isAvailable,
    String? startTime,
    String? endTime,
    String? reason,
  });
  Future<AvailabilityException> updateException(
    String id, {
    bool? isAvailable,
    String? startTime,
    String? endTime,
    String? reason,
  });
  Future<void> deleteException(String id);

  // Slots
  Future<SlotsResponse> getSlots({
    required String surveyorId,
    required DateTime startDate,
    required DateTime endDate,
    int slotDuration = 60,
  });

  // Bookings
  Future<List<Booking>> listBookings({
    String? surveyorId,
    BookingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  });
  Future<List<Booking>> getMyBookings({
    BookingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  });
  Future<Booking> getBooking(String id);
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
  });
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
  });
  Future<Booking> updateBookingStatus(String id, BookingStatus status);
  Future<Booking> cancelBooking(String id);
}
