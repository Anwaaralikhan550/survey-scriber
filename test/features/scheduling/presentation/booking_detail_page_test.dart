import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/scheduling/domain/entities/booking.dart';
import 'package:survey_scriber/features/scheduling/domain/entities/booking_status.dart';
import 'package:survey_scriber/features/scheduling/presentation/pages/booking_detail_page.dart';
import 'package:survey_scriber/features/scheduling/presentation/providers/scheduling_providers.dart';

void main() {
  Booking booking({
    BookingSurveyType surveyType = BookingSurveyType.valuation,
    BookingAccessType? accessType,
    String? estateAgentName,
    String? addressLine,
    String? city,
    String? postcode,
    String? propertyAddress,
  }) =>
      Booking(
        id: 'b1',
        surveyorId: 's1',
        date: DateTime(2026, 3, 4),
        startTime: '09:00',
        endTime: '10:00',
        status: BookingStatus.confirmed,
        surveyType: surveyType,
        jobRef: 'JOB-42',
        clientName: 'Jane Doe',
        accessType: accessType,
        estateAgentName: estateAgentName,
        addressLine: addressLine,
        city: city,
        postcode: postcode,
        propertyAddress: propertyAddress,
        createdById: 'u1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

  // Detail view is a long ListView; a tall surface ensures all cards build.
  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget host(Booking? b) => ProviderScope(
        overrides: [
          bookingDetailProvider.overrideWith((ref, id) async => b),
        ],
        child: const MaterialApp(home: BookingDetailPage(bookingId: 'b1')),
      );

  group('BookingDetailPage — Booking Appointment View (App-Edit)', () {
    testWidgets('shows the combined survey type, job ref and client',
        (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(host(booking()));
      await tester.pumpAndSettle();

      expect(find.text('Survey Type'), findsOneWidget);
      expect(find.text('Valuation'), findsOneWidget);
      expect(find.text('JOB-42'), findsOneWidget);
      expect(find.text('Jane Doe'), findsOneWidget);
    });

    testWidgets('composes the structured address from its parts',
        (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(host(booking(
        addressLine: '12 High Street',
        city: 'Bristol',
        postcode: 'BS1 4ST',
      )));
      await tester.pumpAndSettle();

      expect(find.text('12 High Street, Bristol, BS1 4ST'), findsOneWidget);
    });

    testWidgets('falls back to the legacy single-line address', (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(host(booking(
        propertyAddress: '99 Legacy Road, Bath',
      )));
      await tester.pumpAndSettle();

      expect(find.text('99 Legacy Road, Bath'), findsOneWidget);
    });

    testWidgets('direct access hides the estate-agent block', (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(host(booking(
        accessType: BookingAccessType.directAccess,
        estateAgentName: 'Acme Estates',
      )));
      await tester.pumpAndSettle();
      expect(find.text('Direct Access'), findsOneWidget);
      expect(find.text('Estate Agent'), findsNothing);
    });

    testWidgets('collect keys shows the estate-agent block', (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(host(booking(
        accessType: BookingAccessType.collectKeys,
        estateAgentName: 'Acme Estates',
      )));
      await tester.pumpAndSettle();
      expect(find.text('Collect Keys'), findsOneWidget);
      expect(find.text('Estate Agent'), findsOneWidget);
      expect(find.text('Acme Estates'), findsOneWidget);
    });

    testWidgets('renders a friendly not-found state for a missing booking',
        (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(host(null));
      await tester.pumpAndSettle();

      expect(find.text('Booking Not Found'), findsOneWidget);
    });
  });
}
