import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/scheduling/domain/entities/booking.dart';
import 'package:survey_scriber/features/scheduling/domain/entities/booking_status.dart';
import 'package:survey_scriber/features/scheduling/presentation/pages/bookings_list_page.dart';
import 'package:survey_scriber/features/scheduling/presentation/providers/scheduling_providers.dart';
import 'package:survey_scriber/features/surveys/domain/repositories/survey_repository.dart';
import 'package:survey_scriber/features/surveys/presentation/providers/survey_providers.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

class _NoSurveys implements SurveyRepository {
  @override
  Future<List<Survey>> getAllSurveys() async => <Survey>[];
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

class _FakeBookings extends StateNotifier<BookingsState> implements BookingsNotifier {
  _FakeBookings(List<Booking> list) : super(BookingsState(bookings: list));
  @override
  Future<void> loadMyBookings({BookingStatus? status, DateTime? startDate, DateTime? endDate}) async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

Booking _b(String id, BookingSurveyType type, String jobRef, {String? line, String? city}) => Booking(
      id: id,
      surveyorId: 's1',
      date: DateTime(2026, 7, 25),
      startTime: '09:00',
      endTime: '10:00',
      status: BookingStatus.confirmed,
      surveyType: type,
      jobRef: jobRef,
      clientName: 'Client $id',
      addressLine: line,
      city: city,
      postcode: 'IG4 5DD',
      createdById: 'u1',
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
    );

void main() {
  Widget host({bool showNewBookingButton = true}) => ProviderScope(
        overrides: [
          localSurveyRepositoryProvider.overrideWithValue(_NoSurveys()),
          bookingsNotifierProvider.overrideWith((ref) => _FakeBookings([
                _b('1', BookingSurveyType.homeSurvey, 'HS-100', line: '29 Taylor Drive', city: 'Chelmsford'),
                _b('2', BookingSurveyType.valuation, 'VAL-200', line: '5 High Street', city: 'Bath'),
              ])),
        ],
        child: MaterialApp(
          home: BookingsListPage(showNewBookingButton: showNewBookingButton),
        ),
      );

  group('BookingsListPage - Live Bookings (App-Edit)', () {
    testWidgets('titled Live Bookings with Home Surveys / Valuations kept separate', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      expect(find.text('Live Bookings'), findsOneWidget);
      // Home Surveys is selected first: only the home survey booking is listed
      expect(find.text('HS-100'), findsOneWidget);
      expect(find.text('VAL-200'), findsNothing);

      await tester.tap(find.text('Valuations'));
      await tester.pumpAndSettle();
      expect(find.text('VAL-200'), findsOneWidget);
      expect(find.text('HS-100'), findsNothing);
    });

    testWidgets('each card shows job ref, survey type and address', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      expect(find.text('HS-100'), findsOneWidget);
      expect(find.text('Home Survey'), findsWidgets);
      expect(find.text('29 Taylor Drive, Chelmsford, IG4 5DD'), findsOneWidget);
    });

    testWidgets('status filter chips are still there', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      for (final label in ['All', 'Pending', 'Confirmed']) {
        expect(find.text(label), findsWidgets, reason: label);
      }
    });

    testWidgets('the tab hides the New Booking button (the big plus creates)', (tester) async {
      await tester.pumpWidget(host(showNewBookingButton: false));
      await tester.pumpAndSettle();
      expect(find.text('New Booking'), findsNothing);
    });

    testWidgets('the pushed list keeps the New Booking button', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      expect(find.text('New Booking'), findsOneWidget);
    });
  });
}
