import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/scheduling/domain/entities/booking.dart';
import 'package:survey_scriber/features/scheduling/presentation/pages/create_booking_page.dart';

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
}
