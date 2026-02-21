import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/survey_quality_scores_table.dart';

part 'survey_quality_scores_dao.g.dart';

@DriftAccessor(tables: [SurveyQualityScores])
class SurveyQualityScoresDao extends DatabaseAccessor<AppDatabase>
    with _$SurveyQualityScoresDaoMixin {
  SurveyQualityScoresDao(super.db);

  /// Get the latest quality scores for a survey.
  Future<SurveyQualityScore?> getLatestBySurvey(String surveyId) async {
    final rows = await (select(surveyQualityScores)
          ..where((s) => s.surveyId.equals(surveyId))
          ..orderBy([(s) => OrderingTerm.desc(s.generatedAt)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  /// Insert or replace scores for a survey.
  Future<void> upsert(SurveyQualityScoresCompanion row) async {
    await into(surveyQualityScores).insertOnConflictUpdate(row);
  }

  /// Delete all scores for a survey.
  Future<void> deleteBySurvey(String surveyId) {
    return (delete(surveyQualityScores)
          ..where((s) => s.surveyId.equals(surveyId)))
        .go();
  }
}
