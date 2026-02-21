import 'package:drift/drift.dart';

/// Table for storing all media items (photos, audio, video)
@DataClassName('MediaItemsData')
class MediaItems extends Table {
  /// Unique identifier
  TextColumn get id => text()();

  /// Parent survey ID
  TextColumn get surveyId => text()();

  /// Parent section ID
  TextColumn get sectionId => text()();

  /// Type: photo, audio, video
  TextColumn get mediaType => text()();

  /// Local file path on device
  TextColumn get localPath => text()();

  /// Remote URL after sync (nullable)
  TextColumn get remotePath => text().nullable()();

  /// User-provided caption
  TextColumn get caption => text().nullable()();

  /// Sync status: local, uploading, synced, failed
  TextColumn get status => text().withDefault(const Constant('local'))();

  /// File size in bytes
  IntColumn get fileSize => integer().nullable()();

  /// Duration in milliseconds (for audio/video)
  IntColumn get duration => integer().nullable()();

  /// Width in pixels (for photo/video)
  IntColumn get width => integer().nullable()();

  /// Height in pixels (for photo/video)
  IntColumn get height => integer().nullable()();

  /// Thumbnail path (for photo/video)
  TextColumn get thumbnailPath => text().nullable()();

  /// Whether photo has annotations
  BoolColumn get hasAnnotations =>
      boolean().withDefault(const Constant(false))();

  /// Sort order within section
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Waveform data JSON (for audio)
  TextColumn get waveformData => text().nullable()();

  /// Speech-to-text transcription (for audio)
  TextColumn get transcription => text().nullable()();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime()();

  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table for storing photo annotations
@DataClassName('PhotoAnnotationsData')
class PhotoAnnotations extends Table {
  /// Unique identifier
  TextColumn get id => text()();

  /// Parent photo media item ID
  TextColumn get photoId => text()();

  /// JSON-encoded list of annotation elements
  TextColumn get elementsJson => text()();

  /// Path to rendered annotated image
  TextColumn get annotatedImagePath => text().nullable()();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime()();

  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
