import 'package:drift/drift.dart';

/// Table for storing digital signatures
@DataClassName('SignatureData')
class Signatures extends Table {
  /// Unique identifier
  TextColumn get id => text()();

  /// Parent survey ID
  TextColumn get surveyId => text()();

  /// Parent section ID (optional - signatures can be survey-level)
  TextColumn get sectionId => text().nullable()();

  /// Name of the person signing
  TextColumn get signerName => text().nullable()();

  /// Role of the signer (e.g., Surveyor, Client, Witness)
  TextColumn get signerRole => text().nullable()();

  /// JSON-encoded list of strokes
  TextColumn get strokesJson => text()();

  /// Sync status: local, uploading, synced, failed
  TextColumn get status => text().withDefault(const Constant('local'))();

  /// Path to PNG preview image
  TextColumn get previewPath => text().nullable()();

  /// Canvas width when signature was captured
  IntColumn get width => integer().nullable()();

  /// Canvas height when signature was captured
  IntColumn get height => integer().nullable()();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime()();

  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
