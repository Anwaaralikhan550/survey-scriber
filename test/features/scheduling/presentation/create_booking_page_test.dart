import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show StateNotifier;
import 'package:survey_scriber/features/auth/domain/entities/user.dart';
import 'package:survey_scriber/features/auth/presentation/providers/auth_notifier.dart';
import 'package:survey_scriber/features/auth/presentation/providers/auth_state.dart';
import 'package:survey_scriber/features/scheduling/domain/entities/booking.dart';
import 'package:survey_scriber/features/scheduling/presentation/providers/scheduling_providers.dart';
import 'package:survey_scriber/features/scheduling/presentation/pages/create_booking_page.dart';

class _FakeAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuth()
      : super(const AuthState(
          status: AuthStatus.authenticated,
          hasValidToken: true,
          user: User(id: 'u1', email: 'a@b.c', firstName: 'A', lastName: 'B'),
        ));
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _CapturingBookings extends StateNotifier<BookingsState>
    implements BookingsNotifier {
  _CapturingBookings() : super(const BookingsState());
  Map<String, Object?> captured = {};

  @override
  Future<Booking?> createBooking({
    required String surveyorId,
    required DateTime date,
    required String startTime,
    required String endTime,
    BookingSurveyType surveyType = BookingSurveyType.homeSurvey,
    String? jobRef,
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    String? propertyType,
    String? yearBuilt,
    String? propertyAddress,
    String? addressLine,
    String? city,
    String? town,
    String? postcode,
    String? county,
    String? notes,
    BookingAccessType? accessType,
    String? estateAgentName,
    String? estateAgentPhone,
    String? estateAgentAddress,
    String? estateAgentNotes,
  }) async {
    captured = {
      'surveyType': surveyType,
      'accessType': accessType,
      'estateAgentName': estateAgentName,
      'estateAgentAddress': estateAgentAddress,
    };
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

void main() {
  // The form is a long ListView; give the test a tall surface so every field
  // is built and laid out (ListView lazily builds only what fits otherwise).
  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget host() => const ProviderScope(
        child: MaterialApp(home: CreateBookingPage()),
      );

  group('CreateBookingPage — combined booking form (App-Edit)', () {
    testWidgets(
        'combines the survey-type choice into the booking form '
        '(Home Survey / Valuation)', (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // The survey-type selector lives on the create-booking screen itself,
      // replacing the separate "Select Survey Type" step.
      expect(find.text('Survey Type'), findsOneWidget);
      expect(find.text('Home Survey'), findsOneWidget);
      expect(find.text('Valuation'), findsOneWidget);
      expect(
        find.descendant(
            of: find.byType(AppBar), matching: find.text('Create Booking')),
        findsOneWidget,
      );
    });

    testWidgets(
        'estate-agent block appears only when Collect Keys is selected',
        (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Direct Access is the default: no estate-agent fields, helper text shown.
      expect(find.text('Estate Agent Name'), findsNothing);
      expect(
          find.text('Direct access — no further information required.'),
          findsOneWidget);

      await tester.tap(find.text('Collect Keys'));
      await tester.pumpAndSettle();

      expect(find.text('Estate Agent'), findsOneWidget);
      expect(find.text('Estate Agent Name'), findsOneWidget);
      expect(
          find.text('Direct access — no further information required.'),
          findsNothing);

      // Switch back to Direct Access — the block collapses again.
      await tester.tap(find.text('Direct Access'));
      await tester.pumpAndSettle();
      expect(find.text('Estate Agent Name'), findsNothing);
    });

    testWidgets('rejects an invalid email address on submit', (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      final emailField =
          find.widgetWithText(TextFormField, 'Email Address (optional)');
      await tester.enterText(emailField, 'not-an-email');
      await tester.pump();

      // Submit button is a FilledButton.icon (a FilledButton subtype, so
      // find.byType won't match it); match the subtype by predicate.
      final submit = find.byWidgetPredicate((w) => w is FilledButton);
      expect(submit, findsOneWidget);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });
  });

  group('CreateBookingPage - opened from the big plus (App-Edit)', () {
    testWidgets('Valuation is pre-selected when the Valuations segment opened it',
        (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(
          home: CreateBookingPage(initialSurveyType: BookingSurveyType.valuation),
        ),
      ));
      await tester.pumpAndSettle();
      final seg = tester.widget<SegmentedButton<BookingSurveyType>>(
          find.byType(SegmentedButton<BookingSurveyType>).first);
      expect(seg.selected, {BookingSurveyType.valuation});
    });

    testWidgets('Home Survey is the default selection', (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final seg = tester.widget<SegmentedButton<BookingSurveyType>>(
          find.byType(SegmentedButton<BookingSurveyType>).first);
      expect(seg.selected, {BookingSurveyType.homeSurvey});
    });

    testWidgets('date is tappable and the picked day is shown', (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('pick-date')));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('15').first);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.textContaining(' 15, '), findsOneWidget);
    });

    testWidgets('start and end time are tappable (time picker opens)',
        (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      for (final key in ['pick-start', 'pick-end']) {
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
        expect(find.byType(TimePickerDialog), findsOneWidget, reason: key);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      }
      // unchanged picks keep the default 09:00 - 10:00
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);
    });
  });

  group('CreateBookingPage - estate agent address (App-Edit)', () {
    testWidgets('Collect Keys shows Address Line / City / Postcode / County and '
        'composes them one per line', (tester) async {
      bigScreen(tester);
      final fake = _CapturingBookings();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith((ref) => _FakeAuth()),
          bookingsNotifierProvider.overrideWith((ref) => fake),
        ],
        child: const MaterialApp(home: CreateBookingPage()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Collect Keys'));
      await tester.pumpAndSettle();

      // the agent block has its own four address fields (they come after the property ones)
      Finder agent(String label) => find.widgetWithText(TextFormField, label).last;
      await tester.enterText(agent('Address Line'), '29 Taylor Drive');
      await tester.enterText(agent('City'), 'Chelmsford');
      await tester.enterText(agent('Postcode'), 'IG4 5DD');
      await tester.enterText(agent('County'), 'Essex');
      await tester.enterText(find.widgetWithText(TextFormField, 'Estate Agent Name'), 'Bravo Agent');
      await tester.pump();

      await tester.tap(find.byWidgetPredicate((w) => w is FilledButton));
      await tester.pumpAndSettle();

      expect(fake.captured['accessType'], BookingAccessType.collectKeys);
      expect(fake.captured['estateAgentName'], 'Bravo Agent');
      expect(fake.captured['estateAgentAddress'],
          '29 Taylor Drive\nChelmsford\nIG4 5DD\nEssex');
    });

    testWidgets('Direct Access sends no agent address', (tester) async {
      bigScreen(tester);
      final fake = _CapturingBookings();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith((ref) => _FakeAuth()),
          bookingsNotifierProvider.overrideWith((ref) => fake),
        ],
        child: const MaterialApp(home: CreateBookingPage()),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate((w) => w is FilledButton));
      await tester.pumpAndSettle();
      expect(fake.captured['accessType'], BookingAccessType.directAccess);
      expect(fake.captured['estateAgentAddress'], isNull);
    });
  });
}
