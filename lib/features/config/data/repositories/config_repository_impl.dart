import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/config_version.dart';
import '../../domain/entities/field_definition.dart';
import '../../domain/entities/phrase_category.dart';
import '../../domain/repositories/config_repository.dart';
import '../datasources/config_remote_datasource.dart';
import '../models/full_config_model.dart';
import '../models/phrase_category_model.dart';
import '../models/section_type_model.dart';

class ConfigRepositoryImpl implements ConfigRepository {
  ConfigRepositoryImpl({
    required ConfigRemoteDataSource remoteDataSource,
    required SharedPreferences prefs,
  })  : _remoteDataSource = remoteDataSource,
        _prefs = prefs;

  final ConfigRemoteDataSource _remoteDataSource;
  final SharedPreferences _prefs;

  static const _cacheKey = 'config_cache';
  static const _versionKey = 'config_version';

  // In-memory cache for faster access
  FullConfigModel? _cachedConfig;
  int? _cachedVersion;
  DateTime? _lastRefreshCheck;

  @override
  Future<ConfigVersion> getConfigVersion() async => _remoteDataSource.getConfigVersion();

  @override
  Future<({
    ConfigVersion version,
    List<PhraseCategory> categories,
    List<FieldDefinition> fields,
    List<SectionTypeModel> sectionTypes,
  })> getFullConfig({bool forceRefresh = false}) async {
    // Return in-memory cache if available and not forcing refresh
    if (!forceRefresh && _cachedConfig != null) {
      return (
        version: _cachedConfig!.version,
        categories: _cachedConfig!.categories,
        fields: _cachedConfig!.fields,
        sectionTypes: _cachedConfig!.sectionTypes,
      );
    }

    // Check if we need to refresh from server.
    // Skip the API call if we checked recently (< 60s) — prevents
    // rapid-fire config/version requests from startup + timer + resume.
    bool shouldRefresh;
    if (forceRefresh) {
      shouldRefresh = true;
    } else {
      final now = DateTime.now();
      if (_lastRefreshCheck != null &&
          now.difference(_lastRefreshCheck!) < const Duration(seconds: 60)) {
        shouldRefresh = false;
      } else {
        _lastRefreshCheck = now;
        shouldRefresh = await needsRefresh();
      }
    }

    if (!shouldRefresh) {
      // Try loading from local storage
      final cached = await _loadFromCache();
      if (cached != null) {
        _cachedConfig = cached;
        return (
          version: cached.version,
          categories: cached.categories,
          fields: cached.fields,
          sectionTypes: cached.sectionTypes,
        );
      }
    }

    // Fetch from server
    final config = await _remoteDataSource.getFullConfig();

    // Update caches
    _cachedConfig = config;
    _cachedVersion = config.version.version;
    await _saveToCache(config);

    return (
      version: config.version,
      categories: config.categories,
      fields: config.fields,
      sectionTypes: config.sectionTypes,
    );
  }

  @override
  Future<List<String>> getPhraseValues(String categorySlug) async {
    // Try to get from cache first
    if (_cachedConfig != null) {
      final category = _cachedConfig!.categories.firstWhere(
        (c) => c.slug == categorySlug,
        orElse: () => const PhraseCategoryModel(
          id: '',
          slug: '',
          displayName: '',
          isSystem: false,
          isActive: true,
          displayOrder: 0,
        ),
      );
      if (category.id.isNotEmpty) {
        return category.phrases.map((p) => p.value).toList();
      }
    }

    // Fetch from server if not in cache
    final category = await _remoteDataSource.getPhrasesByCategory(categorySlug);
    return category.phrases.map((p) => p.value).toList();
  }

  @override
  Future<List<FieldDefinition>> getFieldsForSection(String sectionType) async {
    // Try to get from cache first
    if (_cachedConfig != null) {
      final fields = _cachedConfig!.fields
          .where((f) => f.sectionType == sectionType)
          .toList();
      if (fields.isNotEmpty) {
        return fields;
      }
    }

    // Fetch from server if not in cache
    return _remoteDataSource.getFieldsBySection(sectionType);
  }

  @override
  Future<void> clearCache() async {
    _cachedConfig = null;
    _cachedVersion = null;
    await _prefs.remove(_cacheKey);
    await _prefs.remove(_versionKey);
  }

  @override
  Future<bool> needsRefresh() async {
    try {
      final serverVersion = await _remoteDataSource.getConfigVersion();
      final localVersion = _cachedVersion ?? _prefs.getInt(_versionKey) ?? 0;
      return serverVersion.version > localVersion;
    } catch (e) {
      // If we can't check version, don't force refresh
      return false;
    }
  }

  Future<void> _saveToCache(FullConfigModel config) async {
    try {
      final json = jsonEncode(config.toJson());
      await _prefs.setString(_cacheKey, json);
      await _prefs.setInt(_versionKey, config.version.version);
    } catch (e) {
      // Silently fail - caching is optional
    }
  }

  Future<FullConfigModel?> _loadFromCache() async {
    try {
      final json = _prefs.getString(_cacheKey);
      if (json == null) return null;
      return FullConfigModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      // Invalid cache, clear it
      await _prefs.remove(_cacheKey);
      return null;
    }
  }
}
