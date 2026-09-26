import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/dashboard/presentation/pages/jobs_list_page.dart';
import 'package:survey_scriber/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

void main() {
  Survey survey(String id, SurveyStatus status) => Survey(
        id: id,
        title: 'Survey $id',
        type: SurveyType.inspection,
        status: status,
        createdAt: DateTime(2026, 1, 1),
      );

  Widget host(Widget child, {required List<Survey> jobs}) => ProviderScope(
        overrides: [
          jobsListProvider.overrideWith((ref, key) async =>
              jobs.where(key.filter.matches).toList()),
        ],
        child: MaterialApp(home: child),
      );

  group('JobsListPage View-all filter bar (App-Edit req 7)', () {
    testWidgets(
        'shows the All / Live / In Progress / Completed selector when '
        'showFilterBar is true', (tester) async {
      await tester.pumpWidget(host(
        const JobsListPage(
          segment: HomeSegment.homeSurveys,
          initialFilter: JobFilter.all,
          showFilterBar: true,
        ),
        jobs: [survey('1', SurveyStatus.draft)],
      ));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Live'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'In Progress'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Completed'), findsOneWidget);
      // "This week" is never a View-all option.
      expect(find.widgetWithText(ChoiceChip, 'This Week'), findsNothing);
      // The Survey Folder context is shown in the app bar.
      expect(find.text('Survey Folder'), findsOneWidget);
    });

    testWidgets('no filter selector for a single-filter (metric-card) view',
        (tester) async {
      await tester.pumpWidget(host(
        const JobsListPage(
          segment: HomeSegment.homeSurveys,
          initialFilter: JobFilter.inProgress,
        ),
        jobs: [survey('1', SurveyStatus.inProgress)],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsNothing);
      // App-bar title reflects the single fixed filter (scoped to the AppBar,
      // since a survey card may also show an "In Progress" status chip).
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('In Progress'),
        ),
        findsOneWidget,
      );
    });
  });
}
