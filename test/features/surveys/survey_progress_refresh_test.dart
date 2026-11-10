// Client file (3), 10 Nov 2026: "Percentage completion tally only works after
// you leave the report and reopen it". Marking a screen complete now re-reads
// the open overview's survey (its progress ring).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/surveys/domain/repositories/survey_repository.dart';
import 'package:survey_scriber/features/surveys/presentation/providers/survey_detail_provider.dart';
import 'package:survey_scriber/features/surveys/presentation/providers/survey_providers.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

class _CountingRepo implements SurveyRepository {
  final loads = <String, int>{};

  @override
  Future<Survey?> getSurveyById(String id) async {
    loads[id] = (loads[id] ?? 0) + 1;
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('an open overview re-reads its survey; nothing happens when none is open', () async {
    final repo = _CountingRepo();
    final container = ProviderContainer(
      overrides: [localSurveyRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final refProvider = Provider<Ref>((ref) => ref);

    container.listen(surveyDetailProvider('open'), (_, __) {});
    await Future<void>.delayed(Duration.zero);
    expect(repo.loads['open'], 1);

    refreshSurveyProgress(container.read(refProvider), 'open');
    await Future<void>.delayed(Duration.zero);
    expect(repo.loads['open'], 2);

    refreshSurveyProgress(container.read(refProvider), 'closed');
    await Future<void>.delayed(Duration.zero);
    expect(repo.loads['closed'], isNull);
  });
}
