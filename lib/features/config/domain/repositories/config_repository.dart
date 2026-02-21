import '../../data/models/section_type_model.dart';
import '../entities/config_version.dart';
import '../entities/field_definition.dart';
import '../entities/phrase_category.dart';

abstract class ConfigRepository {
  /// Get current config version (checks cache first)
  Future<ConfigVersion> getConfigVersion();

  /// Get full configuration, using cache if version matches
  Future<({
    ConfigVersion version,
    List<PhraseCategory> categories,
    List<FieldDefinition> fields,
    List<SectionTypeModel> sectionTypes,
  })> getFullConfig({bool forceRefresh = false});

  /// Get phrases for a specific category
  Future<List<String>> getPhraseValues(String categorySlug);

  /// Get field definitions for a section type
  Future<List<FieldDefinition>> getFieldsForSection(String sectionType);

  /// Clear cached configuration
  Future<void> clearCache();

  /// Check if config needs refresh based on version
  Future<bool> needsRefresh();
}
