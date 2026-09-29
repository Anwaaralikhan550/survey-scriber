import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/scheduling/domain/entities/booking.dart';
import 'package:survey_scriber/features/scheduling/domain/entities/booking_status.dart';

void main() {
  group('BookingSurveyType (combined Create-Booking survey type)', () {
    test('wire values round-trip', () {
      expect(BookingSurveyType.homeSurvey.wireValue, 'home_survey');
      expect(BookingSurveyType.valuation.wireValue, 'valuation');
      expect(BookingSurveyType.fromWire('valuation'), BookingSurveyType.valuation);
      expect(BookingSurveyType.fromWire('home_survey'),
          BookingSurveyType.homeSurvey);
    });

    test('unknown / null wire value defaults to Home Survey', () {
      expect(BookingSurveyType.fromWire(null), BookingSurveyType.homeSurvey);
      expect(BookingSurveyType.fromWire('anything'),
          BookingSurveyType.homeSurvey);
    });

    test('labels match the App-Edit brief', () {
      expect(BookingSurveyType.homeSurvey.label, 'Home Survey');
      expect(BookingSurveyType.valuation.label, 'Valuation');
    });
  });

  group('BookingAccessType (Direct Access / Collect Keys)', () {
    test('wire values round-trip', () {
      expect(BookingAccessType.directAccess.wireValue, 'direct');
      expect(BookingAccessType.collectKeys.wireValue, 'collect_keys');
      expect(BookingAccessType.fromWire('direct'),
          BookingAccessType.directAccess);
      expect(BookingAccessType.fromWire('collect_keys'),
          BookingAccessType.collectKeys);
    });

    test('unknown / null wire value is null (no access recorded)', () {
      expect(BookingAccessType.fromWire(null), isNull);
      expect(BookingAccessType.fromWire('other'), isNull);
    });

    test('labels', () {
      expect(BookingAccessType.directAccess.label, 'Direct Access');
      expect(BookingAccessType.collectKeys.label, 'Collect Keys');
    });
  });

  group('Booking entity', () {
    Booking make({
      String startTime = '09:00',
      String endTime = '10:00',
      DateTime? date,
    }) =>
        Booking(
          id: 'b1',
          surveyorId: 's1',
          date: date ?? DateTime(2026, 1, 15),
          startTime: startTime,
          endTime: endTime,
          status: BookingStatus.pending,
          createdById: 'u1',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );

    test('surveyType defaults to Home Survey', () {
      expect(make().surveyType, BookingSurveyType.homeSurvey);
    });

    test('timeRange formats the slot', () {
      expect(make(startTime: '09:00', endTime: '10:30').timeRange,
          '09:00 - 10:30');
    });

    test('isPast is true for a finished slot, false for a future one', () {
      expect(make(date: DateTime(2000, 1, 1)).isPast, isTrue);
      expect(make(date: DateTime(2999, 1, 1)).isPast, isFalse);
    });

    test('malformed end time does not throw and is treated as not past', () {
      expect(make(endTime: 'not-a-time', date: DateTime(2000, 1, 1)).isPast,
          isFalse);
    });

    test('copyWith overrides only the given fields', () {
      final b = make();
      final v = b.copyWith(
        surveyType: BookingSurveyType.valuation,
        accessType: BookingAccessType.collectKeys,
        estateAgentName: 'Acme Estates',
      );
      expect(v.surveyType, BookingSurveyType.valuation);
      expect(v.accessType, BookingAccessType.collectKeys);
      expect(v.estateAgentName, 'Acme Estates');
      // untouched fields carry over
      expect(v.id, b.id);
      expect(v.startTime, b.startTime);
    });

    test('value equality via Equatable', () {
      expect(make(), equals(make()));
      expect(make(startTime: '11:00'), isNot(equals(make())));
    });
  });
}
