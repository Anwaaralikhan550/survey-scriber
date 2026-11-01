import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

/// Web: sqlite3 compiled to WASM, persisted in the browser.
///
/// Drift's default choice is the shared-worker storage. Some embedded
/// browsers block `fetch()` inside shared workers (the WASM load fails with
/// "Failed to fetch"), so storages backed by a dedicated worker come first.
QueryExecutor openAppConnection() {
  return DatabaseConnection.delayed(Future(() async {
    final probe = await WasmDatabase.probe(
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
      databaseName: 'survey_scriber',
    );
    const preferred = [
      WasmStorageImplementation.opfsLocks,
      WasmStorageImplementation.unsafeIndexedDb,
      WasmStorageImplementation.opfsShared,
      WasmStorageImplementation.sharedIndexedDb,
      WasmStorageImplementation.inMemory,
    ];
    final storage = preferred.firstWhere(probe.availableStorages.contains);
    debugPrint('[AppDatabase] web storage: $storage '
        '(available: ${probe.availableStorages}, missing: ${probe.missingFeatures})');
    return probe.open(storage, 'survey_scriber');
  }));
}
