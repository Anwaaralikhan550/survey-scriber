import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../settings/presentation/providers/preferences_provider.dart';
import '../../data/datasources/config_remote_datasource.dart';
import '../../data/models/section_type_model.dart';
import '../../data/repositories/config_repository_impl.dart';
import '../../domain/entities/config_version.dart';
import '../../domain/entities/field_definition.dart';
import '../../domain/entities/phrase_category.dart';
import '../../domain/repositories/config_repository.dart';

// Remote data source
final configRemoteDataSourceProvider = Provider<ConfigRemoteDataSource>((ref) => ConfigRemoteDataSourceImpl(ref.watch(apiClientProvider)));

// Repository
final configRepositoryProvider = Provider<ConfigRepository>((ref) => ConfigRepositoryImpl(
    remoteDataSource: ref.watch(configRemoteDataSourceProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  ),);

// Config state
class ConfigState {
  const ConfigState({
    this.version,
    this.categories = const [],
    this.fields = const [],
    this.sectionTypes = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  final ConfigVersion? version;
  final List<PhraseCategory> categories;
  final List<FieldDefinition> fields;
  final List<SectionTypeModel> sectionTypes;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  ConfigState copyWith({
    ConfigVersion? version,
    List<PhraseCategory>? categories,
    List<FieldDefinition>? fields,
    List<SectionTypeModel>? sectionTypes,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) => ConfigState(
      version: version ?? this.version,
      categories: categories ?? this.categories,
      fields: fields ?? this.fields,
      sectionTypes: sectionTypes ?? this.sectionTypes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );

  /// Config is considered loaded when we have a version from the server.
  /// Categories and fields may be empty (no phrase categories configured yet).
  bool get isLoaded => version != null;

  /// Check if we have any fields configured via admin panel
  bool get hasConfiguredFields => fields.isNotEmpty;
}

// Config notifier
class ConfigNotifier extends StateNotifier<ConfigState> {
  ConfigNotifier(this._repository) : super(const ConfigState());

  final ConfigRepository _repository;

  /// Load full configuration from cache/server
  Future<void> loadConfig({bool forceRefresh = false}) async {
    if (state.isLoading) return;

    developer.log('ConfigNotifier: loadConfig(forceRefresh: $forceRefresh)', name: 'config');
    state = state.copyWith(isLoading: true);

    try {
      final config = await _repository.getFullConfig(forceRefresh: forceRefresh);
      developer.log(
        'ConfigNotifier: loaded v${config.version.version}, '
        '${config.categories.length} categories, '
        '${config.fields.length} fields, '
        '${config.sectionTypes.length} sectionTypes',
        name: 'config',
      );
      state = ConfigState(
        version: config.version,
        categories: config.categories,
        fields: config.fields,
        sectionTypes: config.sectionTypes,
        lastUpdated: DateTime.now(),
      );
    } catch (e, stack) {
      developer.log(
        'ConfigNotifier: loadConfig failed: $e',
        name: 'config',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Get phrase values for a category
  List<String> getPhraseValues(String categorySlug) {
    final category = state.categories.firstWhere(
      (c) => c.slug == categorySlug,
      orElse: () => const PhraseCategory(
        id: '',
        slug: '',
        displayName: '',
        isSystem: false,
        isActive: true,
        displayOrder: 0,
      ),
    );
    return category.phrases.map((p) => p.value).toList();
  }

  /// Get field definitions for a section
  List<FieldDefinition> getFieldsForSection(String sectionType) => state.fields.where((f) => f.sectionType == sectionType).toList();

  /// Clear cache and reload
  Future<void> refreshConfig() async {
    developer.log('ConfigNotifier: refreshConfig - clearing cache and reloading', name: 'config');
    await _repository.clearCache();
    await loadConfig(forceRefresh: true);
  }
}

// Main config provider
final configProvider = StateNotifierProvider<ConfigNotifier, ConfigState>((ref) => ConfigNotifier(ref.watch(configRepositoryProvider)));

// Convenience providers for common use cases

/// Get phrases for a specific category
final phrasesProvider = Provider.family<List<String>, String>((ref, categorySlug) {
  final configState = ref.watch(configProvider);
  final category = configState.categories.firstWhere(
    (c) => c.slug == categorySlug,
    orElse: () => const PhraseCategory(
      id: '',
      slug: '',
      displayName: '',
      isSystem: false,
      isActive: true,
      displayOrder: 0,
    ),
  );
  return category.phrases.map((p) => p.value).toList();
});

/// Get field definitions for a section type
final sectionFieldsProvider = Provider.family<List<FieldDefinition>, String>((ref, sectionType) {
  final configState = ref.watch(configProvider);
  return configState.fields.where((f) => f.sectionType == sectionType).toList();
});

/// Check if config is loaded
final configLoadedProvider = Provider<bool>((ref) => ref.watch(configProvider).isLoaded);

/// Config loading state
final configLoadingProvider = Provider<bool>((ref) => ref.watch(configProvider).isLoading);

/// Active section type keys — returns the set of keys for active section types.
/// Returns null when config is not loaded (offline fallback: show all sections).
final activeSectionTypesProvider = Provider<Set<String>?>((ref) {
  final configState = ref.watch(configProvider);
  if (!configState.isLoaded || configState.sectionTypes.isEmpty) return null;
  return configState.sectionTypes
      .where((s) => s.isActive)
      .map((s) => s.key)
      .toSet();
});

/// Legacy survey type aliases from SQL migrations.
/// Maps old string values to the canonical SurveyType enum strings.
const _legacySurveyTypeAliases = <String, String>{
  'homebuyer': 'LEVEL_2',
  'building': 'LEVEL_3',
  'valuation': 'VALUATION',
};

/// Active section type keys filtered by survey type.
/// Only returns section types whose surveyTypes list contains the given
/// backend survey type string (e.g. 'LEVEL_2', 'VALUATION').
/// Also handles legacy DB values ('homebuyer', 'building', 'valuation')
/// from SQL migrations that haven't been normalized yet.
/// Falls back to null (show-all) when surveyTypes data is empty or no match.
final activeSectionTypesForSurveyProvider =
    Provider.family<Set<String>?, String>((ref, backendSurveyType) {
  final configState = ref.watch(configProvider);
  if (!configState.isLoaded || configState.sectionTypes.isEmpty) return null;

  // Build the set of values to match: the canonical enum value plus any
  // legacy aliases that map to it (e.g. 'LEVEL_2' also matches 'homebuyer').
  final matchValues = <String>{backendSurveyType};
  for (final entry in _legacySurveyTypeAliases.entries) {
    if (entry.value == backendSurveyType) {
      matchValues.add(entry.key);
    }
  }

  final filtered = configState.sectionTypes
      .where((s) => s.isActive)
      .where((s) =>
          s.surveyTypes.isEmpty ||
          s.surveyTypes.any(matchValues.contains),)
      .map((s) => s.key)
      .toSet();

  // Safety: return null (show-all fallback) instead of empty set.
  // An empty set would pass the `!= null` check downstream and filter
  // out every section, causing the "0 of 0 sections" bug.
  return filtered.isEmpty ? null : filtered;
});
