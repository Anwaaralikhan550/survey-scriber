import 'package:drift/drift.dart';

/// Surveys table for storing survey metadata
class Surveys extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get type => text()(); // SurveyType enum name
  TextColumn get status => text()(); // SurveyStatus enum name
  TextColumn get jobRef => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get clientName => text().nullable()();
  RealColumn get progress => real().withDefault(const Constant(0))();
  IntColumn get photoCount => integer().withDefault(const Constant(0))();
  IntColumn get noteCount => integer().withDefault(const Constant(0))();
  IntColumn get totalSections => integer().withDefault(const Constant(0))();
  IntColumn get completedSections => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Parent survey ID for re-inspections (links to original survey)
  TextColumn get parentSurveyId => text().nullable()();

  /// Re-inspection number (1, 2, 3...) for tracking iteration
  IntColumn get reinspectionNumber =>
      integer().withDefault(const Constant(0))();

  /// AI-generated executive summary text (persisted when user accepts)
  TextColumn get aiSummary => text().nullable()();

  /// AI-generated risk summary text (persisted when user accepts)
  TextColumn get riskSummary => text().nullable()();

  /// AI-generated repair recommendations text (persisted when user accepts)
  TextColumn get repairRecommendations => text().nullable()();

  /// Soft delete timestamp — mirrors backend `deleted_at` field.
  /// When set, the survey is treated as deleted locally (hidden from UI)
  /// but preserved for sync consistency.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
