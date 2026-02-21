import '../../domain/entities/config_version.dart';
import '../../domain/entities/field_definition.dart';
import '../../domain/entities/phrase_category.dart';
import 'config_version_model.dart';
import 'field_definition_model.dart';
import 'phrase_category_model.dart';
import 'section_type_model.dart';

class FullConfigModel {
  const FullConfigModel({
    required this.version,
    required this.categories,
    required this.fields,
    this.sectionTypes = const [],
  });

  factory FullConfigModel.fromJson(Map<String, dynamic> json) {
    // Backend returns version/updatedAt at top level (int + String),
    // but cache toJson() nests them as { version: { version: int, updatedAt: String } }.
    // Handle both formats.
    final versionData = json['version'];
    final ConfigVersionModel version;
    if (versionData is Map<String, dynamic>) {
      // Cached format: nested object
      version = ConfigVersionModel.fromJson(versionData);
    } else {
      // Server format: top-level int
      version = ConfigVersionModel(
        version: versionData as int? ?? 1,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
      );
    }

    // Backend returns fields grouped by section: { sectionType: [...fields] }
    // Flatten to a single list for local use
    final fieldsData = json['fields'];
    var fields = <FieldDefinition>[];
    if (fieldsData is Map<String, dynamic>) {
      for (final entry in fieldsData.entries) {
        final sectionType = entry.key;
        final sectionFields = entry.value as List<dynamic>? ?? [];
        for (final fieldJson in sectionFields) {
          if (fieldJson is Map<String, dynamic>) {
            fields.add(FieldDefinitionModel.fromConfigJson(fieldJson, sectionType));
          }
        }
      }
    } else if (fieldsData is List<dynamic>) {
      fields = FieldDefinitionModel.fromJsonList(fieldsData);
    }

    // Parse section types
    final sectionTypesData = json['sectionTypes'] as List<dynamic>? ?? [];
    final sectionTypes = SectionTypeModel.fromJsonList(sectionTypesData);

    return FullConfigModel(
      version: version,
      categories: PhraseCategoryModel.fromJsonList(json['categories'] as List<dynamic>? ?? []),
      fields: fields,
      sectionTypes: sectionTypes,
    );
  }

  final ConfigVersion version;
  final List<PhraseCategory> categories;
  final List<FieldDefinition> fields;
  final List<SectionTypeModel> sectionTypes;

  Map<String, dynamic> toJson() => {
      'version': (version as ConfigVersionModel).toJson(),
      'categories': categories.map((c) => (c as PhraseCategoryModel).toJson()).toList(),
      'fields': fields.map((f) => (f as FieldDefinitionModel).toJson()).toList(),
      'sectionTypes': sectionTypes.map((s) => <String, dynamic>{
        'id': s.id,
        'key': s.key,
        'label': s.label,
        'description': s.description,
        'icon': s.icon,
        'displayOrder': s.displayOrder,
        'surveyTypes': s.surveyTypes,
        'isActive': s.isActive,
        'createdAt': s.createdAt.toIso8601String(),
        'updatedAt': s.updatedAt.toIso8601String(),
      }).toList(),
    };
}
