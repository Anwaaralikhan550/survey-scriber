import 'dart:convert';

import 'package:drift/drift.dart';

import '../../sync/sync_state.dart';
import '../app_database.dart';
import '../tables/sync_queue_table.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  /// Add an item to the sync queue with Action Precedence Merging.
  ///
  /// ARCH-B2 FIX: Implements proper action merging to prevent data corruption.
  /// F10 FIX: Wrapped in transaction to prevent race conditions.
  ///
  /// Action Precedence Rules:
  /// - CREATE + UPDATE → Keep CREATE, merge payloads (entity doesn't exist on server yet)
  /// - CREATE + DELETE → Delete queue item entirely (entity never existed on server)
  /// - UPDATE + UPDATE → Keep UPDATE, merge payloads
  /// - UPDATE + DELETE → Keep DELETE (entity will be removed)
  /// - DELETE + any    → Keep DELETE (deletion is final)
  ///
  /// CRITICAL: Never replace CREATE with UPDATE - server would receive UPDATE for
  /// non-existent entity, resulting in 404 error.
  Future<int> addToQueue({
    required SyncEntityType entityType,
    required String entityId,
    required SyncAction action,
    required Map<String, dynamic> payload,
    int priority = 0,
  }) async {
    // F10 FIX: Wrap entire operation in transaction to prevent race conditions
    // This ensures atomic select-then-update/insert/delete operations
    return transaction(() async {
      // Check if there's already a pending OR failed item for this entity.
      //
      // CRITICAL: Must include 'failed' status — otherwise a section whose
      // CREATE permanently failed (retryCount >= maxRetries) will NOT be found,
      // and a new UPDATE row is inserted as a separate queue item. That naked
      // UPDATE then races ahead of the unsynced CREATE → 404 on the server.
      //
      // We intentionally EXCLUDE 'processing' — modifying an in-flight row's
      // payload is unsafe (the HTTP request already read the old payload).
      // Duplicate rows from the processing race are handled by the queue
      // processor's same-entity dedup guard.
      final existing = await (select(syncQueue)
            ..where((t) => t.entityId.equals(entityId))
            ..where((t) => t.entityType.equals(entityType.name))
            ..where((t) => t.status.isIn(['pending', 'failed'])))
          .getSingleOrNull();

      if (existing != null) {
        final existingAction = SyncAction.values.firstWhere(
          (a) => a.name == existing.action,
          orElse: () => SyncAction.update,
        );

        // Decode existing payload for potential merging
        final existingPayload = jsonDecode(existing.payload) as Map<String, dynamic>;

        // ========================================
        // ACTION PRECEDENCE LOGIC
        // ========================================
        final (finalAction, finalPayload, shouldDelete) = _mergeActions(
          existingAction: existingAction,
          newAction: action,
          existingPayload: existingPayload,
          newPayload: payload,
        );

        // Case: CREATE + DELETE = Remove from queue entirely
        if (shouldDelete) {
          await (delete(syncQueue)..where((t) => t.id.equals(existing.id))).go();
          return -1; // Indicate item was removed
        }

        // Update with merged action and payload
        await (update(syncQueue)..where((t) => t.id.equals(existing.id))).write(
          SyncQueueCompanion(
            action: Value(finalAction.name),
            payload: Value(jsonEncode(finalPayload)),
            createdAt: Value(DateTime.now()),
            retryCount: const Value(0),
            status: const Value('pending'),
            errorMessage: const Value(null),
            priority: Value(priority < existing.priority ? priority : existing.priority),
          ),
        );
        return existing.id;
      }

      // No existing item - insert new
      return into(syncQueue).insert(
        SyncQueueCompanion.insert(
          entityType: entityType.name,
          entityId: entityId,
          action: action.name,
          payload: jsonEncode(payload),
          createdAt: DateTime.now(),
          priority: Value(priority),
        ),
      );
    });
  }

  /// Merge actions according to precedence rules.
  ///
  /// Returns (finalAction, mergedPayload, shouldDelete)
  (SyncAction, Map<String, dynamic>, bool) _mergeActions({
    required SyncAction existingAction,
    required SyncAction newAction,
    required Map<String, dynamic> existingPayload,
    required Map<String, dynamic> newPayload,
  }) {
    // ========================================
    // Rule 1: DELETE is always final
    // ========================================
    if (existingAction == SyncAction.delete) {
      // Existing DELETE wins - ignore new action
      return (SyncAction.delete, existingPayload, false);
    }

    // ========================================
    // Rule 2: New DELETE action
    // ========================================
    if (newAction == SyncAction.delete) {
      if (existingAction == SyncAction.create) {
        // CREATE + DELETE = Entity never existed on server, remove from queue
        return (SyncAction.delete, {}, true); // shouldDelete = true
      }
      // UPDATE + DELETE = Keep DELETE
      return (SyncAction.delete, newPayload, false);
    }

    // ========================================
    // Rule 3: CREATE must be preserved
    // ========================================
    if (existingAction == SyncAction.create) {
      // CREATE + UPDATE = Keep CREATE, merge payloads
      // The entity doesn't exist on server yet, so we need CREATE
      final mergedPayload = _mergePayloads(existingPayload, newPayload);
      return (SyncAction.create, mergedPayload, false);
    }

    // ========================================
    // Rule 4: UPDATE + UPDATE = Merge
    // ========================================
    if (existingAction == SyncAction.update && newAction == SyncAction.update) {
      final mergedPayload = _mergePayloads(existingPayload, newPayload);
      return (SyncAction.update, mergedPayload, false);
    }

    // ========================================
    // Rule 5: UPDATE + CREATE (edge case - shouldn't happen normally)
    // ========================================
    if (existingAction == SyncAction.update && newAction == SyncAction.create) {
      // This is unusual - existing UPDATE means entity exists
      // Keep UPDATE with merged payload (CREATE implies full data)
      final mergedPayload = _mergePayloads(existingPayload, newPayload);
      return (SyncAction.update, mergedPayload, false);
    }

    // Default: use new action with merged payload
    final mergedPayload = _mergePayloads(existingPayload, newPayload);
    return (newAction, mergedPayload, false);
  }

  /// F11 FIX: Critical ID fields that must NEVER be overwritten during merge.
  /// These ensure referential integrity between entities.
  static const _protectedIdFields = {
    'id',
    'surveyId',
    'sectionId',
    'parentSurveyId',
    'answerId',
    'mediaId',
    'entityId',
  };

  /// Merge two payloads, with new values taking precedence (except protected IDs).
  ///
  /// F11 FIX: Protected ID fields are ALWAYS preserved from existing payload
  /// to prevent orphaned data or wrong parent references.
  ///
  /// This performs a shallow merge where:
  /// - Protected ID fields from existing payload are preserved (never overwritten)
  /// - All other keys from existing payload are preserved
  /// - Non-protected keys from new payload overwrite existing keys
  /// - Null values in new payload are preserved (explicit null) for non-protected fields
  Map<String, dynamic> _mergePayloads(
    Map<String, dynamic> existing,
    Map<String, dynamic> newPayload,
  ) {
    final merged = <String, dynamic>{};

    // Start with all existing values
    merged.addAll(existing);

    // Apply new payload values, but protect critical IDs
    for (final entry in newPayload.entries) {
      if (_protectedIdFields.contains(entry.key)) {
        // Protected ID: Only use new value if existing doesn't have it
        if (!existing.containsKey(entry.key) || existing[entry.key] == null) {
          merged[entry.key] = entry.value;
        }
        // Otherwise keep existing value (don't overwrite)
      } else {
        // Non-protected field: new value takes precedence
        merged[entry.key] = entry.value;
      }
    }

    return merged;
  }

  /// Get all pending items ordered by priority and creation time (FIFO)
  Future<List<SyncQueueData>> getPendingItems({int limit = 50}) => (select(syncQueue)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([
            (t) => OrderingTerm.asc(t.priority),
            (t) => OrderingTerm.asc(t.createdAt),
          ])
          ..limit(limit))
        .get();

  /// Get count of pending items
  Future<int> getPendingCount() async {
    final query = selectOnly(syncQueue)
      ..addColumns([syncQueue.id.count()])
      ..where(syncQueue.status.equals('pending'));

    final result = await query.getSingle();
    return result.read(syncQueue.id.count()) ?? 0;
  }

  /// Get count of failed items
  Future<int> getFailedCount() async {
    final query = selectOnly(syncQueue)
      ..addColumns([syncQueue.id.count()])
      ..where(syncQueue.status.equals('failed'));

    final result = await query.getSingle();
    return result.read(syncQueue.id.count()) ?? 0;
  }

  /// Get count of conflict items
  Future<int> getConflictCount() async {
    final query = selectOnly(syncQueue)
      ..addColumns([syncQueue.id.count()])
      ..where(syncQueue.status.equals('conflict'));

    final result = await query.getSingle();
    return result.read(syncQueue.id.count()) ?? 0;
  }

  /// Mark item as processing with timestamp for crash recovery
  Future<void> markAsProcessing(int id) => (update(syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        status: const Value('processing'),
        processedAt: Value(DateTime.now()),
      ),
    );

  /// Recover stale processing items (crash recovery - F9 fix)
  ///
  /// Items stuck in 'processing' state for longer than [staleThreshold]
  /// are reset to 'pending' for retry. This handles the case where:
  /// - App crashed between markAsProcessing and completion
  /// - Network timeout left item in limbo
  /// - Device killed the app during sync
  ///
  /// Returns the count of recovered items.
  Future<int> recoverStaleProcessingItems({
    Duration staleThreshold = const Duration(minutes: 5),
  }) async {
    final cutoffTime = DateTime.now().subtract(staleThreshold);

    // Find and reset items that have been in 'processing' state too long
    final result = await (update(syncQueue)
          ..where((t) => t.status.equals('processing'))
          ..where((t) => t.processedAt.isSmallerOrEqualValue(cutoffTime)))
        .write(
      const SyncQueueCompanion(
        status: Value('pending'),
        processedAt: Value(null),
        errorMessage: Value('Recovered from stale processing state'),
      ),
    );

    return result;
  }

  /// Get items currently stuck in processing (for diagnostics)
  Future<List<SyncQueueData>> getProcessingItems() => (select(syncQueue)
          ..where((t) => t.status.equals('processing'))
          ..orderBy([(t) => OrderingTerm.asc(t.processedAt)]))
        .get();

  /// Mark item as completed and remove from queue
  Future<void> markAsCompleted(int id) => (delete(syncQueue)..where((t) => t.id.equals(id))).go();

  /// Mark item as failed with error message
  Future<void> markAsFailed(int id, String errorMessage) async {
    final item = await (select(syncQueue)..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (item == null) return;

    final newRetryCount = item.retryCount + 1;
    final newStatus =
        newRetryCount >= SyncQueueItem.maxRetries ? 'failed' : 'pending';

    await (update(syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        status: Value(newStatus),
        retryCount: Value(newRetryCount),
        errorMessage: Value(errorMessage),
      ),
    );
  }

  /// Reset a single item back to pending with zero retry count.
  /// Used when rate-limited (429) — the item should be retried fresh.
  Future<void> resetToPending(int id) =>
      (update(syncQueue)..where((t) => t.id.equals(id))).write(
        const SyncQueueCompanion(
          status: Value('pending'),
          retryCount: Value(0),
          errorMessage: Value(null),
        ),
      );

  /// Mark item as conflict
  Future<void> markAsConflict(int id, int serverVersion) => (update(syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        status: const Value('conflict'),
        serverVersion: Value(serverVersion),
      ),
    );

  /// Reset failed items to pending for ONE more retry attempt.
  ///
  /// Sets retryCount to maxRetries - 1 so each manual "Retry Failed" tap
  /// gives exactly 1 automatic attempt. This prevents infinite retry loops
  /// where items cycle between 'failed' → reset → 3 retries → 'failed' → ...
  Future<void> resetFailedItems() => (update(syncQueue)..where((t) => t.status.equals('failed'))).write(
      const SyncQueueCompanion(
        status: Value('pending'),
        retryCount: Value(SyncQueueItem.maxRetries - 1),
      ),
    );

  /// Permanently remove all failed items from the queue.
  ///
  /// Use when failed items have permanently broken payloads (e.g., from
  /// a code bug that has since been fixed). The underlying entities will
  /// be re-queued with correct payloads on next local edit.
  Future<int> clearFailedItems() =>
      (delete(syncQueue)..where((t) => t.status.equals('failed'))).go();

  /// Get all failed items with their error messages for diagnostics.
  Future<List<SyncQueueData>> getFailedItems({int limit = 50}) =>
      (select(syncQueue)
            ..where((t) => t.status.equals('failed'))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .get();

  /// Auto-resolve CREATE-action items stuck in 'conflict' status.
  ///
  /// These are items that received a 409 "already exists" error before
  /// the idempotent-create fix was applied. Since the entity already exists
  /// on the server, these should be treated as successfully synced.
  /// Returns the number of resolved items.
  Future<int> resolveCreateConflicts() =>
      (delete(syncQueue)
            ..where((t) => t.status.equals('conflict'))
            ..where((t) => t.action.equals('create')))
          .go();

  /// Get items with conflicts
  Future<List<SyncQueueData>> getConflictItems() => (select(syncQueue)
          ..where((t) => t.status.equals('conflict'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();

  /// Resolve conflict by keeping local version
  Future<void> resolveConflictKeepLocal(int id) => (update(syncQueue)..where((t) => t.id.equals(id))).write(
      const SyncQueueCompanion(
        status: Value('pending'),
        retryCount: Value(0),
        errorMessage: Value(null),
        serverVersion: Value(null),
      ),
    );

  /// Clear all completed items
  Future<void> clearCompleted() => (delete(syncQueue)..where((t) => t.status.equals('completed'))).go();

  /// Watch pending count for reactive UI
  Stream<int> watchPendingCount() {
    final query = selectOnly(syncQueue)
      ..addColumns([syncQueue.id.count()])
      ..where(syncQueue.status.equals('pending'));

    return query.watchSingle().map((row) => row.read(syncQueue.id.count()) ?? 0);
  }

  /// Watch all queue stats
  Stream<({int pending, int failed, int conflict})> watchQueueStats() => customSelect(
      '''
      SELECT
        SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
        SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed,
        SUM(CASE WHEN status = 'conflict' THEN 1 ELSE 0 END) as conflict
      FROM sync_queue
      ''',
      readsFrom: {syncQueue},
    ).watchSingle().map((row) => (
          pending: row.read<int?>('pending') ?? 0,
          failed: row.read<int?>('failed') ?? 0,
          conflict: row.read<int?>('conflict') ?? 0,
        ),);

  /// Check if a specific entity has an unsynced queue item.
  ///
  /// Includes 'failed' status because a permanently failed parent MUST block
  /// its children — otherwise children fire 404s against a server that never
  /// received the parent. The transitive chain:
  ///   survey(failed) → blocks section → blocks answer
  Future<bool> hasPendingSync(String entityId) async {
    final result = await (select(syncQueue)
          ..where((t) => t.entityId.equals(entityId))
          ..where((t) => t.status.isIn(['pending', 'processing', 'failed', 'conflict'])))
        .getSingleOrNull();
    return result != null;
  }

  /// Get sync status for a specific entity
  Future<SyncQueueItemStatus?> getEntitySyncStatus(String entityId) async {
    final result = await (select(syncQueue)
          ..where((t) => t.entityId.equals(entityId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();

    if (result == null) return null;

    return SyncQueueItemStatus.values.firstWhere(
      (s) => s.name == result.status,
      orElse: () => SyncQueueItemStatus.pending,
    );
  }

  /// Retrieve the merged payload for an entity from the sync queue.
  ///
  /// Returns the decoded payload map from the most recent queue item
  /// for this entity (any status). Used by _ensureSectionExists to
  /// reconstruct V2 section metadata when the entity isn't in the
  /// survey_sections table.
  Future<Map<String, dynamic>?> getEntityPayload(
    String entityId,
    SyncEntityType entityType,
  ) async {
    final result = await (select(syncQueue)
          ..where((t) => t.entityId.equals(entityId))
          ..where((t) => t.entityType.equals(entityType.name))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    if (result == null) return null;
    return jsonDecode(result.payload) as Map<String, dynamic>;
  }

  /// Convert database row to SyncQueueItem
  SyncQueueItem toSyncQueueItem(SyncQueueData data) => SyncQueueItem(
      id: data.id,
      entityType: SyncEntityType.values.firstWhere(
        (t) => t.name == data.entityType,
        orElse: () => SyncEntityType.survey,
      ),
      entityId: data.entityId,
      action: SyncAction.values.firstWhere(
        (a) => a.name == data.action,
        orElse: () => SyncAction.update,
      ),
      payload: data.payload,
      createdAt: data.createdAt,
      retryCount: data.retryCount,
      status: SyncQueueItemStatus.values.firstWhere(
        (s) => s.name == data.status,
        orElse: () => SyncQueueItemStatus.pending,
      ),
      errorMessage: data.errorMessage,
      serverVersion: data.serverVersion,
    );
}
