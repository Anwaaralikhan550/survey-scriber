import 'package:equatable/equatable.dart';

/// Sync status enum for the application
enum SyncStatus {
  /// No sync activity, everything is up to date
  idle,

  /// Currently syncing data to server
  syncing,

  /// Has pending changes waiting to sync
  pending,

  /// Sync completed successfully
  success,

  /// Sync failed with error
  error,

  /// Device is offline
  offline,
}

/// Entity types that can be synced
enum SyncEntityType {
  survey,
  section,
  answer,
  photo,
}

/// Actions that can be queued for sync
enum SyncAction {
  create,
  update,
  delete,
}

/// Sync queue item status
enum SyncQueueItemStatus {
  pending,
  processing,
  completed,
  failed,
  conflict,
}

/// Model representing the current sync state
class SyncState extends Equatable {
  const SyncState({
    this.status = SyncStatus.idle,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.errorMessage,
    this.isConnected = true,
    this.isSyncing = false,
    this.currentItem,
    this.failedCount = 0,
    this.conflictCount = 0,
    this.isPulling = false,
    this.lastPulledAt,
    this.pullError,
  });

  final SyncStatus status;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? errorMessage;
  final bool isConnected;
  final bool isSyncing;
  final String? currentItem;
  final int failedCount;
  final int conflictCount;
  final bool isPulling;
  final DateTime? lastPulledAt;
  final String? pullError;

  /// Whether there are pending changes to sync
  bool get hasPendingChanges => pendingCount > 0;

  /// Whether the device is offline
  bool get isOffline => !isConnected;

  /// Whether sync is blocked (offline or has errors)
  bool get isSyncBlocked => isOffline || status == SyncStatus.error;

  /// Whether all data is synced
  bool get isFullySynced =>
      pendingCount == 0 &&
      failedCount == 0 &&
      status != SyncStatus.error;

  /// Human-readable status text
  String get statusText {
    if (isOffline) return 'Offline';
    switch (status) {
      case SyncStatus.idle:
        return hasPendingChanges ? '$pendingCount pending' : 'Synced';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.pending:
        return '$pendingCount pending';
      case SyncStatus.success:
        return 'Synced';
      case SyncStatus.error:
        return 'Sync error';
      case SyncStatus.offline:
        return 'Offline';
    }
  }

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    DateTime? lastSyncedAt,
    String? errorMessage,
    bool? isConnected,
    bool? isSyncing,
    String? currentItem,
    int? failedCount,
    int? conflictCount,
    bool? isPulling,
    DateTime? lastPulledAt,
    String? pullError,
    bool clearError = false,
    bool clearCurrentItem = false,
    bool clearPullError = false,
  }) =>
      SyncState(
        status: status ?? this.status,
        pendingCount: pendingCount ?? this.pendingCount,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        isConnected: isConnected ?? this.isConnected,
        isSyncing: isSyncing ?? this.isSyncing,
        currentItem: clearCurrentItem ? null : (currentItem ?? this.currentItem),
        failedCount: failedCount ?? this.failedCount,
        conflictCount: conflictCount ?? this.conflictCount,
        isPulling: isPulling ?? this.isPulling,
        lastPulledAt: lastPulledAt ?? this.lastPulledAt,
        pullError: clearPullError ? null : (pullError ?? this.pullError),
      );

  /// Initial state
  static const initial = SyncState();

  @override
  List<Object?> get props => [
        status,
        pendingCount,
        lastSyncedAt,
        errorMessage,
        isConnected,
        isSyncing,
        currentItem,
        failedCount,
        conflictCount,
        isPulling,
        lastPulledAt,
        pullError,
      ];
}

/// Model for a sync queue item
class SyncQueueItem extends Equatable {
  const SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.status = SyncQueueItemStatus.pending,
    this.errorMessage,
    this.serverVersion,
  });

  final int id;
  final SyncEntityType entityType;
  final String entityId;
  final SyncAction action;
  final String payload; // JSON string
  final DateTime createdAt;
  final int retryCount;
  final SyncQueueItemStatus status;
  final String? errorMessage;
  final int? serverVersion;

  /// Maximum retry attempts before marking as failed
  static const maxRetries = 3;

  /// Whether this item can be retried
  bool get canRetry => retryCount < maxRetries;

  /// Whether this item has a conflict
  bool get hasConflict => status == SyncQueueItemStatus.conflict;

  SyncQueueItem copyWith({
    int? id,
    SyncEntityType? entityType,
    String? entityId,
    SyncAction? action,
    String? payload,
    DateTime? createdAt,
    int? retryCount,
    SyncQueueItemStatus? status,
    String? errorMessage,
    int? serverVersion,
  }) =>
      SyncQueueItem(
        id: id ?? this.id,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        action: action ?? this.action,
        payload: payload ?? this.payload,
        createdAt: createdAt ?? this.createdAt,
        retryCount: retryCount ?? this.retryCount,
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
        serverVersion: serverVersion ?? this.serverVersion,
      );

  @override
  List<Object?> get props => [
        id,
        entityType,
        entityId,
        action,
        payload,
        createdAt,
        retryCount,
        status,
        errorMessage,
        serverVersion,
      ];
}
