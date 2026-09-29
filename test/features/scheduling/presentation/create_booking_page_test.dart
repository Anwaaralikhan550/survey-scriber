import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
