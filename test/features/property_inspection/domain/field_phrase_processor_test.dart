import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/field_phrase_processor.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';

void main() {
  group('FieldPhraseProcessor', () {
    test('returns empty list when no fields have phraseTemplate', () {
      final fields = [
        const InspectionFieldDefinition(
          id: 'field_1',
          label: 'Field One',
          type: InspectionFieldType.text,
        ),
        const InspectionFieldDefinition(
          id: 'field_2',
          label: 'Field Two',
          type: InspectionFieldType.dropdown,
          options: ['A', 'B'],
        ),
      ];

      final result = FieldPhraseProcessor.buildFieldPhrases(fields, {
        'field_1': 'some value',
        'field_2': 'A',
      });

      expect(result, isEmpty);
    });

    test('resolves {fieldId} placeholders with answer values', () {
      final fields = [
        const InspectionFieldDefinition(
          id: 'condition_rating',
          label: 'Condition Rating',
          type: InspectionFieldType.dropdown,
          options: ['1', '2', '3'],
          phraseTemplate:
              'The roof was observed to be in condition {condition_rating}.',
        ),
      ];

      final result = FieldPhraseProcessor.buildFieldPhrases(fields, {
        'condition_rating': '2',
      });

      expect(result, hasLength(1));
      expect(result.first, 'The roof was observed to be in condition 2.');
    });

    test('resolves multiple placeholders', () {
      final fields = [
        const InspectionFieldDefinition(
          id: 'main_wall_type',
          label: 'Main Wall Type',
          type: InspectionFieldType.text,
          phraseTemplate:
              'The {main_wall_type} walls are in {wall_condition} condition.',
        ),
      ];

      final result = FieldPhraseProcessor.buildFieldPhrases(fields, {
        'main_wall_type': 'brick',
        'wall_condition': 'satisfactory',
      });

      expect(result, hasLength(1));
      expect(result.first,
          'The brick walls are in satisfactory condition.');
    });

    test('skips templates when no placeholders resolve', () {
      final fields = [
        const InspectionFieldDefinition(
          id: 'field_1',
          label: 'Field',
          type: InspectionFieldType.text,
          phraseTemplate: 'The condition is {some_field}.',
        ),
      ];

      final result = FieldPhraseProcessor.buildFieldPhrases(fields, {});
      expect(result, isEmpty);
    });

    test('skips empty and whitespace-only templates', () {
      final fields = [
        const InspectionFieldDefinition(
          id: 'field_1',
          label: 'Field',
          type: InspectionFieldType.text,
          phraseTemplate: '',
        ),
        const InspectionFieldDefinition(
          id: 'field_2',
          label: 'Field',
          type: InspectionFieldType.text,
          phraseTemplate: '   ',
        ),
      ];

      final result = FieldPhraseProcessor.buildFieldPhrases(fields, {
        'field_1': 'value',
      });
      expect(result, isEmpty);
    });

    test('skips hidden conditional fields', () {
      final fields = [
        const InspectionFieldDefinition(
          id: 'show_details',
          label: 'Show Details',
          type: InspectionFieldType.checkbox,
        ),
        const InspectionFieldDefinition(
          id: 'details_text',
          label: 'Details',
          type: InspectionFieldType.text,
          conditionalOn: 'show_details',
          conditionalValue: 'true',
          phraseTemplate: 'Details: {details_text}',
        ),
      ];

      // Conditional not met — checkbox not checked
      final result = FieldPhraseProcessor.buildFieldPhrases(fields, {
        'show_details': '',
        'details_text': 'Some detail',
      });
      expect(result, isEmpty);

      // Conditional met — checkbox checked
      final result2 = FieldPhraseProcessor.buildFieldPhrases(fields, {
        'show_details': 'true',
        'details_text': 'Some detail',
      });
      expect(result2, hasLength(1));
      expect(result2.first, 'Details: Some detail');
    });

    test('handles conditional hide mode', () {
      final fields = [
        const InspectionFieldDefinition(
          id: 'status',
          label: 'Status',
          type: InspectionFieldType.dropdown,
          options: ['active', 'inactive'],
          conditionalOn: 'toggle',
          conditionalValue: 'hide_me',
          conditionalMode: 'hide',
          phraseTemplate: 'Status is {status}.',
        ),
      ];

      // Value matches hide condition → field hidden
      final result = FieldPhraseProcessor.buildFieldPhrases(fields, {
        'toggle': 'hide_me',
        'status': 'active',
      });
      expect(result, isEmpty);

      // Value does NOT match hide condition → field visible
      final result2 = FieldPhraseProcessor.buildFieldPhrases(fields, {
        'toggle': 'show_me',
        'status': 'active',
      });
      expect(result2, hasLength(1));
      expect(result2.first, 'Status is active.');
    });

    test('multiple fields with templates produce multiple phrases', () {
      final fields = [
        const InspectionFieldDefinition(
          id: 'roof_type',
          label: 'Roof Type',
          type: InspectionFieldType.text,
          phraseTemplate: 'The roof is of {roof_type} construction.',
        ),
        const InspectionFieldDefinition(
          id: 'roof_condition',
          label: 'Condition',
          type: InspectionFieldType.dropdown,
          options: ['1', '2', '3'],
          phraseTemplate: 'Roof condition rating: {roof_condition}.',
        ),
      ];

      final result = FieldPhraseProcessor.buildFieldPhrases(fields, {
        'roof_type': 'slate',
        'roof_condition': '2',
      });

      expect(result, hasLength(2));
      expect(result[0], 'The roof is of slate construction.');
      expect(result[1], 'Roof condition rating: 2.');
    });

    test('collapses multiple spaces from empty placeholders', () {
      final fields = [
        const InspectionFieldDefinition(
          id: 'field_a',
          label: 'A',
          type: InspectionFieldType.text,
          phraseTemplate: 'Value is {field_a} and {field_b} here.',
        ),
      ];

      final result = FieldPhraseProcessor.buildFieldPhrases(fields, {
        'field_a': 'present',
        'field_b': '',
      });

      // field_b resolves to empty, so "and  here" → "and here"
      expect(result, hasLength(1));
      expect(result.first, 'Value is present and here.');
    });
  });

  group('InspectionFieldDefinition.phraseTemplate', () {
    test('serializes to JSON when set', () {
      const field = InspectionFieldDefinition(
        id: 'test_field',
        label: 'Test',
        type: InspectionFieldType.text,
        phraseTemplate: 'The value is {test_field}.',
      );

      final json = field.toJson();
      expect(json['phraseTemplate'], 'The value is {test_field}.');
    });

    test('omits from JSON when null', () {
      const field = InspectionFieldDefinition(
        id: 'test_field',
        label: 'Test',
        type: InspectionFieldType.text,
      );

      final json = field.toJson();
      expect(json.containsKey('phraseTemplate'), isFalse);
    });

    test('deserializes from JSON', () {
      final field = InspectionFieldDefinition.fromJson({
        'id': 'test_field',
        'label': 'Test',
        'type': 'text',
        'phraseTemplate': 'Template text here.',
      });

      expect(field.phraseTemplate, 'Template text here.');
    });

    test('copyWith preserves phraseTemplate', () {
      const field = InspectionFieldDefinition(
        id: 'test_field',
        label: 'Test',
        type: InspectionFieldType.text,
        phraseTemplate: 'Original template.',
      );

      final updated = field.copyWith(label: 'Updated Test');
      expect(updated.phraseTemplate, 'Original template.');
      expect(updated.label, 'Updated Test');
    });

    test('copyWith replaces phraseTemplate', () {
      const field = InspectionFieldDefinition(
        id: 'test_field',
        label: 'Test',
        type: InspectionFieldType.text,
        phraseTemplate: 'Original.',
      );

      final updated = field.copyWith(phraseTemplate: 'New template.');
      expect(updated.phraseTemplate, 'New template.');
    });
  });
}
