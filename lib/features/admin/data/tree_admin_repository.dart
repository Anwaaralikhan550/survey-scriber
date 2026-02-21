import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/network/api_client.dart';
import '../../property_inspection/domain/models/inspection_models.dart';

/// Identifies which survey tree to operate on.
enum SurveyTreeType {
  inspection('inspection_v2', 'assets/property_inspection/inspection_tree.json'),
  valuation('valuation_v2', 'assets/property_valuation/valuation_tree.json');

  const SurveyTreeType(this.key, this.assetPath);
  final String key;
  final String assetPath;

  String get displayName => switch (this) {
        SurveyTreeType.inspection => 'Inspection',
        SurveyTreeType.valuation => 'Valuation',
      };
}

/// Result of a tree validation check.
class TreeValidationResult {
  const TreeValidationResult({
    this.errors = const [],
    this.warnings = const [],
  });

  final List<String> errors;
  final List<String> warnings;

  bool get isValid => errors.isEmpty;
}

/// Repository for admin management of survey trees.
///
/// Reads trees from bundled assets, writes edited copies to app documents.
/// The runtime repositories (InspectionRepository, ValuationRepository)
/// should call [loadTreeRaw] to check for local overrides before falling back
/// to the bundled asset.
class TreeAdminRepository {
  TreeAdminRepository({ApiClient? apiClient}) : _apiClient = apiClient;

  final ApiClient? _apiClient;
  final Map<SurveyTreeType, InspectionTreePayload> _cache = {};
  Directory? _docsDir;

  Future<Directory> get _documentsDir async {
    _docsDir ??= await getApplicationDocumentsDirectory();
    return _docsDir!;
  }

  String _treeFileName(SurveyTreeType type) => '${type.key}_tree.json';

  String _phraseTextsFileName() => 'inspection_v2_phrase_texts.json';

  Future<File> _treeFile(SurveyTreeType type) async {
    final dir = await _documentsDir;
    return File('${dir.path}/admin/${_treeFileName(type)}');
  }

  Future<File> _phraseTextsFile() async {
    final dir = await _documentsDir;
    return File('${dir.path}/admin/${_phraseTextsFileName()}');
  }

  Future<File> _backupFile(SurveyTreeType type) async {
    final dir = await _documentsDir;
    final ts = DateTime.now().millisecondsSinceEpoch;
    return File('${dir.path}/admin/backups/${type.key}_$ts.json');
  }

  // ─── Tree Loading ───────────────────────────────────────────────

  /// Returns the raw JSON string for a tree.
  /// Checks for a local override in documents first, then falls back to asset.
  Future<String> loadTreeRaw(SurveyTreeType type) async {
    final local = await _treeFile(type);
    if (await local.exists()) {
      return local.readAsString();
    }
    return rootBundle.loadString(type.assetPath);
  }

  /// Returns a parsed tree payload.
  Future<InspectionTreePayload> loadTree(SurveyTreeType type) async {
    if (_cache.containsKey(type)) return _cache[type]!;
    final raw = await loadTreeRaw(type);
    final tree = InspectionTreePayload.fromJson(raw);
    _cache[type] = tree;
    return tree;
  }

  /// Whether a local override exists for this tree type.
  Future<bool> hasLocalOverride(SurveyTreeType type) async {
    final local = await _treeFile(type);
    return local.exists();
  }

  // ─── Tree Saving ────────────────────────────────────────────────

  /// Save a modified tree, creating a backup of the previous version first.
  Future<void> saveTree(
    SurveyTreeType type,
    InspectionTreePayload tree,
  ) async {
    // Validate before saving
    final validation = validateTree(tree);
    if (!validation.isValid) {
      throw ArgumentError(
        'Tree validation failed:\n${validation.errors.join('\n')}',
      );
    }

    // Backup current version if it exists
    final local = await _treeFile(type);
    if (await local.exists()) {
      await _createBackup(type, await local.readAsString());
    }

    // Ensure directory exists
    await local.parent.create(recursive: true);

    // Write new version
    await local.writeAsString(tree.toJsonString());

    // Invalidate caches
    _cache.remove(type);
  }

  /// Reset to the bundled asset version (remove local override).
  Future<void> resetToAsset(SurveyTreeType type) async {
    final local = await _treeFile(type);
    if (await local.exists()) {
      // Backup before reset
      await _createBackup(type, await local.readAsString());
      await local.delete();
    }
    _cache.remove(type);
  }

  // ─── Backup / Restore ──────────────────────────────────────────

  Future<void> _createBackup(SurveyTreeType type, String content) async {
    final backup = await _backupFile(type);
    await backup.parent.create(recursive: true);
    await backup.writeAsString(content);
  }

  /// List all backup files for a tree type, newest first.
  Future<List<File>> listBackups(SurveyTreeType type) async {
    final dir = await _documentsDir;
    final backupsDir = Directory('${dir.path}/admin/backups');
    if (!await backupsDir.exists()) return [];

    final files = await backupsDir
        .list()
        .where((f) => f is File && f.path.contains(type.key))
        .cast<File>()
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  /// Restore from a specific backup file.
  Future<void> restoreFromBackup(SurveyTreeType type, File backup) async {
    final content = await backup.readAsString();
    // Validate the backup content
    final tree = InspectionTreePayload.fromJson(content);
    final validation = validateTree(tree);
    if (!validation.isValid) {
      throw ArgumentError(
        'Backup validation failed:\n${validation.errors.join('\n')}',
      );
    }

    final local = await _treeFile(type);
    await local.parent.create(recursive: true);
    await local.writeAsString(content);
    _cache.remove(type);
  }

  // ─── Phrase Texts Management ────────────────────────────────────

  /// Load phrase texts (from local override or asset).
  Future<Map<String, String>> loadPhraseTexts() async {
    String raw;
    final local = await _phraseTextsFile();
    if (await local.exists()) {
      raw = await local.readAsString();
    } else {
      raw = await rootBundle.loadString(
        'assets/property_inspection/phrase_texts.json',
      );
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v?.toString() ?? ''));
  }

  /// Save phrase texts with backup.
  Future<void> savePhraseTexts(Map<String, String> texts) async {
    final local = await _phraseTextsFile();

    // Backup if exists
    if (await local.exists()) {
      final dir = await _documentsDir;
      final ts = DateTime.now().millisecondsSinceEpoch;
      final backup =
          File('${dir.path}/admin/backups/phrase_texts_$ts.json');
      await backup.parent.create(recursive: true);
      await backup.writeAsString(await local.readAsString());
    }

    await local.parent.create(recursive: true);
    final json = const JsonEncoder.withIndent('  ').convert(texts);
    await local.writeAsString(json);
  }

  /// Update a single phrase template.
  Future<void> updatePhraseTemplate(String key, String value) async {
    final texts = await loadPhraseTexts();
    texts[key] = value;
    await savePhraseTexts(texts);
  }

  /// Delete a phrase template.
  Future<void> deletePhraseTemplate(String key) async {
    final texts = await loadPhraseTexts();
    texts.remove(key);
    await savePhraseTexts(texts);
  }

  // ─── Field Operations ──────────────────────────────────────────

  /// Update a field's label.
  Future<void> updateFieldLabel(
    SurveyTreeType type,
    String screenId,
    String fieldId,
    String newLabel,
  ) async {
    final tree = await loadTree(type);
    final updated = _mapTreeFields(tree, screenId, (field) {
      if (field.id == fieldId) {
        return field.copyWith(label: newLabel);
      }
      return field;
    });
    await saveTree(type, updated);
  }

  /// Update dropdown options for a field.
  Future<void> updateDropdownOptions(
    SurveyTreeType type,
    String screenId,
    String fieldId,
    List<String> options,
  ) async {
    final tree = await loadTree(type);
    final updated = _mapTreeFields(tree, screenId, (field) {
      if (field.id == fieldId) {
        return field.copyWith(options: options);
      }
      return field;
    });
    await saveTree(type, updated);
  }

  /// Update the phrase template for a field.
  Future<void> updateFieldPhraseTemplate(
    SurveyTreeType type,
    String screenId,
    String fieldId,
    String? phraseTemplate,
  ) async {
    final tree = await loadTree(type);
    final updated = _mapTreeFields(tree, screenId, (field) {
      if (field.id == fieldId) {
        return InspectionFieldDefinition(
          id: field.id,
          label: field.label,
          type: field.type,
          options: field.options,
          conditionalOn: field.conditionalOn,
          conditionalValue: field.conditionalValue,
          conditionalMode: field.conditionalMode,
          phraseTemplate: phraseTemplate,
        );
      }
      return field;
    });
    await saveTree(type, updated);
  }

  /// Update conditional visibility rule for a field.
  Future<void> updateConditionalRule(
    SurveyTreeType type,
    String screenId,
    String fieldId, {
    String? conditionalOn,
    String? conditionalValue,
    String? conditionalMode,
  }) async {
    final tree = await loadTree(type);
    final updated = _mapTreeFields(tree, screenId, (field) {
      if (field.id == fieldId) {
        return InspectionFieldDefinition(
          id: field.id,
          label: field.label,
          type: field.type,
          options: field.options,
          conditionalOn: conditionalOn,
          conditionalValue: conditionalValue,
          conditionalMode: conditionalMode,
        );
      }
      return field;
    });
    await saveTree(type, updated);
  }

  /// Reorder fields within a screen.
  Future<void> reorderFields(
    SurveyTreeType type,
    String screenId,
    List<String> fieldIds,
  ) async {
    final tree = await loadTree(type);
    final updated = _mapTreeNodes(tree, (node) {
      if (node.id != screenId) return node;
      final fieldMap = {for (final f in node.fields) f.id: f};
      final reordered = <InspectionFieldDefinition>[];
      for (final fid in fieldIds) {
        final f = fieldMap.remove(fid);
        if (f != null) reordered.add(f);
      }
      // Append any fields not in the reorder list (safety)
      reordered.addAll(fieldMap.values);
      return node.copyWith(fields: reordered);
    });
    await saveTree(type, updated);
  }

  /// Add a new field to a screen.
  Future<void> addField(
    SurveyTreeType type,
    String screenId,
    InspectionFieldDefinition field,
  ) async {
    final tree = await loadTree(type);
    final updated = _mapTreeNodes(tree, (node) {
      if (node.id != screenId) return node;
      return node.copyWith(fields: [...node.fields, field]);
    });
    await saveTree(type, updated);
  }

  /// Remove a field from a screen.
  Future<void> removeField(
    SurveyTreeType type,
    String screenId,
    String fieldId,
  ) async {
    final tree = await loadTree(type);
    final updated = _mapTreeNodes(tree, (node) {
      if (node.id != screenId) return node;
      return node.copyWith(
        fields: node.fields.where((f) => f.id != fieldId).toList(),
      );
    });
    await saveTree(type, updated);
  }

  // ─── Node Operations (Add Screen/Group/Remove) ────────────────

  /// Generate a unique node ID that doesn't collide with any existing node.
  String generateUniqueNodeId(
    InspectionTreePayload tree,
    InspectionNodeType nodeType,
    String hint,
  ) {
    final allIds = <String>{};
    for (final section in tree.sections) {
      for (final node in section.nodes) {
        allIds.add(node.id);
      }
    }

    final prefix = nodeType == InspectionNodeType.group ? 'group_' : 'activity_';
    final base = '$prefix${hint.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_').replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '')}';

    if (!allIds.contains(base)) return base;

    for (var i = 2; i < 9999; i++) {
      final candidate = '${base}_$i';
      if (!allIds.contains(candidate)) return candidate;
    }
    return '${base}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Generate a unique field ID within a screen.
  String generateUniqueFieldId(
    InspectionTreePayload tree,
    String screenId,
    InspectionFieldType fieldType,
    String hint,
  ) {
    final screenFieldIds = <String>{};
    for (final section in tree.sections) {
      for (final node in section.nodes) {
        if (node.id == screenId) {
          for (final f in node.fields) {
            screenFieldIds.add(f.id);
          }
        }
      }
    }

    final typePrefix = switch (fieldType) {
      InspectionFieldType.checkbox => 'cb_',
      InspectionFieldType.dropdown => 'android_material_design_spinner_',
      InspectionFieldType.text => 'edittext_',
      InspectionFieldType.number => 'number_',
      InspectionFieldType.label => 'label_',
    };
    final base = '$typePrefix${hint.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_').replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '')}';

    if (!screenFieldIds.contains(base)) return base;

    for (var i = 2; i < 9999; i++) {
      final candidate = '${base}_$i';
      if (!screenFieldIds.contains(candidate)) return candidate;
    }
    return '${base}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Add a new screen node to a section.
  Future<void> addScreen(
    SurveyTreeType type,
    String sectionKey,
    String title, {
    String? parentId,
    List<InspectionFieldDefinition> fields = const [],
  }) async {
    final tree = await loadTree(type);
    final nodeId = generateUniqueNodeId(tree, InspectionNodeType.screen, title);
    final newNode = InspectionNodeDefinition(
      id: nodeId,
      title: title,
      fields: fields,
      type: InspectionNodeType.screen,
      parentId: parentId,
    );
    final updated = InspectionTreePayload(
      sections: tree.sections.map((s) {
        if (s.key != sectionKey) return s;
        return InspectionSectionDefinition(
          key: s.key,
          title: s.title,
          description: s.description,
          nodes: [...s.nodes, newNode],
        );
      }).toList(),
    );
    await saveTree(type, updated);
  }

  /// Add a new group node to a section.
  Future<void> addGroup(
    SurveyTreeType type,
    String sectionKey,
    String title, {
    String? parentId,
  }) async {
    final tree = await loadTree(type);
    final nodeId = generateUniqueNodeId(tree, InspectionNodeType.group, title);
    final newNode = InspectionNodeDefinition(
      id: nodeId,
      title: title,
      fields: const [],
      type: InspectionNodeType.group,
      parentId: parentId,
    );
    final updated = InspectionTreePayload(
      sections: tree.sections.map((s) {
        if (s.key != sectionKey) return s;
        return InspectionSectionDefinition(
          key: s.key,
          title: s.title,
          description: s.description,
          nodes: [...s.nodes, newNode],
        );
      }).toList(),
    );
    await saveTree(type, updated);
  }

  /// Remove a node (screen or group) from a section.
  /// Also removes all child nodes that reference this node as parentId.
  Future<void> removeNode(
    SurveyTreeType type,
    String sectionKey,
    String nodeId,
  ) async {
    final tree = await loadTree(type);
    // Collect the node and all its descendants
    final toRemove = <String>{nodeId};
    bool changed = true;
    while (changed) {
      changed = false;
      for (final section in tree.sections) {
        for (final node in section.nodes) {
          if (!toRemove.contains(node.id) &&
              node.parentId != null &&
              toRemove.contains(node.parentId)) {
            toRemove.add(node.id);
            changed = true;
          }
        }
      }
    }

    final updated = InspectionTreePayload(
      sections: tree.sections.map((s) {
        if (s.key != sectionKey) return s;
        return InspectionSectionDefinition(
          key: s.key,
          title: s.title,
          description: s.description,
          nodes: s.nodes.where((n) => !toRemove.contains(n.id)).toList(),
        );
      }).toList(),
    );
    await saveTree(type, updated);
  }

  // ─── Screen Operations ─────────────────────────────────────────

  /// Update a screen's title.
  Future<void> updateScreenTitle(
    SurveyTreeType type,
    String screenId,
    String newTitle,
  ) async {
    final tree = await loadTree(type);
    final updated = _mapTreeNodes(tree, (node) {
      if (node.id != screenId) return node;
      return node.copyWith(title: newTitle);
    });
    await saveTree(type, updated);
  }

  // ─── Section Operations ────────────────────────────────────────

  /// Reorder sections in the tree.
  Future<void> reorderSections(
    SurveyTreeType type,
    List<String> sectionKeys,
  ) async {
    final tree = await loadTree(type);
    final sectionMap = {for (final s in tree.sections) s.key: s};
    final reordered = <InspectionSectionDefinition>[];
    for (final key in sectionKeys) {
      final s = sectionMap.remove(key);
      if (s != null) reordered.add(s);
    }
    reordered.addAll(sectionMap.values);
    await saveTree(type, InspectionTreePayload(sections: reordered));
  }

  // ─── Validation ────────────────────────────────────────────────

  /// Validate a tree for structural integrity.
  TreeValidationResult validateTree(InspectionTreePayload tree) {
    final errors = <String>[];
    final warnings = <String>[];
    final allNodeIds = <String>{};
    final allFieldIds = <String, Set<String>>{};

    for (final section in tree.sections) {
      if (section.key.isEmpty) {
        errors.add('Section has empty key');
      }

      for (final node in section.nodes) {
        if (node.id.isEmpty) {
          errors.add('Node in section ${section.key} has empty ID');
          continue;
        }
        if (allNodeIds.contains(node.id)) {
          errors.add('Duplicate node ID: ${node.id}');
        }
        allNodeIds.add(node.id);

        // Check parent references
        if (node.parentId != null && node.parentId!.isNotEmpty) {
          final parentExists = tree.sections.any(
            (s) => s.nodes.any((n) => n.id == node.parentId),
          );
          if (!parentExists) {
            warnings.add(
              'Node ${node.id} references non-existent parent: ${node.parentId}',
            );
          }
        }

        // Check field IDs within screen
        final screenFieldIds = <String>{};
        for (final field in node.fields) {
          if (field.id.isEmpty) {
            errors.add('Field in screen ${node.id} has empty ID');
            continue;
          }
          if (screenFieldIds.contains(field.id)) {
            errors.add(
              'Duplicate field ID in screen ${node.id}: ${field.id}',
            );
          }
          screenFieldIds.add(field.id);

          // Check conditional references
          if (field.conditionalOn != null &&
              field.conditionalOn!.isNotEmpty &&
              !field.conditionalOn!.contains('&') &&
              !field.conditionalOn!.contains('|') &&
              !field.conditionalOn!.contains('=') &&
              !field.conditionalOn!.startsWith('!')) {
            if (!screenFieldIds.contains(field.conditionalOn) &&
                !node.fields.any((f) => f.id == field.conditionalOn)) {
              warnings.add(
                'Field ${field.id} in ${node.id} references unknown conditionalOn: ${field.conditionalOn}',
              );
            }
          }

          // Check dropdown has options (backend rejects empty options)
          if (field.type == InspectionFieldType.dropdown &&
              (field.options == null || field.options!.isEmpty)) {
            errors.add(
              'Dropdown field "${field.id}" in screen "${node.id}" has no options',
            );
          }
        }
        allFieldIds[node.id] = screenFieldIds;
      }
    }

    return TreeValidationResult(errors: errors, warnings: warnings);
  }

  // ─── Stats ─────────────────────────────────────────────────────

  /// Get summary statistics for a tree.
  Future<Map<String, dynamic>> getTreeStats(SurveyTreeType type) async {
    final tree = await loadTree(type);
    var groups = 0;
    var screens = 0;
    var fields = 0;
    final fieldTypes = <String, int>{};
    var dropdowns = 0;
    var conditionals = 0;

    for (final section in tree.sections) {
      for (final node in section.nodes) {
        if (node.type == InspectionNodeType.group) {
          groups++;
        } else {
          screens++;
        }
        for (final field in node.fields) {
          fields++;
          fieldTypes[field.type.name] =
              (fieldTypes[field.type.name] ?? 0) + 1;
          if (field.type == InspectionFieldType.dropdown) dropdowns++;
          if (field.conditionalOn != null) conditionals++;
        }
      }
    }

    return {
      'sections': tree.sections.length,
      'groups': groups,
      'screens': screens,
      'fields': fields,
      'fieldTypes': fieldTypes,
      'dropdowns': dropdowns,
      'conditionals': conditionals,
      'hasLocalOverride': await hasLocalOverride(type),
    };
  }

  // ─── Publish to Server ─────────────────────────────────────────

  /// Publish the local tree override to the remote server.
  ///
  /// Safety layers:
  /// 1. Checks that a local override exists (nothing to publish otherwise).
  /// 2. Validates the JSON structure before sending.
  /// 3. Posts to the backend via the injected [ApiClient].
  ///
  /// Throws [StateError] if no ApiClient is available.
  /// Throws [ArgumentError] if local file is missing or validation fails.
  /// Network/server errors propagate as [ServerException], [NetworkException], etc.
  Future<void> publishTree(SurveyTreeType type) async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      throw StateError(
        'ApiClient not available. Ensure you are logged in.',
      );
    }

    // 1. Check local override exists
    final local = await _treeFile(type);
    if (!await local.exists()) {
      throw ArgumentError(
        'No local changes to publish for ${type.displayName}. '
        'Make edits first before publishing.',
      );
    }

    // 2. Load and validate the raw JSON
    final rawJson = await local.readAsString();
    if (rawJson.trim().isEmpty) {
      throw ArgumentError('Local file is empty. Cannot publish an empty tree.');
    }

    // Parse to verify it's valid JSON
    final Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(rawJson) as Map<String, dynamic>;
    } catch (e) {
      throw ArgumentError(
        'Local file contains invalid JSON. Please reset and try again.\n$e',
      );
    }

    // Structural validation
    final tree = InspectionTreePayload.fromJson(rawJson);
    final validation = validateTree(tree);
    if (!validation.isValid) {
      throw ArgumentError(
        'Tree validation failed. Fix these errors before publishing:\n'
        '${validation.errors.join('\n')}',
      );
    }

    // 3. POST to the backend (large payload — extend timeouts)
    await apiClient.post<Map<String, dynamic>>(
      'admin/config/v2-tree/upload',
      data: {
        'treeType': type.key,
        'tree': parsed,
      },
      options: Options(
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────

  InspectionTreePayload _mapTreeFields(
    InspectionTreePayload tree,
    String screenId,
    InspectionFieldDefinition Function(InspectionFieldDefinition) mapper,
  ) {
    return _mapTreeNodes(tree, (node) {
      if (node.id != screenId) return node;
      return node.copyWith(
        fields: node.fields.map(mapper).toList(),
      );
    });
  }

  InspectionTreePayload _mapTreeNodes(
    InspectionTreePayload tree,
    InspectionNodeDefinition Function(InspectionNodeDefinition) mapper,
  ) {
    return InspectionTreePayload(
      sections: tree.sections
          .map(
            (s) => InspectionSectionDefinition(
              key: s.key,
              title: s.title,
              description: s.description,
              nodes: s.nodes.map(mapper).toList(),
            ),
          )
          .toList(),
    );
  }
}
