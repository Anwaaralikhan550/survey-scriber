import 'package:drift/drift.dart';

/// Sync queue table for storing pending sync operations
/// This table acts as a local-first queue that persists sync operations
/// until they can be successfully sent to the server.
class SyncQueue extends Table {
  /// Auto-incrementing primary key
  IntColumn get id => integer().autoIncrement()();

  /// Type of entity being synced (survey, section, answer, photo)
  TextColumn get entityType => text()();

  /// ID of the entity being synced
  TextColumn get entityId => text()();

  /// Action to perform (create, update, delete)
  TextColumn get action => text()();

  /// JSON payload containing the data to sync
  TextColumn get payload => text()();

  /// When this item was added to the queue
  DateTimeColumn get createdAt => dateTime()();

  /// Number of retry attempts
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Status of this queue item (pending, processing, completed, failed, conflict)
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Error message if sync failed
  TextColumn get errorMessage => text().nullable()();

  /// Server version for conflict detection
  IntColumn get serverVersion => integer().nullable()();

  /// Priority for ordering (lower = higher priority)
  IntColumn get priority => integer().withDefault(const Constant(0))();

  /// Timestamp when item started processing (for crash recovery)
  /// If an item is in 'processing' status but processedAt is older than
  /// the stale threshold, it's considered stuck and will be reset.
  DateTimeColumn get processedAt => dateTime().nullable()();
}
