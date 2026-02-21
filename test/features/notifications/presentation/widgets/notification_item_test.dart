import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/notifications/domain/entities/notification.dart';
import 'package:survey_scriber/features/notifications/presentation/widgets/notification_item.dart';

void main() {
  group('NotificationItem', () {
    late AppNotification normalNotification;
    late AppNotification expiredNotification;

    setUp(() {
      normalNotification = AppNotification(
        id: 'notif-1',
        type: NotificationType.bookingCreated,
        title: 'New Booking Created',
        body: 'A new booking was created for tomorrow at 10:00 AM',
        isRead: false,
        createdAt: DateTime.now(),
        bookingId: 'booking-123',
      );

      expiredNotification = AppNotification(
        id: 'notif-2',
        type: NotificationType.bookingCreated,
        title: 'Old Booking Notification',
        body: 'This booking no longer exists',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        bookingId: 'booking-deleted',
        bookingDeleted: true, // Booking was deleted
      );
    });

    Widget buildTestWidget({
      required AppNotification notification,
      VoidCallback? onTap,
      VoidCallback? onExpiredTap,
      VoidCallback? onMarkAsRead,
      VoidCallback? onDelete,
    }) => MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: Scaffold(
          body: NotificationItem(
            notification: notification,
            onTap: onTap,
            onExpiredTap: onExpiredTap,
            onMarkAsRead: onMarkAsRead,
            onDelete: onDelete,
          ),
        ),
      );

    group('Normal Notification', () {
      testWidgets('renders title and body correctly', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          notification: normalNotification,
        ),);

        expect(find.text('New Booking Created'), findsOneWidget);
        expect(find.text('A new booking was created for tomorrow at 10:00 AM'), findsOneWidget);
      });

      testWidgets('calls onTap when tapped (not expired)', (tester) async {
        var tapCalled = false;
        var expiredTapCalled = false;

        await tester.pumpWidget(buildTestWidget(
          notification: normalNotification,
          onTap: () => tapCalled = true,
          onExpiredTap: () => expiredTapCalled = true,
        ),);

        await tester.tap(find.byType(NotificationItem));
        await tester.pumpAndSettle();

        expect(tapCalled, isTrue);
        expect(expiredTapCalled, isFalse);
      });

      testWidgets('does not show Expired badge', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          notification: normalNotification,
        ),);

        expect(find.text('Expired'), findsNothing);
      });

      testWidgets('shows mark as read button when unread', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          notification: normalNotification,
          onMarkAsRead: () {},
        ),);

        expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
      });
    });

    group('Expired Notification (bookingDeleted=true)', () {
      testWidgets('renders title and body correctly', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          notification: expiredNotification,
        ),);

        expect(find.text('Old Booking Notification'), findsOneWidget);
        expect(find.text('This booking no longer exists'), findsOneWidget);
      });

      testWidgets('shows Expired badge', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          notification: expiredNotification,
        ),);

        expect(find.text('Expired'), findsOneWidget);
      });

      testWidgets('calls onExpiredTap instead of onTap when tapped', (tester) async {
        var tapCalled = false;
        var expiredTapCalled = false;

        await tester.pumpWidget(buildTestWidget(
          notification: expiredNotification,
          onTap: () => tapCalled = true,
          onExpiredTap: () => expiredTapCalled = true,
        ),);

        await tester.tap(find.byType(NotificationItem));
        await tester.pumpAndSettle();

        expect(tapCalled, isFalse);
        expect(expiredTapCalled, isTrue);
      });

      testWidgets('does NOT call onTap when bookingDeleted is true', (tester) async {
        var tapCalled = false;

        await tester.pumpWidget(buildTestWidget(
          notification: expiredNotification,
          onTap: () => tapCalled = true,
          // No onExpiredTap provided
        ),);

        await tester.tap(find.byType(NotificationItem));
        await tester.pumpAndSettle();

        // onTap should NOT be called because bookingDeleted is true
        expect(tapCalled, isFalse);
      });

      testWidgets('hides mark as read button when expired', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          notification: expiredNotification,
          onMarkAsRead: () {},
        ),);

        // Mark as read button should not appear for expired notifications
        expect(find.byIcon(Icons.check_circle_outline_rounded), findsNothing);
      });

      testWidgets('uses event_busy icon for expired notifications', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          notification: expiredNotification,
        ),);

        expect(find.byIcon(Icons.event_busy_rounded), findsOneWidget);
      });

      testWidgets('has reduced opacity (visual treatment)', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          notification: expiredNotification,
        ),);

        // Find the Opacity widget and verify its value
        final opacityFinder = find.byType(Opacity);
        expect(opacityFinder, findsOneWidget);

        final opacityWidget = tester.widget<Opacity>(opacityFinder);
        expect(opacityWidget.opacity, equals(0.5));
      });
    });

    group('Visual Comparison', () {
      testWidgets('normal notification has full opacity', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          notification: normalNotification,
        ),);

        final opacityFinder = find.byType(Opacity);
        expect(opacityFinder, findsOneWidget);

        final opacityWidget = tester.widget<Opacity>(opacityFinder);
        expect(opacityWidget.opacity, equals(1.0));
      });
    });

    group('Swipe to Delete', () {
      testWidgets('shows Dismissible when onDelete is provided', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          notification: normalNotification,
          onDelete: () {},
        ),);

        expect(find.byType(Dismissible), findsOneWidget);
      });

      testWidgets('does not show Dismissible when onDelete is null', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          notification: normalNotification,
        ),);

        expect(find.byType(Dismissible), findsNothing);
      });

      testWidgets('calls onDelete when swiped', (tester) async {
        var deleteCalled = false;

        await tester.pumpWidget(buildTestWidget(
          notification: normalNotification,
          onDelete: () => deleteCalled = true,
        ),);

        // Swipe left to delete
        await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
        await tester.pumpAndSettle();

        expect(deleteCalled, isTrue);
      });

      testWidgets('shows delete icon on swipe background', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          notification: normalNotification,
          onDelete: () {},
        ),);

        // Start dragging to reveal background
        await tester.drag(find.byType(Dismissible), const Offset(-100, 0));
        await tester.pump();

        expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      });
    });
  });
}
