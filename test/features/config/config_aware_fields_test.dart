import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/config/data/models/section_type_model.dart';
import 'package:survey_scriber/features/config/domain/entities/config_version.dart';
import 'package:survey_scriber/features/config/domain/entities/field_definition.dart';
import 'package:survey_scriber/features/config/presentation/helpers/config_aware_fields.dart';
import 'package:survey_scriber/features/config/presentation/providers/config_providers.dart';
import 'package:survey_scriber/shared/domain/entities/survey_section.dart';

void main() {
  final loadedEmptyConfig = ConfigState(
    version: ConfigVersion(version: 1, updatedAt: DateTime(2024)),
    sectionTypes: [
      SectionTypeModel(
        id: '1',
        key: 'construction',
        label: 'Construction',
        displayOrder: 1,
        isActive: true,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ),
    ],
  );

  final loadedWithApiFields = ConfigState(
    version: ConfigVersion(version: 2, updatedAt: DateTime(2024)),
    fields: [
      const FieldDefinition(
        id: 'f1',
        sectionType: 'construction',
        fieldKey: 'general_notes',
        fieldType: FieldType.textarea,
        label: 'General Notes',
        isRequired: false,
        displayOrder: 1,
        isActive: true,
      ),
      const FieldDefinition(
        id: 'f2',
        sectionType: 'construction',
        fieldKey: 'defects_noted',
        fieldType: FieldType.textarea,
        label: 'Defects Noted',
        isRequired: false,
        displayOrder: 2,
        isActive: true,
      ),
      const FieldDefinition(
        id: 'f3',
        sectionType: 'services',
        fieldKey: 'electrical_notes',
        fieldType: FieldType.text,
        label: 'Electrical Notes',
        isRequired: false,
        displayOrder: 1,
        isActive: true,
      ),
    ],
    sectionTypes: [
      SectionTypeModel(
        id: '1',
        key: 'construction',
        label: 'Construction',
        displayOrder: 1,
        isActive: true,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ),
    ],
  );

  group('ConfigAwareSectionFields.getFields', () {
    test('returns empty when config is not loaded', () {
      const unloaded = ConfigState();
      final fields = ConfigAwareSectionFields.getFields(
        SectionType.construction,
        unloaded,
      );
      expect(fields, isEmpty);
    });

    test('returns empty when config is loaded but has no fields for section', () {
      final fields = ConfigAwareSectionFields.getFields(
        SectionType.construction,
        loadedEmptyConfig,
      );
      expect(fields, isEmpty);
    });

    test('returns API fields for matching section', () {
      final fields = ConfigAwareSectionFields.getFields(
        SectionType.construction,
        loadedWithApiFields,
      );
      expect(fields.length, 2);
      expect(fields[0].fieldKey, 'general_notes');
      expect(fields[1].fieldKey, 'defects_noted');
    });

    test('only returns fields for the requested section', () {
      final construction = ConfigAwareSectionFields.getFields(
        SectionType.construction,
        loadedWithApiFields,
      );
      final services = ConfigAwareSectionFields.getFields(
        SectionType.services,
        loadedWithApiFields,
      );
      expect(construction.length, 2);
      expect(services.length, 1);
      expect(services.first.fieldKey, 'electrical_notes');
    });

    test('excludes inactive fields', () {
      final configWithInactive = ConfigState(
        version: ConfigVersion(version: 1, updatedAt: DateTime(2024)),
        fields: [
          const FieldDefinition(
            id: 'f1',
            sectionType: 'construction',
            fieldKey: 'active_field',
            fieldType: FieldType.text,
            label: 'Active',
            isRequired: false,
            displayOrder: 1,
            isActive: true,
          ),
          const FieldDefinition(
            id: 'f2',
            sectionType: 'construction',
            fieldKey: 'inactive_field',
            fieldType: FieldType.text,
            label: 'Inactive',
            isRequired: false,
            displayOrder: 2,
            isActive: false,
          ),
        ],
      );

      final fields = ConfigAwareSectionFields.getFields(
        SectionType.construction,
        configWithInactive,
      );
      expect(fields.length, 1);
      expect(fields.first.fieldKey, 'active_field');
    });

    test('sorts fields by displayOrder', () {
      final configUnordered = ConfigState(
        version: ConfigVersion(version: 1, updatedAt: DateTime(2024)),
        fields: [
          const FieldDefinition(
            id: 'f1',
            sectionType: 'construction',
            fieldKey: 'second',
            fieldType: FieldType.text,
            label: 'Second',
            isRequired: false,
            displayOrder: 10,
            isActive: true,
          ),
          const FieldDefinition(
            id: 'f2',
            sectionType: 'construction',
            fieldKey: 'first',
            fieldType: FieldType.text,
            label: 'First',
            isRequired: false,
            displayOrder: 1,
            isActive: true,
          ),
        ],
      );

      final fields = ConfigAwareSectionFields.getFields(
        SectionType.construction,
        configUnordered,
      );
      expect(fields[0].fieldKey, 'first');
      expect(fields[1].fieldKey, 'second');
    });
  });

  group('SectionTypeMapper', () {
    test('maps all SectionType values to non-empty API keys', () {
      for (final type in SectionType.values) {
        expect(type.apiSectionType, isNotEmpty,
            reason: '${type.name} should have an API key');
      }
    });

    test('uses kebab-case for API keys', () {
      for (final type in SectionType.values) {
        final key = type.apiSectionType;
        expect(key, matches(RegExp(r'^[a-z][a-z0-9-]*$')),
            reason: '${type.name} key "$key" should be kebab-case');
      }
    });
  });

  group('sectionTypeFromApiKey', () {
    test('round-trips through mapper', () {
      for (final type in SectionType.values) {
        final key = type.apiSectionType;
        final resolved = sectionTypeFromApiKey(key);
        expect(resolved, type, reason: 'Key "$key" should resolve back to ${type.name}');
      }
    });

    test('returns null for unknown key', () {
      expect(sectionTypeFromApiKey('unknown-section'), isNull);
    });
  });
}
