import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:survey_scriber/app/router/routes.dart';

void main() {
  test('the route path carries the survey id, the report type and the title', () {
    expect(Routes.surveyDesktopEditing, '/survey/:id/desktop-editing');
    expect(
      Routes.surveyDesktopEditingPath('abc-123', valuation: true, title: 'A B & C'),
      '/survey/abc-123/desktop-editing?valuation=true&title=A+B+%26+C',
    );
    expect(Routes.surveyDesktopEditingPath('abc-123', valuation: false), '/survey/abc-123/desktop-editing?valuation=false');
  });

  testWidgets('the same path pattern the app router uses resolves the id and the query values', (tester) async {
    String? id;
    String? valuation;
    String? title;
    final router = GoRouter(
      initialLocation: Routes.surveyDesktopEditingPath('s-1', valuation: true, title: 'A B & C'),
      routes: [
        GoRoute(
          path: Routes.surveyDesktopEditing,
          builder: (context, state) {
            id = state.pathParameters['id'];
            valuation = state.uri.queryParameters['valuation'];
            title = state.uri.queryParameters['title'];
            return const SizedBox();
          },
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect([id, valuation, title], ['s-1', 'true', 'A B & C']);
  });
}
