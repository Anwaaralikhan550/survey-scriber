import 'package:flutter_test/flutter_test.dart';

import 'package:survey_scriber/features/config/data/models/section_type_model.dart';
import 'package:survey_scriber/features/config/presentation/helpers/config_aware_fields.dart';
import 'package:survey_scriber/shared/domain/entities/survey_section.dart';

/// Helper to create a SectionTypeModel for tests.
SectionTypeModel _makeSectionType({
  required String key,
  bool isActive = true,
  int displayOrder = 0,
  List<String> surveyTypes = const [],
}) =>
    SectionTypeModel(
      id: 'st-$key',
      key: key,
      label: key,
      displayOrder: displayOrder,
      surveyTypes: surveyTypes,
      isActive: isActive,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

void main() {
  group('Section type filtering at creation time', () {
    test('filters inspection templates by active section types', () {
      // Simulate active section types from config
      final activeSectionTypes = <String>{
        'about-inspection',
        'about-property',
        'construction',
        'photos',
        'signature',
      };

      final allTemplates = SectionTemplates.getInspectionSections();
      final filtered = allTemplates
          .where((t) => activeSectionTypes.contains(t.$1.apiSectionType))
          .toList();

      expect(filtered.length, 5);
      expect(
        filtered.map((t) => t.$1.apiSectionType).toList(),
        containsAll(['about-inspection', 'about-property', 'construction', 'photos', 'signature']),
      );
    });

    test('excludes inactive section types', () {
      // 'signature' is NOT in the active set => should be excluded
      final activeSectionTypes = <String>{
        'about-inspection',
        'about-property',
        'construction',
        'external-items',
        'internal-items',
        'rooms',
        'services',
        'issues-and-risks',
        'photos',
        'notes',
        // 'signature' deliberately missing
      };

      final allTemplates = SectionTemplates.getInspectionSections();
      final filtered = allTemplates
          .where((t) => activeSectionTypes.contains(t.$1.apiSectionType))
          .toList();

      expect(
        filtered.any((t) => t.$1 == SectionType.signature),
        isFalse,
      );
      expect(filtered.length, allTemplates.length - 1);
    });

    test('shows all sections when config not loaded (null active set)', () {
      // null means config not loaded (offline fallback)
      const Set<String>? activeSectionTypes = null;

      final allTemplates = SectionTemplates.getInspectionSections();
      final filtered = activeSectionTypes != null
          ? allTemplates
              .where((t) => activeSectionTypes.contains(t.$1.apiSectionType))
              .toList()
          : allTemplates;

      expect(filtered.length, allTemplates.length);
    });

    test('re-enabled section types reappear', () {
      // First: signature is inactive
      final withoutSignature = <String>{
        'about-inspection',
        'about-property',
      };

      final allTemplates = SectionTemplates.getInspectionSections();
      final filtered1 = allTemplates
          .where((t) => withoutSignature.contains(t.$1.apiSectionType))
          .toList();
      expect(filtered1.any((t) => t.$1 == SectionType.signature), isFalse);

      // Then: signature is re-enabled
      final withSignature = <String>{
        'about-inspection',
        'about-property',
        'signature',
      };

      final filtered2 = allTemplates
          .where((t) => withSignature.contains(t.$1.apiSectionType))
          .toList();
      expect(filtered2.any((t) => t.$1 == SectionType.signature), isTrue);
    });
  });

  group('SectionTypeModel parsing', () {
    test('parses sectionTypes from JSON correctly', () {
      final models = SectionTypeModel.fromJsonList([
        {
          'id': 'st-1',
          'key': 'about-property',
          'label': 'About Property',
          'isActive': true,
          'displayOrder': 0,
          'surveyTypes': ['homebuyer'],
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-01T00:00:00.000Z',
        },
        {
          'id': 'st-2',
          'key': 'signature',
          'label': 'Sign Off',
          'isActive': false,
          'displayOrder': 1,
          'surveyTypes': [],
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-01T00:00:00.000Z',
        },
      ]);

      expect(models.length, 2);
      expect(models[0].key, 'about-property');
      expect(models[0].isActive, isTrue);
      expect(models[1].key, 'signature');
      expect(models[1].isActive, isFalse);
    });

    test('derives active keys set correctly', () {
      final sectionTypes = [
        _makeSectionType(key: 'about-property'),
        _makeSectionType(key: 'signature', isActive: false),
        _makeSectionType(key: 'photos'),
      ];

      final activeKeys = sectionTypes
          .where((s) => s.isActive)
          .map((s) => s.key)
          .toSet();

      expect(activeKeys, {'about-property', 'photos'});
      expect(activeKeys.contains('signature'), isFalse);
    });
  });

  group('SectionTypeMapper extension', () {
    test('maps SectionType enum to API key strings', () {
      expect(SectionType.aboutProperty.apiSectionType, 'about-property');
      expect(SectionType.signature.apiSectionType, 'signature');
      expect(SectionType.externalItems.apiSectionType, 'external-items');
      expect(SectionType.issuesAndRisks.apiSectionType, 'issues-and-risks');
    });
  });

  group('DB seed key coverage (regression guard)', () {
    // These are the keys that MUST exist in section_type_definitions table.
    // If any key is missing, the corresponding section will be hidden when
    // config is loaded and activeSectionTypesProvider is non-null.
    //
    // Migration: 20260129060000_seed_missing_section_types
    const expectedInspectionKeys = <String>{
      'about-inspection',
      'about-property',
      'construction',
      'external-items',
      'internal-items',
      'rooms',
      'services',
      'issues-and-risks',
      'photos',
      'notes',
      'signature',
    };

    const expectedValuationKeys = <String>{
      'about-valuation',
      'property-summary',
      'market-analysis',
      'comparables',
      'adjustments',
      'valuation',
      'summary',
      'photos',
      'signature',
    };

    test('every inspection template key maps to an expected DB key', () {
      final templateKeys = SectionTemplates.getInspectionSections()
          .map((t) => t.$1.apiSectionType)
          .toSet();

      expect(templateKeys, expectedInspectionKeys);
    });

    test('every valuation template key maps to an expected DB key', () {
      final templateKeys = SectionTemplates.getValuationSections()
          .map((t) => t.$1.apiSectionType)
          .toSet();

      expect(templateKeys, expectedValuationKeys);
    });

    test('all inspection keys are present when DB is fully seeded', () {
      // Simulate a fully-seeded DB (all 20 unique keys)
      final allDbKeys = <String>{
        ...expectedInspectionKeys,
        ...expectedValuationKeys,
        'exterior',  // legacy key (still in DB, not used by new templates)
        'interior',  // legacy key (still in DB, not used by new templates)
      };

      // Build active set (all active)
      final activeSectionTypes = allDbKeys;

      final templates = SectionTemplates.getInspectionSections();
      final filtered = templates
          .where((t) => activeSectionTypes.contains(t.$1.apiSectionType))
          .toList();

      // All 11 inspection sections must pass the filter
      expect(filtered.length, templates.length);
    });

    test('all valuation keys are present when DB is fully seeded', () {
      final allDbKeys = <String>{
        ...expectedInspectionKeys,
        ...expectedValuationKeys,
        'exterior',
        'interior',
      };

      final activeSectionTypes = allDbKeys;

      final templates = SectionTemplates.getValuationSections();
      final filtered = templates
          .where((t) => activeSectionTypes.contains(t.$1.apiSectionType))
          .toList();

      // All 9 valuation sections must pass the filter
      expect(filtered.length, templates.length);
    });

    test('disabling a single key hides only that section', () {
      // All keys active except 'rooms'
      final allDbKeys = <String>{...expectedInspectionKeys};
      allDbKeys.remove('rooms');

      final templates = SectionTemplates.getInspectionSections();
      final filtered = templates
          .where((t) => allDbKeys.contains(t.$1.apiSectionType))
          .toList();

      expect(filtered.length, templates.length - 1);
      expect(filtered.any((t) => t.$1 == SectionType.rooms), isFalse);
      // All other sections still present
      expect(filtered.any((t) => t.$1 == SectionType.aboutInspection), isTrue);
      expect(filtered.any((t) => t.$1 == SectionType.services), isTrue);
      expect(filtered.any((t) => t.$1 == SectionType.signature), isTrue);
    });
  });

  group('Key normalization (regression: underscore vs hyphen)', () {
    /// Mirrors _normalizeKey from section_type_management_page.dart
    String normalizeKey(String input) => input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_]+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\-]'), '')
        .replaceAll(RegExp('-{2,}'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    test('normalizes underscores to hyphens', () {
      expect(normalizeKey('about_property'), 'about-property');
      expect(normalizeKey('issues_and_risks'), 'issues-and-risks');
      expect(normalizeKey('external_items'), 'external-items');
    });

    test('normalizes spaces to hyphens', () {
      expect(normalizeKey('about property'), 'about-property');
      expect(normalizeKey('About Property'), 'about-property');
    });

    test('preserves already-correct kebab-case', () {
      expect(normalizeKey('about-property'), 'about-property');
      expect(normalizeKey('issues-and-risks'), 'issues-and-risks');
    });

    test('strips special characters', () {
      expect(normalizeKey('about@property!'), 'aboutproperty');
      expect(normalizeKey('section (new)'), 'section-new');
    });

    test('collapses multiple hyphens', () {
      expect(normalizeKey('about--property'), 'about-property');
      expect(normalizeKey('a___b'), 'a-b');
    });

    test('trims leading/trailing hyphens', () {
      expect(normalizeKey('-about-'), 'about');
      expect(normalizeKey('_about_'), 'about');
    });

    test('normalized keys match apiSectionType format', () {
      // Verify that common admin-entered keys normalize to correct apiSectionType
      final keyPairs = <String, String>{
        'about_inspection': 'about-inspection',
        'about_property': 'about-property',
        'external_items': 'external-items',
        'internal_items': 'internal-items',
        'issues_and_risks': 'issues-and-risks',
        'about_valuation': 'about-valuation',
        'property_summary': 'property-summary',
        'market_analysis': 'market-analysis',
      };

      for (final entry in keyPairs.entries) {
        final normalized = normalizeKey(entry.key);
        expect(normalized, entry.value,
            reason: 'Admin key "${entry.key}" should normalize to "${entry.value}"',);
        // Also verify the normalized key matches a real apiSectionType
        final matchingEnums = SectionType.values
            .where((t) => t.apiSectionType == normalized);
        expect(matchingEnums.isNotEmpty, isTrue,
            reason: 'Normalized key "$normalized" should match an apiSectionType',);
      }
    });
  });

  group('sectionTypeFromApiKey reverse mapping', () {
    test('maps known API keys back to SectionType enum', () {
      expect(sectionTypeFromApiKey('about-property'), SectionType.aboutProperty);
      expect(sectionTypeFromApiKey('signature'), SectionType.signature);
      expect(sectionTypeFromApiKey('external-items'), SectionType.externalItems);
      expect(sectionTypeFromApiKey('issues-and-risks'), SectionType.issuesAndRisks);
      expect(sectionTypeFromApiKey('about-valuation'), SectionType.aboutValuation);
    });

    test('returns null for unknown API keys', () {
      expect(sectionTypeFromApiKey('custom-section'), isNull);
      expect(sectionTypeFromApiKey('asd'), isNull);
      expect(sectionTypeFromApiKey(''), isNull);
    });

    test('round-trips: apiSectionType -> sectionTypeFromApiKey', () {
      for (final st in SectionType.values) {
        final key = st.apiSectionType;
        final result = sectionTypeFromApiKey(key);
        expect(result, st, reason: 'Round-trip failed for $st ($key)');
      }
    });
  });

  group('Config-driven section merging for inspection', () {
    // Legacy section keys superseded by new section types.
    // These must never be merged into inspection templates.
    const legacyKeys = <String>{'exterior', 'interior'};

    test('legacy keys (exterior, interior) are excluded from merge', () {
      // Hardcoded inspection templates
      final templates = SectionTemplates.getInspectionSections();
      final existingKeys = templates.map((t) => t.$1.apiSectionType).toSet();
      final originalLength = templates.length;

      // Config has 'exterior' which is a valid enum but is a legacy key
      final configSectionTypes = [
        _makeSectionType(key: 'exterior'),
        _makeSectionType(key: 'interior'),
      ];

      // Merge with legacy exclusion
      for (final st in configSectionTypes) {
        if (!st.isActive || existingKeys.contains(st.key)) continue;
        if (legacyKeys.contains(st.key)) continue;
        final enumType = sectionTypeFromApiKey(st.key);
        if (enumType != null) {
          templates.add((enumType, st.label));
          existingKeys.add(st.key);
        }
      }

      // Legacy keys must NOT be added
      expect(templates.any((t) => t.$1 == SectionType.exterior), isFalse);
      expect(templates.any((t) => t.$1 == SectionType.interior), isFalse);
      expect(templates.length, originalLength);
    });

    test('does not add config section types with unknown keys', () {
      final templates = SectionTemplates.getInspectionSections();
      final existingKeys = templates.map((t) => t.$1.apiSectionType).toSet();
      final originalLength = templates.length;

      // Config has a custom key that doesn't map to any SectionType enum
      final configSectionTypes = [
        _makeSectionType(key: 'custom-unknown'),
      ];

      for (final st in configSectionTypes) {
        if (!st.isActive || existingKeys.contains(st.key)) continue;
        if (legacyKeys.contains(st.key)) continue;
        final enumType = sectionTypeFromApiKey(st.key);
        if (enumType != null) {
          templates.add((enumType, st.label));
          existingKeys.add(st.key);
        }
      }

      // Length should be unchanged
      expect(templates.length, originalLength);
    });

    test('does not duplicate section types already in templates', () {
      final templates = SectionTemplates.getInspectionSections();
      final existingKeys = templates.map((t) => t.$1.apiSectionType).toSet();
      final originalLength = templates.length;

      // Config has 'about-property' which IS already in inspection templates
      final configSectionTypes = [
        _makeSectionType(key: 'about-property'),
      ];

      for (final st in configSectionTypes) {
        if (!st.isActive || existingKeys.contains(st.key)) continue;
        if (legacyKeys.contains(st.key)) continue;
        final enumType = sectionTypeFromApiKey(st.key);
        if (enumType != null) {
          templates.add((enumType, st.label));
          existingKeys.add(st.key);
        }
      }

      // Length should be unchanged (no duplicate)
      expect(templates.length, originalLength);
    });

    test('inactive config section types are not added', () {
      final templates = SectionTemplates.getInspectionSections();
      final existingKeys = templates.map((t) => t.$1.apiSectionType).toSet();
      final originalLength = templates.length;

      // Config has 'exterior' but it's inactive (also a legacy key)
      final configSectionTypes = [
        _makeSectionType(key: 'exterior', isActive: false),
      ];

      for (final st in configSectionTypes) {
        if (!st.isActive || existingKeys.contains(st.key)) continue;
        if (legacyKeys.contains(st.key)) continue;
        final enumType = sectionTypeFromApiKey(st.key);
        if (enumType != null) {
          templates.add((enumType, st.label));
          existingKeys.add(st.key);
        }
      }

      expect(templates.length, originalLength);
    });
  });

  group('Delete removes, undo restores (unit logic)', () {
    test('deleting removes item from list', () {
      final sectionTypes = [
        _makeSectionType(key: 'about-property'),
        _makeSectionType(key: 'construction'),
        _makeSectionType(key: 'signature'),
      ];

      // Delete 'construction'
      final deleted = sectionTypes.firstWhere((s) => s.key == 'construction');
      final afterDelete = sectionTypes.where((s) => s.id != deleted.id).toList();

      expect(afterDelete.length, 2);
      expect(afterDelete.any((s) => s.key == 'construction'), isFalse);
      expect(afterDelete.any((s) => s.key == 'about-property'), isTrue);
      expect(afterDelete.any((s) => s.key == 'signature'), isTrue);
    });

    test('restoring re-inserts item into list', () {
      final deleted = _makeSectionType(key: 'construction', displayOrder: 1);
      final remaining = [
        _makeSectionType(key: 'about-property'),
        _makeSectionType(key: 'signature', displayOrder: 2),
      ];

      // Restore
      final restored = [...remaining, deleted]
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      expect(restored.length, 3);
      expect(restored[1].key, 'construction');
    });

    test('disable (isActive=false) is separate from delete', () {
      final sectionTypes = [
        _makeSectionType(key: 'about-property'),
        _makeSectionType(key: 'construction', isActive: false), // disabled but not deleted
        _makeSectionType(key: 'signature'),
      ];

      // Disabled items remain in list
      expect(sectionTypes.length, 3);
      expect(sectionTypes.any((s) => s.key == 'construction'), isTrue);

      // Active filter excludes disabled
      final activeOnly = sectionTypes.where((s) => s.isActive).toList();
      expect(activeOnly.length, 2);
      expect(activeOnly.any((s) => s.key == 'construction'), isFalse);
    });
  });

  group('Survey type isolation (inspection vs valuation)', () {
    // Inspection-only section keys (must NEVER appear in a valuation survey)
    const inspectionOnlyKeys = <String>{
      'about-inspection',
      'external-items',
      'internal-items',
      'issues-and-risks',
    };

    // Valuation-only section keys (must NEVER appear in an inspection survey)
    const valuationOnlyKeys = <String>{
      'about-valuation',
      'property-summary',
      'market-analysis',
      'comparables',
      'adjustments',
      'valuation',
      'summary',
    };

    /// Simulates the create_survey_provider merge logic with survey-type filtering.
    /// Legacy keys (exterior, interior) are excluded — they've been superseded.
    const legacyKeys = <String>{'exterior', 'interior'};

    List<(SectionType, String)> buildSectionsForSurveyType({
      required String backendSurveyType,
      required List<SectionTypeModel> configSectionTypes,
    }) {
      final isInspection = backendSurveyType == 'LEVEL_2' ||
          backendSurveyType == 'LEVEL_3' ||
          backendSurveyType == 'SNAGGING';
      var templates = isInspection
          ? SectionTemplates.getInspectionSections()
          : SectionTemplates.getValuationSections();

      final activeSectionTypes = configSectionTypes
          .where((s) => s.isActive)
          .where((s) =>
              s.surveyTypes.isEmpty ||
              s.surveyTypes.contains(backendSurveyType),)
          .map((s) => s.key)
          .toSet();

      templates = templates
          .where((t) => activeSectionTypes.contains(t.$1.apiSectionType))
          .toList();

      final existingKeys =
          templates.map((t) => t.$1.apiSectionType).toSet();
      for (final st in configSectionTypes) {
        if (!st.isActive || existingKeys.contains(st.key)) continue;
        if (legacyKeys.contains(st.key)) continue;
        if (st.surveyTypes.isNotEmpty &&
            !st.surveyTypes.contains(backendSurveyType)) continue;
        final enumType = sectionTypeFromApiKey(st.key);
        if (enumType != null) {
          templates.add((enumType, st.label));
          existingKeys.add(st.key);
        }
      }

      return templates;
    }

    List<SectionTypeModel> buildFullConfig() {
      const inspectionTypes = ['LEVEL_2', 'LEVEL_3', 'SNAGGING'];
      const valuationTypes = ['VALUATION'];
      const sharedTypes = [...inspectionTypes, ...valuationTypes];

      return [
        _makeSectionType(key: 'about-inspection', surveyTypes: inspectionTypes),
        _makeSectionType(key: 'about-property', surveyTypes: sharedTypes),
        _makeSectionType(key: 'construction', surveyTypes: sharedTypes),
        _makeSectionType(key: 'external-items', surveyTypes: inspectionTypes),
        _makeSectionType(key: 'internal-items', surveyTypes: inspectionTypes),
        _makeSectionType(key: 'exterior', surveyTypes: sharedTypes),
        _makeSectionType(key: 'interior', surveyTypes: sharedTypes),
        _makeSectionType(key: 'rooms', surveyTypes: sharedTypes),
        _makeSectionType(key: 'services', surveyTypes: sharedTypes),
        _makeSectionType(key: 'issues-and-risks', surveyTypes: inspectionTypes),
        _makeSectionType(key: 'photos', surveyTypes: sharedTypes),
        _makeSectionType(key: 'notes', surveyTypes: sharedTypes),
        _makeSectionType(key: 'signature', surveyTypes: sharedTypes),
        _makeSectionType(key: 'about-valuation', surveyTypes: valuationTypes),
        _makeSectionType(key: 'property-summary', surveyTypes: valuationTypes),
        _makeSectionType(key: 'market-analysis', surveyTypes: valuationTypes),
        _makeSectionType(key: 'comparables', surveyTypes: valuationTypes),
        _makeSectionType(key: 'adjustments', surveyTypes: valuationTypes),
        _makeSectionType(key: 'valuation', surveyTypes: valuationTypes),
        _makeSectionType(key: 'summary', surveyTypes: valuationTypes),
      ];
    }

    test('LEVEL_2 inspection NEVER includes valuation-only sections', () {
      final config = buildFullConfig();
      final sections = buildSectionsForSurveyType(
        backendSurveyType: 'LEVEL_2',
        configSectionTypes: config,
      );
      final keys = sections.map((t) => t.$1.apiSectionType).toSet();

      for (final vKey in valuationOnlyKeys) {
        expect(keys.contains(vKey), isFalse,
            reason: 'Inspection survey must not contain valuation key "$vKey"',);
      }
    });

    test('LEVEL_3 inspection NEVER includes valuation-only sections', () {
      final config = buildFullConfig();
      final sections = buildSectionsForSurveyType(
        backendSurveyType: 'LEVEL_3',
        configSectionTypes: config,
      );
      final keys = sections.map((t) => t.$1.apiSectionType).toSet();

      for (final vKey in valuationOnlyKeys) {
        expect(keys.contains(vKey), isFalse,
            reason: 'Inspection survey must not contain valuation key "$vKey"',);
      }
    });

    test('VALUATION survey NEVER includes inspection-only sections', () {
      final config = buildFullConfig();
      final sections = buildSectionsForSurveyType(
        backendSurveyType: 'VALUATION',
        configSectionTypes: config,
      );
      final keys = sections.map((t) => t.$1.apiSectionType).toSet();

      for (final iKey in inspectionOnlyKeys) {
        expect(keys.contains(iKey), isFalse,
            reason: 'Valuation survey must not contain inspection key "$iKey"',);
      }
    });

    test('SNAGGING survey NEVER includes valuation-only sections', () {
      final config = buildFullConfig();
      final sections = buildSectionsForSurveyType(
        backendSurveyType: 'SNAGGING',
        configSectionTypes: config,
      );
      final keys = sections.map((t) => t.$1.apiSectionType).toSet();

      for (final vKey in valuationOnlyKeys) {
        expect(keys.contains(vKey), isFalse,
            reason: 'Snagging survey must not contain valuation key "$vKey"',);
      }
    });

    test('inspection survey includes all expected inspection sections', () {
      final config = buildFullConfig();
      final sections = buildSectionsForSurveyType(
        backendSurveyType: 'LEVEL_2',
        configSectionTypes: config,
      );
      final keys = sections.map((t) => t.$1.apiSectionType).toSet();

      for (final iKey in inspectionOnlyKeys) {
        expect(keys.contains(iKey), isTrue,
            reason: 'Inspection survey must contain "$iKey"',);
      }
      expect(keys.contains('photos'), isTrue);
      expect(keys.contains('signature'), isTrue);
    });

    test('valuation survey includes all expected valuation sections', () {
      final config = buildFullConfig();
      final sections = buildSectionsForSurveyType(
        backendSurveyType: 'VALUATION',
        configSectionTypes: config,
      );
      final keys = sections.map((t) => t.$1.apiSectionType).toSet();

      for (final vKey in valuationOnlyKeys) {
        expect(keys.contains(vKey), isTrue,
            reason: 'Valuation survey must contain "$vKey"',);
      }
      expect(keys.contains('photos'), isTrue);
      expect(keys.contains('signature'), isTrue);
    });

    test('empty surveyTypes falls back to showing section (backward compat)', () {
      final config = [
        _makeSectionType(key: 'about-inspection', surveyTypes: []),
        _makeSectionType(key: 'about-property', surveyTypes: []),
        _makeSectionType(key: 'construction', surveyTypes: []),
        _makeSectionType(key: 'external-items', surveyTypes: []),
        _makeSectionType(key: 'internal-items', surveyTypes: []),
        _makeSectionType(key: 'rooms', surveyTypes: []),
        _makeSectionType(key: 'services', surveyTypes: []),
        _makeSectionType(key: 'issues-and-risks', surveyTypes: []),
        _makeSectionType(key: 'photos', surveyTypes: []),
        _makeSectionType(key: 'notes', surveyTypes: []),
        _makeSectionType(key: 'signature', surveyTypes: []),
      ];

      final inspSections = buildSectionsForSurveyType(
        backendSurveyType: 'LEVEL_2',
        configSectionTypes: config,
      );
      expect(inspSections.isNotEmpty, isTrue);
      // All inspection template sections should be present
      expect(inspSections.length, SectionTemplates.getInspectionSections().length);
    });

    test('no duplicate sections when config and template overlap', () {
      final config = buildFullConfig();
      final sections = buildSectionsForSurveyType(
        backendSurveyType: 'LEVEL_2',
        configSectionTypes: config,
      );
      final keys = sections.map((t) => t.$1.apiSectionType).toList();
      expect(keys.length, keys.toSet().length,
          reason: 'There should be no duplicate section keys',);
    });
  });

  group('Regression: 0-of-0 sections bug (Bug #1 + Bug #2)', () {
    // Bug #1: create_survey_provider only checked `== SurveyType.inspection` for
    // inspection templates.  level3, snagging, reinspection got valuation
    // templates, which then filtered to 0 sections.
    //
    // Bug #2: activeSectionTypesForSurveyProvider returned empty Set instead
    // of null when filtering yielded zero results. The empty set passed the
    // `!= null` check in survey_detail_provider and filtered out everything.

    const inspectionBackendTypes = ['LEVEL_2', 'LEVEL_3', 'SNAGGING'];
    const valuationBackendTypes = ['VALUATION'];
    const sharedBackendTypes = [...inspectionBackendTypes, ...valuationBackendTypes];

    List<SectionTypeModel> buildFullConfig() => [
        _makeSectionType(key: 'about-inspection', surveyTypes: inspectionBackendTypes),
        _makeSectionType(key: 'about-property', surveyTypes: sharedBackendTypes),
        _makeSectionType(key: 'construction', surveyTypes: sharedBackendTypes),
        _makeSectionType(key: 'external-items', surveyTypes: inspectionBackendTypes),
        _makeSectionType(key: 'internal-items', surveyTypes: inspectionBackendTypes),
        _makeSectionType(key: 'exterior', surveyTypes: sharedBackendTypes),
        _makeSectionType(key: 'interior', surveyTypes: sharedBackendTypes),
        _makeSectionType(key: 'rooms', surveyTypes: sharedBackendTypes),
        _makeSectionType(key: 'services', surveyTypes: sharedBackendTypes),
        _makeSectionType(key: 'issues-and-risks', surveyTypes: inspectionBackendTypes),
        _makeSectionType(key: 'photos', surveyTypes: sharedBackendTypes),
        _makeSectionType(key: 'notes', surveyTypes: sharedBackendTypes),
        _makeSectionType(key: 'signature', surveyTypes: sharedBackendTypes),
        _makeSectionType(key: 'about-valuation', surveyTypes: valuationBackendTypes),
        _makeSectionType(key: 'property-summary', surveyTypes: valuationBackendTypes),
        _makeSectionType(key: 'market-analysis', surveyTypes: valuationBackendTypes),
        _makeSectionType(key: 'comparables', surveyTypes: valuationBackendTypes),
        _makeSectionType(key: 'adjustments', surveyTypes: valuationBackendTypes),
        _makeSectionType(key: 'valuation', surveyTypes: valuationBackendTypes),
        _makeSectionType(key: 'summary', surveyTypes: valuationBackendTypes),
      ];

    /// Mirrors the FIXED create_survey_provider logic (isInspectionType set).
    /// Legacy keys (exterior, interior) are excluded from merge.
    const legacyKeysFixed = <String>{'exterior', 'interior'};

    List<(SectionType, String)> buildSectionsFixed({
      required String backendSurveyType,
      required List<SectionTypeModel> configSectionTypes,
    }) {
      final isInspection = const {'LEVEL_2', 'LEVEL_3', 'SNAGGING', 'REINSPECTION'}
          .contains(backendSurveyType);
      var templates = isInspection
          ? SectionTemplates.getInspectionSections()
          : SectionTemplates.getValuationSections();

      final activeSectionTypes = configSectionTypes
          .where((s) => s.isActive)
          .where((s) =>
              s.surveyTypes.isEmpty ||
              s.surveyTypes.contains(backendSurveyType),)
          .map((s) => s.key)
          .toSet();

      if (activeSectionTypes.isNotEmpty) {
        templates = templates
            .where((t) => activeSectionTypes.contains(t.$1.apiSectionType))
            .toList();
      }

      final existingKeys =
          templates.map((t) => t.$1.apiSectionType).toSet();
      for (final st in configSectionTypes) {
        if (!st.isActive || existingKeys.contains(st.key)) continue;
        if (legacyKeysFixed.contains(st.key)) continue;
        if (st.surveyTypes.isNotEmpty &&
            !st.surveyTypes.contains(backendSurveyType)) continue;
        final enumType = sectionTypeFromApiKey(st.key);
        if (enumType != null) {
          templates.add((enumType, st.label));
          existingKeys.add(st.key);
        }
      }

      return templates;
    }

    test('Bug #1 regression: LEVEL_3 gets inspection templates, not valuation', () {
      final config = buildFullConfig();
      final sections = buildSectionsFixed(
        backendSurveyType: 'LEVEL_3',
        configSectionTypes: config,
      );

      expect(sections.isNotEmpty, isTrue,
          reason: 'LEVEL_3 survey must not have 0 sections',);
      final keys = sections.map((t) => t.$1.apiSectionType).toSet();
      expect(keys.contains('about-inspection'), isTrue,
          reason: 'LEVEL_3 is an inspection type and must have about-inspection',);
      expect(keys.contains('about-valuation'), isFalse,
          reason: 'LEVEL_3 must NOT have valuation-only sections',);
    });

    test('Bug #1 regression: SNAGGING gets inspection templates, not valuation', () {
      final config = buildFullConfig();
      final sections = buildSectionsFixed(
        backendSurveyType: 'SNAGGING',
        configSectionTypes: config,
      );

      expect(sections.isNotEmpty, isTrue,
          reason: 'SNAGGING survey must not have 0 sections',);
      final keys = sections.map((t) => t.$1.apiSectionType).toSet();
      expect(keys.contains('about-inspection'), isTrue);
      expect(keys.contains('about-valuation'), isFalse);
    });

    test('Bug #1 regression: REINSPECTION gets inspection templates', () {
      final config = buildFullConfig();
      final sections = buildSectionsFixed(
        backendSurveyType: 'REINSPECTION',
        configSectionTypes: config,
      );

      expect(sections.isNotEmpty, isTrue,
          reason: 'REINSPECTION survey must not have 0 sections',);
      // Since no config types match REINSPECTION, the empty-set safety
      // should skip filtering → all inspection templates present.
      expect(sections.length, SectionTemplates.getInspectionSections().length);
    });

    test('Bug #2 regression: empty config filter returns null (show-all fallback)', () {
      final configSectionTypes = buildFullConfig();
      final filtered = configSectionTypes
          .where((s) => s.isActive)
          .where((s) =>
              s.surveyTypes.isEmpty ||
              s.surveyTypes.contains('REINSPECTION'),)
          .map((s) => s.key)
          .toSet();

      // The FIXED provider returns null when empty
      final result = filtered.isEmpty ? null : filtered;
      expect(result, isNull,
          reason: 'Empty filter set must return null to trigger show-all fallback',);
    });

    test('Bug #2 regression: non-empty config filter returns valid set', () {
      final configSectionTypes = buildFullConfig();
      final filtered = configSectionTypes
          .where((s) => s.isActive)
          .where((s) =>
              s.surveyTypes.isEmpty ||
              s.surveyTypes.contains('LEVEL_2'),)
          .map((s) => s.key)
          .toSet();

      final result = filtered.isEmpty ? null : filtered;
      expect(result, isNotNull);
      expect(result!.isNotEmpty, isTrue);
      expect(result.contains('about-inspection'), isTrue);
    });

    test('survey_detail_provider safety: never filter sections to zero', () {
      final allSections = SectionTemplates.getInspectionSections();
      final Set<String> activeSectionTypes = <String>{}; // empty set (bug scenario)

      // FIXED logic: check isNotEmpty before filtering
      var sections = allSections;
      if (activeSectionTypes.isNotEmpty) {
        final filtered = allSections
            .where((t) => activeSectionTypes.contains(t.$1.apiSectionType))
            .toList();
        if (filtered.isNotEmpty) {
          sections = filtered;
        }
      }

      expect(sections.isNotEmpty, isTrue,
          reason: 'Sections must never be filtered to zero',);
      expect(sections.length, allSections.length,
          reason: 'With empty activeSectionTypes, all sections should remain',);
    });

    test('all inspection types produce non-zero sections with full config', () {
      final config = buildFullConfig();
      for (final surveyType in ['LEVEL_2', 'LEVEL_3', 'SNAGGING']) {
        final sections = buildSectionsFixed(
          backendSurveyType: surveyType,
          configSectionTypes: config,
        );
        expect(sections.isNotEmpty, isTrue,
            reason: '$surveyType must produce non-zero sections',);
        expect(sections.length, 11,
            reason: '$surveyType should have exactly 11 inspection sections (no legacy exterior/interior)',);
      }
    });

    test('VALUATION still works correctly after the fix', () {
      final config = buildFullConfig();
      final sections = buildSectionsFixed(
        backendSurveyType: 'VALUATION',
        configSectionTypes: config,
      );

      expect(sections.isNotEmpty, isTrue);
      final keys = sections.map((t) => t.$1.apiSectionType).toSet();
      expect(keys.contains('about-valuation'), isTrue);
      expect(keys.contains('about-inspection'), isFalse,
          reason: 'Valuation must NOT include inspection-only sections',);
    });
  });

  group('Legacy surveyTypes values (pre-normalization migration)', () {
    // SQL migrations seeded surveyTypes with legacy values: 'homebuyer',
    // 'building', 'valuation'. The runtime seed and normalization migration
    // convert these to 'LEVEL_2', 'LEVEL_3', 'VALUATION'. These tests
    // ensure filtering works regardless of which values are in the DB.

    /// Legacy alias map (same as in config_providers.dart).
    const legacyAliases = <String, String>{
      'homebuyer': 'LEVEL_2',
      'building': 'LEVEL_3',
      'valuation': 'VALUATION',
    };

    /// Simulates the FIXED activeSectionTypesForSurveyProvider logic
    /// that matches both canonical and legacy values.
    Set<String>? filterWithLegacySupport(
      String backendSurveyType,
      List<SectionTypeModel> sectionTypes,
    ) {
      final matchValues = <String>{backendSurveyType};
      for (final entry in legacyAliases.entries) {
        if (entry.value == backendSurveyType) {
          matchValues.add(entry.key);
        }
      }

      final filtered = sectionTypes
          .where((s) => s.isActive)
          .where((s) =>
              s.surveyTypes.isEmpty ||
              s.surveyTypes.any(matchValues.contains),)
          .map((s) => s.key)
          .toSet();

      return filtered.isEmpty ? null : filtered;
    }

    test('LEVEL_2 matches legacy "homebuyer" surveyTypes', () {
      final sectionTypes = [
        _makeSectionType(key: 'about-property', surveyTypes: ['homebuyer', 'building', 'valuation']),
        _makeSectionType(key: 'construction', surveyTypes: ['homebuyer', 'building']),
        _makeSectionType(key: 'about-valuation', surveyTypes: ['valuation']),
      ];

      final result = filterWithLegacySupport('LEVEL_2', sectionTypes);
      expect(result, isNotNull);
      expect(result, contains('about-property'));
      expect(result, contains('construction'));
      expect(result!.contains('about-valuation'), isFalse);
    });

    test('LEVEL_3 matches legacy "building" surveyTypes', () {
      final sectionTypes = [
        _makeSectionType(key: 'about-property', surveyTypes: ['homebuyer', 'building', 'valuation']),
        _makeSectionType(key: 'construction', surveyTypes: ['homebuyer', 'building']),
        _makeSectionType(key: 'about-valuation', surveyTypes: ['valuation']),
      ];

      final result = filterWithLegacySupport('LEVEL_3', sectionTypes);
      expect(result, isNotNull);
      expect(result, contains('about-property'));
      expect(result, contains('construction'));
      expect(result!.contains('about-valuation'), isFalse);
    });

    test('VALUATION matches legacy "valuation" surveyTypes', () {
      final sectionTypes = [
        _makeSectionType(key: 'about-property', surveyTypes: ['homebuyer', 'building', 'valuation']),
        _makeSectionType(key: 'construction', surveyTypes: ['homebuyer', 'building']),
        _makeSectionType(key: 'about-valuation', surveyTypes: ['valuation']),
      ];

      final result = filterWithLegacySupport('VALUATION', sectionTypes);
      expect(result, isNotNull);
      expect(result, contains('about-property'));
      expect(result, contains('about-valuation'));
      expect(result!.contains('construction'), isFalse);
    });

    test('canonical values still match after normalization migration', () {
      final sectionTypes = [
        _makeSectionType(key: 'about-property', surveyTypes: ['LEVEL_2', 'LEVEL_3', 'SNAGGING', 'VALUATION']),
        _makeSectionType(key: 'construction', surveyTypes: ['LEVEL_2', 'LEVEL_3', 'SNAGGING']),
        _makeSectionType(key: 'about-valuation', surveyTypes: ['VALUATION']),
      ];

      final result = filterWithLegacySupport('LEVEL_2', sectionTypes);
      expect(result, isNotNull);
      expect(result, contains('about-property'));
      expect(result, contains('construction'));
      expect(result!.contains('about-valuation'), isFalse);
    });

    test('full legacy DB config produces non-empty inspection filter', () {
      // Simulate a DB with ALL legacy values (as originally migrated)
      final legacyConfig = [
        _makeSectionType(key: 'about-inspection', surveyTypes: ['homebuyer', 'building']),
        _makeSectionType(key: 'about-property', surveyTypes: ['homebuyer', 'building', 'valuation']),
        _makeSectionType(key: 'construction', surveyTypes: ['homebuyer', 'building']),
        _makeSectionType(key: 'external-items', surveyTypes: ['homebuyer', 'building']),
        _makeSectionType(key: 'internal-items', surveyTypes: ['homebuyer', 'building']),
        _makeSectionType(key: 'rooms', surveyTypes: ['homebuyer', 'building']),
        _makeSectionType(key: 'services', surveyTypes: ['homebuyer', 'building']),
        _makeSectionType(key: 'issues-and-risks', surveyTypes: ['homebuyer', 'building']),
        _makeSectionType(key: 'photos', surveyTypes: ['homebuyer', 'building', 'valuation']),
        _makeSectionType(key: 'notes', surveyTypes: ['homebuyer', 'building', 'valuation']),
        _makeSectionType(key: 'signature', surveyTypes: ['homebuyer', 'building', 'valuation']),
        _makeSectionType(key: 'about-valuation', surveyTypes: ['valuation']),
        _makeSectionType(key: 'property-summary', surveyTypes: ['valuation']),
        _makeSectionType(key: 'market-analysis', surveyTypes: ['valuation']),
        _makeSectionType(key: 'comparables', surveyTypes: ['valuation']),
        _makeSectionType(key: 'adjustments', surveyTypes: ['valuation']),
        _makeSectionType(key: 'valuation', surveyTypes: ['valuation']),
        _makeSectionType(key: 'summary', surveyTypes: ['homebuyer', 'building', 'valuation']),
      ];

      final inspectionResult = filterWithLegacySupport('LEVEL_2', legacyConfig);
      expect(inspectionResult, isNotNull,
          reason: 'Legacy DB must produce non-null filter for LEVEL_2',);
      expect(inspectionResult!.length, greaterThanOrEqualTo(11),
          reason: 'LEVEL_2 should match at least 11 inspection+shared section types',);
      expect(inspectionResult.contains('about-valuation'), isFalse,
          reason: 'LEVEL_2 must not include valuation-only sections',);

      final valuationResult = filterWithLegacySupport('VALUATION', legacyConfig);
      expect(valuationResult, isNotNull,
          reason: 'Legacy DB must produce non-null filter for VALUATION',);
      expect(valuationResult!.contains('about-valuation'), isTrue);
      expect(valuationResult.contains('about-inspection'), isFalse,
          reason: 'VALUATION must not include inspection-only sections',);
    });

    test('SNAGGING falls back to show-all with legacy DB (no snagging alias)', () {
      // Legacy DB has no alias for SNAGGING, so no section types match.
      // The safety net should return null → show-all fallback.
      final legacyConfig = [
        _makeSectionType(key: 'about-property', surveyTypes: ['homebuyer', 'building', 'valuation']),
        _makeSectionType(key: 'construction', surveyTypes: ['homebuyer', 'building']),
      ];

      final result = filterWithLegacySupport('SNAGGING', legacyConfig);
      // SNAGGING has no legacy alias, so nothing matches → null (show-all)
      expect(result, isNull,
          reason: 'SNAGGING with legacy-only DB should return null (show-all fallback)',);
    });
  });

  group('Dynamic section type dropdown (field management)', () {
    test('hardcoded enum covers all known apiSectionType keys', () {
      // Ensure every SectionType enum has a unique apiSectionType
      final keys = SectionType.values.map((t) => t.apiSectionType).toSet();
      expect(keys.length, SectionType.values.length,
          reason: 'Every SectionType enum should have a unique apiSectionType',);
    });

    test('config section types with matching keys are not duplicated', () {
      // Simulate: config has section types that match hardcoded enums
      final hardcodedKeys = SectionType.values
          .map((t) => t.apiSectionType)
          .toSet();

      final configSectionTypes = [
        _makeSectionType(key: 'about-property'),  // matches enum
        _makeSectionType(key: 'custom-section'),   // does NOT match enum
        _makeSectionType(key: 'signature'),         // matches enum
      ];

      // The merged list should include hardcoded + only non-matching config types
      final dynamicKeys = configSectionTypes
          .where((st) => st.isActive && !hardcodedKeys.contains(st.key))
          .map((st) => st.key)
          .toList();

      expect(dynamicKeys, ['custom-section']);
      expect(dynamicKeys.contains('about-property'), isFalse,
          reason: 'Should not duplicate hardcoded keys',);
    });

    test('inactive config section types are excluded from dynamic list', () {
      final hardcodedKeys = SectionType.values
          .map((t) => t.apiSectionType)
          .toSet();

      final configSectionTypes = [
        _makeSectionType(key: 'custom-active'),
        _makeSectionType(key: 'custom-inactive', isActive: false),
      ];

      final dynamicKeys = configSectionTypes
          .where((st) => st.isActive && !hardcodedKeys.contains(st.key))
          .map((st) => st.key)
          .toList();

      expect(dynamicKeys, ['custom-active']);
      expect(dynamicKeys.contains('custom-inactive'), isFalse);
    });
  });
}
