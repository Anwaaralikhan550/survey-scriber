import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/dashboard/presentation/pages/jobs_list_page.dart';
import 'package:survey_scriber/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

Survey _survey(SurveyStatus status, {SurveyType type = SurveyType.inspection}) =>
    Survey(
      id: 's-$status-$type',
      title: 'Test',
      type: type,
      status: status,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('JobFilter.all (App-Edit brief: View all = All/Live/In Progress/Completed)',
      () {
    test('title is "All"', () {
      expect(JobFilter.all.title, 'All');
    });

    test('matches every survey regardless of status', () {
      for (final status in SurveyStatus.values) {
        expect(JobFilter.all.matches(_survey(status)), isTrue,
            reason: 'All should match $status');
      }
    });

    test('the other status filters remain status-specific', () {
      expect(JobFilter.live.matches(_survey(SurveyStatus.draft)), isTrue);
      expect(JobFilter.live.matches(_survey(SurveyStatus.inProgress)), isFalse);
      expect(
          JobFilter.inProgress.matches(_survey(SurveyStatus.inProgress)), isTrue);
      expect(
          JobFilter.completed.matches(_survey(SurveyStatus.completed)), isTrue);
    });
  });

  group('Survey Folder "View all" filter options', () {
    test('offers exactly All, Live, In Progress, Completed — in order', () {
      expect(
        JobsListPage.filterBarOptions,
        <JobFilter>[
          JobFilter.all,
          JobFilter.live,
          JobFilter.inProgress,
          JobFilter.completed,
        ],
      );
      // "This week" is an analytics card only — never a View-all option.
      expect(JobsListPage.filterBarOptions, isNot(contains(JobFilter.thisWeek)));
    });
  });
}
