import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/config/presentation/providers/config_providers.dart';
import '../../features/media/data/services/media_upload_service.dart';
import '../../features/surveys/presentation/providers/survey_invalidation.dart';
import '../../shared/domain/entities/survey.dart' as entities;
import '../../shared/domain/entities/survey_answer.dart' as entities;
import '../../shared/domain/entities/survey_section.dart' as entities;
import '../database/daos/media_dao.dart';
import '../database/daos/survey_answers_dao.dart';
import '../database/daos/survey_sections_dao.dart';
import '../database/daos/surveys_dao.dart';
import '../database/daos/sync_queue_dao.dart';
import '../database/database_providers.dart';
import '../error/exceptions.dart';
import '../network/api_client.dart';
import '../storage/storage_service.dart';
import '../utils/logger.dart';
import '../../features/config/presentation/helpers/config_aware_fields.dart';
import 'sync_state.dart';

/// F12 FIX: Custom exception for sync conflicts (HTTP 409)
/// Thrown when server detects a version mismatch during sync
class SyncConflictException implements Exception {
  SyncConflictException({
    required this.entityId,
    required this.entityType,
    this.serverVersion,
    this.message,
  });

  final String entityId;
  final SyncEntityType entityType;
  final int? serverVersion;
  final String? message;

  @override
  String toString() =>
      'SyncConflictException: Conflict for $entityType $entityId. ${message ?? ''}';
}

/// Provider for SyncManager
final syncManagerProvider = Provider<SyncManager>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final syncQueueDao = ref.watch(syncQueueDaoProvider);
  final mediaUploadService = ref.watch(mediaUploadServiceProvider);
  final surveysDao = ref.watch(surveysDaoProvider);
  final sectionsDao = ref.watch(surveySectionsDaoProvider);
  final answersDao = ref.watch(surveyAnswersDaoProvider);
  final mediaDao = ref.watch(mediaDaoProvider);
  return SyncManager(
    apiClient: apiClient,
    syncQueueDao: syncQueueDao,
    mediaUploadService: mediaUploadService,
    connectivity: Connectivity(),
    surveysDao: surveysDao,
    sectionsDao: sectionsDao,
    answersDao: answersDao,
    mediaDao: mediaDao,
  );
});

/// Provider for the sync state notifier
final syncStateProvider =
    StateNotifierProvider<SyncStateNotifier, SyncState>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  return SyncStateNotifier(syncManager, ref);
});

/// SyncStateNotifier manages the sync state and coordinates with SyncManager
class SyncStateNotifier extends StateNotifier<SyncState> {
  SyncStateNotifier(this._syncManager, this._ref) : super(SyncState.initial) {
    _init();
  }

  final SyncManager _syncManager;
  final Ref _ref;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<({int pending, int failed, int conflict})>?
      _statsSubscription;
  Timer? _autoSyncTimer;

  Future<void> _init() async {
    // Listen to connectivity changes
    _connectivitySubscription =
        _syncManager.connectivityStream.listen(_onConnectivityChanged);

    // Listen to queue stats
    _statsSubscription = _syncManager.watchQueueStats().listen(_onStatsChanged);

    // Run independent startup operations in parallel for faster init:
    // - Crash recovery (DB query)
    // - Connectivity check (network probe)
    // - Stats refresh (3 DB queries, also parallelized internally)
    late final bool isConnected;
    await Future.wait([
      _syncManager.recoverStaleProcessingItems(),
      _syncManager.checkConnectivity().then((c) => isConnected = c),
      _refreshStats(),
    ]);

    state = state.copyWith(isConnected: isConnected);

    // Pull server changes on startup (if online) — non-blocking
    if (isConnected) {
      _pullFromServer();
    }

    // Start auto-sync timer (every 30 seconds when online)
    _startAutoSyncTimer();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isConnected = results.isNotEmpty &&
        !results.contains(ConnectivityResult.none);

    final wasOffline = state.isOffline;
    state = state.copyWith(
      isConnected: isConnected,
      status: isConnected
          ? (state.hasPendingChanges ? SyncStatus.pending : SyncStatus.idle)
          : SyncStatus.offline,
    );

    // If we just came back online, pull then push
    if (wasOffline && isConnected) {
      _pullFromServer();
      if (state.hasPendingChanges) {
        syncNow();
      }
    }
  }

  void _onStatsChanged(({int pending, int failed, int conflict}) stats) {
    state = state.copyWith(
      pendingCount: stats.pending,
      failedCount: stats.failed,
      conflictCount: stats.conflict,
      status: _computeStatus(stats.pending, state.isConnected, state.isSyncing),
    );
  }

  SyncStatus _computeStatus(int pending, bool isConnected, bool isSyncing) {
    if (!isConnected) return SyncStatus.offline;
    if (isSyncing) return SyncStatus.syncing;
    if (pending > 0) return SyncStatus.pending;
    return SyncStatus.idle;
  }

  Future<void> _refreshStats() async {
    // Run all three count queries in parallel for faster startup
    final results = await Future.wait([
      _syncManager.getPendingCount(),
      _syncManager.getFailedCount(),
      _syncManager.getConflictCount(),
    ]);

    state = state.copyWith(
      pendingCount: results[0],
      failedCount: results[1],
      conflictCount: results[2],
    );
  }

  void _startAutoSyncTimer() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (state.isConnected && state.hasPendingChanges && !state.isSyncing) {
          syncNow();
        }
        // Piggyback config version check on the sync timer
        if (state.isConnected) {
          checkConfigVersion();
        }
      },
    );
  }

  /// Check if the server config version is newer than the local cache.
  /// If so, refresh the config so admin changes propagate to all devices.
  ///
  /// Public so it can be called from lifecycle observers (e.g. on app resume).
  Future<void> checkConfigVersion() async {
    try {
      final configNotifier = _ref.read(configProvider.notifier);
      final configState = _ref.read(configProvider);
      final repo = _ref.read(configRepositoryProvider);

      // Only check if config was previously loaded
      if (!configState.isLoaded) return;

      final needsRefresh = await repo.needsRefresh();
      if (needsRefresh) {
        AppLogger.d('SyncManager', 'Config version changed on server, refreshing...');
        await configNotifier.loadConfig(forceRefresh: true);
      }
    } catch (e) {
      // Non-critical — silently ignore config check failures
      AppLogger.d('SyncManager', 'Config version check failed: $e');
    }
  }

  /// Manually trigger sync
  Future<void> syncNow() async {
    if (!state.isConnected || state.isSyncing) return;

    state = state.copyWith(
      status: SyncStatus.syncing,
      isSyncing: true,
      clearError: true,
    );

    try {
      final result = await _syncManager.processQueue(
        onProgress: (current, total, item) {
          state = state.copyWith(
            currentItem: 'Syncing ${item.entityType.name}...',
          );
        },
      );

      if (result.success) {
        state = state.copyWith(
          status: SyncStatus.success,
          isSyncing: false,
          lastSyncedAt: DateTime.now(),
          clearCurrentItem: true,
        );

        // Pull server changes after successful push
        _pullFromServer();

        // After brief success indication, go back to idle
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          state = state.copyWith(
            status: state.hasPendingChanges ? SyncStatus.pending : SyncStatus.idle,
          );
        }
      } else {
        state = state.copyWith(
          status: SyncStatus.error,
          isSyncing: false,
          errorMessage: result.errorMessage,
          clearCurrentItem: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        isSyncing: false,
        errorMessage: 'Sync failed: $e',
        clearCurrentItem: true,
      );
    }
  }

  /// Queue a new sync item
  Future<void> queueSync({
    required SyncEntityType entityType,
    required String entityId,
    required SyncAction action,
    required Map<String, dynamic> payload,
  }) async {
    await _syncManager.queueSync(
      entityType: entityType,
      entityId: entityId,
      action: action,
      payload: payload,
    );

    // Update state
    await _refreshStats();

    // Auto-sync if online
    if (state.isConnected && !state.isSyncing) {
      // Debounce: wait a bit for more changes before syncing
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && state.isConnected && !state.isSyncing) {
          syncNow();
        }
      });
    }
  }

  /// Pull changes from server.
  /// Runs asynchronously - does not block push operations.
  /// After a successful pull with changes, invalidates survey list providers
  /// so the UI reflects server-side data.
  Future<void> _pullFromServer() async {
    if (state.isPulling || !state.isConnected) return;

    state = state.copyWith(isPulling: true, clearPullError: true);

    try {
      final result = await _syncManager.pullChanges();

      if (mounted) {
        if (result.success) {
          state = state.copyWith(
            isPulling: false,
            lastPulledAt: DateTime.now(),
          );

          // Invalidate survey providers so UI refreshes with pulled data.
          // afterBulkMutation covers list-level providers (dashboard, forms).
          // Also invalidate specific surveyDetailProviders for any surveys
          // whose sections were upserted (their section IDs may have changed).
          if (result.upsertedCount > 0) {
            SurveyInvalidation.afterBulkMutation(_ref);
            for (final surveyId in result.affectedSurveyIds) {
              SurveyInvalidation.afterSurveyMutation(_ref, surveyId);
            }
          }
        } else {
          state = state.copyWith(
            isPulling: false,
            pullError: result.errorMessage,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isPulling: false,
          pullError: 'Pull failed: $e',
        );
      }
    }
  }

  /// Manually trigger a pull from server
  Future<void> pullNow() => _pullFromServer();

  /// Retry failed items (1 attempt per manual tap)
  Future<void> retryFailed() async {
    await _syncManager.retryFailed();
    await _refreshStats();
    if (state.isConnected) {
      syncNow();
    }
  }

  /// Permanently clear all failed items
  Future<void> clearFailed() async {
    await _syncManager.clearFailed();
    await _refreshStats();
  }

  /// Get failed items with error details for diagnostics UI
  Future<List<SyncQueueItem>> getFailedItems() =>
      _syncManager.getFailedItems();

  /// Check if entity has pending sync
  Future<bool> hasPendingSync(String entityId) => _syncManager.hasPendingSync(entityId);

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _statsSubscription?.cancel();
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}

/// Result of a sync push operation
class SyncResult {
  const SyncResult({
    required this.success,
    this.syncedCount = 0,
    this.failedCount = 0,
    this.errorMessage,
  });

  final bool success;
  final int syncedCount;
  final int failedCount;
  final String? errorMessage;
}

/// Result of a sync pull operation
class SyncPullResult {
  const SyncPullResult({
    required this.success,
    this.upsertedCount = 0,
    this.skippedCount = 0,
    this.errorMessage,
    this.affectedSurveyIds = const {},
  });

  final bool success;
  final int upsertedCount;
  final int skippedCount;
  final String? errorMessage;
  /// Survey IDs that had sections upserted (for targeted provider invalidation).
  final Set<String> affectedSurveyIds;
}

/// Internal result for processing a single sync queue item.
class _ItemSyncResult {
  const _ItemSyncResult({
    required this.success,
    this.isRetryable = false,
    this.isAuthFailure = false,
    this.error,
  });

  final bool success;
  /// True if the failure is transient (rate limit, dependency not ready)
  /// and should not count toward the permanent failure total.
  final bool isRetryable;
  /// True if the failure is due to expired authentication (401).
  /// Signals the queue processor to abort all remaining items.
  final bool isAuthFailure;
  final String? error;
}

/// SyncManager handles the actual sync operations
/// This is a pure Dart service that doesn't depend on Flutter
class SyncManager {
  SyncManager({
    required this.apiClient,
    required this.syncQueueDao,
    required this.mediaUploadService,
    required this.connectivity,
    required this.surveysDao,
    required this.sectionsDao,
    required this.answersDao,
    required this.mediaDao,
  });

  /// Maximum number of times a dependency-not-found (404) error will be
  /// retried before marking the entity as permanently failed (orphaned).
  /// This is higher than the normal maxRetries (3) because dependency issues
  /// are often transient — the parent may sync in the next cycle.
  static const _maxDependencyRetries = 5;

  final ApiClient apiClient;
  final SyncQueueDao syncQueueDao;
  final MediaUploadService mediaUploadService;
  final Connectivity connectivity;

  // DAOs for composite entity sync (ARCH-B1 fix)
  final SurveysDao surveysDao;
  final SurveySectionsDao sectionsDao;
  final SurveyAnswersDao answersDao;
  final MediaDao mediaDao;

  /// Stream of connectivity changes
  Stream<List<ConnectivityResult>> get connectivityStream =>
      connectivity.onConnectivityChanged;

  /// Check current connectivity
  Future<bool> checkConnectivity() async {
    final results = await connectivity.checkConnectivity();
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }

  /// Get pending items count
  Future<int> getPendingCount() => syncQueueDao.getPendingCount();

  /// Get failed items count
  Future<int> getFailedCount() => syncQueueDao.getFailedCount();

  /// Get conflict items count
  Future<int> getConflictCount() => syncQueueDao.getConflictCount();

  /// Watch queue stats
  Stream<({int pending, int failed, int conflict})> watchQueueStats() =>
      syncQueueDao.watchQueueStats();

  /// Queue a sync operation (LOCAL-FIRST)
  Future<int> queueSync({
    required SyncEntityType entityType,
    required String entityId,
    required SyncAction action,
    required Map<String, dynamic> payload,
  }) => syncQueueDao.addToQueue(
      entityType: entityType,
      entityId: entityId,
      action: action,
      payload: payload,
    );

  /// Check if entity has pending sync
  Future<bool> hasPendingSync(String entityId) =>
      syncQueueDao.hasPendingSync(entityId);

  /// F9 FIX: Recover stale processing items (crash recovery)
  ///
  /// This is called on app startup to handle items that got stuck in
  /// 'processing' state due to app crash, force close, or network timeout.
  /// Items older than the threshold are reset to 'pending' for retry.
  Future<int> recoverStaleProcessingItems({
    Duration staleThreshold = const Duration(minutes: 5),
  }) async {
    final recovered = await syncQueueDao.recoverStaleProcessingItems(
      staleThreshold: staleThreshold,
    );
    if (recovered > 0) {
      AppLogger.w(
        'SyncManager',
        'Recovered $recovered stale processing items from previous session',
      );
    }

    // Also resolve stuck CREATE-action conflicts: these are items that
    // got a 409 "already exists" before the idempotent-create fix.
    // They should be marked as completed since the entity exists on server.
    final resolvedConflicts = await syncQueueDao.resolveCreateConflicts();
    if (resolvedConflicts > 0) {
      AppLogger.w(
        'SyncManager',
        'Auto-resolved $resolvedConflicts stuck CREATE-conflict items '
        '(entities already exist on server)',
      );
    }

    return recovered + resolvedConflicts;
  }

  /// Process the sync queue with dependency-aware ordering.
  ///
  /// DEPENDENCY FIX: Processes entities in strict dependency order:
  ///   1. Media files uploaded first (F14 FIX)
  ///   2. Surveys synced and confirmed on server
  ///   3. Sections synced (only after ALL surveys succeed)
  ///   4. Answers synced (only after ALL sections succeed)
  ///
  /// This prevents the "Section not found 404" race condition where
  /// sections were sent before their parent survey was acknowledged
  /// by the server.
  ///
  /// If a dependency tier fails (e.g., a survey fails to sync), all
  /// dependent items (its sections/answers) are reset to pending for
  /// the next sync cycle rather than being attempted and failing with 404.
  Future<SyncResult> processQueue({
    void Function(int current, int total, SyncQueueItem item)? onProgress,
  }) async {
    AppLogger.d('SyncManager', 'processQueue called');
    final isConnected = await checkConnectivity();
    if (!isConnected) {
      AppLogger.d('SyncManager', 'No internet connection, aborting sync');
      return const SyncResult(
        success: false,
        errorMessage: 'No internet connection',
      );
    }

    var syncedCount = 0;
    var failedCount = 0;
    String? lastError;

    // STEP 1: Upload media files FIRST before metadata sync (F14 FIX)
    AppLogger.d('SyncManager', 'STEP 1: Uploading pending media files first...');
    try {
      final mediaResult = await mediaUploadService.uploadAllPendingMedia();
      AppLogger.d('SyncManager', 'Media upload complete: ${mediaResult.success} success, ${mediaResult.failed} failed');
      syncedCount += mediaResult.success;
      if (mediaResult.failed > 0) {
        AppLogger.w('SyncManager', 'Some media uploads failed (${mediaResult.failed}). Continuing with metadata sync.');
        failedCount += mediaResult.failed;
        lastError = 'Some media uploads failed';
      }
    } catch (e) {
      AppLogger.e('SyncManager', 'Media upload error: $e');
      lastError = 'Media upload failed: $e';
    }

    // STEP 2: Sync metadata in dependency order (surveys → sections → answers)
    AppLogger.d('SyncManager', 'STEP 2: Syncing metadata with dependency ordering...');
    final pendingItems = await syncQueueDao.getPendingItems();
    AppLogger.d('SyncManager', 'Found ${pendingItems.length} pending sync queue items');

    // Group items by entity type for dependency-ordered processing
    final surveyItems = <SyncQueueItem>[];
    final sectionItems = <SyncQueueItem>[];
    final answerItems = <SyncQueueItem>[];
    final photoItems = <SyncQueueItem>[];

    for (final data in pendingItems) {
      final item = syncQueueDao.toSyncQueueItem(data);
      switch (item.entityType) {
        case SyncEntityType.survey:
          surveyItems.add(item);
        case SyncEntityType.section:
          sectionItems.add(item);
        case SyncEntityType.answer:
          answerItems.add(item);
        case SyncEntityType.photo:
          photoItems.add(item);
      }
    }

    AppLogger.d('SyncManager',
      'Dependency groups: ${surveyItems.length} surveys, '
      '${sectionItems.length} sections, ${answerItems.length} answers, '
      '${photoItems.length} photos',
    );

    // Track which survey/section IDs failed so we skip their dependents
    final failedSurveyIds = <String>{};
    final failedSectionIds = <String>{};
    var progressIndex = 0;
    final totalItems = pendingItems.length;

    // --- TIER 1: Sync all surveys first ---
    var authAborted = false;
    for (final item in surveyItems) {
      progressIndex++;
      onProgress?.call(progressIndex, totalItems, item);
      final result = await _processOneItem(item);
      if (result.success) {
        syncedCount++;
      } else if (result.isAuthFailure) {
        authAborted = true;
        lastError = 'Session expired';
        break;
      } else {
        failedSurveyIds.add(item.entityId);
        if (result.isRetryable) {
          // Don't count dependency-deferred items as failures
        } else {
          failedCount++;
        }
        lastError = result.error ?? lastError;
      }
    }

    // --- TIER 2: Sync sections (strict dependency lock) ---
    //
    // DEPENDENCY FIX: Four guards prevent the "Section not found 404" race:
    //   CHECK 1: Parent survey failed IN THIS cycle (in-memory set)
    //   CHECK 2: Parent survey still unsynced from a PREVIOUS cycle (DB query)
    //   CHECK 3: Same section already failed this cycle (duplicate row guard)
    //   CHECK 4: Same section already processed this cycle (CREATE+UPDATE split)
    final processedSectionEntityIds = <String>{};
    for (final item in sectionItems) {
      if (authAborted) break;
      progressIndex++;
      onProgress?.call(progressIndex, totalItems, item);

      final payload = jsonDecode(item.payload) as Map<String, dynamic>;
      final surveyId = payload['surveyId'] as String?;

      // CHECK 1: Parent survey failed in THIS cycle
      if (surveyId != null && failedSurveyIds.contains(surveyId)) {
        AppLogger.d('SyncManager',
          'Deferring section ${item.entityId}: parent survey $surveyId failed this cycle',
        );
        await syncQueueDao.resetToPending(item.id);
        continue;
      }

      // CHECK 2: Parent survey still unsynced from a PREVIOUS cycle
      // (mirrors the hasPendingSync pattern TIER 3 already uses for sections)
      if (surveyId != null) {
        final surveyStillUnsynced = await syncQueueDao.hasPendingSync(surveyId);
        if (surveyStillUnsynced) {
          AppLogger.d('SyncManager',
            'Deferring section ${item.entityId}: parent survey $surveyId still unsynced',
          );
          await syncQueueDao.resetToPending(item.id);
          continue;
        }
      }

      // CHECK 3: Same section already failed earlier in this cycle
      // (catches the CREATE+UPDATE split where CREATE failed and UPDATE
      // would otherwise proceed with a PUT against a non-existent entity)
      if (failedSectionIds.contains(item.entityId)) {
        AppLogger.d('SyncManager',
          'Deferring section ${item.entityId}: duplicate item already failed this cycle',
        );
        await syncQueueDao.resetToPending(item.id);
        continue;
      }

      // CHECK 4: Another queue item for the same section already processed
      // this cycle (one entity = one sync attempt per cycle)
      if (processedSectionEntityIds.contains(item.entityId)) {
        AppLogger.d('SyncManager',
          'Deferring section ${item.entityId}: same entity already processed this cycle',
        );
        await syncQueueDao.resetToPending(item.id);
        continue;
      }

      final result = await _processOneItem(item);
      processedSectionEntityIds.add(item.entityId);
      if (result.success) {
        syncedCount++;
      } else if (result.isAuthFailure) {
        authAborted = true;
        lastError = 'Session expired';
        break;
      } else {
        failedSectionIds.add(item.entityId);
        if (!result.isRetryable) failedCount++;
        lastError = result.error ?? lastError;
      }
    }

    // --- TIER 3: Sync answers (strict dependency lock) ---
    //
    // Guards mirror TIER 2 + same-entity dedup for answers.
    final processedAnswerEntityIds = <String>{};
    for (final item in answerItems) {
      if (authAborted) break;
      progressIndex++;
      onProgress?.call(progressIndex, totalItems, item);

      final payload = jsonDecode(item.payload) as Map<String, dynamic>;
      final sectionId = payload['sectionId'] as String?;

      // CHECK 1: Parent section failed in THIS cycle
      if (sectionId != null && failedSectionIds.contains(sectionId)) {
        AppLogger.d('SyncManager',
          'Deferring answer ${item.entityId}: parent section $sectionId failed this cycle',
        );
        await syncQueueDao.resetToPending(item.id);
        continue;
      }

      // CHECK 2: Parent section (or grandparent survey) still unsynced
      // from a PREVIOUS cycle — hasPendingSync now includes 'failed' status,
      // so this transitively blocks: survey(failed) → section(pending) → answer(blocked)
      if (sectionId != null) {
        final sectionStillUnsynced = await syncQueueDao.hasPendingSync(sectionId);
        if (sectionStillUnsynced) {
          AppLogger.d('SyncManager',
            'Deferring answer ${item.entityId}: parent section $sectionId still unsynced',
          );
          await syncQueueDao.resetToPending(item.id);
          continue;
        }
      }

      // CHECK 3: Same answer already processed this cycle (CREATE+UPDATE split)
      if (processedAnswerEntityIds.contains(item.entityId)) {
        AppLogger.d('SyncManager',
          'Deferring answer ${item.entityId}: same entity already processed this cycle',
        );
        await syncQueueDao.resetToPending(item.id);
        continue;
      }

      final result = await _processOneItem(item);
      processedAnswerEntityIds.add(item.entityId);
      if (result.success) {
        syncedCount++;
      } else if (result.isAuthFailure) {
        authAborted = true;
        lastError = 'Session expired';
        break;
      } else {
        if (!result.isRetryable) failedCount++;
        lastError = result.error ?? lastError;
      }
    }

    // --- TIER 4: Sync photo metadata ---
    for (final item in photoItems) {
      if (authAborted) break;
      progressIndex++;
      onProgress?.call(progressIndex, totalItems, item);
      final result = await _processOneItem(item);
      if (result.success) {
        syncedCount++;
      } else if (result.isAuthFailure) {
        authAborted = true;
        lastError = 'Session expired';
        break;
      } else {
        if (!result.isRetryable) failedCount++;
        lastError = result.error ?? lastError;
      }
    }

    // Structured sync metrics summary
    AppLogger.d('SyncManager',
      'SYNC COMPLETE | '
      'synced=$syncedCount | '
      'failed=$failedCount | '
      'deferred_surveys=${failedSurveyIds.length} | '
      'deferred_sections=${failedSectionIds.length} | '
      'total_queued=$totalItems | '
      'surveys=${surveyItems.length} | '
      'sections=${sectionItems.length} | '
      'answers=${answerItems.length} | '
      'photos=${photoItems.length}',
    );
    return SyncResult(
      success: failedCount == 0,
      syncedCount: syncedCount,
      failedCount: failedCount,
      errorMessage: lastError,
    );
  }

  /// Process a single sync queue item. Returns a result indicating success
  /// or failure with retry information.
  Future<_ItemSyncResult> _processOneItem(SyncQueueItem item) async {
    await syncQueueDao.markAsProcessing(item.id);

    // Calculate backoff delay based on retry count
    if (item.retryCount > 0) {
      final delay = _calculateBackoff(item.retryCount);
      await Future.delayed(delay);
    }

    try {
      final success = await _syncItem(item);
      if (success) {
        await syncQueueDao.markAsCompleted(item.id);
        return const _ItemSyncResult(success: true);
      } else {
        const msg = 'Server rejected request (non-retryable)';
        AppLogger.w('SyncManager',
          'Sync failed for ${item.entityType.name} ${item.entityId}: $msg',
        );
        await syncQueueDao.markAsFailed(item.id, msg);
        return const _ItemSyncResult(success: false, error: 'Some items failed to sync');
      }
    } on RateLimitException catch (e) {
      final waitSeconds = e.retryAfterSeconds ?? 5;
      AppLogger.w(
        'SyncManager',
        'Rate limited (429) syncing ${item.entityType.name} ${item.entityId}. '
        'Pausing for ${waitSeconds}s.',
      );
      await syncQueueDao.resetToPending(item.id);
      await Future.delayed(Duration(seconds: waitSeconds));
      return _ItemSyncResult(
        success: false,
        isRetryable: true,
        error: 'Rate limited by server — retrying after delay',
      );
    } on SyncConflictException catch (e) {
      AppLogger.w(
        'SyncManager',
        'Conflict detected for ${e.entityType.name} ${e.entityId}: ${e.message}',
      );
      await syncQueueDao.markAsConflict(item.id, e.serverVersion ?? 0);
      return _ItemSyncResult(
        success: false,
        error: 'Conflict detected - requires resolution',
      );
    } on AuthException {
      // Auth failure — token refresh already attempted and failed.
      // Abort this item immediately and signal caller to stop the queue.
      AppLogger.w('SyncManager',
        'Auth failure syncing ${item.entityType.name} ${item.entityId}. '
        'Session expired — aborting sync queue.',
      );
      await syncQueueDao.resetToPending(item.id);
      return const _ItemSyncResult(
        success: false,
        isAuthFailure: true,
        error: 'Session expired',
      );
    } catch (e) {
      final errorMsg = _extractReadableError(e);
      AppLogger.e('SyncManager',
        'Sync error for ${item.entityType.name} ${item.entityId}: $errorMsg',
      );

      // DEPENDENCY FIX: If this is a 404 "not found" error on a section/answer,
      // treat it as a retryable dependency issue — but with a cap to prevent
      // infinite retries for truly orphaned entities.
      if (_isDependencyNotFoundError(e)) {
        if (item.retryCount < _maxDependencyRetries) {
          AppLogger.w('SyncManager',
            'Dependency not found for ${item.entityType.name} ${item.entityId} '
            '(attempt ${item.retryCount + 1}/$_maxDependencyRetries) — '
            'deferring to next sync cycle',
          );
          // Use markAsFailed which increments retryCount but keeps as 'pending'
          // until maxRetries is reached. We pass through to let normal retry
          // logic handle it, but flag it as retryable for this cycle.
          await syncQueueDao.markAsFailed(
            item.id,
            'Dependency not found (404) — parent entity not yet synced '
            '(attempt ${item.retryCount + 1}/$_maxDependencyRetries)',
          );
          return const _ItemSyncResult(
            success: false,
            isRetryable: true,
            error: 'Parent entity not yet synced — will retry',
          );
        } else {
          // Exceeded dependency retry cap — this is likely a true orphan
          AppLogger.e('SyncManager',
            'ORPHAN DETECTED: ${item.entityType.name} ${item.entityId} failed '
            'dependency check $_maxDependencyRetries times. Marking as permanently '
            'failed. Parent entity likely does not exist.',
          );
          await syncQueueDao.markAsFailed(
            item.id,
            'Permanently failed: parent entity not found after '
            '$_maxDependencyRetries attempts (orphaned entity)',
          );
          return const _ItemSyncResult(
            success: false,
            error: 'Orphaned entity — parent not found after max retries',
          );
        }
      }

      await syncQueueDao.markAsFailed(item.id, errorMsg);
      return _ItemSyncResult(success: false, error: errorMsg);
    }
  }

  /// Check if an error is a 404 "not found" that indicates a missing
  /// parent entity (survey or section) — a dependency ordering issue.
  bool _isDependencyNotFoundError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('404') &&
        (errorStr.contains('not found') ||
         errorStr.contains('survey not found') ||
         errorStr.contains('section not found'));
  }

  /// Calculate exponential backoff delay
  Duration _calculateBackoff(int retryCount) {
    // Base: 1 second, doubles each retry, max 30 seconds
    final seconds = (1 << retryCount).clamp(1, 30);
    return Duration(seconds: seconds);
  }

  /// Extract a human-readable error message from an exception.
  ///
  /// Handles DioException responses that contain structured validation errors
  /// from the NestJS backend (e.g., {"message":["field must be a string"]}).
  String _extractReadableError(dynamic error) {
    try {
      final errorStr = error.toString();

      // Try to extract structured error from Dio response
      if (errorStr.contains('DioException') || errorStr.contains('status code')) {
        // Look for status code
        final statusMatch = RegExp(r'status code.*?(\d{3})').firstMatch(errorStr);
        final status = statusMatch?.group(1) ?? '';

        // Look for validation messages in response data
        final msgMatch = RegExp(r'"message"\s*:\s*\[([^\]]+)\]').firstMatch(errorStr);
        if (msgMatch != null) {
          return 'HTTP $status: ${msgMatch.group(1)?.replaceAll('"', '') ?? 'Validation failed'}';
        }

        final singleMsgMatch = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(errorStr);
        if (singleMsgMatch != null) {
          return 'HTTP $status: ${singleMsgMatch.group(1)}';
        }

        if (status.isNotEmpty) {
          return 'HTTP $status error';
        }
      }

      // Truncate long error messages
      if (errorStr.length > 200) {
        return '${errorStr.substring(0, 200)}...';
      }
      return errorStr;
    } catch (_) {
      return error.toString().length > 200
          ? '${error.toString().substring(0, 200)}...'
          : error.toString();
    }
  }

  /// Sync a single item to the server.
  ///
  /// Throws on error so the caller can capture the real error message
  /// for diagnostics (stored in sync_queue.errorMessage).
  Future<bool> _syncItem(SyncQueueItem item) async {
    final payload = jsonDecode(item.payload) as Map<String, dynamic>;

    AppLogger.d(
      'SyncManager',
      'Syncing ${item.entityType.name} ${item.entityId} '
      '(action=${item.action.name}, retry=${item.retryCount})',
    );

    switch (item.entityType) {
      case SyncEntityType.survey:
        return _syncSurvey(item.action, item.entityId, payload);
      case SyncEntityType.section:
        return _syncSection(item.action, item.entityId, payload);
      case SyncEntityType.answer:
        return _syncAnswer(item.action, item.entityId, payload);
      case SyncEntityType.photo:
        return _syncPhoto(item.action, item.entityId, payload);
    }
  }

  Future<bool> _syncSurvey(
    SyncAction action,
    String entityId,
    Map<String, dynamic> payload,
  ) async {
    try {
      switch (action) {
        case SyncAction.create:
          // CRITICAL: Include the survey ID in the payload for offline-first sync
          // This ensures the backend uses the same ID as the local database
          final createPayload = {
            'id': entityId, // Client-provided UUID for ID consistency
            ...payload,
          };
          await apiClient.post('surveys', data: createPayload);
        case SyncAction.update:
          try {
            await apiClient.put('surveys/$entityId', data: payload);
          } on NotFoundException {
            // UPSERT: Server doesn't have this survey (DB reset, data loss).
            // Auto-create via POST so dependents (sections, answers) can sync.
            //
            // CRITICAL: Do NOT reuse payload — UPDATE payloads may only
            // contain mutated fields and be missing required CREATE fields
            // (title, propertyAddress, status, type). Fetch the complete
            // entity from local DB to build a valid CREATE payload.
            AppLogger.w('SyncManager',
              'Survey $entityId not found on server (404 on UPDATE). '
              'Fetching full entity from local DB for upsert.',
            );

            final survey = await surveysDao.getSurveyById(entityId);
            if (survey == null) {
              AppLogger.e('SyncManager',
                'Cannot upsert survey $entityId: not found in local DB either.',
              );
              return false;
            }

            final fullCreatePayload = {
              'id': entityId,
              'title': survey.title,
              'propertyAddress': survey.address ?? '',
              'status': survey.status.toBackendString(),
              'type': survey.type.toBackendString(),
              if (survey.jobRef != null) 'jobRef': survey.jobRef,
              if (survey.clientName != null) 'clientName': survey.clientName,
              if (survey.parentSurveyId != null) 'parentSurveyId': survey.parentSurveyId,
              // Merge any extra fields from the original update payload
              // so they're not lost.
              ...payload,
            };
            await apiClient.post('surveys', data: fullCreatePayload);
          }
        case SyncAction.delete:
          try {
            await apiClient.delete('surveys/$entityId');
          } on NotFoundException {
            // Entity already gone — treat as success
            AppLogger.d('SyncManager',
              'Survey $entityId already deleted on server (404 on DELETE). '
              'Treating as success.',
            );
          }
      }
      return true;
    } catch (e) {
      // Rethrow rate limit exceptions for queue-level handling
      if (e is RateLimitException) rethrow;
      // IDEMPOTENT CREATE: If server returns 409 "already exists" for a
      // CREATE action, treat it as success — the survey already exists on
      // the server with the same client-generated UUID. This prevents the
      // sync queue from getting stuck in "conflict" state forever.
      if (_isConflictError(e) && action == SyncAction.create) {
        AppLogger.d('SyncManager',
          'Survey $entityId already exists on server (409). '
          'Treating CREATE as success (idempotent).',
        );
        return true;
      }
      // F12 FIX: Properly detect and handle 409 conflicts for UPDATE actions
      if (_isConflictError(e)) {
        throw SyncConflictException(
          entityId: entityId,
          entityType: SyncEntityType.survey,
          serverVersion: _extractServerVersion(e),
          message: 'Survey version conflict with server',
        );
      }
      rethrow;
    }
  }

  /// Check if error is a 409 conflict.
  ///
  /// Primary: Check `ServerException.statusCode` directly (reliable).
  /// Fallback: String-based detection for non-ServerException errors
  /// (e.g. raw DioException leaking through).
  bool _isConflictError(dynamic error) {
    // Direct status code check — most reliable
    if (error is ServerException && error.statusCode == 409) return true;

    // Fallback: string-based detection for edge cases
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('409') ||
        errorStr.contains('conflict') ||
        errorStr.contains('unique constraint') ||
        errorStr.contains('already exists') ||
        errorStr.contains('version mismatch');
  }

  /// Extract server version from conflict error response if available
  int? _extractServerVersion(dynamic error) {
    // Try to extract version from error message or response
    // This is a best-effort extraction - returns null if not found
    final errorStr = error is ServerException
        ? (error.message ?? error.toString())
        : error.toString();
    final versionMatch = RegExp(r'version[:\s]+(\d+)').firstMatch(errorStr);
    if (versionMatch != null) {
      return int.tryParse(versionMatch.group(1) ?? '');
    }
    return null;
  }

  Future<bool> _syncSection(
    SyncAction action,
    String entityId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final surveyId = payload['surveyId'] as String?;
      // Strip routing fields before sending to backend —
      // 'surveyId' is used as a URL param, not a body field.
      // Backend forbidNonWhitelisted:true rejects unknown fields.
      final bodyPayload = Map<String, dynamic>.from(payload)
        ..remove('surveyId');
      switch (action) {
        case SyncAction.create:
          // Include client-generated UUID so server uses the same ID
          // as the local database — prevents ID mismatch on child entities
          final createPayload = {
            'id': entityId,
            ...bodyPayload,
          };
          try {
            await apiClient.post('surveys/$surveyId/sections', data: createPayload);
          } on NotFoundException {
            // Parent survey not found on server — auto-create it from local
            // DB then retry. Handles server DB reset / data loss gracefully.
            if (surveyId != null) {
              AppLogger.w('SyncManager',
                'Parent survey $surveyId not found while creating section '
                '$entityId. Auto-creating survey (ensure-parent).',
              );
              await _ensureSurveyExists(surveyId);
              await apiClient.post('surveys/$surveyId/sections', data: createPayload);
            } else {
              rethrow;
            }
          }
        case SyncAction.update:
          try {
            await apiClient.put('sections/$entityId', data: bodyPayload);
          } on NotFoundException {
            // UPSERT: Server doesn't have this section (DB reset, data loss).
            // Auto-create via POST so dependents (answers) can sync.
            //
            // CRITICAL: Do NOT reuse bodyPayload — UPDATE payloads only contain
            // mutated fields (e.g. phraseOutput, userNotes) and are missing
            // required CREATE fields (title, order, sectionTypeKey). Fetch the
            // complete entity from local DB to build a valid CREATE payload.
            AppLogger.w('SyncManager',
              'Section $entityId not found on server (404 on UPDATE). '
              'Fetching full entity from local DB for upsert.',
            );

            final section = await sectionsDao.getSectionById(entityId);
            if (section == null) {
              // Stale queue item: section was removed locally, and server also
              // doesn't have it. Drop this update item as a no-op so sync
              // doesn't get stuck forever on an orphaned operation.
              AppLogger.w('SyncManager',
                'Dropping stale section update $entityId: '
                'missing in local DB and server (404).',
              );
              return true;
            }

            final resolvedSurveyId = surveyId ?? section.surveyId;
            final fullCreatePayload = {
              'id': entityId,
              'title': section.title,
              'order': section.order,
              'sectionTypeKey': section.sectionType.apiSectionType,
              // Merge any extra fields from the original update payload
              // (e.g. phraseOutput, userNotes) so they're not lost.
              ...bodyPayload,
            };

            try {
              await apiClient.post('surveys/$resolvedSurveyId/sections', data: fullCreatePayload);
            } on NotFoundException {
              // Parent survey also missing — ensure it exists first
              await _ensureSurveyExists(resolvedSurveyId);
              await apiClient.post('surveys/$resolvedSurveyId/sections', data: fullCreatePayload);
            }
          }
        case SyncAction.delete:
          try {
            await apiClient.delete('sections/$entityId');
          } on NotFoundException {
            // Entity already gone — treat as success
            AppLogger.d('SyncManager',
              'Section $entityId already deleted on server (404 on DELETE). '
              'Treating as success.',
            );
          }
      }
      return true;
    } catch (e) {
      // Rethrow rate limit exceptions for queue-level handling
      if (e is RateLimitException) rethrow;
      // IDEMPOTENT CREATE: 409 on CREATE means section already exists
      if (_isConflictError(e) && action == SyncAction.create) {
        AppLogger.d('SyncManager',
          'Section $entityId already exists on server (409). '
          'Treating CREATE as success (idempotent).',
        );
        return true;
      }
      if (_isConflictError(e)) {
        throw SyncConflictException(
          entityId: entityId,
          entityType: SyncEntityType.section,
          serverVersion: _extractServerVersion(e),
          message: 'Section version conflict with server',
        );
      }
      rethrow;
    }
  }

  Future<bool> _syncAnswer(
    SyncAction action,
    String entityId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final sectionId = payload['sectionId'] as String?;
      // Strip routing fields before sending to backend —
      // 'sectionId' is used as a URL param, not a body field.
      // Backend forbidNonWhitelisted:true rejects unknown fields.
      final bodyPayload = Map<String, dynamic>.from(payload)
        ..remove('sectionId');
      switch (action) {
        case SyncAction.create:
          // Include client-generated UUID so server uses the same ID
          // as the local database — prevents ID mismatch
          final createPayload = {
            'id': entityId,
            ...bodyPayload,
          };
          try {
            await apiClient.post('sections/$sectionId/answers', data: createPayload);
          } on NotFoundException {
            // Parent section not found on server — auto-create it from local
            // DB then retry. Handles server DB reset / data loss gracefully.
            if (sectionId != null) {
              AppLogger.w('SyncManager',
                'Parent section $sectionId not found while creating answer '
                '$entityId. Auto-creating section (ensure-parent).',
              );
              await _ensureSectionExists(sectionId);
              await apiClient.post('sections/$sectionId/answers', data: createPayload);
            } else {
              rethrow;
            }
          }
        case SyncAction.update:
          try {
            await apiClient.put('answers/$entityId', data: bodyPayload);
          } on NotFoundException {
            // UPSERT: Server doesn't have this answer (DB reset, data loss).
            // Auto-create via POST.
            //
            // CRITICAL: Do NOT reuse bodyPayload — UPDATE payloads may only
            // contain mutated fields (e.g. just 'value') and be missing
            // required CREATE fields (questionKey). Fetch the complete
            // entity from local DB to build a valid CREATE payload.
            AppLogger.w('SyncManager',
              'Answer $entityId not found on server (404 on UPDATE). '
              'Fetching full entity from local DB for upsert.',
            );

            final answer = await answersDao.getAnswerById(entityId);
            if (answer == null) {
              // Stale queue item: answer was removed locally, and server also
              // doesn't have it. Drop this update item as a no-op so sync
              // doesn't get stuck forever on an orphaned operation.
              AppLogger.w('SyncManager',
                'Dropping stale answer update $entityId: '
                'missing in local DB and server (404).',
              );
              return true;
            }

            final resolvedSectionId = sectionId ?? answer.sectionId;
            final fullCreatePayload = {
              'id': entityId,
              'questionKey': answer.fieldKey,
              'value': answer.value ?? '',
              // Merge any extra fields from the original update payload
              // so they're not lost.
              ...bodyPayload,
            };

            try {
              await apiClient.post('sections/$resolvedSectionId/answers', data: fullCreatePayload);
            } on NotFoundException {
              // Parent section also missing — ensure it exists first
              await _ensureSectionExists(resolvedSectionId);
              await apiClient.post('sections/$resolvedSectionId/answers', data: fullCreatePayload);
            }
          }
        case SyncAction.delete:
          try {
            await apiClient.delete('answers/$entityId');
          } on NotFoundException {
            // Entity already gone — treat as success
            AppLogger.d('SyncManager',
              'Answer $entityId already deleted on server (404 on DELETE). '
              'Treating as success.',
            );
          }
      }
      return true;
    } catch (e) {
      // Rethrow rate limit exceptions for queue-level handling
      if (e is RateLimitException) rethrow;
      // IDEMPOTENT CREATE: 409 on CREATE means answer already exists
      if (_isConflictError(e) && action == SyncAction.create) {
        AppLogger.d('SyncManager',
          'Answer $entityId already exists on server (409). '
          'Treating CREATE as success (idempotent).',
        );
        return true;
      }
      if (_isConflictError(e)) {
        throw SyncConflictException(
          entityId: entityId,
          entityType: SyncEntityType.answer,
          serverVersion: _extractServerVersion(e),
          message: 'Answer version conflict with server',
        );
      }
      rethrow;
    }
  }

  /// Ensure a survey exists on the server by reading it from local DB and
  /// creating it via POST. Used by section/answer sync when the parent survey
  /// is missing (server DB reset, data loss, etc.).
  ///
  /// If the survey already exists (409), this is treated as success.
  /// If the survey is not in local DB, this is a no-op (nothing to recreate).
  Future<void> _ensureSurveyExists(String surveyId) async {
    final survey = await surveysDao.getSurveyById(surveyId);
    if (survey == null) {
      AppLogger.w('SyncManager',
        'Cannot auto-create survey $surveyId: not found in local DB.',
      );
      return;
    }

    // Build payload matching CreateSurveyDto fields exactly.
    // Backend forbidNonWhitelisted:true rejects unknown fields.
    final payload = {
      'id': surveyId,
      'title': survey.title,
      'propertyAddress': survey.address ?? '',
      'status': survey.status.toBackendString(),
      'type': survey.type.toBackendString(),
      if (survey.jobRef != null) 'jobRef': survey.jobRef,
      if (survey.clientName != null) 'clientName': survey.clientName,
      if (survey.parentSurveyId != null) 'parentSurveyId': survey.parentSurveyId,
    };

    try {
      await apiClient.post('surveys', data: payload);
      AppLogger.d('SyncManager',
        'Auto-created survey $surveyId on server (ensure-parent).',
      );
    } catch (e) {
      // 409 = already exists — that's fine, the survey is there now
      if (_isConflictError(e)) {
        AppLogger.d('SyncManager',
          'Survey $surveyId already exists on server (409 during ensure-parent).',
        );
        return;
      }
      // Any other error — log and rethrow so the child sync fails with
      // a meaningful error instead of silently losing data.
      AppLogger.e('SyncManager',
        'Failed to auto-create survey $surveyId: $e',
      );
      rethrow;
    }
  }

  /// Ensure a section exists on the server by reading it from local DB and
  /// creating it via POST. Used by answer sync when the parent section
  /// is missing (server DB reset, data loss, etc.).
  ///
  /// This also ensures the grandparent survey exists (transitive dependency).
  Future<void> _ensureSectionExists(String sectionId) async {
    final section = await sectionsDao.getSectionById(sectionId);
    if (section == null) {
      AppLogger.w('SyncManager',
        'Cannot auto-create section $sectionId: not found in local DB.',
      );
      return;
    }

    // Ensure the grandparent survey exists first (transitive dependency)
    await _ensureSurveyExists(section.surveyId);

    // Build payload matching CreateSectionDto fields exactly.
    // 'surveyId' is a URL param, not a body field.
    final payload = {
      'id': sectionId,
      'title': section.title,
      'order': section.order,
      'sectionTypeKey': section.sectionType.apiSectionType,
    };

    try {
      await apiClient.post(
        'surveys/${section.surveyId}/sections',
        data: payload,
      );
      AppLogger.d('SyncManager',
        'Auto-created section $sectionId on server (ensure-parent).',
      );
    } catch (e) {
      // 409 = already exists — that's fine, the section is there now
      if (_isConflictError(e)) {
        AppLogger.d('SyncManager',
          'Section $sectionId already exists on server (409 during ensure-parent).',
        );
        return;
      }
      AppLogger.e('SyncManager',
        'Failed to auto-create section $sectionId: $e',
      );
      rethrow;
    }
  }

  Future<bool> _syncPhoto(
    SyncAction action,
    String entityId,
    Map<String, dynamic> payload,
  ) async {
    // Media sync using backend /media endpoints
    // CREATE requires multipart upload handled separately via MediaSyncService
    // This handles metadata-only operations
    try {
      switch (action) {
        case SyncAction.create:
          // Photo create requires multipart upload - queued items with filePath
          // are handled by MediaSyncService.uploadPendingMedia()
          // This path handles metadata-only fallback
          if (payload['filePath'] != null) {
            // Has local file - skip here, MediaSyncService handles it
            return true;
          }
          // Metadata only - shouldn't happen for photos
          return false;
        case SyncAction.update:
          // Media doesn't support update - only create/delete
          return true;
        case SyncAction.delete:
          await apiClient.delete('media/$entityId');
      }
      return true;
    } catch (e) {
      if (e is RateLimitException) rethrow;
      // IDEMPOTENT CREATE: 409 on CREATE means photo already exists
      if (_isConflictError(e) && action == SyncAction.create) {
        AppLogger.d('SyncManager',
          'Photo $entityId already exists on server (409). '
          'Treating CREATE as success (idempotent).',
        );
        return true;
      }
      if (_isConflictError(e)) {
        throw SyncConflictException(
          entityId: entityId,
          entityType: SyncEntityType.photo,
          serverVersion: _extractServerVersion(e),
          message: 'Photo version conflict with server',
        );
      }
      rethrow;
    }
  }

  // ========================================
  // SYNC PULL - Fetch server changes
  // ========================================

  /// Pull changes from server since last pull timestamp.
  ///
  /// Uses cursor-based pagination via the `since` parameter.
  /// Conflict strategy: server-wins, but entities with pending local
  /// sync queue items are skipped to avoid overwriting unsaved local edits.
  ///
  /// Returns the number of entities upserted into local DB.
  Future<SyncPullResult> pullChanges() async {
    AppLogger.d('SyncManager', 'pullChanges called');
    final isConnected = await checkConnectivity();
    if (!isConnected) {
      AppLogger.d('SyncManager', 'No internet connection, aborting pull');
      return const SyncPullResult(
        success: false,
        errorMessage: 'No internet connection',
      );
    }

    var totalUpserted = 0;
    var totalSkipped = 0;
    final affectedSurveyIds = <String>{};
    var hasMore = true;
    var cursor = StorageService.lastPullTimestamp;

    try {
      while (hasMore) {
        // Build query parameters
        final queryParams = <String, dynamic>{
          'limit': 100,
        };
        if (cursor != null) {
          queryParams['since'] = cursor;
        }

        AppLogger.d('SyncManager', 'Pulling changes since=$cursor');
        final response = await apiClient.get<Map<String, dynamic>>(
          'sync/pull',
          queryParameters: queryParams,
        );

        final data = response.data;
        if (data == null) {
          AppLogger.w('SyncManager', 'Pull response was null');
          break;
        }

        final changes = (data['changes'] as List<dynamic>?) ?? [];
        final serverTimestamp = data['serverTimestamp'] as String?;
        hasMore = (data['hasMore'] as bool?) ?? false;

        AppLogger.d('SyncManager', 'Received ${changes.length} changes, hasMore=$hasMore');

        for (final change in changes) {
          final map = change as Map<String, dynamic>;
          final entityType = map['entityType'] as String?;
          final entityId = map['entityId'] as String?;
          final changeType = map['changeType'] as String?;
          final entityData = map['data'] as Map<String, dynamic>?;

          if (entityType == null || entityId == null || changeType == null) {
            AppLogger.w('SyncManager', 'Skipping malformed change: $map');
            totalSkipped++;
            continue;
          }

          // Skip entities that have pending local changes (avoid overwriting)
          final hasPending = await syncQueueDao.hasPendingSync(entityId);
          if (hasPending) {
            AppLogger.d('SyncManager', 'Skipping $entityType $entityId - has pending local changes');
            totalSkipped++;
            continue;
          }

          try {
            if (changeType == 'DELETE') {
              await _applyDelete(entityType, entityId);
            } else if (entityData != null) {
              await _applyUpsert(entityType, entityId, entityData);
              // Track affected survey IDs for targeted provider invalidation.
              if (entityType == 'SECTION') {
                final surveyId = entityData['surveyId'] as String?;
                if (surveyId != null && surveyId.isNotEmpty) {
                  affectedSurveyIds.add(surveyId);
                }
              } else if (entityType == 'SURVEY') {
                affectedSurveyIds.add(entityId);
              }
            }
            totalUpserted++;
          } catch (e) {
            AppLogger.e('SyncManager', 'Failed to apply $changeType for $entityType $entityId: $e');
            totalSkipped++;
          }
        }

        // Update cursor for next page / next pull session
        if (serverTimestamp != null) {
          cursor = serverTimestamp;
          await StorageService.setLastPullTimestamp(serverTimestamp);
        }
      }

      AppLogger.d('SyncManager', 'Pull complete: $totalUpserted upserted, $totalSkipped skipped');
      return SyncPullResult(
        success: true,
        upsertedCount: totalUpserted,
        skippedCount: totalSkipped,
        affectedSurveyIds: affectedSurveyIds,
      );
    } catch (e) {
      AppLogger.e('SyncManager', 'Pull failed: $e');
      return SyncPullResult(
        success: false,
        upsertedCount: totalUpserted,
        skippedCount: totalSkipped,
        errorMessage: 'Pull failed: $e',
        affectedSurveyIds: affectedSurveyIds,
      );
    }
  }

  /// Apply a server-side upsert to the local Drift database.
  Future<void> _applyUpsert(
    String entityType,
    String entityId,
    Map<String, dynamic> data,
  ) async {
    switch (entityType) {
      case 'SURVEY':
        final survey = _mapServerSurvey(entityId, data);
        await surveysDao.upsertSurvey(survey);
      case 'SECTION':
        var section = _mapServerSection(entityId, data);
        // Prevent duplication: composite sync push sends sections without
        // local IDs, so the server creates new IDs. When those come back
        // via pull, we must remove the stale local copy (same surveyId +
        // order but different ID) before upserting the server version.
        // CRITICAL: Preserve local-only fields (sectionType, isCompleted)
        // since the server doesn't store them — the local DB is the
        // source of truth for these fields.
        if (section.surveyId.isNotEmpty) {
          final existing = await sectionsDao.getSectionsForSurvey(section.surveyId);
          for (final old in existing) {
            if (old.order == section.order && old.id != section.id) {
              // Preserve local-only fields from the local copy before deleting it.
              section = section.copyWith(
                sectionType: old.sectionType,
                isCompleted: old.isCompleted,
              );
              await sectionsDao.deleteSection(old.id);
            }
          }
          // Also preserve local-only fields when upserting over an existing
          // row with the same ID (server update of a previously synced section).
          final existingSameId = existing.where((s) => s.id == section.id).firstOrNull;
          if (existingSameId != null) {
            section = section.copyWith(isCompleted: existingSameId.isCompleted);
            if (existingSameId.sectionType != entities.SectionType.notes) {
              section = section.copyWith(sectionType: existingSameId.sectionType);
            }
          }
        }
        await sectionsDao.upsertSection(section);
      case 'ANSWER':
        final answer = _mapServerAnswer(entityId, data);
        await answersDao.saveAnswer(answer);
      case 'MEDIA':
        // Media pull only updates metadata - file download is separate
        AppLogger.d('SyncManager', 'Media pull not yet supported for $entityId');
      default:
        AppLogger.w('SyncManager', 'Unknown entity type for upsert: $entityType');
    }
  }

  /// Apply a server-side delete to the local Drift database.
  Future<void> _applyDelete(String entityType, String entityId) async {
    switch (entityType) {
      case 'SURVEY':
        // Delete cascade: answers → sections → survey
        await answersDao.deleteAnswersForSurvey(entityId);
        await sectionsDao.deleteSectionsForSurvey(entityId);
        await surveysDao.deleteSurvey(entityId);
      case 'SECTION':
        await answersDao.deleteAnswersForSection(entityId);
        await sectionsDao.deleteSectionsForSurvey(entityId);
      case 'ANSWER':
        // No direct delete-by-id on answersDao, use survey-level
        // Answer deletes from server are rare; log and skip for now
        AppLogger.d('SyncManager', 'Answer delete for $entityId - skipping (no single-delete DAO method)');
      case 'MEDIA':
        await mediaDao.deleteMedia(entityId);
      default:
        AppLogger.w('SyncManager', 'Unknown entity type for delete: $entityType');
    }
  }

  /// Map server survey JSON to local Survey entity.
  entities.Survey _mapServerSurvey(String id, Map<String, dynamic> data) => entities.Survey(
      id: id,
      title: data['title'] as String? ?? 'Untitled',
      type: entities.SurveyType.fromBackendString(
        data['type'] as String? ?? 'OTHER',
      ),
      status: entities.SurveyStatus.fromBackendString(
        data['status'] as String? ?? 'DRAFT',
      ),
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updatedAt']),
      address: data['propertyAddress'] as String?,
      jobRef: data['jobRef'] as String?,
      clientName: data['clientName'] as String?,
      parentSurveyId: data['parentSurveyId'] as String?,
    );

  /// Map server section JSON to local SurveySection entity.
  /// Uses sectionTypeKey from server if available, otherwise falls back to
  /// title-based inference. The sync dedup logic in `_applyUpsert` also
  /// preserves sectionType from the existing local copy when available.
  entities.SurveySection _mapServerSection(String id, Map<String, dynamic> data) {
    final title = data['title'] as String? ?? 'Untitled';
    final serverKey = data['sectionTypeKey'] as String?;
    final sectionType = (serverKey != null ? sectionTypeFromApiKey(serverKey) : null)
        ?? _inferSectionTypeFromTitle(title);
    return entities.SurveySection(
      id: id,
      surveyId: data['surveyId'] as String? ?? '',
      sectionType: sectionType,
      title: title,
      order: (data['order'] as num?)?.toInt() ?? 0,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  /// Best-effort inference of SectionType from the section title.
  /// This is a fallback for when the server sends sections without sectionType.
  /// The canonical source of truth is the local DB (set at creation time);
  /// this only runs when no local copy exists to preserve from.
  static entities.SectionType _inferSectionTypeFromTitle(String title) {
    final lower = title.toLowerCase();
    // Order matters: check more specific patterns first.
    if (lower.contains('about') && lower.contains('inspection')) return entities.SectionType.aboutInspection;
    if (lower.contains('about') && lower.contains('valuation')) return entities.SectionType.aboutValuation;
    if (lower.contains('about') && lower.contains('property')) return entities.SectionType.aboutProperty;
    if (lower.contains('property') && lower.contains('summary')) return entities.SectionType.propertySummary;
    if (lower.contains('external') || lower.contains('exterior')) return entities.SectionType.externalItems;
    if (lower.contains('internal') || lower.contains('interior')) return entities.SectionType.internalItems;
    if (lower.contains('construction')) return entities.SectionType.construction;
    if (lower.contains('room')) return entities.SectionType.rooms;
    if (lower.contains('services') || lower.contains('utilities')) return entities.SectionType.services;
    if (lower.contains('issues') || lower.contains('risks') || lower.contains('defects')) return entities.SectionType.issuesAndRisks;
    if (lower.contains('market') && lower.contains('analysis')) return entities.SectionType.marketAnalysis;
    if (lower.contains('comparable')) return entities.SectionType.comparables;
    if (lower.contains('adjustment')) return entities.SectionType.adjustments;
    if (lower.contains('valuation') || lower.contains('final valuation')) return entities.SectionType.valuation;
    if (lower.contains('summary') || lower.contains('conclusion') || lower.contains('assumptions')) return entities.SectionType.summary;
    if (lower.contains('photo')) return entities.SectionType.photos;
    if (lower.contains('sign')) return entities.SectionType.signature;
    if (lower.contains('note')) return entities.SectionType.notes;
    return entities.SectionType.notes; // Ultimate fallback
  }

  /// Map server answer JSON to local SurveyAnswer entity.
  entities.SurveyAnswer _mapServerAnswer(String id, Map<String, dynamic> data) => entities.SurveyAnswer(
      id: id,
      surveyId: '', // Server answers don't include surveyId directly
      sectionId: data['sectionId'] as String? ?? '',
      fieldKey: data['questionKey'] as String? ?? '',
      value: data['value'] as String?,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );

  /// Parse a date string or date value from server response.
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Retry all failed items (1 attempt per manual retry).
  Future<void> retryFailed() => syncQueueDao.resetFailedItems();

  /// Permanently clear all failed items from the queue.
  Future<int> clearFailed() => syncQueueDao.clearFailedItems();

  /// Get failed items with error details for UI diagnostics.
  Future<List<SyncQueueItem>> getFailedItems() async {
    final rows = await syncQueueDao.getFailedItems();
    return rows.map(syncQueueDao.toSyncQueueItem).toList();
  }

  /// Process only sync queue items belonging to a specific survey.
  ///
  /// Unlike [processQueue] which syncs ALL pending items across ALL surveys,
  /// this method scopes processing to a single survey and its children
  /// (sections, answers).  This is used by the export pipeline to avoid
  /// syncing unrelated surveys during the pre-upload sync step.
  ///
  /// Items are still processed in dependency order: surveys → sections → answers.
  Future<SyncResult> processQueueForSurvey(String surveyId) async {
    AppLogger.d('SyncManager', 'processQueueForSurvey called for $surveyId');
    final isConnected = await checkConnectivity();
    if (!isConnected) {
      return const SyncResult(
        success: false,
        errorMessage: 'No internet connection',
      );
    }

    // Resolve which section IDs belong to this survey so we can
    // identify answer items (answers store sectionId, not surveyId).
    final sections = await sectionsDao.getSectionsForSurvey(surveyId);
    final sectionIds = sections.map((s) => s.id).toSet();

    // Use a generous limit — a single survey with 500 screens can have
    // 1 survey + ~10 sections + ~500 answers ≈ 511 items.
    final pendingItems = await syncQueueDao.getPendingItems(limit: 1000);

    final surveyItems = <SyncQueueItem>[];
    final sectionItems = <SyncQueueItem>[];
    final answerItems = <SyncQueueItem>[];

    for (final data in pendingItems) {
      final item = syncQueueDao.toSyncQueueItem(data);
      switch (item.entityType) {
        case SyncEntityType.survey:
          if (item.entityId == surveyId) surveyItems.add(item);
        case SyncEntityType.section:
          final payload = jsonDecode(item.payload) as Map<String, dynamic>;
          if (payload['surveyId'] == surveyId) sectionItems.add(item);
        case SyncEntityType.answer:
          final payload = jsonDecode(item.payload) as Map<String, dynamic>;
          final sectionId = payload['sectionId'] as String?;
          if (sectionId != null && sectionIds.contains(sectionId)) {
            answerItems.add(item);
          }
        case SyncEntityType.photo:
          break; // Photos handled by MediaUploadService
      }
    }

    final totalFiltered = surveyItems.length + sectionItems.length + answerItems.length;
    AppLogger.d('SyncManager',
      'Scoped sync for $surveyId: ${surveyItems.length} surveys, '
      '${sectionItems.length} sections, ${answerItems.length} answers '
      '(filtered from ${pendingItems.length} total pending)',
    );

    if (totalFiltered == 0) {
      return const SyncResult(success: true, syncedCount: 0);
    }

    // Process in dependency order: surveys → sections → answers
    var syncedCount = 0;
    var failedCount = 0;
    String? lastError;

    for (final item in surveyItems) {
      final result = await _processOneItem(item);
      if (result.success) {
        syncedCount++;
      } else if (result.isAuthFailure) {
        return SyncResult(
          success: false,
          syncedCount: syncedCount,
          failedCount: failedCount + 1,
          errorMessage: 'Session expired',
        );
      } else {
        if (!result.isRetryable) failedCount++;
        lastError = result.error ?? lastError;
      }
    }

    // Only process sections if all survey items succeeded
    if (failedCount == 0) {
      for (final item in sectionItems) {
        final result = await _processOneItem(item);
        if (result.success) {
          syncedCount++;
        } else if (result.isAuthFailure) {
          return SyncResult(
            success: false,
            syncedCount: syncedCount,
            failedCount: failedCount + 1,
            errorMessage: 'Session expired',
          );
        } else {
          if (!result.isRetryable) failedCount++;
          lastError = result.error ?? lastError;
        }
      }
    }

    // Only process answers if all sections succeeded
    if (failedCount == 0) {
      for (final item in answerItems) {
        final result = await _processOneItem(item);
        if (result.success) {
          syncedCount++;
        } else if (result.isAuthFailure) {
          return SyncResult(
            success: false,
            syncedCount: syncedCount,
            failedCount: failedCount + 1,
            errorMessage: 'Session expired',
          );
        } else {
          if (!result.isRetryable) failedCount++;
          lastError = result.error ?? lastError;
        }
      }
    }

    AppLogger.d('SyncManager',
      'Scoped sync complete for $surveyId: synced=$syncedCount, failed=$failedCount',
    );

    return SyncResult(
      success: failedCount == 0,
      syncedCount: syncedCount,
      failedCount: failedCount,
      errorMessage: lastError,
    );
  }

  /// Force re-queue a survey AND ALL ITS CHILDREN for sync.
  ///
  /// ARCH-B1 FIX: Implements "Composite Entity Sync" pattern.
  ///
  /// This is the "Force Dirty" pattern - when we detect a survey doesn't exist
  /// on the server (404), we force it back into the sync queue to be uploaded.
  ///
  /// CRITICAL: This method now fetches ALL child entities (sections, answers,
  /// media) from the local database and queues them for sync. This prevents
  /// data loss where only the survey shell would sync, leaving children orphaned.
  ///
  /// This handles the case where:
  /// - The sync queue item was marked complete but server never received it
  /// - Network issues caused silent failure
  /// - The survey was created offline and never synced
  /// - Partial sync left children unsynced
  Future<void> forceResyncSurvey({
    required String surveyId,
    required Map<String, dynamic>? surveyPayload,
  }) async {
    AppLogger.d('SyncManager', 'Force re-queuing survey $surveyId with ALL children for sync');

    try {
      // ========================================
      // STEP 1: Fetch survey from local database
      // ========================================
      final survey = await surveysDao.getSurveyById(surveyId);
      if (survey == null) {
        AppLogger.w('SyncManager', 'Cannot force resync: Survey $surveyId not found in local database');
        return;
      }

      // Build complete survey payload from local database (authoritative source).
      // CRITICAL: Only include fields declared in backend CreateSurveyDto.
      // Backend uses forbidNonWhitelisted:true — extra fields cause 400 errors.
      // Use toBackendString() for enums (e.g. 'LEVEL_2' not 'level2').
      final fullSurveyPayload = surveyPayload ?? {
        'title': survey.title,
        'propertyAddress': survey.address ?? '',
        'status': survey.status.toBackendString(),
        'type': survey.type.toBackendString(),
        if (survey.jobRef != null) 'jobRef': survey.jobRef,
        if (survey.clientName != null) 'clientName': survey.clientName,
        if (survey.parentSurveyId != null) 'parentSurveyId': survey.parentSurveyId,
      };

      // Queue survey with HIGH priority
      await syncQueueDao.addToQueue(
        entityType: SyncEntityType.survey,
        entityId: surveyId,
        action: SyncAction.create,
        payload: fullSurveyPayload,
        priority: -10, // Highest priority - survey must sync first
      );
      AppLogger.d('SyncManager', 'Queued survey $surveyId for resync');

      // ========================================
      // STEP 2: Fetch and queue ALL sections
      // ========================================
      final sections = await sectionsDao.getSectionsForSurvey(surveyId);
      AppLogger.d('SyncManager', 'Found ${sections.length} sections for survey $surveyId');

      for (final section in sections) {
        // Only include fields declared in backend CreateSectionDto: id, title, order.
        // Extra fields (sectionType, isCompleted, etc.) cause 400 with
        // forbidNonWhitelisted:true.
        // 'surveyId' is needed by _syncSection to build the URL path but is
        // NOT sent in the POST body — it's extracted and used as a URL param.
        // 'id' is the client UUID — _syncSection adds it to the POST body for
        // CREATE actions so the server uses the same ID as the local database.
        final sectionPayload = {
          'surveyId': section.surveyId,
          'title': section.title,
          'order': section.order,
          'sectionTypeKey': section.sectionType.apiSectionType,
        };

        await syncQueueDao.addToQueue(
          entityType: SyncEntityType.section,
          entityId: section.id,
          action: SyncAction.create,
          payload: sectionPayload,
          priority: -5, // High priority - sections sync after survey
        );
      }
      AppLogger.d('SyncManager', 'Queued ${sections.length} sections for resync');

      // ========================================
      // STEP 3: Fetch and queue ALL answers
      // ========================================
      final answers = await answersDao.getAnswersForSurvey(surveyId);
      // Skip answers with empty/null values — backend rejects empty strings
      // with @IsNotEmpty() validation. These are optional unfilled fields.
      final nonEmptyAnswers = answers
          .where((a) => a.value != null && a.value!.trim().isNotEmpty)
          .toList();
      AppLogger.d('SyncManager',
        'Found ${answers.length} answers for survey $surveyId '
        '(${nonEmptyAnswers.length} non-empty, ${answers.length - nonEmptyAnswers.length} skipped)',
      );

      for (final answer in nonEmptyAnswers) {
        // Only include fields declared in backend CreateAnswerDto: questionKey, value.
        // 'sectionId' is needed by _syncAnswer to build the URL path but is
        // NOT sent in the POST body — it's extracted and used as a URL param.
        // Use 'questionKey' (backend field name), not 'fieldKey' (local name).
        final answerPayload = {
          'sectionId': answer.sectionId,
          'questionKey': answer.fieldKey,
          'value': answer.value!,
        };

        await syncQueueDao.addToQueue(
          entityType: SyncEntityType.answer,
          entityId: answer.id,
          action: SyncAction.create,
          payload: answerPayload,
          priority: -3, // Medium-high priority - answers sync after sections
        );
      }
      AppLogger.d('SyncManager', 'Queued ${nonEmptyAnswers.length} answers for resync');

      // ========================================
      // STEP 4: Fetch and queue ALL media
      // ========================================
      final mediaItems = await mediaDao.getMediaBySurvey(surveyId);
      AppLogger.d('SyncManager', 'Found ${mediaItems.length} media items for survey $surveyId');

      for (final media in mediaItems) {
        // Media with local files are handled by MediaUploadService
        // Here we queue the metadata sync
        final mediaPayload = {
          'id': media.id,
          'surveyId': media.surveyId,
          'sectionId': media.sectionId,
          'type': media.mediaType,
          'filePath': media.localPath, // For MediaUploadService
          'caption': media.caption,
          'createdAt': media.createdAt.toIso8601String(),
        };

        await syncQueueDao.addToQueue(
          entityType: SyncEntityType.photo,
          entityId: media.id,
          action: SyncAction.create,
          payload: mediaPayload,
          priority: -1, // Lower priority - media syncs last
        );
      }
      AppLogger.d('SyncManager', 'Queued ${mediaItems.length} media items for resync');

      AppLogger.d(
        'SyncManager',
        'Force resync complete for survey $surveyId: '
        '1 survey, ${sections.length} sections, ${answers.length} answers, ${mediaItems.length} media',
      );
    } catch (e, stackTrace) {
      AppLogger.e('SyncManager', 'Failed to force resync survey $surveyId: $e\n$stackTrace');
      rethrow;
    }
  }
}
