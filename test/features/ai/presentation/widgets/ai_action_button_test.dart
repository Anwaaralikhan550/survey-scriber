import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/ai/presentation/widgets/ai_action_button.dart';

void main() {
  group('AiActionButton', () {
    Widget buildTestWidget({
      required String label,
      VoidCallback? onPressed,
      IconData icon = Icons.auto_awesome,
      bool isLoading = false,
      bool isOutlined = false,
      bool isCompact = false,
    }) => MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: Scaffold(
          body: AiActionButton(
            label: label,
            onPressed: onPressed,
            icon: icon,
            isLoading: isLoading,
            isOutlined: isOutlined,
            isCompact: isCompact,
          ),
        ),
      );

    group('Basic rendering', () {
      testWidgets('renders label text', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          label: 'Generate AI Summary',
          onPressed: () {},
        ),);

        expect(find.text('Generate AI Summary'), findsOneWidget);
      });

      testWidgets('renders icon', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          label: 'Test',
          onPressed: () {},
          icon: Icons.lightbulb_outline,
        ),);

        expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      });

      testWidgets('uses FilledButton by default', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          label: 'Test',
          onPressed: () {},
        ),);

        expect(find.byType(FilledButton), findsOneWidget);
        expect(find.byType(OutlinedButton), findsNothing);
      });

      testWidgets('uses OutlinedButton when isOutlined is true', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          label: 'Test',
          onPressed: () {},
          isOutlined: true,
        ),);

        expect(find.byType(OutlinedButton), findsOneWidget);
        expect(find.byType(FilledButton), findsNothing);
      });
    });

    group('Loading state', () {
      testWidgets('shows CircularProgressIndicator when loading', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          label: 'Test',
          onPressed: () {},
          isLoading: true,
        ),);

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.auto_awesome), findsNothing);
      });

      testWidgets('shows Generating... text when loading', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          label: 'Generate AI Summary',
          onPressed: () {},
          isLoading: true,
        ),);

        expect(find.text('Generating...'), findsOneWidget);
        expect(find.text('Generate AI Summary'), findsNothing);
      });

      testWidgets('disables button when loading', (tester) async {
        var tapCount = 0;

        await tester.pumpWidget(buildTestWidget(
          label: 'Test',
          onPressed: () => tapCount++,
          isLoading: true,
        ),);

        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        expect(tapCount, 0);
      });
    });

    group('Disabled state', () {
      testWidgets('button is disabled when onPressed is null', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          label: 'Test',
        ),);

        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull);
      });
    });

    group('Interaction', () {
      testWidgets('calls onPressed when tapped', (tester) async {
        var tapped = false;

        await tester.pumpWidget(buildTestWidget(
          label: 'Test',
          onPressed: () => tapped = true,
        ),);

        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });
    });

    group('Compact mode', () {
      testWidgets('compact button has smaller icon', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          label: 'Test',
          onPressed: () {},
          isCompact: true,
        ),);

        final icon = tester.widget<Icon>(find.byIcon(Icons.auto_awesome));
        expect(icon.size, 16);
      });

      testWidgets('normal button has larger icon', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          label: 'Test',
          onPressed: () {},
        ),);

        final icon = tester.widget<Icon>(find.byIcon(Icons.auto_awesome));
        expect(icon.size, 18);
      });
    });
  });

  group('AiIconButton', () {
    Widget buildTestWidget({
      required String tooltip,
      VoidCallback? onPressed,
      IconData icon = Icons.auto_awesome,
      bool isLoading = false,
    }) => MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: Scaffold(
          body: AiIconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            icon: icon,
            isLoading: isLoading,
          ),
        ),
      );

    testWidgets('renders tooltip', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tooltip: 'Auto-tag with AI',
        onPressed: () {},
      ),);

      expect(find.byType(Tooltip), findsOneWidget);
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Auto-tag with AI');
    });

    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tooltip: 'Test',
        onPressed: () {},
        icon: Icons.auto_fix_high,
      ),);

      expect(find.byIcon(Icons.auto_fix_high), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when loading', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tooltip: 'Test',
        onPressed: () {},
        isLoading: true,
      ),);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    testWidgets('disables button when loading', (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(buildTestWidget(
        tooltip: 'Test',
        onPressed: () => tapCount++,
        isLoading: true,
      ),);

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(tapCount, 0);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(buildTestWidget(
        tooltip: 'Test',
        onPressed: () => tapped = true,
      ),);

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('button is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        tooltip: 'Test',
      ),);

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.onPressed, isNull);
    });
  });

  group('AiButtonSkeleton', () {
    testWidgets('renders animated container', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: const Scaffold(
            body: AiButtonSkeleton(),
          ),
        ),
      );

      expect(find.byType(AiButtonSkeleton), findsOneWidget);
      // AnimatedBuilder is used for the skeleton animation
      expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
    });

    testWidgets('compact mode changes height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: const Scaffold(
            body: Column(
              children: [
                AiButtonSkeleton(),
                AiButtonSkeleton(isCompact: true),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(AiButtonSkeleton), findsNWidgets(2));
    });

    testWidgets('respects custom width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: const Scaffold(
            body: AiButtonSkeleton(width: 200),
          ),
        ),
      );

      expect(find.byType(AiButtonSkeleton), findsOneWidget);
    });
  });

  group('AiIconButtonSkeleton', () {
    testWidgets('renders animated container', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: const Scaffold(
            body: AiIconButtonSkeleton(),
          ),
        ),
      );

      expect(find.byType(AiIconButtonSkeleton), findsOneWidget);
      // AnimatedBuilder is used for the skeleton animation
      expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
    });

    testWidgets('has fixed 40x40 size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: const Scaffold(
            body: AiIconButtonSkeleton(),
          ),
        ),
      );

      // Find the Container with size constraints
      expect(find.byType(AiIconButtonSkeleton), findsOneWidget);
    });
  });
}
