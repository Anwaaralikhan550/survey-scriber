import '../../domain/entities/phrase.dart';

class PhraseModel extends Phrase {
  const PhraseModel({
    required super.id,
    required super.categoryId,
    required super.value,
    required super.displayOrder,
    required super.isActive,
    required super.isDefault,
    super.metadata,
  });

  factory PhraseModel.fromJson(Map<String, dynamic> json) => PhraseModel(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String? ?? json['category_id'] as String? ?? '',
      value: json['value'] as String,
      displayOrder: json['displayOrder'] as int? ?? json['display_order'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      isDefault: json['isDefault'] as bool? ?? json['is_default'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

  Map<String, dynamic> toJson() => {
      'id': id,
      'categoryId': categoryId,
      'value': value,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'isDefault': isDefault,
      if (metadata != null) 'metadata': metadata,
    };

  static List<PhraseModel> fromJsonList(List<dynamic> jsonList) => jsonList
        .map((json) => PhraseModel.fromJson(json as Map<String, dynamic>))
        .toList();
}
