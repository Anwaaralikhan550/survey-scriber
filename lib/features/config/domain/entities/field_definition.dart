import 'package:equatable/equatable.dart';
import 'phrase.dart';

enum FieldType {
  text,
  number,
  dropdown,
  radio,
  checkbox,
  date,
  signature,
  textarea;

  static FieldType fromString(String value) => FieldType.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => FieldType.text,
    );
}

class FieldDefinition extends Equatable {
  const FieldDefinition({
    required this.id,
    required this.sectionType,
    required this.fieldKey,
    required this.fieldType,
    required this.label,
    this.placeholder,
    this.helperText,
    required this.isRequired,
    required this.displayOrder,
    required this.isActive,
    this.validationRules,
    this.phraseCategoryId,
    this.phraseCategorySlug,
    this.options = const [],
    this.fieldGroup,
    this.conditionalOn,
    this.conditionalValue,
    this.description,
  });

  final String id;
  final String sectionType;
  final String fieldKey;
  final FieldType fieldType;
  final String label;
  final String? placeholder;
  final String? helperText;
  final bool isRequired;
  final int displayOrder;
  final bool isActive;
  final Map<String, dynamic>? validationRules;
  final String? phraseCategoryId;
  final String? phraseCategorySlug;
  final List<Phrase> options;
  final String? fieldGroup;
  final String? conditionalOn;
  final String? conditionalValue;
  final String? description;

  @override
  List<Object?> get props => [
        id,
        sectionType,
        fieldKey,
        fieldType,
        label,
        placeholder,
        helperText,
        isRequired,
        displayOrder,
        isActive,
        validationRules,
        phraseCategoryId,
        phraseCategorySlug,
        options,
        fieldGroup,
        conditionalOn,
        conditionalValue,
        description,
      ];

  FieldDefinition copyWith({
    String? id,
    String? sectionType,
    String? fieldKey,
    FieldType? fieldType,
    String? label,
    String? placeholder,
    String? helperText,
    bool? isRequired,
    int? displayOrder,
    bool? isActive,
    Map<String, dynamic>? validationRules,
    String? phraseCategoryId,
    String? phraseCategorySlug,
    List<Phrase>? options,
    String? fieldGroup,
    String? conditionalOn,
    String? conditionalValue,
    String? description,
  }) => FieldDefinition(
      id: id ?? this.id,
      sectionType: sectionType ?? this.sectionType,
      fieldKey: fieldKey ?? this.fieldKey,
      fieldType: fieldType ?? this.fieldType,
      label: label ?? this.label,
      placeholder: placeholder ?? this.placeholder,
      helperText: helperText ?? this.helperText,
      isRequired: isRequired ?? this.isRequired,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      validationRules: validationRules ?? this.validationRules,
      phraseCategoryId: phraseCategoryId ?? this.phraseCategoryId,
      phraseCategorySlug: phraseCategorySlug ?? this.phraseCategorySlug,
      options: options ?? this.options,
      fieldGroup: fieldGroup ?? this.fieldGroup,
      conditionalOn: conditionalOn ?? this.conditionalOn,
      conditionalValue: conditionalValue ?? this.conditionalValue,
      description: description ?? this.description,
    );

  /// Get options as simple string list for dropdowns/radios
  List<String> get optionValues => options.map((p) => p.value).toList();
}
