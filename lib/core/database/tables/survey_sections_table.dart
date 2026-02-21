import 'package:drift/drift.dart';

/// Survey sections table for storing section data
class SurveySections extends Table {
  TextColumn get id => text()();
  TextColumn get surveyId => text()();
  TextColumn get sectionType => text()(); // SectionType enum name
  TextColumn get title => text()();
  IntColumn get sectionOrder => integer()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
