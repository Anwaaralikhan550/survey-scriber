import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/property_inspection/domain/models/inspection_models.dart';
import '../network/api_client.dart';

/// Where the last tree received from the server is kept.
abstract class TreeStore {
  Future<String?> read(String name);
  Future<void> write(String name, String content);
  Future<void> delete(String name);
}

class _FileTreeStore implements TreeStore {
  Future<File> _file(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/cache/$name');
  }

  @override
  Future<String?> read(String name) async {
    final file = await _file(name);
    return await file.exists() ? file.readAsString() : null;
  }

  @override
  Future<void> write(String name, String content) async {
    final file = await _file(name);
    await file.parent.create(recursive: true);
    await file.writeAsString(content, flush: true);
  }

  @override
  Future<void> delete(String name) async {
    final file = await _file(name);
    if (await file.exists()) await file.delete();
  }
}

/// The browser build has no documents folder.
class _PrefsTreeStore implements TreeStore {
  @override
  Future<String?> read(String name) async =>
      (await SharedPreferences.getInstance()).getString('tree_cache_$name');

  @override
  Future<void> write(String name, String content) async {
    await (await SharedPreferences.getInstance()).setString('tree_cache_$name', content);
  }

  @override
  Future<void> delete(String name) async {
    await (await SharedPreferences.getInstance()).remove('tree_cache_$name');
  }
}

/// Live survey tree edits: the server holds the latest published tree; phones
/// keep a copy for offline use and re-check on start and resume.
///
/// A published tree says which built-in tree it was made from
/// (`baseBundledVersion`). The app uses it only when that is its own built-in
/// tree, so an old publish can never replace a newer tree shipped in an update.
/// Anything wrong with the copy means the built-in tree is used.
class TreeSync {
  TreeSync({ApiClient? apiClient, TreeStore? store})
      : _api = apiClient,
        _store = store ?? (kIsWeb ? _PrefsTreeStore() : _FileTreeStore());

  final ApiClient? _api;
  final TreeStore _store;

  String _treeFile(String type) => 'tree_$type.json';
  String _checksumFile(String type) => 'tree_$type.sha';

  /// The tree, when [raw] is complete and belongs to this app's built-in tree.
  static InspectionTreePayload? parseUsable(String raw, int bundledVersion) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['baseBundledVersion'] != bundledVersion) return null;
      final tree = InspectionTreePayload.fromJson(raw);
      if (tree.sections.any((s) => s.key.isEmpty)) return null;
      if (tree.sections.every((s) => s.nodes.isEmpty)) return null;
      return tree;
    } catch (e) {
      debugPrint('[TreeSync] unusable tree: $e');
      return null;
    }
  }

  /// The published tree this app can use, or null for the built-in one.
  /// Never throws: reading a survey must not depend on this file.
  Future<InspectionTreePayload?> readUsable(String type, int bundledVersion) async {
    try {
      final raw = await _store.read(_treeFile(type));
      return raw == null ? null : parseUsable(raw, bundledVersion);
    } catch (e) {
      debugPrint('[TreeSync] cache read failed: $e');
      return null;
    }
  }

  /// Raw JSON of the published copy this app can use, for the mobile tree editor.
  Future<String?> readUsableRaw(String type, int bundledVersion) async {
    try {
      final raw = await _store.read(_treeFile(type));
      if (raw == null) return null;
      return parseUsable(raw, bundledVersion) == null ? null : raw;
    } catch (_) {
      return null;
    }
  }

  /// Asks the server for a newer tree. Returns true when the copy on this phone
  /// changed. Never throws: offline or server trouble keeps the current tree.
  Future<bool> refresh(String type, int bundledVersion) async {
    final api = _api;
    if (api == null) return false;
    try {
      final known = await _store.read(_checksumFile(type));
      final response = await api.get<Map<String, dynamic>>(
        'config/v2-tree/$type',
        queryParameters: {if (known != null) 'known': known.trim()},
      );
      final data = response.data;
      if (data == null || data['unchanged'] == true) return false;
      final tree = data['tree'];
      final checksum = data['checksum'];
      if (tree is! Map || checksum is! String) return false;
      final raw = jsonEncode(tree);
      if (parseUsable(raw, bundledVersion) == null) {
        debugPrint('[TreeSync] $type v${data['version']} is not for this app; ignored');
        return false;
      }
      await store(type, raw, checksum);
      debugPrint('[TreeSync] $type updated to v${data['version']}');
      return true;
    } catch (e) {
      // 404 = nothing published yet; anything else = offline. Both are fine.
      debugPrint('[TreeSync] refresh $type skipped: $e');
      return false;
    }
  }

  /// Tree first, checksum last: a crash in between just causes one re-download.
  Future<void> store(String type, String raw, String checksum) async {
    await _store.write(_treeFile(type), raw);
    await _store.write(_checksumFile(type), checksum);
  }

  /// The version on the server now, 0 when nothing is published, null when it
  /// cannot be reached. Downloads no tree.
  Future<int?> serverVersion(String type) async {
    final api = _api;
    if (api == null) return null;
    try {
      final response = await api.get<Map<String, dynamic>>(
        'config/v2-tree/$type/version',
      );
      return (response.data?['version'] as num?)?.toInt();
    } catch (e) {
      debugPrint('[TreeSync] version check failed: $e');
      return null;
    }
  }
}

final treeSyncProvider = Provider<TreeSync>(
  (ref) => TreeSync(apiClient: ref.watch(apiClientProvider)),
);
