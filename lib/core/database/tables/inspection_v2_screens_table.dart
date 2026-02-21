import 'package:drift/drift.dart';

/// Stores screen metadata for inspection/valuation flows.
/// Table name kept as `inspection_v2_screens` for SQLite schema stability.
class InspectionV2Screens extends Table {
  TextColumn get id => text()();
  TextColumn get surveyId => text()();
  TextColumn get sectionKey => text()();
  TextColumn get screenId => text()();
  TextColumn get title => text()();
  TextColumn get groupKey => text().nullable()();
  TextColumn get nodeType => text().withDefault(const Constant('screen'))();
  TextColumn get parentId => text().nullable()();
  IntColumn get displayOrder => integer()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get phraseOutput => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
