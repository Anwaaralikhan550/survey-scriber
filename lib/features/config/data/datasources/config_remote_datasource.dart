import '../../../../core/network/api_client.dart';
import '../models/config_version_model.dart';
import '../models/field_definition_model.dart';
import '../models/full_config_model.dart';
import '../models/phrase_category_model.dart';

abstract class ConfigRemoteDataSource {
  /// Fetch current config version for cache invalidation
  Future<ConfigVersionModel> getConfigVersion();

  /// Fetch full configuration (categories + phrases + fields)
  Future<FullConfigModel> getFullConfig();

  /// Fetch phrases by category slug
  Future<PhraseCategoryModel> getPhrasesByCategory(String categorySlug);

  /// Fetch field definitions by section type
  Future<List<FieldDefinitionModel>> getFieldsBySection(String sectionType);
}

class ConfigRemoteDataSourceImpl implements ConfigRemoteDataSource {
  const ConfigRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ConfigVersionModel> getConfigVersion() async {
    final response = await _apiClient.get<Map<String, dynamic>>('config/version');
    return ConfigVersionModel.fromJson(response.data!);
  }

  @override
  Future<FullConfigModel> getFullConfig() async {
    final response = await _apiClient.get<Map<String, dynamic>>('config/all');
    return FullConfigModel.fromJson(response.data!);
  }

  @override
  Future<PhraseCategoryModel> getPhrasesByCategory(String categorySlug) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      'config/phrases/$categorySlug',
    );
    return PhraseCategoryModel.fromJson(response.data!);
  }

  @override
  Future<List<FieldDefinitionModel>> getFieldsBySection(String sectionType) async {
    final response = await _apiClient.get<List<dynamic>>(
      'config/fields/$sectionType',
    );
    return FieldDefinitionModel.fromJsonList(response.data!);
  }
}
