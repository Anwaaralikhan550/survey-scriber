// Client file (4), 10 Nov 2026: Sign Up now ends with "check your email" instead of an automatic sign-in.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:survey_scriber/features/auth/presentation/pages/register_page.dart';
import 'package:survey_scriber/features/auth/presentation/providers/auth_notifier.dart';
import 'package:survey_scriber/features/auth/presentation/providers/auth_state.dart';

class _FakeAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuth() : super(const AuthState());

  int registers = 0;
  int logins = 0;

  @override
  Future<(bool, AuthFailureType)> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    String? organization,
  }) async {
    registers++;
    return (true, AuthFailureType.none);
  }

  @override
  Future<(bool, AuthFailureType)> login({
    required String email,
    required String password,
  }) async {
    logins++;
    return (true, AuthFailureType.none);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('after signing up: a Check your email message, no automatic sign-in, then the login page', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final auth = _FakeAuth();
    final router = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
        GoRoute(path: '/login', builder: (_, __) => const Scaffold(body: Text('LOGIN PAGE'))),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authNotifierProvider.overrideWith((_) => auth)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(fields, findsWidgets);
    await tester.enterText(fields.at(0), 'Grace');
    await tester.enterText(fields.at(1), 'Hill');
    await tester.enterText(fields.at(2), 'grace@example.com');
    await tester.enterText(fields.at(3), 'Passw0rd!x');
    await tester.enterText(fields.at(4), 'Passw0rd!x');
    await tester.pump();

    final create = find.widgetWithText(ElevatedButton, 'Create Account');
    final button = create.evaluate().isNotEmpty ? create : find.text('Create Account');
    await tester.ensureVisible(button.first);
    await tester.tap(button.first);
    await tester.pumpAndSettle();

    expect(auth.registers, 1);
    expect(auth.logins, 0);
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.textContaining('activate your account'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('LOGIN PAGE'), findsOneWidget);
  });
}
