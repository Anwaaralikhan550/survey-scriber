import 'package:drift/drift.dart';

import '../../../shared/domain/entities/survey_answer.dart' as entities;
import '../app_database.dart';
import '../tables/survey_answers_table.dart';

part 'survey_answers_dao.g.dart';

@DriftAccessor(tables: [SurveyAnswers])
class SurveyAnswersDao extends DatabaseAccessor<AppDatabase>
    with _$SurveyAnswersDaoMixin {
  SurveyAnswersDao(super.db);

  /// Get all answers for a survey
  Future<List<entities.SurveyAnswer>> getAnswersForSurvey(String surveyId) async {
    final results = await (select(surveyAnswers)
          ..where((a) => a.surveyId.equals(surveyId)))
        .get();
    return results.map(_mapToAnswer).toList();
  }

  /// Get all answers for a section
  Future<List<entities.SurveyAnswer>> getAnswersForSection(String sectionId) async {
    final results = await (select(surveyAnswers)
          ..where((a) => a.sectionId.equals(sectionId)))
        .get();
    return results.map(_mapToAnswer).toList();
  }

  /// Get answer by ID
  Future<entities.SurveyAnswer?> getAnswerById(String id) async {
    final result = await (select(surveyAnswers)
          ..where((a) => a.id.equals(id)))
        .getSingleOrNull();
    return result != null ? _mapToAnswer(result) : null;
  }

  /// Get answer by survey, section, and field key
  Future<entities.SurveyAnswer?> getAnswer(
    String surveyId,
    String sectionId,
    String fieldKey,
  ) async {
    final result = await (select(surveyAnswers)
          ..where((a) =>
              a.surveyId.equals(surveyId) &
              a.sectionId.equals(sectionId) &
              a.fieldKey.equals(fieldKey),))
        .getSingleOrNull();
    return result != null ? _mapToAnswer(result) : null;
  }

  /// Save an answer (insert or update)
  @Deprecated('Legacy V1 table — all new surveys use inspection_v2_answers')
  Future<void> saveAnswer(entities.SurveyAnswer answer) async {
    await into(surveyAnswers).insertOnConflictUpdate(_mapToCompanion(answer));
  }

  /// Save multiple answers
  @Deprecated('Legacy V1 table — all new surveys use inspection_v2_answers')
  Future<void> saveAnswers(List<entities.SurveyAnswer> answers) async {
    await batch((batch) {
      for (final answer in answers) {
        batch.insert(
          surveyAnswers,
          _mapToCompanion(answer),
          onConflict: DoUpdate((_) => _mapToCompanion(answer)),
        );
      }
    });
  }

  /// Delete all answers for a survey
  Future<void> deleteAnswersForSurvey(String surveyId) async {
    await (delete(surveyAnswers)..where((a) => a.surveyId.equals(surveyId)))
        .go();
  }

  /// Delete all answers for a section
  Future<void> deleteAnswersForSection(String sectionId) async {
    await (delete(surveyAnswers)..where((a) => a.sectionId.equals(sectionId)))
        .go();
  }

  /// Get section answers as a map
  Future<Map<String, String>> getSectionAnswersMap(String sectionId) async {
    final answers = await getAnswersForSection(sectionId);
    return {
      for (final answer in answers)
        if (answer.value != null) answer.fieldKey: answer.value!,
    };
  }

  /// Map database row to domain entity
  entities.SurveyAnswer _mapToAnswer(SurveyAnswer row) => entities.SurveyAnswer(
        id: row.id,
        surveyId: row.surveyId,
        sectionId: row.sectionId,
        fieldKey: row.fieldKey,
        value: row.value,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  /// Map domain entity to database companion
  SurveyAnswersCompanion _mapToCompanion(entities.SurveyAnswer answer) =>
      SurveyAnswersCompanion(
        id: Value(answer.id),
        surveyId: Value(answer.surveyId),
        sectionId: Value(answer.sectionId),
        fieldKey: Value(answer.fieldKey),
        value: Value(answer.value),
        createdAt: Value(answer.createdAt ?? DateTime.now()),
        updatedAt: Value(answer.updatedAt),
      );
}
