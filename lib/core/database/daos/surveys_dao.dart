import 'package:drift/drift.dart';

import '../../../shared/domain/entities/survey.dart' as entities;
import '../app_database.dart';
import '../tables/surveys_table.dart';

part 'surveys_dao.g.dart';

@DriftAccessor(tables: [Surveys])
class SurveysDao extends DatabaseAccessor<AppDatabase> with _$SurveysDaoMixin {
  SurveysDao(super.db);

  /// Get all active (non-deleted) surveys
  Future<List<entities.Survey>> getAllSurveys() async {
    final results = await (select(surveys)
          ..where((s) => s.deletedAt.isNull()))
        .get();
    return results.map(_mapToSurvey).toList();
  }

  /// Get surveys by status (excludes soft-deleted)
  Future<List<entities.Survey>> getSurveysByStatus(entities.SurveyStatus status) async {
    final results = await (select(surveys)
          ..where((s) => s.status.equals(status.name) & s.deletedAt.isNull()))
        .get();
    return results.map(_mapToSurvey).toList();
  }

  /// Get in-progress surveys (draft, inProgress, paused) — excludes soft-deleted
  Future<List<entities.Survey>> getInProgressSurveys() async {
    final results = await (select(surveys)
          ..where((s) => s.status.isIn([
                entities.SurveyStatus.draft.name,
                entities.SurveyStatus.inProgress.name,
                entities.SurveyStatus.paused.name,
              ]) & s.deletedAt.isNull(),))
        .get();
    return results.map(_mapToSurvey).toList();
  }

  /// Get completed surveys — excludes soft-deleted
  Future<List<entities.Survey>> getCompletedSurveys() async {
    final results = await (select(surveys)
          ..where((s) => s.status.isIn([
                entities.SurveyStatus.completed.name,
                entities.SurveyStatus.pendingReview.name,
                entities.SurveyStatus.approved.name,
              ]) & s.deletedAt.isNull(),))
        .get();
    return results.map(_mapToSurvey).toList();
  }

  /// Get recent surveys — excludes soft-deleted
  Future<List<entities.Survey>> getRecentSurveys({int limit = 5}) async {
    final results = await (select(surveys)
          ..where((s) => s.deletedAt.isNull())
          ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])
          ..limit(limit))
        .get();
    return results.map(_mapToSurvey).toList();
  }

  /// Get survey by ID
  Future<entities.Survey?> getSurveyById(String id) async {
    final result = await (select(surveys)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    return result != null ? _mapToSurvey(result) : null;
  }

  /// Insert a new survey
  Future<void> insertSurvey(entities.Survey survey) async {
    await into(surveys).insert(_mapToCompanion(survey));
  }

  /// Update a survey
  Future<void> updateSurvey(entities.Survey survey) async {
    await (update(surveys)..where((s) => s.id.equals(survey.id)))
        .write(_mapToCompanion(survey));
  }

  /// Upsert a survey (insert or update on conflict).
  /// Used by sync pull to idempotently apply server changes.
  Future<void> upsertSurvey(entities.Survey survey) async {
    await into(surveys).insertOnConflictUpdate(_mapToCompanion(survey));
  }

  /// Delete a survey
  Future<void> deleteSurvey(String id) async {
    await (delete(surveys)..where((s) => s.id.equals(id))).go();
  }

  /// Update survey progress
  Future<void> updateSurveyProgress(
    String surveyId,
    int completedSections,
    int totalSections,
  ) async {
    final progress = totalSections > 0 ? completedSections / totalSections : 0.0;
    await (update(surveys)..where((s) => s.id.equals(surveyId))).write(
      SurveysCompanion(
        completedSections: Value(completedSections),
        totalSections: Value(totalSections),
        progress: Value(progress),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update survey status
  Future<void> updateSurveyStatus(String surveyId, entities.SurveyStatus status) async {
    final now = DateTime.now();

    if (status == entities.SurveyStatus.completed) {
      await (update(surveys)..where((s) => s.id.equals(surveyId))).write(
        SurveysCompanion(
          status: Value(status.name),
          updatedAt: Value(now),
          completedAt: Value(now),
        ),
      );
    } else if (status == entities.SurveyStatus.inProgress) {
      // Set startedAt on first transition to inProgress (only if not already set)
      final existing = await getSurveyById(surveyId);
      final companion = SurveysCompanion(
        status: Value(status.name),
        updatedAt: Value(now),
        startedAt: existing?.startedAt == null ? Value(now) : const Value.absent(),
      );
      await (update(surveys)..where((s) => s.id.equals(surveyId)))
          .write(companion);
    } else {
      await (update(surveys)..where((s) => s.id.equals(surveyId))).write(
        SurveysCompanion(
          status: Value(status.name),
          updatedAt: Value(now),
        ),
      );
    }
  }

  /// Get total survey count (excludes soft-deleted)
  Future<int> getTotalSurveyCount() async {
    final count = surveys.id.count();
    final query = selectOnly(surveys)
      ..addColumns([count])
      ..where(surveys.deletedAt.isNull());
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Get in-progress count (excludes soft-deleted)
  Future<int> getInProgressCount() async {
    final count = surveys.id.count();
    final query = selectOnly(surveys)
      ..addColumns([count])
      ..where(surveys.status.isIn([
        entities.SurveyStatus.draft.name,
        entities.SurveyStatus.inProgress.name,
        entities.SurveyStatus.paused.name,
      ]) & surveys.deletedAt.isNull(),);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Get completed count (excludes soft-deleted)
  Future<int> getCompletedCount() async {
    final count = surveys.id.count();
    final query = selectOnly(surveys)
      ..addColumns([count])
      ..where(surveys.status.isIn([
        entities.SurveyStatus.completed.name,
        entities.SurveyStatus.pendingReview.name,
        entities.SurveyStatus.approved.name,
      ]) & surveys.deletedAt.isNull(),);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Update AI summary for a survey
  Future<void> updateAiSummary(String surveyId, String? summary) async {
    await (update(surveys)..where((s) => s.id.equals(surveyId))).write(
      SurveysCompanion(
        aiSummary: Value(summary),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update risk summary for a survey
  Future<void> updateRiskSummary(String surveyId, String? summary) async {
    await (update(surveys)..where((s) => s.id.equals(surveyId))).write(
      SurveysCompanion(
        riskSummary: Value(summary),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update repair recommendations for a survey
  Future<void> updateRepairRecommendations(String surveyId, String? recommendations) async {
    await (update(surveys)..where((s) => s.id.equals(surveyId))).write(
      SurveysCompanion(
        repairRecommendations: Value(recommendations),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Get parent survey (original survey for re-inspections)
  Future<entities.Survey?> getParentSurvey(String parentSurveyId) async => getSurveyById(parentSurveyId);

  /// Get all re-inspections of a survey
  Future<List<entities.Survey>> getReinspections(String parentSurveyId) async {
    final results = await (select(surveys)
          ..where((s) => s.parentSurveyId.equals(parentSurveyId))
          ..orderBy([(s) => OrderingTerm.asc(s.reinspectionNumber)]))
        .get();
    return results.map(_mapToSurvey).toList();
  }

  /// Get the next re-inspection number for a survey
  Future<int> getNextReinspectionNumber(String parentSurveyId) async {
    final max = surveys.reinspectionNumber.max();
    final query = selectOnly(surveys)
      ..addColumns([max])
      ..where(surveys.parentSurveyId.equals(parentSurveyId));
    final result = await query.getSingle();
    return (result.read(max) ?? 0) + 1;
  }

  /// Check if survey has any re-inspections
  Future<bool> hasReinspections(String surveyId) async {
    final count = surveys.id.count();
    final query = selectOnly(surveys)
      ..addColumns([count])
      ..where(surveys.parentSurveyId.equals(surveyId));
    final result = await query.getSingle();
    return (result.read(count) ?? 0) > 0;
  }

  /// Get latest re-inspection of a survey
  Future<entities.Survey?> getLatestReinspection(String parentSurveyId) async {
    final result = await (select(surveys)
          ..where((s) => s.parentSurveyId.equals(parentSurveyId))
          ..orderBy([(s) => OrderingTerm.desc(s.reinspectionNumber)])
          ..limit(1))
        .getSingleOrNull();
    return result != null ? _mapToSurvey(result) : null;
  }

  /// Map database row to domain entity
  entities.Survey _mapToSurvey(Survey row) => entities.Survey(
        id: row.id,
        title: row.title,
        type: entities.SurveyType.values.firstWhere(
          (t) => t.name == row.type,
          orElse: () => entities.SurveyType.other,
        ),
        status: entities.SurveyStatus.values.firstWhere(
          (s) => s.name == row.status,
          orElse: () => entities.SurveyStatus.draft,
        ),
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        startedAt: row.startedAt,
        completedAt: row.completedAt,
        jobRef: row.jobRef,
        address: row.address,
        clientName: row.clientName,
        progress: row.progress,
        photoCount: row.photoCount,
        noteCount: row.noteCount,
        totalSections: row.totalSections,
        completedSections: row.completedSections,
        parentSurveyId: row.parentSurveyId,
        reinspectionNumber: row.reinspectionNumber,
        aiSummary: row.aiSummary,
        riskSummary: row.riskSummary,
        repairRecommendations: row.repairRecommendations,
        deletedAt: row.deletedAt,
      );

  /// Map domain entity to database companion
  SurveysCompanion _mapToCompanion(entities.Survey survey) => SurveysCompanion(
        id: Value(survey.id),
        title: Value(survey.title),
        type: Value(survey.type.name),
        status: Value(survey.status.name),
        createdAt: Value(survey.createdAt),
        updatedAt: Value(survey.updatedAt),
        startedAt: Value(survey.startedAt),
        completedAt: Value(survey.completedAt),
        jobRef: Value(survey.jobRef),
        address: Value(survey.address),
        clientName: Value(survey.clientName),
        progress: Value(survey.progress),
        photoCount: Value(survey.photoCount),
        noteCount: Value(survey.noteCount),
        totalSections: Value(survey.totalSections),
        completedSections: Value(survey.completedSections),
        parentSurveyId: Value(survey.parentSurveyId),
        reinspectionNumber: Value(survey.reinspectionNumber),
        aiSummary: Value(survey.aiSummary),
        riskSummary: Value(survey.riskSummary),
        repairRecommendations: Value(survey.repairRecommendations),
        deletedAt: Value(survey.deletedAt),
      );
}
