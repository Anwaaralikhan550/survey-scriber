import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/core/sync/sync_state.dart';

void main() {
  group('SyncStatus', () {
    test('all status values are defined', () {
      expect(SyncStatus.values.length, 6);
      expect(SyncStatus.values, contains(SyncStatus.idle));
      expect(SyncStatus.values, contains(SyncStatus.syncing));
      expect(SyncStatus.values, contains(SyncStatus.pending));
      expect(SyncStatus.values, contains(SyncStatus.success));
      expect(SyncStatus.values, contains(SyncStatus.error));
      expect(SyncStatus.values, contains(SyncStatus.offline));
    });
  });

  group('SyncState', () {
    test('initial state has correct defaults', () {
      const state = SyncState.initial;
      expect(state.status, SyncStatus.idle);
      expect(state.pendingCount, 0);
      expect(state.lastSyncedAt, isNull);
      expect(state.errorMessage, isNull);
      expect(state.isConnected, true);
      expect(state.isSyncing, false);
      expect(state.failedCount, 0);
      expect(state.conflictCount, 0);
    });

    test('hasPendingChanges returns true when pendingCount > 0', () {
      const state = SyncState(pendingCount: 5);
      expect(state.hasPendingChanges, true);
    });

    test('hasPendingChanges returns false when pendingCount is 0', () {
      const state = SyncState();
      expect(state.hasPendingChanges, false);
    });

    test('isOffline returns true when not connected', () {
      const state = SyncState(isConnected: false);
      expect(state.isOffline, true);
    });

    test('isOffline returns false when connected', () {
      const state = SyncState();
      expect(state.isOffline, false);
    });

    test('isFullySynced returns true when no pending/failed items', () {
      const state = SyncState(
        
      );
      expect(state.isFullySynced, true);
    });

    test('isFullySynced returns false when has pending items', () {
      const state = SyncState(pendingCount: 3);
      expect(state.isFullySynced, false);
    });

    test('isFullySynced returns false when has failed items', () {
      const state = SyncState(failedCount: 2);
      expect(state.isFullySynced, false);
    });

    test('isFullySynced returns false when status is error', () {
      const state = SyncState(status: SyncStatus.error);
      expect(state.isFullySynced, false);
    });

    test('isSyncBlocked returns true when offline', () {
      const state = SyncState(isConnected: false);
      expect(state.isSyncBlocked, true);
    });

    test('isSyncBlocked returns true when error status', () {
      const state = SyncState(status: SyncStatus.error);
      expect(state.isSyncBlocked, true);
    });

    test('isSyncBlocked returns false when connected and no error', () {
      const state = SyncState();
      expect(state.isSyncBlocked, false);
    });

    test('statusText returns correct text for different states', () {
      expect(
        const SyncState().statusText,
        'Synced',
      );
      expect(
        const SyncState(pendingCount: 3).statusText,
        '3 pending',
      );
      expect(
        const SyncState(status: SyncStatus.syncing).statusText,
        'Syncing...',
      );
      expect(
        const SyncState(status: SyncStatus.pending, pendingCount: 5).statusText,
        '5 pending',
      );
      expect(
        const SyncState(status: SyncStatus.error).statusText,
        'Sync error',
      );
      expect(
        const SyncState(isConnected: false).statusText,
        'Offline',
      );
    });

    test('copyWith creates new state with updated values', () {
      const original = SyncState(
        
      );

      final updated = original.copyWith(
        status: SyncStatus.syncing,
        pendingCount: 5,
      );

      expect(updated.status, SyncStatus.syncing);
      expect(updated.pendingCount, 5);
      expect(original.status, SyncStatus.idle); // Original unchanged
    });

    test('copyWith with clearError removes error message', () {
      const state = SyncState(errorMessage: 'Some error');
      final cleared = state.copyWith(clearError: true);
      expect(cleared.errorMessage, isNull);
    });

    test('copyWith with clearCurrentItem removes current item', () {
      const state = SyncState(currentItem: 'Syncing survey');
      final cleared = state.copyWith(clearCurrentItem: true);
      expect(cleared.currentItem, isNull);
    });

    test('equality works correctly', () {
      const state1 = SyncState(pendingCount: 5);
      const state2 = SyncState(pendingCount: 5);
      const state3 = SyncState(status: SyncStatus.syncing, pendingCount: 5);

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });
  });

  group('SyncQueueItem', () {
    test('canRetry returns true when retryCount < maxRetries', () {
      final item = SyncQueueItem(
        id: 1,
        entityType: SyncEntityType.survey,
        entityId: 'survey-1',
        action: SyncAction.update,
        payload: '{}',
        createdAt: DateTime.now(),
        retryCount: 2,
      );
      expect(item.canRetry, true);
    });

    test('canRetry returns false when retryCount >= maxRetries', () {
      final item = SyncQueueItem(
        id: 1,
        entityType: SyncEntityType.survey,
        entityId: 'survey-1',
        action: SyncAction.update,
        payload: '{}',
        createdAt: DateTime.now(),
        retryCount: 3,
      );
      expect(item.canRetry, false);
    });

    test('hasConflict returns true when status is conflict', () {
      final item = SyncQueueItem(
        id: 1,
        entityType: SyncEntityType.survey,
        entityId: 'survey-1',
        action: SyncAction.update,
        payload: '{}',
        createdAt: DateTime.now(),
        status: SyncQueueItemStatus.conflict,
      );
      expect(item.hasConflict, true);
    });

    test('maxRetries is 3', () {
      expect(SyncQueueItem.maxRetries, 3);
    });
  });

  group('SyncEntityType', () {
    test('all entity types are defined', () {
      expect(SyncEntityType.values.length, 4);
      expect(SyncEntityType.values, contains(SyncEntityType.survey));
      expect(SyncEntityType.values, contains(SyncEntityType.section));
      expect(SyncEntityType.values, contains(SyncEntityType.answer));
      expect(SyncEntityType.values, contains(SyncEntityType.photo));
    });
  });

  group('SyncAction', () {
    test('all actions are defined', () {
      expect(SyncAction.values.length, 3);
      expect(SyncAction.values, contains(SyncAction.create));
      expect(SyncAction.values, contains(SyncAction.update));
      expect(SyncAction.values, contains(SyncAction.delete));
    });
  });

  group('SyncQueueItemStatus', () {
    test('all statuses are defined', () {
      expect(SyncQueueItemStatus.values.length, 5);
      expect(SyncQueueItemStatus.values, contains(SyncQueueItemStatus.pending));
      expect(SyncQueueItemStatus.values, contains(SyncQueueItemStatus.processing));
      expect(SyncQueueItemStatus.values, contains(SyncQueueItemStatus.completed));
      expect(SyncQueueItemStatus.values, contains(SyncQueueItemStatus.failed));
      expect(SyncQueueItemStatus.values, contains(SyncQueueItemStatus.conflict));
    });
  });
}
