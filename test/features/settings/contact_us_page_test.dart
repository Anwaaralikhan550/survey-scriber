// Client file (4), 10 Nov 2026: Contact Us in the app.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:survey_scriber/core/error/exceptions.dart';
import 'package:survey_scriber/core/network/api_client.dart';
import 'package:survey_scriber/features/settings/presentation/pages/contact_us_page.dart';

class _Api extends Mock implements ApiClient {}

Future<_Api> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final api = _Api();
  final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(
        path: '/start',
        builder: (context, _) => Scaffold(
          body: TextButton(onPressed: () => context.push('/contact'), child: const Text('OPEN')),
        ),
      ),
      GoRoute(path: '/contact', builder: (_, __) => const ContactUsPage()),
      GoRoute(path: '/settings', builder: (_, __) => const Scaffold(body: Text('SETTINGS'))),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(api)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.tap(find.text('OPEN'));
  await tester.pumpAndSettle();
  return api;
}

Future<void> _fill(WidgetTester tester, {String email = 'grace@example.com', String subject = 'My report', String message = 'Hello'}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), subject);
  await tester.enterText(fields.at(2), message);
  await tester.pump();
}

Future<void> _send(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Send'));
  await tester.tap(find.text('Send'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('has Email, Subject and Message, and refuses an empty form', (tester) async {
    final api = await _open(tester);
    expect(find.text('Contact Us'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Subject'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Message'), findsOneWidget);
    await _send(tester);
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter a subject'), findsOneWidget);
    expect(find.text('Please enter a message'), findsOneWidget);
    verifyNever(() => api.post<void>(any(), data: any(named: 'data')));
  });

  testWidgets('a wrong email address is refused before anything is sent', (tester) async {
    final api = await _open(tester);
    await _fill(tester, email: 'not-an-email');
    await _send(tester);
    expect(find.text('Please enter a valid email'), findsOneWidget);
    verifyNever(() => api.post<void>(any(), data: any(named: 'data')));
  });

  testWidgets('sends exactly what was typed, thanks the person and goes back', (tester) async {
    final api = await _open(tester);
    when(() => api.post<void>('contact', data: any(named: 'data'))).thenAnswer(
      (_) async => Response<void>(requestOptions: RequestOptions(path: 'contact')),
    );
    await _fill(tester, message: '  Line one\nLine two  ');
    await _send(tester);
    final sent = verify(() => api.post<void>('contact', data: captureAny(named: 'data'))).captured.single as Map;
    expect(sent, {'email': 'grace@example.com', 'subject': 'My report', 'message': 'Line one\nLine two'});
    expect(find.text('Thank you. Your message has been sent.'), findsOneWidget);
    expect(find.text('Contact Us'), findsNothing);
  });

  testWidgets('when the server says no, the person reads why and can try again', (tester) async {
    final api = await _open(tester);
    when(() => api.post<void>('contact', data: any(named: 'data')))
        .thenThrow(const ServerException(message: 'Your message could not be sent. Please try again in a few minutes.', statusCode: 503));
    await _fill(tester);
    await _send(tester);
    expect(find.text('Your message could not be sent. Please try again in a few minutes.'), findsOneWidget);
    expect(find.text('Contact Us'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
  });

  test('the words for each kind of failure', () {
    expect(ContactUsPage.messageFor(const NetworkException()), contains('No internet connection'));
    expect(ContactUsPage.messageFor(const RateLimitException()), contains('try again later'));
    expect(ContactUsPage.messageFor(const ServerException()), contains('could not be sent'));
  });
}
