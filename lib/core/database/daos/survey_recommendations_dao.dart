import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/survey_recommendations_table.dart';

part 'survey_recommendations_dao.g.dart';

@DriftAccessor(tables: [SurveyRecommendations])
class SurveyRecommendationsDao extends DatabaseAccessor<AppDatabase>
    with _$SurveyRecommendationsDaoMixin {
  SurveyRecommendationsDao(super.db);

  /// Get all recommendations for a survey.
  Future<List<SurveyRecommendation>> getBySurvey(String surveyId) {
    return (select(surveyRecommendations)
          ..where((r) => r.surveyId.equals(surveyId))
          ..orderBy([
            (r) => OrderingTerm(expression: r.severity),
            (r) => OrderingTerm(expression: r.category),
          ]))
        .get();
  }

  /// Get only accepted recommendations for a survey (used during export).
  Future<List<SurveyRecommendation>> getAcceptedBySurvey(String surveyId) {
    return (select(surveyRecommendations)
          ..where(
              (r) => r.surveyId.equals(surveyId) & r.accepted.equals(true)))
        .get();
  }

  /// Insert a batch of recommendations.
  Future<void> insertAll(List<SurveyRecommendationsCompanion> rows) async {
    await batch((b) => b.insertAll(surveyRecommendations, rows));
  }

  /// Mark a recommendation as accepted or unaccepted.
  Future<void> setAccepted(String id, {required bool accepted}) {
    return (update(surveyRecommendations)..where((r) => r.id.equals(id)))
        .write(SurveyRecommendationsCompanion(accepted: Value(accepted)));
  }

  /// Delete all recommendations for a survey.
  Future<void> deleteBySurvey(String surveyId) {
    return (delete(surveyRecommendations)
          ..where((r) => r.surveyId.equals(surveyId)))
        .go();
  }

  /// Replace all recommendations for a survey (re-analysis).
  ///
  /// Preserves `accepted` state for recommendations that match by
  /// screenId + fieldId + category.
  Future<void> replaceForSurvey(
    String surveyId,
    List<SurveyRecommendationsCompanion> newRows,
  ) async {
    await transaction(() async {
      // Read existing accepted state
      final existing = await getBySurvey(surveyId);
      final acceptedKeys = <String>{};
      for (final r in existing) {
        if (r.accepted) {
          acceptedKeys.add('${r.screenId}|${r.fieldId ?? ''}|${r.category}');
        }
      }

      // Delete old
      await deleteBySurvey(surveyId);

      // Insert new, restoring accepted state where applicable
      final restored = newRows.map((row) {
        final key =
            '${row.screenId.value}|${row.fieldId.value ?? ''}|${row.category.value}';
        if (acceptedKeys.contains(key)) {
          return row.copyWith(accepted: const Value(true));
        }
        return row;
      }).toList();

      if (restored.isNotEmpty) {
        await insertAll(restored);
      }
    });
  }
}
