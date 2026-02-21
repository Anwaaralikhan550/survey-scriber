import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../property_inspection/domain/models/inspection_models.dart';
import '../../../property_inspection/presentation/providers/inspection_providers.dart';
import '../../../property_valuation/presentation/providers/valuation_providers.dart';
import '../../data/tree_admin_repository.dart';

// ─── Repository Provider ──────────────────────────────────────────

final treeAdminRepositoryProvider = Provider<TreeAdminRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TreeAdminRepository(apiClient: apiClient);
});

// ─── Tree Providers ───────────────────────────────────────────────

/// The currently selected survey tree type in the admin panel.
final treeAdminSelectedTreeTypeProvider =
    StateProvider<SurveyTreeType>((ref) => SurveyTreeType.inspection);

/// Loads the full tree for the selected type.
final treeAdminTreeProvider =
    FutureProvider.autoDispose<InspectionTreePayload>((ref) async {
  final repo = ref.watch(treeAdminRepositoryProvider);
  final type = ref.watch(treeAdminSelectedTreeTypeProvider);
  return repo.loadTree(type);
});

/// Stats for the selected tree type.
final treeAdminTreeStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(treeAdminRepositoryProvider);
  final type = ref.watch(treeAdminSelectedTreeTypeProvider);
  return repo.getTreeStats(type);
});

/// Whether the selected tree has local modifications.
final treeAdminHasOverrideProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final repo = ref.watch(treeAdminRepositoryProvider);
  final type = ref.watch(treeAdminSelectedTreeTypeProvider);
  return repo.hasLocalOverride(type);
});

/// Backups for the selected tree type.
final treeAdminBackupsProvider =
    FutureProvider.autoDispose<List<File>>((ref) async {
  final repo = ref.watch(treeAdminRepositoryProvider);
  final type = ref.watch(treeAdminSelectedTreeTypeProvider);
  return repo.listBackups(type);
});

// ─── Section Browser ──────────────────────────────────────────────

/// The currently selected section key in the tree browser.
final treeAdminSelectedSectionProvider = StateProvider<String?>((ref) => null);

/// Nodes for the selected section.
final treeAdminSectionNodesProvider =
    Provider.autoDispose<List<InspectionNodeDefinition>>((ref) {
  final treeAsync = ref.watch(treeAdminTreeProvider);
  final selectedSection = ref.watch(treeAdminSelectedSectionProvider);
  if (selectedSection == null) return [];
  return treeAsync.maybeWhen(
    data: (tree) {
      final section = tree.sections
          .where((s) => s.key == selectedSection)
          .toList();
      if (section.isEmpty) return [];
      return section.first.nodes;
    },
    orElse: () => [],
  );
});

// ─── Screen Editor ────────────────────────────────────────────────

/// The currently selected screen ID in the admin editor.
final treeAdminSelectedScreenProvider = StateProvider<String?>((ref) => null);

/// Full node definition for the selected screen.
final treeAdminScreenDefinitionProvider =
    Provider.autoDispose<InspectionNodeDefinition?>((ref) {
  final treeAsync = ref.watch(treeAdminTreeProvider);
  final screenId = ref.watch(treeAdminSelectedScreenProvider);
  if (screenId == null) return null;
  return treeAsync.maybeWhen(
    data: (tree) {
      for (final section in tree.sections) {
        for (final node in section.nodes) {
          if (node.id == screenId) return node;
        }
      }
      return null;
    },
    orElse: () => null,
  );
});

// ─── Phrase Texts ─────────────────────────────────────────────────

/// All phrase template texts.
final treeAdminPhraseTextsProvider =
    FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final repo = ref.watch(treeAdminRepositoryProvider);
  return repo.loadPhraseTexts();
});

// ─── Notifier for Admin Operations ────────────────────────────────

class TreeAdminState {
  const TreeAdminState({
    this.isSaving = false,
    this.isPublishing = false,
    this.error,
    this.lastAction,
  });

  final bool isSaving;
  final bool isPublishing;
  final String? error;
  final String? lastAction;

  TreeAdminState copyWith({
    bool? isSaving,
    bool? isPublishing,
    String? error,
    String? lastAction,
  }) =>
      TreeAdminState(
        isSaving: isSaving ?? this.isSaving,
        isPublishing: isPublishing ?? this.isPublishing,
        error: error,
        lastAction: lastAction,
      );
}

class TreeAdminNotifier extends StateNotifier<TreeAdminState> {
  TreeAdminNotifier(this._repo, this._ref) : super(const TreeAdminState());

  final TreeAdminRepository _repo;
  final Ref _ref;

  void _invalidate() {
    _ref.invalidate(treeAdminTreeProvider);
    _ref.invalidate(treeAdminTreeStatsProvider);
    _ref.invalidate(treeAdminHasOverrideProvider);
    _ref.invalidate(treeAdminBackupsProvider);
    _ref.invalidate(treeAdminPhraseTextsProvider);

    // Always invalidate phrase texts — they are inspection-scoped but
    // editable regardless of which tree type is currently selected.
    // This cascades to inspectionPhraseEngineProvider and reportBuilderProvider.
    _ref.invalidate(inspectionPhraseTextsProvider);

    // Invalidate runtime repository caches so inspection/valuation modules
    // pick up tree changes immediately without app restart.
    if (_type == SurveyTreeType.inspection) {
      _ref.read(inspectionRepositoryProvider).invalidateCache();
      _ref.invalidate(inspectionSectionsProvider);
      _ref.invalidate(inspectionNodeMapProvider);
    } else {
      _ref.read(valuationRepositoryProvider).invalidateCache();
      _ref.invalidate(valuationSectionsProvider);
      _ref.invalidate(valuationNodeMapProvider);
    }
  }

  SurveyTreeType get _type => _ref.read(treeAdminSelectedTreeTypeProvider);

  Future<bool> updateFieldLabel(
    String screenId,
    String fieldId,
    String newLabel,
  ) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repo.updateFieldLabel(_type, screenId, fieldId, newLabel);
      _invalidate();
      state = state.copyWith(
        isSaving: false,
        lastAction: 'Field label updated',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: '$e');
      return false;
    }
  }

  Future<bool> updateDropdownOptions(
    String screenId,
    String fieldId,
    List<String> options,
  ) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repo.updateDropdownOptions(_type, screenId, fieldId, options);
      _invalidate();
      state = state.copyWith(
        isSaving: false,
        lastAction: 'Dropdown options updated',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: '$e');
      return false;
    }
  }

  Future<bool> updateFieldPhraseTemplate(
    String screenId,
    String fieldId,
    String? phraseTemplate,
  ) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repo.updateFieldPhraseTemplate(
        _type,
        screenId,
        fieldId,
        phraseTemplate,
      );
      _invalidate();
      state = state.copyWith(
        isSaving: false,
        lastAction: 'Phrase template updated',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: '$e');
      return false;
    }
  }

  Future<bool> updateConditionalRule(
    String screenId,
    String fieldId, {
    String? conditionalOn,
    String? conditionalValue,
    String? conditionalMode,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repo.updateConditionalRule(
        _type,
        screenId,
        fieldId,
        conditionalOn: conditionalOn,
        conditionalValue: conditionalValue,
        conditionalMode: conditionalMode,
      );
      _invalidate();
      state = state.copyWith(
        isSaving: false,
        lastAction: 'Conditional rule updated',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: '$e');
      return false;
    }
  }

  Future<bool> reorderFields(
    String screenId,
    List<String> fieldIds,
  ) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repo.reorderFields(_type, screenId, fieldIds);
      _invalidate();
      state = state.copyWith(
        isSaving: false,
        lastAction: 'Fields reordered',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: '$e');
      return false;
    }
  }

  Future<bool> addField(
    String screenId,
    InspectionFieldDefinition field,
  ) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repo.addField(_type, screenId, field);
      _invalidate();
      state = state.copyWith(
        isSaving: false,
        lastAction: 'Field added',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: '$e');
      return false;
    }
  }

  Future<bool> addScreen(
    String sectionKey,
    String title, {
    String? parentId,
    List<InspectionFieldDefinition> fields = const [],
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repo.addScreen(
        _type,
        sectionKey,
        title,
        parentId: parentId,
        fields: fields,
      );
      _invalidate();
      state = state.copyWith(
        isSaving: false,
        lastAction: 'Screen added',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: '$e');
      return false;
    }
  }

  Future<bool> addGroup(
    String sectionKey,
    String title, {
    String? parentId,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repo.addGroup(
        _type,
        sectionKey,
        title,
        parentId: parentId,
      );
      _invalidate();
      state = state.copyWith(
        isSaving: false,
        lastAction: 'Group added',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: '$e');
      return false;
    }
  }

  Future<bool> removeNode(String sectionKey, String nodeId) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repo.removeNode(_type, sectionKey, nodeId);
      _invalidate();
      state = state.copyWith(
        isSaving: false,
        lastAction: 'Node removed',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: '$e');
      return false;
    }
  }

  Future<bool> removeField(String screenId, String fieldId) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repo.removeField(_type, screenId, fieldId);
      _invalidate();
      state = state.copyWith(
        isSaving: false,
        lastAction: 'Field removed',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: '$e');
      return false;
    }
  }

  Future<bool> updateScreenTitle(String screenId, String newTitle) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repo.updateScreenTitle(_type, screenId, newTitle);
      _invalidate();
      state = state.copyWith(
        isSaving: false,
        lastAction: 'Screen title updated',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: '$e');
      return false;
    }
  }

  Future<bool> reorderSections(List<String> sectionKeys) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repo.reorderSections(_type, sectionKeys);
      _invalidate();
      state = state.copyWith(
        isSaving: false,
        lastAction: 'Sections reordered',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: '$e');
      return false;
    }
  }

  Future<bool> resetToAsset() async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repo.resetToAsset(_type);
      _invalidate();
      state = state.copyWith(
        isSaving: false,
        lastAction: 'Reset to original',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: '$e');
      return false;
    }
  }

  Future<bool> restoreBackup(File backup) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repo.restoreFromBackup(_type, backup);
      _invalidate();
      state = state.copyWith(
        isSaving: false,
        lastAction: 'Backup restored',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: '$e');
      return false;
    }
  }

  Future<bool> updatePhraseTemplate(String key, String value) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repo.updatePhraseTemplate(key, value);
      _invalidate();
      state = state.copyWith(
        isSaving: false,
        lastAction: 'Phrase template updated',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: '$e');
      return false;
    }
  }

  Future<bool> deletePhraseTemplate(String key) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repo.deletePhraseTemplate(key);
      _invalidate();
      state = state.copyWith(
        isSaving: false,
        lastAction: 'Phrase template deleted',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: '$e');
      return false;
    }
  }

  /// Publish the local tree override to the remote server.
  ///
  /// Returns a user-friendly error message string on failure, or null on success.
  Future<String?> publishChanges() async {
    state = state.copyWith(isPublishing: true, error: null);
    try {
      await _repo.publishTree(_type);
      _invalidate();
      state = state.copyWith(
        isPublishing: false,
        lastAction: '${_type.displayName} published to server',
      );
      return null; // success
    } on NetworkException catch (e) {
      final msg = 'No internet connection. Please check your network and try again.\n(${e.message})';
      state = state.copyWith(isPublishing: false, error: msg);
      return msg;
    } on AuthException catch (e) {
      final msg = 'Authentication failed. Please log in again.\n(${e.message})';
      state = state.copyWith(isPublishing: false, error: msg);
      return msg;
    } on UnauthorizedException catch (e) {
      final msg = 'You do not have permission to publish.\n(${e.message})';
      state = state.copyWith(isPublishing: false, error: msg);
      return msg;
    } on ServerException catch (e) {
      final msg = 'Server error (${e.statusCode ?? 'unknown'}): ${e.message ?? 'Unknown error'}';
      state = state.copyWith(isPublishing: false, error: msg);
      return msg;
    } on ValidationException catch (e) {
      final detail = e.message ?? 'Invalid data';
      final msg = 'Server rejected the tree:\n\n$detail';
      state = state.copyWith(isPublishing: false, error: msg);
      return msg;
    } on RateLimitException catch (e) {
      final msg = 'Too many requests. Please wait ${e.retryAfterSeconds ?? 60} seconds and try again.';
      state = state.copyWith(isPublishing: false, error: msg);
      return msg;
    } on ArgumentError catch (e) {
      final msg = '$e';
      state = state.copyWith(isPublishing: false, error: msg);
      return msg;
    } on StateError catch (e) {
      final msg = '$e';
      state = state.copyWith(isPublishing: false, error: msg);
      return msg;
    } catch (e) {
      final msg = 'Unexpected error: $e';
      state = state.copyWith(isPublishing: false, error: msg);
      return msg;
    }
  }
}

final treeAdminNotifierProvider =
    StateNotifierProvider<TreeAdminNotifier, TreeAdminState>((ref) {
  final repo = ref.watch(treeAdminRepositoryProvider);
  return TreeAdminNotifier(repo, ref);
});
