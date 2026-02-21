import '../../domain/entities/field_definition.dart';
import 'phrase_model.dart';

class FieldDefinitionModel extends FieldDefinition {
  const FieldDefinitionModel({
    required super.id,
    required super.sectionType,
    required super.fieldKey,
    required super.fieldType,
    required super.label,
    super.placeholder,
    super.helperText,
    required super.isRequired,
    required super.displayOrder,
    required super.isActive,
    super.validationRules,
    super.phraseCategoryId,
    super.phraseCategorySlug,
    super.options = const [],
    super.fieldGroup,
    super.conditionalOn,
    super.conditionalValue,
    super.description,
  });

  /// Creates a FieldDefinitionModel from the simplified config/all response format
  /// Config endpoint returns: { key, label, type, hint, placeholder, required, options, group, conditionalOn, conditionalValue, description }
  factory FieldDefinitionModel.fromConfigJson(Map<String, dynamic> json, String sectionType) {
    final optionsJson = json['options'] as List<dynamic>?;

    return FieldDefinitionModel(
      id: '', // Config endpoint doesn't include ID
      sectionType: sectionType,
      fieldKey: json['key'] as String? ?? '',
      fieldType: FieldType.fromString(json['type'] as String? ?? 'TEXT'),
      label: json['label'] as String? ?? '',
      placeholder: json['placeholder'] as String?,
      helperText: json['hint'] as String?,
      isRequired: json['required'] as bool? ?? false,
      displayOrder: 0, // Not included in config response
      isActive: true,
      fieldGroup: json['group'] as String?,
      conditionalOn: json['conditionalOn'] as String?,
      conditionalValue: json['conditionalValue'] as String?,
      description: json['description'] as String?,
      // Config endpoint returns options as List<String>, not List<Phrase>
      options: optionsJson?.map((v) => PhraseModel(
        id: '',
        categoryId: '',
        value: v as String,
        displayOrder: 0,
        isActive: true,
        isDefault: false,
      ),).toList() ?? const [],
    );
  }

  factory FieldDefinitionModel.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['options'] as List<dynamic>?;
    final phraseCategory = json['phraseCategory'] as Map<String, dynamic>?;

    return FieldDefinitionModel(
      id: json['id'] as String,
      sectionType: json['sectionType'] as String? ?? json['section_type'] as String? ?? '',
      fieldKey: json['fieldKey'] as String? ?? json['field_key'] as String? ?? '',
      fieldType: FieldType.fromString(
        json['fieldType'] as String? ?? json['field_type'] as String? ?? 'TEXT',
      ),
      label: json['label'] as String,
      placeholder: json['placeholder'] as String?,
      helperText: json['helperText'] as String? ?? json['helper_text'] as String?,
      isRequired: json['isRequired'] as bool? ?? json['is_required'] as bool? ?? false,
      displayOrder: json['displayOrder'] as int? ?? json['display_order'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      validationRules: json['validationRules'] as Map<String, dynamic>? ??
                       json['validation_rules'] as Map<String, dynamic>?,
      phraseCategoryId: json['phraseCategoryId'] as String? ??
                        json['phrase_category_id'] as String?,
      phraseCategorySlug: phraseCategory?['slug'] as String?,
      options: optionsJson != null ? PhraseModel.fromJsonList(optionsJson) : const [],
      fieldGroup: json['fieldGroup'] as String? ?? json['field_group'] as String?,
      conditionalOn: json['conditionalOn'] as String? ?? json['conditional_on'] as String?,
      conditionalValue: json['conditionalValue'] as String? ?? json['conditional_value'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
      'id': id,
      'sectionType': sectionType,
      'fieldKey': fieldKey,
      'fieldType': fieldType.name.toUpperCase(),
      'label': label,
      if (placeholder != null) 'placeholder': placeholder,
      if (helperText != null) 'helperText': helperText,
      'isRequired': isRequired,
      'displayOrder': displayOrder,
      'isActive': isActive,
      if (validationRules != null) 'validationRules': validationRules,
      if (phraseCategoryId != null) 'phraseCategoryId': phraseCategoryId,
      if (fieldGroup != null) 'fieldGroup': fieldGroup,
      if (conditionalOn != null) 'conditionalOn': conditionalOn,
      if (conditionalValue != null) 'conditionalValue': conditionalValue,
      if (description != null) 'description': description,
    };

  static List<FieldDefinitionModel> fromJsonList(List<dynamic> jsonList) => jsonList
        .map((json) => FieldDefinitionModel.fromJson(json as Map<String, dynamic>))
        .toList();
}
