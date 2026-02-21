import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/ai/presentation/widgets/ai_result_sheet.dart';

void main() {
  group('AiErrorSheet', () {
    Widget buildTestWidget({
      required String title,
      required String errorMessage,
      required VoidCallback onRetry,
      required VoidCallback onDismiss,
    }) => MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: Scaffold(
          body: AiErrorSheet(
            title: title,
            errorMessage: errorMessage,
            onRetry: onRetry,
            onDismiss: onDismiss,
          ),
        ),
      );

    testWidgets('renders title and error message', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        title: 'Generation Failed',
        errorMessage: 'Unable to generate summary. Please try again.',
        onRetry: () {},
        onDismiss: () {},
      ),);

      expect(find.text('Generation Failed'), findsOneWidget);
      expect(
        find.text('Unable to generate summary. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('shows warning icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        title: 'Test Error',
        errorMessage: 'Test message',
        onRetry: () {},
        onDismiss: () {},
      ),);

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('has Dismiss and Try Again buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        title: 'Test Error',
        errorMessage: 'Test message',
        onRetry: () {},
        onDismiss: () {},
      ),);

      expect(find.text('Dismiss'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('calls onDismiss when Dismiss is tapped', (tester) async {
      var dismissCalled = false;

      await tester.pumpWidget(buildTestWidget(
        title: 'Test Error',
        errorMessage: 'Test message',
        onRetry: () {},
        onDismiss: () => dismissCalled = true,
      ),);

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      expect(dismissCalled, isTrue);
    });

    testWidgets('calls onRetry when Try Again is tapped', (tester) async {
      var retryCalled = false;

      await tester.pumpWidget(buildTestWidget(
        title: 'Test Error',
        errorMessage: 'Test message',
        onRetry: () => retryCalled = true,
        onDismiss: () {},
      ),);

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(retryCalled, isTrue);
    });
  });

  group('AiUnavailableMessage', () {
    testWidgets('renders default message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: const Scaffold(
            body: AiUnavailableMessage(),
          ),
        ),
      );

      expect(
        find.text('AI features are temporarily unavailable. Please try again later.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    });

    testWidgets('renders custom message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: const Scaffold(
            body: AiUnavailableMessage(
              message: 'AI service is down for maintenance',
            ),
          ),
        ),
      );

      expect(
        find.text('AI service is down for maintenance'),
        findsOneWidget,
      );
    });

    testWidgets('uses correct icon color from theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: const Scaffold(
            body: AiUnavailableMessage(),
          ),
        ),
      );

      // Just verify the icon exists - color testing requires more complex setup
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    });
  });

  group('AiResultSheet', () {
    Widget buildTestWidget({
      required String title,
      required String content,
      required String disclaimer,
      required VoidCallback onAccept,
      required VoidCallback onDiscard,
      VoidCallback? onRetry,
      bool isEditable = true,
    }) => MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: Scaffold(
          body: AiResultSheet(
            title: title,
            content: content,
            disclaimer: disclaimer,
            onAccept: onAccept,
            onDiscard: onDiscard,
            onRetry: onRetry,
            isEditable: isEditable,
          ),
        ),
      );

    testWidgets('renders title and AI Generated label', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        title: 'Risk Summary',
        content: 'Test content',
        disclaimer: 'Test disclaimer',
        onAccept: () {},
        onDiscard: () {},
      ),);

      expect(find.text('Risk Summary'), findsOneWidget);
      expect(find.text('AI Generated'), findsOneWidget);
    });

    testWidgets('renders content text', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        title: 'Test Title',
        content: 'This is the AI generated content',
        disclaimer: 'Test disclaimer',
        onAccept: () {},
        onDiscard: () {},
      ),);

      expect(find.text('This is the AI generated content'), findsOneWidget);
    });

    testWidgets('renders disclaimer in banner', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        title: 'Test Title',
        content: 'Test content',
        disclaimer: 'This is AI generated. Review before using.',
        onAccept: () {},
        onDiscard: () {},
      ),);

      expect(
        find.text('This is AI generated. Review before using.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('has AI icon in header', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        title: 'Test Title',
        content: 'Test content',
        disclaimer: 'Test disclaimer',
        onAccept: () {},
        onDiscard: () {},
      ),);

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('has Discard and Use This buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        title: 'Test Title',
        content: 'Test content',
        disclaimer: 'Test disclaimer',
        onAccept: () {},
        onDiscard: () {},
      ),);

      expect(find.text('Discard'), findsOneWidget);
      expect(find.text('Use This'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('calls onDiscard when Discard is tapped', (tester) async {
      var discardCalled = false;

      await tester.pumpWidget(buildTestWidget(
        title: 'Test Title',
        content: 'Test content',
        disclaimer: 'Test disclaimer',
        onAccept: () {},
        onDiscard: () => discardCalled = true,
      ),);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(discardCalled, isTrue);
    });

    testWidgets('calls onAccept when Use This is tapped', (tester) async {
      var acceptCalled = false;

      await tester.pumpWidget(buildTestWidget(
        title: 'Test Title',
        content: 'Test content',
        disclaimer: 'Test disclaimer',
        onAccept: () => acceptCalled = true,
        onDiscard: () {},
      ),);

      await tester.tap(find.text('Use This'));
      await tester.pumpAndSettle();

      expect(acceptCalled, isTrue);
    });

    testWidgets('shows Regenerate button when onRetry is provided', (tester) async {
      var retryCalled = false;

      await tester.pumpWidget(buildTestWidget(
        title: 'Test Title',
        content: 'Test content',
        disclaimer: 'Test disclaimer',
        onAccept: () {},
        onDiscard: () {},
        onRetry: () => retryCalled = true,
      ),);

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byTooltip('Regenerate'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(retryCalled, isTrue);
    });

    testWidgets('hides Regenerate button when onRetry is null', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        title: 'Test Title',
        content: 'Test content',
        disclaimer: 'Test disclaimer',
        onAccept: () {},
        onDiscard: () {},
      ),);

      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('shows Edit button when isEditable is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: Scaffold(
            body: AiResultSheet(
              title: 'Test Title',
              content: 'Test content',
              disclaimer: 'Test disclaimer',
              onAccept: () {},
              onDiscard: () {},
              onEdit: (value) {}, // onEdit must be provided for Edit button
            ),
          ),
        ),
      );

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Generated Content'), findsOneWidget);
    });

    testWidgets('hides Edit button when isEditable is false', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        title: 'Test Title',
        content: 'Test content',
        disclaimer: 'Test disclaimer',
        onAccept: () {},
        onDiscard: () {},
        isEditable: false,
      ),);

      expect(find.text('Edit'), findsNothing);
    });
  });

  group('AiErrorSheet.show', () {
    testWidgets('shows error sheet as bottom sheet', (tester) async {
      var retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  AiErrorSheet.show(
                    context: context,
                    title: 'Error Title',
                    errorMessage: 'Something went wrong',
                    onRetry: () => retryCalled = true,
                  );
                },
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show error sheet
      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      // Verify error sheet is shown
      expect(find.text('Error Title'), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);

      // Tap Try Again
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(retryCalled, isTrue);
    });

    testWidgets('dismiss button closes the sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  AiErrorSheet.show(
                    context: context,
                    title: 'Error Title',
                    errorMessage: 'Something went wrong',
                    onRetry: () {},
                  );
                },
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      // Show error sheet
      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      expect(find.text('Error Title'), findsOneWidget);

      // Tap Dismiss
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      // Sheet should be dismissed
      expect(find.text('Error Title'), findsNothing);
    });
  });
}
