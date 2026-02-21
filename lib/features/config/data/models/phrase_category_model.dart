import '../../domain/entities/phrase_category.dart';
import 'phrase_model.dart';

class PhraseCategoryModel extends PhraseCategory {
  const PhraseCategoryModel({
    required super.id,
    required super.slug,
    required super.displayName,
    super.description,
    required super.isSystem,
    required super.isActive,
    required super.displayOrder,
    super.phrases = const [],
  });

  /// Creates a PhraseCategoryModel from the simplified config/all response format
  /// Config endpoint returns: { slug, displayName, phrases: string[] }
  factory PhraseCategoryModel.fromConfigJson(Map<String, dynamic> json) {
    final phrasesJson = json['phrases'] as List<dynamic>?;

    return PhraseCategoryModel(
      id: '', // Config endpoint doesn't include ID
      slug: json['slug'] as String,
      displayName: json['displayName'] as String? ?? json['display_name'] as String? ?? '',
      isSystem: false,
      isActive: true,
      displayOrder: 0,
      // Config endpoint returns phrases as List<String>, not List<Phrase>
      phrases: phrasesJson?.map((v) => PhraseModel(
        id: '',
        categoryId: '',
        value: v is String ? v : (v as Map<String, dynamic>)['value'] as String? ?? '',
        displayOrder: 0,
        isActive: true,
        isDefault: false,
      ),).toList() ?? const [],
    );
  }

  factory PhraseCategoryModel.fromJson(Map<String, dynamic> json) {
    final phrasesJson = json['phrases'] as List<dynamic>?;

    return PhraseCategoryModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      displayName: json['displayName'] as String? ?? json['display_name'] as String? ?? '',
      description: json['description'] as String?,
      isSystem: json['isSystem'] as bool? ?? json['is_system'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      displayOrder: json['displayOrder'] as int? ?? json['display_order'] as int? ?? 0,
      phrases: phrasesJson != null ? PhraseModel.fromJsonList(phrasesJson) : const [],
    );
  }

  Map<String, dynamic> toJson() => {
      'id': id,
      'slug': slug,
      'displayName': displayName,
      if (description != null) 'description': description,
      'isSystem': isSystem,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'phrases': phrases.map((p) => (p as PhraseModel).toJson()).toList(),
    };

  static List<PhraseCategoryModel> fromJsonList(List<dynamic> jsonList) => jsonList.map((json) {
      final map = json as Map<String, dynamic>;
      // Config endpoint returns simplified format without id
      if (!map.containsKey('id')) {
        return PhraseCategoryModel.fromConfigJson(map);
      }
      return PhraseCategoryModel.fromJson(map);
    }).toList();
}
