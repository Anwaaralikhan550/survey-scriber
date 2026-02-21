import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/generated_reports_table.dart';

part 'generated_reports_dao.g.dart';

@DriftAccessor(tables: [GeneratedReports])
class GeneratedReportsDao extends DatabaseAccessor<AppDatabase>
    with _$GeneratedReportsDaoMixin {
  GeneratedReportsDao(super.db);

  /// Get all reports ordered by most recent first.
  Future<List<GeneratedReportData>> getAllReports() =>
      (select(generatedReports)
            ..orderBy([(t) => OrderingTerm.desc(t.generatedAt)]))
          .get();

  /// Get reports for a specific survey.
  Future<List<GeneratedReportData>> getReportsForSurvey(String surveyId) =>
      (select(generatedReports)
            ..where((t) => t.surveyId.equals(surveyId))
            ..orderBy([(t) => OrderingTerm.desc(t.generatedAt)]))
          .get();

  /// Get a single report by ID.
  Future<GeneratedReportData?> getReportById(String id) =>
      (select(generatedReports)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// Insert a new report record.
  Future<int> insertReport(GeneratedReportsCompanion report) =>
      into(generatedReports).insert(report);

  /// Update a report record.
  Future<bool> updateReport(String id, GeneratedReportsCompanion companion) =>
      (update(generatedReports)..where((t) => t.id.equals(id)))
          .write(companion)
          .then((rows) => rows > 0);

  /// Delete a report record by ID.
  Future<int> deleteReport(String id) =>
      (delete(generatedReports)..where((t) => t.id.equals(id))).go();

  /// Delete all reports for a survey.
  Future<int> deleteReportsForSurvey(String surveyId) =>
      (delete(generatedReports)..where((t) => t.surveyId.equals(surveyId)))
          .go();

  /// Watch all reports (reactive stream).
  Stream<List<GeneratedReportData>> watchAllReports() =>
      (select(generatedReports)
            ..orderBy([(t) => OrderingTerm.desc(t.generatedAt)]))
          .watch();

  /// Get total report count.
  Future<int> getReportCount() async {
    final result = await (selectOnly(generatedReports)
          ..addColumns([generatedReports.id.count()]))
        .getSingle();
    return result.read(generatedReports.id.count()) ?? 0;
  }
}
