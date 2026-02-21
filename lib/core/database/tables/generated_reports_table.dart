import 'package:drift/drift.dart';

/// Tracks locally generated PDF reports for history/re-access.
@DataClassName('GeneratedReportData')
class GeneratedReports extends Table {
  /// Unique identifier (UUID).
  TextColumn get id => text()();

  /// Survey this report was generated for.
  TextColumn get surveyId => text()();

  /// Human-readable survey title at time of generation.
  TextColumn get surveyTitle => text().withDefault(const Constant(''))();

  /// Absolute file path on device.
  TextColumn get filePath => text()();

  /// Display filename (e.g. "my_survey_1706000000.pdf").
  TextColumn get fileName => text()();

  /// File size in bytes.
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();

  /// When the report was generated.
  DateTimeColumn get generatedAt => dateTime()();

  /// Module type: 'inspection' or 'valuation'.
  TextColumn get moduleType => text().withDefault(const Constant('inspection'))();

  /// Output format: 'pdf' or 'docx'.
  TextColumn get format => text().withDefault(const Constant('pdf'))();

  /// Export style: 'legacy' or 'premium'.
  TextColumn get style => text().withDefault(const Constant('legacy'))();

  /// Backend URL after upload (null if not uploaded).
  TextColumn get remoteUrl => text().nullable()();

  /// SHA-256 checksum of file bytes for integrity.
  TextColumn get checksum => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}
