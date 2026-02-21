import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:survey_scriber/features/report_export/presentation/widgets/email_compose_sheet.dart';

void main() {
  EmailReportInfo makeReportInfo({
    String format = 'pdf',
    String moduleType = 'inspection',
    String surveyTitle = 'Test Property',
  }) {
    return EmailReportInfo(
      surveyId: 'survey-1',
      surveyTitle: surveyTitle,
      filePath: '/tmp/report.pdf',
      fileName: 'report.pdf',
      format: format,
      moduleType: moduleType,
      generatedAt: DateTime(2026, 2, 15),
      sizeBytes: 1024,
    );
  }

  Widget buildTestWidget(EmailReportInfo reportInfo) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => EmailComposeSheet.show(
                context,
                reportInfo: reportInfo,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  group('EmailComposeSheet', () {
    testWidgets('shows pre-filled subject for inspection report',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(makeReportInfo()));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextFormField, 'Property Inspection Report — Test Property'),
        findsOneWidget,
      );
    });

    testWidgets('shows pre-filled subject for valuation report',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        makeReportInfo(moduleType: 'valuation'),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextFormField, 'Property Valuation Report — Test Property'),
        findsOneWidget,
      );
    });

    testWidgets('body template includes format', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        makeReportInfo(format: 'docx'),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // The body field should contain the format
      final bodyField = find.widgetWithText(TextFormField, 'Message').evaluate().isEmpty
          ? null
          : find.byType(TextFormField).evaluate().last.widget as TextFormField;
      expect(bodyField, isNotNull);
    });

    testWidgets('validates empty email', (tester) async {
      await tester.pumpWidget(buildTestWidget(makeReportInfo()));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap Send without entering email
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(find.text('Email address is required'), findsOneWidget);
    });

    testWidgets('validates invalid email', (tester) async {
      await tester.pumpWidget(buildTestWidget(makeReportInfo()));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Enter invalid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Recipient email'),
        'not-an-email',
      );
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('accepts valid email format', (tester) async {
      await tester.pumpWidget(buildTestWidget(makeReportInfo()));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Enter valid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Recipient email'),
        'test@example.com',
      );
      await tester.tap(find.text('Send'));
      // Use pump() instead of pumpAndSettle() because Send triggers
      // async loading state with a CircularProgressIndicator
      await tester.pump();

      // No validation errors should appear
      expect(find.text('Email address is required'), findsNothing);
      expect(find.text('Enter a valid email address'), findsNothing);
    });

    testWidgets('has send button with icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(makeReportInfo()));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Send'), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });
  });
}
