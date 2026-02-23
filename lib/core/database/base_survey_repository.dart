import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';
import '../network/api_client.dart';
import '../../features/property_inspection/domain/models/inspection_models.dart';

/// Shared base class for InspectionRepository and ValuationRepository.
///
/// Both modules use the same JSON tree format, the same Drift tables
/// (inspectionV2Screens / inspectionV2Answers), and identical CRUD logic.
/// The only differences are:
///   - asset path & local override filename
///   - optional ID prefix (valuation uses `val_` to avoid row collisions)
abstract class BaseSurveyRepository {
  BaseSurveyRepository(
    this._db, {
    required String treeAsset,
    required String localOverrideName,
    String idPrefix = '',
    ApiClient? apiClient,
    String? treeType,
    int bundledTreeVersion = 0,
  })  : _treeAsset = treeAsset,
        _localOverrideName = localOverrideName,
        _idPrefix = idPrefix,
        _apiClient = apiClient,
        _treeType = treeType,
        _bundledTreeVersion = bundledTreeVersion;

  final AppDatabase _db;
  final String _treeAsset;
  final String _localOverrideName;
  final String _idPrefix;
  final ApiClient? _apiClient;
  final String? _treeType;
  final int _bundledTreeVersion;

  InspectionTreePayload? _treeCache;
  Map<String, InspectionNodeDefinition>? _nodeCache;

  /// Expose the database to subclasses that need it (e.g. condition ratings).
  AppDatabase get db => _db;

  /// Clear cached tree so next loadTree() re-reads from disk.
  void invalidateCache() {
    _treeCache = null;
    _nodeCache = null;
  }

  Future<InspectionTreePayload> loadTree() async {
    if (_treeCache != null) return _treeCache!;

    final dir = await getApplicationDocumentsDirectory();

    // ─── Bundled asset override ──────────────────────────────────────
    // When bundledTreeVersion > 0, ALWAYS use the bundled asset.
    // This ensures app-shipped tree fixes take effect regardless of
    // what the server or local caches have. To resume OTA updates,
    // set bundledTreeVersion back to 0 after publishing to the server.
    if (_bundledTreeVersion > 0) {
      debugPrint('[BaseSurveyRepo] Using bundled asset (v$_bundledTreeVersion): $_treeAsset');
      final raw = await rootBundle.loadString(_treeAsset);
      _treeCache = InspectionTreePayload.fromJson(raw);
      return _treeCache!;
    }

    // ─── PRIORITY 1: Admin local override (set by admin panel) ─────
    try {
      final adminFile = File('${dir.path}/admin/$_localOverrideName');
      if (await adminFile.exists()) {
        final raw = await adminFile.readAsString();
        _treeCache = InspectionTreePayload.fromJson(raw);
        debugPrint('[BaseSurveyRepo] Loaded from admin override: $_localOverrideName');
        return _treeCache!;
      }
    } catch (e) {
      debugPrint('[BaseSurveyRepo] Admin override failed: $e');
    }

    // ─── PRIORITY 2: API fetch (OTA update) ────────────────────────
    if (_apiClient != null && _treeType != null) {
      try {
        final raw = await _fetchTreeFromApi();
        _treeCache = InspectionTreePayload.fromJson(raw);
        // Write cache in background — don't block the return.
        // ignore: unawaited_futures
        _writeCacheFile(dir, raw);
        debugPrint('[BaseSurveyRepo] Loaded from API (OTA): $_treeType');
        return _treeCache!;
      } catch (e) {
        debugPrint('[BaseSurveyRepo] API fetch failed, trying cache: $e');
      }
    }

    // ─── PRIORITY 3: Cached API response (offline fallback) ────────
    try {
      final cacheFile = File('${dir.path}/cache/ota_$_localOverrideName');
      if (await cacheFile.exists()) {
        final raw = await cacheFile.readAsString();
        _treeCache = InspectionTreePayload.fromJson(raw);
        debugPrint('[BaseSurveyRepo] Loaded from OTA cache: $_localOverrideName');
        return _treeCache!;
      }
    } catch (e) {
      debugPrint('[BaseSurveyRepo] OTA cache failed: $e');
    }

    // ─── PRIORITY 4: Bundled asset (factory default) ───────────────
    debugPrint('[BaseSurveyRepo] Loading from bundled asset: $_treeAsset');
    final raw = await rootBundle.loadString(_treeAsset);
    _treeCache = InspectionTreePayload.fromJson(raw);
    return _treeCache!;
  }


  // ─── OTA Helpers ──────────────────────────────────────────────────

  /// Fetch the latest published V2 tree from the backend API.
  ///
  /// Returns the raw JSON string of the tree payload (the `tree` field
  /// from the `V2TreeLatestResponseDto`).
  Future<String> _fetchTreeFromApi() async {
    final response = await _apiClient!.get<Map<String, dynamic>>(
      'admin/config/v2-tree/latest/$_treeType',
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Empty response from v2-tree API');
    }

    final tree = data['tree'];
    if (tree == null) {
      throw Exception('No "tree" field in v2-tree response');
    }

    return jsonEncode(tree);
  }

  /// Persist the API-fetched tree JSON to a cache file for offline use.
  ///
  /// This is fire-and-forget — cache write failures are non-fatal.
  Future<void> _writeCacheFile(Directory dir, String content) async {
    try {
      final cacheFile = File('${dir.path}/cache/ota_$_localOverrideName');
      await cacheFile.parent.create(recursive: true);
      await cacheFile.writeAsString(content);
    } catch (e) {
      debugPrint('[BaseSurveyRepo] Failed to write OTA cache: $e');
    }
  }

  Future<Map<String, InspectionNodeDefinition>> loadNodeMap() async {
    if (_nodeCache != null) return _nodeCache!;
    final tree = await loadTree();
    final map = <String, InspectionNodeDefinition>{};
    for (final section in tree.sections) {
      for (final node in section.nodes) {
        map[node.id] = node;
      }
    }
    _nodeCache = map;
    return map;
  }

  Future<List<InspectionSectionDefinition>> getSections() async {
    final tree = await loadTree();
    return tree.sections;
  }

  /// Ensures the V2 screen metadata rows exist for [surveyId].
  ///
  /// Returns `true` if initialization was performed (first time for this
  /// survey), `false` if the rows already existed.  Callers can use this
  /// to decide whether V2 sections need to be queued for sync.
  Future<bool> ensureSurveyInitialized(String surveyId) async {
    final tree = await loadTree();
    final expectedCount =
        tree.sections.fold<int>(0, (sum, section) => sum + section.nodes.length);

    final existingRows = await (_db.select(_db.inspectionV2Screens)
          ..where((tbl) => tbl.surveyId.equals(surveyId)))
        .get();
    if (existingRows.isNotEmpty && existingRows.length == expectedCount) {
      return false;
    }
    final now = DateTime.now();
    final entries = <InspectionV2ScreensCompanion>[];
    for (final section in tree.sections) {
      for (var i = 0; i < section.nodes.length; i += 1) {
        final node = section.nodes[i];
        entries.add(InspectionV2ScreensCompanion.insert(
          id: '${surveyId}_$_idPrefix${node.id}',
          surveyId: surveyId,
          sectionKey: section.key,
          screenId: node.id,
          title: node.title,
          groupKey: const Value(null),
          nodeType: Value(node.type.name),
          parentId: Value(node.parentId),
          displayOrder: i,
          createdAt: now,
        ));
      }
    }

    await _db.transaction(() async {
      if (existingRows.isNotEmpty) {
        await (_db.delete(_db.inspectionV2Screens)
              ..where((tbl) => tbl.surveyId.equals(surveyId)))
            .go();
      }
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.inspectionV2Screens, entries);
      });
    });

    final totalScreens = entries.where((e) => e.nodeType.value == 'screen').length;
    await updateSurveyProgress(surveyId, totalOverride: totalScreens);

    return true;
  }

  Future<List<InspectionV2Screen>> getNodesForSection(
    String surveyId,
    String sectionKey,
  ) async {
    final query = _db.select(_db.inspectionV2Screens)
      ..where((tbl) => tbl.surveyId.equals(surveyId) & tbl.sectionKey.equals(sectionKey))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.displayOrder)]);
    return query.get();
  }

  Future<List<InspectionNodeDefinition>> getChildScreens(
    String parentId,
  ) async {
    final tree = await loadTree();
    final screens = <InspectionNodeDefinition>[];
    for (final section in tree.sections) {
      for (final node in section.nodes) {
        if (node.type == InspectionNodeType.screen && node.parentId == parentId) {
          screens.add(node);
        }
      }
    }
    return screens;
  }

  Future<InspectionV2Screen?> getScreen(
    String surveyId,
    String screenId,
  ) async {
    return (_db.select(_db.inspectionV2Screens)
          ..where((tbl) => tbl.surveyId.equals(surveyId) & tbl.screenId.equals(screenId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<InspectionNodeDefinition?> getNodeDefinition(String nodeId) async {
    final map = await loadNodeMap();
    return map[nodeId];
  }

  Future<Map<String, Map<String, String>>> getAllAnswersForSurvey(
    String surveyId,
  ) async {
    final rows = await (_db.select(_db.inspectionV2Answers)
          ..where((tbl) => tbl.surveyId.equals(surveyId)))
        .get();
    final result = <String, Map<String, String>>{};
    for (final row in rows) {
      result.putIfAbsent(row.screenId, () => {})[row.fieldKey] = row.value ?? '';
    }
    return result;
  }

  Future<List<InspectionV2Screen>> getAllScreensForSurvey(
    String surveyId,
  ) async {
    return (_db.select(_db.inspectionV2Screens)
          ..where((tbl) => tbl.surveyId.equals(surveyId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.displayOrder)]))
        .get();
  }

  Future<Map<String, String>> getScreenAnswersMap(
    String surveyId,
    String screenId,
  ) async {
    final rows = await (_db.select(_db.inspectionV2Answers)
          ..where((tbl) => tbl.surveyId.equals(surveyId) & tbl.screenId.equals(screenId)))
        .get();
    return {
      for (final row in rows) row.fieldKey: row.value ?? '',
    };
  }

  Future<void> saveScreenAnswers({
    required String surveyId,
    required String screenId,
    required Map<String, String> answers,
  }) async {
    final now = DateTime.now();

    final rows = answers.entries.map((entry) {
      return InspectionV2AnswersCompanion.insert(
        id: '${surveyId}_$_idPrefix${screenId}_${entry.key}',
        surveyId: surveyId,
        screenId: screenId,
        fieldKey: entry.key,
        value: Value(entry.value),
        createdAt: now,
        updatedAt: Value(now),
      );
    }).toList();

    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.inspectionV2Answers, rows);
    });
  }

  Future<void> setScreenCompleted({
    required String surveyId,
    required String screenId,
    required bool isCompleted,
  }) async {
    await (_db.update(_db.inspectionV2Screens)
          ..where((tbl) => tbl.surveyId.equals(surveyId) & tbl.screenId.equals(screenId)))
        .write(
      InspectionV2ScreensCompanion(
        isCompleted: Value(isCompleted),
        updatedAt: Value(DateTime.now()),
      ),
    );

    await updateSurveyProgress(surveyId);
  }

  Future<void> updateSurveyProgress(String surveyId, {int? totalOverride}) async {
    final screens = await (_db.select(_db.inspectionV2Screens)
          ..where((tbl) => tbl.surveyId.equals(surveyId)))
        .get();

    final screenRows = screens.where((s) => s.nodeType == 'screen');
    final total = totalOverride ?? screenRows.length;
    final completed = screenRows.where((s) => s.isCompleted).length;
    final progress = total == 0 ? 0.0 : completed / total;

    await (_db.update(_db.surveys)..where((tbl) => tbl.id.equals(surveyId))).write(
      SurveysCompanion(
        totalSections: Value(total),
        completedSections: Value(completed),
        progress: Value(progress),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ─── Phrase Output ─────────────────────────────────────────────

  /// Persist JSON-encoded phrase engine output for a single screen.
  Future<void> savePhraseOutput({
    required String surveyId,
    required String screenId,
    required String phraseJson,
  }) async {
    await (_db.update(_db.inspectionV2Screens)
          ..where((tbl) => tbl.surveyId.equals(surveyId) & tbl.screenId.equals(screenId)))
        .write(
      InspectionV2ScreensCompanion(
        phraseOutput: Value(phraseJson),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Returns the aggregated phrase output for all screens in a section.
  ///
  /// Result is a JSON map: `{ screenId: [phrase1, phrase2, ...] }`.
  /// Screens with no phrases are omitted.
  Future<String> getAggregatedPhraseOutput(
    String surveyId,
    String sectionKey,
  ) async {
    final screens = await getNodesForSection(surveyId, sectionKey);
    final map = <String, dynamic>{};
    for (final screen in screens) {
      if (screen.phraseOutput != null && screen.phraseOutput!.isNotEmpty) {
        map[screen.screenId] = jsonDecode(screen.phraseOutput!);
      }
    }
    return jsonEncode(map);
  }

  // ─── User Notes ──────────────────────────────────────────────────

  /// Persist a surveyor's custom note for a single screen.
  Future<void> saveUserNote({
    required String surveyId,
    required String screenId,
    required String note,
  }) async {
    await (_db.update(_db.inspectionV2Screens)
          ..where((tbl) => tbl.surveyId.equals(surveyId) & tbl.screenId.equals(screenId)))
        .write(
      InspectionV2ScreensCompanion(
        userNote: Value(note),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Returns the aggregated user notes for all screens in a section.
  ///
  /// Result is a JSON map: `{ screenId: "note text" }`.
  /// Screens with no notes are omitted.
  Future<String> getAggregatedUserNotes(
    String surveyId,
    String sectionKey,
  ) async {
    final screens = await getNodesForSection(surveyId, sectionKey);
    final map = <String, dynamic>{};
    for (final screen in screens) {
      if (screen.userNote != null && screen.userNote!.isNotEmpty) {
        map[screen.screenId] = screen.userNote;
      }
    }
    return jsonEncode(map);
  }

  // ─── Sync Helpers ────────────────────────────────────────────────

  /// Returns the sectionKey for a given screen in a survey.
  ///
  /// Used by notifiers to map screenId → sectionKey → deterministic
  /// section UUID for answer sync payloads.
  Future<String?> getSectionKeyForScreen(
    String surveyId,
    String screenId,
  ) async {
    final screen = await getScreen(surveyId, screenId);
    return screen?.sectionKey;
  }

  /// Returns V2 section metadata from the tree definition.
  ///
  /// Each entry contains the section key, title, and display order.
  /// Used by notifiers to queue section CREATE operations for sync.
  Future<List<({String key, String title, int order})>>
      getV2SectionMeta() async {
    final tree = await loadTree();
    return tree.sections
        .asMap()
        .entries
        .map(
          (entry) => (
            key: entry.value.key,
            title: entry.value.title,
            order: entry.key,
          ),
        )
        .toList();
  }
}
