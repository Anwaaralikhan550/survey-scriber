import 'package:drift/drift.dart';

/// Survey answers table for storing field answers
class SurveyAnswers extends Table {
  TextColumn get id => text()();
  TextColumn get surveyId => text()();
  TextColumn get sectionId => text()();
  TextColumn get fieldKey => text()();
  TextColumn get value => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
