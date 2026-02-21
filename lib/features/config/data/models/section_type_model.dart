class SectionTypeModel {
  const SectionTypeModel({
    required this.id,
    required this.key,
    required this.label,
    this.description,
    this.icon,
    required this.displayOrder,
    this.surveyTypes = const [],
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a SectionTypeModel from the simplified config/all response format.
  /// Config endpoint returns: { key, label, description?, icon?, isActive, displayOrder, surveyTypes }
  /// without an 'id' field.
  factory SectionTypeModel.fromConfigJson(Map<String, dynamic> json) =>
      SectionTypeModel(
        id: '', // Config endpoint doesn't include ID
        key: json['key'] as String,
        label: json['label'] as String,
        description: json['description'] as String?,
        icon: json['icon'] as String?,
        displayOrder:
            json['displayOrder'] as int? ?? json['display_order'] as int? ?? 0,
        surveyTypes: (json['surveyTypes'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        isActive:
            json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(
          json['createdAt'] as String? ??
              json['created_at'] as String? ??
              DateTime.now().toIso8601String(),
        ),
        updatedAt: DateTime.parse(
          json['updatedAt'] as String? ??
              json['updated_at'] as String? ??
              DateTime.now().toIso8601String(),
        ),
      );

  factory SectionTypeModel.fromJson(Map<String, dynamic> json) =>
      SectionTypeModel(
        id: json['id'] as String,
        key: json['key'] as String,
        label: json['label'] as String,
        description: json['description'] as String?,
        icon: json['icon'] as String?,
        displayOrder:
            json['displayOrder'] as int? ?? json['display_order'] as int? ?? 0,
        surveyTypes: (json['surveyTypes'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        isActive:
            json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(
          json['createdAt'] as String? ??
              json['created_at'] as String? ??
              DateTime.now().toIso8601String(),
        ),
        updatedAt: DateTime.parse(
          json['updatedAt'] as String? ??
              json['updated_at'] as String? ??
              DateTime.now().toIso8601String(),
        ),
      );

  final String id;
  final String key;
  final String label;
  final String? description;
  final String? icon;
  final int displayOrder;
  final List<String> surveyTypes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SectionTypeModel copyWith({
    String? id,
    String? key,
    String? label,
    String? description,
    String? icon,
    int? displayOrder,
    List<String>? surveyTypes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      SectionTypeModel(
        id: id ?? this.id,
        key: key ?? this.key,
        label: label ?? this.label,
        description: description ?? this.description,
        icon: icon ?? this.icon,
        displayOrder: displayOrder ?? this.displayOrder,
        surveyTypes: surveyTypes ?? this.surveyTypes,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  static List<SectionTypeModel> fromJsonList(List<dynamic> jsonList) =>
      jsonList.map((json) {
        final map = json as Map<String, dynamic>;
        // Config endpoint returns simplified format without id
        if (!map.containsKey('id')) {
          return SectionTypeModel.fromConfigJson(map);
        }
        return SectionTypeModel.fromJson(map);
      }).toList();
}
