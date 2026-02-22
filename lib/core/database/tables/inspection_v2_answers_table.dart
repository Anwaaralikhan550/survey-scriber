import 'package:drift/drift.dart';

/// Stores individual field answers for inspection/valuation screens.
/// Table name kept as `inspection_v2_answers` for SQLite schema stability.
class InspectionV2Answers extends Table {
  TextColumn get id => text()();
  TextColumn get surveyId => text()();
  TextColumn get screenId => text()();
  TextColumn get fieldKey => text()();
  TextColumn get value => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  /// Matches backend @@unique([sectionId, questionKey]) — prevents duplicate
  /// answers for the same survey+screen+field even if IDs diverge.
  @override
  List<Set<Column>> get uniqueKeys => [
        {surveyId, screenId, fieldKey},
      ];
}
