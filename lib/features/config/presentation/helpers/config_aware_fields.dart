import '../../../../shared/domain/entities/survey_section.dart';
import '../../domain/entities/field_definition.dart';
import '../../domain/entities/phrase_category.dart';
import '../providers/config_providers.dart';

/// Extension to get section type string from enum
extension SectionTypeMapper on SectionType {
  String get apiSectionType => switch (this) {
        SectionType.aboutInspection => 'about-inspection',
        SectionType.aboutProperty => 'about-property',
        SectionType.construction => 'construction',
        SectionType.externalItems => 'external-items',
        SectionType.internalItems => 'internal-items',
        SectionType.exterior => 'exterior',
        SectionType.interior => 'interior',
        SectionType.rooms => 'rooms',
        SectionType.services => 'services',
        SectionType.issuesAndRisks => 'issues-and-risks',
        SectionType.photos => 'photos',
        SectionType.notes => 'notes',
        SectionType.signature => 'signature',
        SectionType.aboutValuation => 'about-valuation',
        SectionType.propertySummary => 'property-summary',
        SectionType.marketAnalysis => 'market-analysis',
        SectionType.comparables => 'comparables',
        SectionType.adjustments => 'adjustments',
        SectionType.valuation => 'valuation',
        SectionType.summary => 'summary',
      };
}

/// Reverse lookup: API key string -> SectionType enum.
/// Returns null for keys that don't map to a known SectionType.
SectionType? sectionTypeFromApiKey(String key) => const <String, SectionType>{
      'about-inspection': SectionType.aboutInspection,
      'about-property': SectionType.aboutProperty,
      'construction': SectionType.construction,
      'external-items': SectionType.externalItems,
      'internal-items': SectionType.internalItems,
      'exterior': SectionType.exterior,
      'interior': SectionType.interior,
      'rooms': SectionType.rooms,
      'services': SectionType.services,
      'issues-and-risks': SectionType.issuesAndRisks,
      'photos': SectionType.photos,
      'notes': SectionType.notes,
      'signature': SectionType.signature,
      'about-valuation': SectionType.aboutValuation,
      'property-summary': SectionType.propertySummary,
      'market-analysis': SectionType.marketAnalysis,
      'comparables': SectionType.comparables,
      'adjustments': SectionType.adjustments,
      'valuation': SectionType.valuation,
      'summary': SectionType.summary,
    }[key];

/// Config-aware section fields that returns admin-created API fields
/// for a given section type.
class ConfigAwareSectionFields {
  /// Get fields for a section type from admin config.
  static List<FieldDefinition> getFields(SectionType type, ConfigState configState) {
    if (!configState.isLoaded) return [];

    return configState.fields
        .where((f) => f.sectionType == type.apiSectionType && f.isActive)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  /// Get phrase options for a category slug.
  /// Falls back to the provided default options if config not loaded.
  static List<String> getOptions(
    String categorySlug,
    ConfigState configState, {
    List<String> fallback = const [],
  }) {
    if (configState.isLoaded) {
      final category = configState.categories.firstWhere(
        (c) => c.slug == categorySlug && c.isActive,
        orElse: () => const PhraseCategory(
          id: '',
          slug: '',
          displayName: '',
          isSystem: false,
          isActive: false,
          displayOrder: 0,
        ),
      );

      if (category.id.isNotEmpty && category.phrases.isNotEmpty) {
        return category.phrases
            .where((p) => p.isActive)
            .map((p) => p.value)
            .toList();
      }
    }

    return fallback;
  }
}
