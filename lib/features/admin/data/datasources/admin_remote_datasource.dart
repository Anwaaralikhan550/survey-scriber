import '../../../../core/network/api_client.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../config/data/models/field_definition_model.dart';
import '../../../config/data/models/phrase_category_model.dart';
import '../../../config/data/models/phrase_model.dart';
import '../../../config/data/models/section_type_model.dart';
import '../../../config/domain/entities/field_definition.dart';

/// User data for admin management
class AdminUserDto {
  const AdminUserDto({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory AdminUserDto.fromJson(Map<String, dynamic> json) => AdminUserDto(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String? ?? json['first_name'] as String?,
      lastName: json['lastName'] as String? ?? json['last_name'] as String?,
      role: _parseRole(json['role'] as String? ?? 'SURVEYOR'),
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  static UserRole _parseRole(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'MANAGER':
        return UserRole.manager;
      case 'SURVEYOR':
        return UserRole.surveyor;
      case 'VIEWER':
        return UserRole.viewer;
      default:
        return UserRole.surveyor;
    }
  }

  String get fullName {
    if (firstName == null && lastName == null) return email;
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }

  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    return email.substring(0, 2).toUpperCase();
  }
}

abstract class AdminRemoteDataSource {
  /// Get all users
  Future<List<AdminUserDto>> getUsers();

  /// Update user role
  Future<AdminUserDto> updateUserRole(String userId, UserRole newRole);

  // ============================================
  // Phrase Management
  // ============================================

  /// Get all categories (with includeInactive option)
  Future<List<PhraseCategoryModel>> getCategories({bool includeInactive = false});

  /// Create a new phrase category
  Future<PhraseCategoryModel> createCategory({
    required String slug,
    required String displayName,
    String? description,
    bool? isSystem,
  });

  /// Update an existing phrase category
  Future<PhraseCategoryModel> updateCategory(
    String categoryId, {
    String? displayName,
    String? description,
    bool? isActive,
  });

  /// Delete (soft) a phrase category
  Future<void> deleteCategory(String categoryId);

  /// Restore a soft-deleted phrase category
  Future<void> restoreCategory(String categoryId);

  /// Get phrases for a category
  Future<List<PhraseModel>> getPhrases(String categoryId, {bool includeInactive = false});

  /// Create a new phrase
  Future<PhraseModel> createPhrase({
    required String categoryId,
    required String value,
    int? displayOrder,
    bool? isDefault,
  });

  /// Update an existing phrase
  Future<PhraseModel> updatePhrase(
    String phraseId, {
    String? value,
    int? displayOrder,
    bool? isActive,
    bool? isDefault,
  });

  /// Delete (soft) a phrase
  Future<void> deletePhrase(String phraseId);

  /// Reorder phrases within a category
  Future<void> reorderPhrases(String categoryId, List<String> phraseIds);

  // ============================================
  // Field Definition Management
  // ============================================

  /// Get all field definitions
  Future<List<FieldDefinitionModel>> getFields({bool includeInactive = false});

  /// Get fields for a specific section
  Future<List<FieldDefinitionModel>> getFieldsBySection(String sectionType);

  /// Create a new field definition
  Future<FieldDefinitionModel> createField({
    required String sectionType,
    required String fieldKey,
    required FieldType fieldType,
    required String label,
    String? placeholder,
    String? hint,
    bool? isRequired,
    int? displayOrder,
    String? phraseCategoryId,
    Map<String, dynamic>? validationRules,
    int? maxLines,
    String? fieldGroup,
    String? conditionalOn,
    String? conditionalValue,
    String? description,
  });

  /// Update an existing field definition
  Future<FieldDefinitionModel> updateField(
    String fieldId, {
    FieldType? fieldType,
    String? label,
    String? placeholder,
    String? hint,
    bool? isRequired,
    int? displayOrder,
    String? phraseCategoryId,
    Map<String, dynamic>? validationRules,
    int? maxLines,
    String? fieldGroup,
    String? conditionalOn,
    String? conditionalValue,
    String? description,
    bool? isActive,
  });

  /// Delete (soft) a field definition
  Future<void> deleteField(String fieldId);

  /// Reorder fields within a section
  Future<void> reorderFields(String sectionType, List<String> fieldIds);

  // ============================================
  // Section Type Definition Management
  // ============================================

  /// Get all section type definitions
  Future<List<SectionTypeModel>> getSectionTypes({bool includeInactive = false});

  /// Create a new section type definition
  Future<SectionTypeModel> createSectionType({
    required String key,
    required String label,
    String? description,
    String? icon,
    int? displayOrder,
    List<String>? surveyTypes,
  });

  /// Update an existing section type definition
  Future<SectionTypeModel> updateSectionType(
    String sectionTypeId, {
    String? label,
    String? description,
    String? icon,
    int? displayOrder,
    List<String>? surveyTypes,
    bool? isActive,
  });

  /// Delete (soft) a section type definition
  Future<void> deleteSectionType(String sectionTypeId);

  /// Restore a soft-deleted section type definition
  Future<void> restoreSectionType(String sectionTypeId);

  /// Reorder section type definitions
  Future<void> reorderSectionTypes(List<String> sectionTypeIds);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  const AdminRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<AdminUserDto>> getUsers() async {
    // Backend returns paginated response: { data: [...], meta: {...} }
    final response = await _apiClient.get<Map<String, dynamic>>('admin/config/users');
    final responseData = response.data!;
    final usersList = responseData['data'] as List<dynamic>? ?? [];
    return usersList
        .map((json) => AdminUserDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AdminUserDto> updateUserRole(String userId, UserRole newRole) async {
    final roleString = newRole.name.toUpperCase();
    final response = await _apiClient.put<Map<String, dynamic>>(
      'admin/config/users/$userId/role',
      data: {'role': roleString},
    );
    return AdminUserDto.fromJson(response.data!);
  }

  // ============================================
  // Phrase Management Implementation
  // ============================================

  @override
  Future<List<PhraseCategoryModel>> getCategories({bool includeInactive = false}) async {
    final queryParams = includeInactive ? '?includeInactive=true' : '';
    final response = await _apiClient.get<List<dynamic>>(
      'admin/config/categories$queryParams',
    );
    return response.data!
        .map((json) => PhraseCategoryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PhraseCategoryModel> createCategory({
    required String slug,
    required String displayName,
    String? description,
    bool? isSystem,
  }) async {
    final data = <String, dynamic>{
      'slug': slug,
      'displayName': displayName,
    };
    if (description != null) data['description'] = description;
    if (isSystem != null) data['isSystem'] = isSystem;

    final response = await _apiClient.post<Map<String, dynamic>>(
      'admin/config/categories',
      data: data,
    );
    return PhraseCategoryModel.fromJson(response.data!);
  }

  @override
  Future<PhraseCategoryModel> updateCategory(
    String categoryId, {
    String? displayName,
    String? description,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['displayName'] = displayName;
    if (description != null) data['description'] = description;
    if (isActive != null) data['isActive'] = isActive;

    final response = await _apiClient.put<Map<String, dynamic>>(
      'admin/config/categories/$categoryId',
      data: data,
    );
    return PhraseCategoryModel.fromJson(response.data!);
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _apiClient.delete<void>('admin/config/categories/$categoryId');
  }

  @override
  Future<void> restoreCategory(String categoryId) async {
    await _apiClient.post<void>('admin/config/categories/$categoryId/restore');
  }

  @override
  Future<List<PhraseModel>> getPhrases(String categoryId, {bool includeInactive = false}) async {
    final queryParams = 'categoryId=$categoryId${includeInactive ? '&includeInactive=true' : ''}';
    final response = await _apiClient.get<List<dynamic>>(
      'admin/config/phrases?$queryParams',
    );
    return PhraseModel.fromJsonList(response.data!);
  }

  @override
  Future<PhraseModel> createPhrase({
    required String categoryId,
    required String value,
    int? displayOrder,
    bool? isDefault,
  }) async {
    final data = <String, dynamic>{
      'categoryId': categoryId,
      'value': value,
    };
    if (displayOrder != null) data['displayOrder'] = displayOrder;
    if (isDefault != null) data['isDefault'] = isDefault;

    final response = await _apiClient.post<Map<String, dynamic>>(
      'admin/config/phrases',
      data: data,
    );
    return PhraseModel.fromJson(response.data!);
  }

  @override
  Future<PhraseModel> updatePhrase(
    String phraseId, {
    String? value,
    int? displayOrder,
    bool? isActive,
    bool? isDefault,
  }) async {
    final data = <String, dynamic>{};
    if (value != null) data['value'] = value;
    if (displayOrder != null) data['displayOrder'] = displayOrder;
    if (isActive != null) data['isActive'] = isActive;
    if (isDefault != null) data['isDefault'] = isDefault;

    final response = await _apiClient.put<Map<String, dynamic>>(
      'admin/config/phrases/$phraseId',
      data: data,
    );
    return PhraseModel.fromJson(response.data!);
  }

  @override
  Future<void> deletePhrase(String phraseId) async {
    await _apiClient.delete<void>('admin/config/phrases/$phraseId');
  }

  @override
  Future<void> reorderPhrases(String categoryId, List<String> phraseIds) async {
    await _apiClient.post<Map<String, dynamic>>(
      'admin/config/phrases/reorder',
      data: {
        'categoryId': categoryId,
        'phraseIds': phraseIds,
      },
    );
  }

  // ============================================
  // Field Definition Management Implementation
  // ============================================

  @override
  Future<List<FieldDefinitionModel>> getFields({bool includeInactive = false}) async {
    final queryParams = includeInactive ? '?includeInactive=true' : '';
    final response = await _apiClient.get<List<dynamic>>(
      'admin/config/fields$queryParams',
    );
    return FieldDefinitionModel.fromJsonList(response.data!);
  }

  @override
  Future<List<FieldDefinitionModel>> getFieldsBySection(String sectionType) async {
    final response = await _apiClient.get<List<dynamic>>(
      'admin/config/fields/$sectionType',
    );
    return FieldDefinitionModel.fromJsonList(response.data!);
  }

  @override
  Future<FieldDefinitionModel> createField({
    required String sectionType,
    required String fieldKey,
    required FieldType fieldType,
    required String label,
    String? placeholder,
    String? hint,
    bool? isRequired,
    int? displayOrder,
    String? phraseCategoryId,
    Map<String, dynamic>? validationRules,
    int? maxLines,
    String? fieldGroup,
    String? conditionalOn,
    String? conditionalValue,
    String? description,
  }) async {
    final data = <String, dynamic>{
      'sectionType': sectionType,
      'fieldKey': fieldKey,
      'fieldType': fieldType.name.toUpperCase(),
      'label': label,
    };
    if (placeholder != null) data['placeholder'] = placeholder;
    if (hint != null) data['hint'] = hint;
    if (isRequired != null) data['isRequired'] = isRequired;
    if (displayOrder != null) data['displayOrder'] = displayOrder;
    if (phraseCategoryId != null) data['phraseCategoryId'] = phraseCategoryId;
    if (validationRules != null) data['validationRules'] = validationRules;
    if (maxLines != null) data['maxLines'] = maxLines;
    if (fieldGroup != null) data['fieldGroup'] = fieldGroup;
    if (conditionalOn != null) data['conditionalOn'] = conditionalOn;
    if (conditionalValue != null) data['conditionalValue'] = conditionalValue;
    if (description != null) data['description'] = description;

    final response = await _apiClient.post<Map<String, dynamic>>(
      'admin/config/fields',
      data: data,
    );
    return FieldDefinitionModel.fromJson(response.data!);
  }

  @override
  Future<FieldDefinitionModel> updateField(
    String fieldId, {
    FieldType? fieldType,
    String? label,
    String? placeholder,
    String? hint,
    bool? isRequired,
    int? displayOrder,
    String? phraseCategoryId,
    Map<String, dynamic>? validationRules,
    int? maxLines,
    String? fieldGroup,
    String? conditionalOn,
    String? conditionalValue,
    String? description,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (fieldType != null) data['fieldType'] = fieldType.name.toUpperCase();
    if (label != null) data['label'] = label;
    if (placeholder != null) data['placeholder'] = placeholder;
    if (hint != null) data['hint'] = hint;
    if (isRequired != null) data['isRequired'] = isRequired;
    if (displayOrder != null) data['displayOrder'] = displayOrder;
    if (phraseCategoryId != null) data['phraseCategoryId'] = phraseCategoryId;
    if (validationRules != null) data['validationRules'] = validationRules;
    if (maxLines != null) data['maxLines'] = maxLines;
    if (fieldGroup != null) data['fieldGroup'] = fieldGroup;
    if (conditionalOn != null) data['conditionalOn'] = conditionalOn;
    if (conditionalValue != null) data['conditionalValue'] = conditionalValue;
    if (description != null) data['description'] = description;
    if (isActive != null) data['isActive'] = isActive;

    final response = await _apiClient.put<Map<String, dynamic>>(
      'admin/config/fields/$fieldId',
      data: data,
    );
    return FieldDefinitionModel.fromJson(response.data!);
  }

  @override
  Future<void> deleteField(String fieldId) async {
    await _apiClient.delete<void>('admin/config/fields/$fieldId');
  }

  @override
  Future<void> reorderFields(String sectionType, List<String> fieldIds) async {
    await _apiClient.post<Map<String, dynamic>>(
      'admin/config/fields/reorder',
      data: {
        'sectionType': sectionType,
        'fieldIds': fieldIds,
      },
    );
  }

  // ============================================
  // Section Type Definition Management
  // ============================================

  @override
  Future<List<SectionTypeModel>> getSectionTypes({bool includeInactive = false}) async {
    final queryParams = includeInactive ? '?includeInactive=true' : '';
    final response = await _apiClient.get<List<dynamic>>(
      'admin/config/section-types$queryParams',
    );
    return SectionTypeModel.fromJsonList(response.data!);
  }

  @override
  Future<SectionTypeModel> createSectionType({
    required String key,
    required String label,
    String? description,
    String? icon,
    int? displayOrder,
    List<String>? surveyTypes,
  }) async {
    final data = <String, dynamic>{
      'key': key,
      'label': label,
    };
    if (description != null) data['description'] = description;
    if (icon != null) data['icon'] = icon;
    if (displayOrder != null) data['displayOrder'] = displayOrder;
    if (surveyTypes != null) data['surveyTypes'] = surveyTypes;

    final response = await _apiClient.post<Map<String, dynamic>>(
      'admin/config/section-types',
      data: data,
    );
    return SectionTypeModel.fromJson(response.data!);
  }

  @override
  Future<SectionTypeModel> updateSectionType(
    String sectionTypeId, {
    String? label,
    String? description,
    String? icon,
    int? displayOrder,
    List<String>? surveyTypes,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (label != null) data['label'] = label;
    if (description != null) data['description'] = description;
    if (icon != null) data['icon'] = icon;
    if (displayOrder != null) data['displayOrder'] = displayOrder;
    if (surveyTypes != null) data['surveyTypes'] = surveyTypes;
    if (isActive != null) data['isActive'] = isActive;

    final response = await _apiClient.put<Map<String, dynamic>>(
      'admin/config/section-types/$sectionTypeId',
      data: data,
    );
    return SectionTypeModel.fromJson(response.data!);
  }

  @override
  Future<void> deleteSectionType(String sectionTypeId) async {
    await _apiClient.delete<void>('admin/config/section-types/$sectionTypeId');
  }

  @override
  Future<void> restoreSectionType(String sectionTypeId) async {
    await _apiClient.post<void>('admin/config/section-types/$sectionTypeId/restore');
  }

  @override
  Future<void> reorderSectionTypes(List<String> sectionTypeIds) async {
    await _apiClient.post<Map<String, dynamic>>(
      'admin/config/section-types/reorder',
      data: {
        'sectionTypeIds': sectionTypeIds,
      },
    );
  }
}
