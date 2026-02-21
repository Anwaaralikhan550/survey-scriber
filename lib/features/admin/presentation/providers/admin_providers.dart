import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../config/data/models/phrase_category_model.dart';
import '../../../config/data/models/section_type_model.dart';
import '../../../config/domain/entities/field_definition.dart';
import '../../../config/domain/entities/phrase.dart';
import '../../../config/domain/entities/phrase_category.dart';
import '../../../config/presentation/providers/config_providers.dart';
import '../../data/datasources/admin_remote_datasource.dart';

// Data source provider
final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) => AdminRemoteDataSourceImpl(ref.watch(apiClientProvider)));

// Users state
class UsersState {
  const UsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  final List<AdminUserDto> users;
  final bool isLoading;
  final String? error;

  UsersState copyWith({
    List<AdminUserDto>? users,
    bool? isLoading,
    String? error,
  }) => UsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );

  int get adminCount => users.where((u) => u.role == UserRole.admin && u.isActive).length;
}

class UsersNotifier extends StateNotifier<UsersState> {
  UsersNotifier(this._dataSource) : super(const UsersState());

  final AdminRemoteDataSource _dataSource;

  Future<void> loadUsers() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      final users = await _dataSource.getUsers();
      state = UsersState(users: users);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> updateUserRole(String userId, UserRole newRole) async {
    try {
      final updatedUser = await _dataSource.updateUserRole(userId, newRole);

      // Update local state
      final updatedUsers = state.users.map((u) {
        if (u.id == userId) {
          return updatedUser;
        }
        return u;
      }).toList();

      state = state.copyWith(users: updatedUsers);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool canDemoteUser(AdminUserDto user) {
    if (user.role != UserRole.admin) return true;
    return state.adminCount > 1;
  }
}

final usersProvider = StateNotifierProvider<UsersNotifier, UsersState>((ref) => UsersNotifier(ref.watch(adminRemoteDataSourceProvider)));

// ============================================
// Phrase Management
// ============================================

class AdminPhrasesState {
  const AdminPhrasesState({
    this.categories = const [],
    this.selectedCategory,
    this.phrases = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  final List<PhraseCategoryModel> categories;
  final PhraseCategory? selectedCategory;
  final List<Phrase> phrases;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  AdminPhrasesState copyWith({
    List<PhraseCategoryModel>? categories,
    PhraseCategory? selectedCategory,
    List<Phrase>? phrases,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) => AdminPhrasesState(
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      phrases: phrases ?? this.phrases,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
}

class AdminPhrasesNotifier extends StateNotifier<AdminPhrasesState> {
  AdminPhrasesNotifier(this._dataSource, this._ref) : super(const AdminPhrasesState());

  final AdminRemoteDataSource _dataSource;
  final Ref _ref;

  Future<void> loadCategories() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      final categories = await _dataSource.getCategories(includeInactive: true);
      if (categories.isNotEmpty) {
        state = state.copyWith(categories: categories, isLoading: false);
      } else {
        // Fall back to seed categories when API returns empty
        state = state.copyWith(categories: _defaultCategories, isLoading: false);
      }
    } catch (e) {
      // On API error, show seed categories so the page is usable offline
      if (state.categories.isEmpty) {
        state = state.copyWith(categories: _defaultCategories, isLoading: false, error: e.toString());
      } else {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  /// Default phrase categories derived from the app's dropdown fields.
  /// Used when the API returns no categories so the page is never empty.
  static final _defaultCategories = [
    const PhraseCategoryModel(id: 'seed-property-type', slug: 'property-type', displayName: 'Property Type', isSystem: true, isActive: true, displayOrder: 0),
    const PhraseCategoryModel(id: 'seed-tenure', slug: 'tenure', displayName: 'Tenure', isSystem: true, isActive: true, displayOrder: 1),
    const PhraseCategoryModel(id: 'seed-wall-construction', slug: 'wall-construction', displayName: 'Wall Construction', isSystem: true, isActive: true, displayOrder: 2),
    const PhraseCategoryModel(id: 'seed-roof-type', slug: 'roof-type', displayName: 'Roof Type', isSystem: true, isActive: true, displayOrder: 3),
    const PhraseCategoryModel(id: 'seed-roof-covering', slug: 'roof-covering', displayName: 'Roof Covering', isSystem: true, isActive: true, displayOrder: 4),
    const PhraseCategoryModel(id: 'seed-foundation-type', slug: 'foundation-type', displayName: 'Foundation Type', isSystem: true, isActive: true, displayOrder: 5),
    const PhraseCategoryModel(id: 'seed-energy-rating', slug: 'energy-rating', displayName: 'Energy Rating', isSystem: true, isActive: true, displayOrder: 6),
    const PhraseCategoryModel(id: 'seed-condition-rating', slug: 'condition-rating', displayName: 'Condition Rating', isSystem: true, isActive: true, displayOrder: 7),
    const PhraseCategoryModel(id: 'seed-heating-type', slug: 'heating-type', displayName: 'Heating Type', isSystem: true, isActive: true, displayOrder: 8),
    const PhraseCategoryModel(id: 'seed-consumer-unit', slug: 'consumer-unit-type', displayName: 'Consumer Unit Type', isSystem: true, isActive: true, displayOrder: 9),
    const PhraseCategoryModel(id: 'seed-windows', slug: 'windows-type', displayName: 'Windows Type', isSystem: true, isActive: true, displayOrder: 10),
    const PhraseCategoryModel(id: 'seed-property-location', slug: 'property-location', displayName: 'Property Location', isSystem: true, isActive: true, displayOrder: 11),
    const PhraseCategoryModel(id: 'seed-listed-building', slug: 'listed-building', displayName: 'Listed Building', isSystem: true, isActive: true, displayOrder: 12),
    const PhraseCategoryModel(id: 'seed-ground-type', slug: 'ground-type', displayName: 'Ground Type', isSystem: true, isActive: true, displayOrder: 13),
  ];

  Future<void> selectCategory(PhraseCategory category) async {
    state = state.copyWith(selectedCategory: category, isLoading: true);

    // Seed categories (id starts with 'seed-') have no API data
    if (category.id.startsWith('seed-')) {
      state = state.copyWith(phrases: const [], isLoading: false);
      return;
    }

    try {
      final phrases = await _dataSource.getPhrases(category.id, includeInactive: true);
      state = state.copyWith(phrases: phrases, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create a new phrase category
  /// Generates a URL-safe slug from the display name automatically
  Future<bool> createCategory({
    required String displayName,
    String? description,
  }) async {
    // Validate display name
    final trimmedName = displayName.trim();
    if (trimmedName.isEmpty) {
      state = state.copyWith(error: 'Category name cannot be empty');
      return false;
    }

    // Generate URL-safe slug from display name
    // e.g., "Structural Damage" -> "structural-damage"
    final slug = _generateSlug(trimmedName);

    // Validate generated slug
    if (slug.isEmpty || slug.length < 2) {
      state = state.copyWith(
        error: 'Category name must contain at least 2 alphanumeric characters',
      );
      return false;
    }

    state = state.copyWith(isSaving: true);

    try {
      developer.log(
        'AdminPhrasesNotifier: creating category "$trimmedName" (slug: $slug)',
        name: 'admin',
      );

      final newCategory = await _dataSource.createCategory(
        slug: slug,
        displayName: trimmedName,
        description: description?.trim(),
      );

      // Add to categories list (remove any seed category with same slug)
      final updatedCategories = [
        ...state.categories.where((c) => c.slug != slug && !c.id.startsWith('seed-')),
        newCategory,
      ]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      state = state.copyWith(
        categories: updatedCategories,
        selectedCategory: newCategory,
        phrases: const [],
        isSaving: false,
      );

      // Refresh global config
      _ref.read(configProvider.notifier).refreshConfig();

      return true;
    } catch (e) {
      developer.log('AdminPhrasesNotifier: createCategory failed: $e', name: 'admin');
      state = state.copyWith(isSaving: false, error: _parseError(e));
      return false;
    }
  }

  /// Generates a URL-safe slug from a display name
  /// "Structural Damage" -> "structural-damage"
  /// "Property Type (UK)" -> "property-type-uk"
  String _generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-') // Replace non-alphanumeric with hyphen
        .replaceAll(RegExp('-+'), '-') // Collapse multiple hyphens
        .replaceAll(RegExp(r'^-|-$'), ''); // Trim leading/trailing hyphens
  }

  /// Checks if a category ID is a valid UUID (not a seed placeholder)
  bool _isValidUuid(String id) {
    // Seed IDs start with "seed-" and are NOT valid UUIDs
    if (id.startsWith('seed-')) return false;
    // Basic UUID format check (8-4-4-4-12 hex characters)
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(id);
  }

  /// Update an existing phrase category
  Future<bool> updateCategory(
    String categoryId, {
    String? displayName,
    String? description,
  }) async {
    state = state.copyWith(isSaving: true);

    try {
      final updated = await _dataSource.updateCategory(
        categoryId,
        displayName: displayName,
        description: description,
      );

      final updatedCategories = state.categories.map((c) {
        if (c.id == categoryId) return updated;
        return c;
      }).toList();

      // If the selected category was updated, update the selection too
      final selectedUpdated =
          state.selectedCategory?.id == categoryId ? updated : null;

      state = state.copyWith(
        categories: updatedCategories,
        isSaving: false,
        selectedCategory: selectedUpdated ?? state.selectedCategory,
      );

      _ref.read(configProvider.notifier).refreshConfig();
      return true;
    } catch (e) {
      developer.log('AdminPhrasesNotifier: updateCategory failed: $e', name: 'admin');
      state = state.copyWith(isSaving: false, error: _parseError(e));
      return false;
    }
  }

  /// Delete a phrase category (real soft-delete via deletedAt).
  /// Returns the deleted [PhraseCategoryModel] so the caller can offer undo.
  Future<PhraseCategoryModel?> deleteCategory(String categoryId) async {
    state = state.copyWith(isSaving: true);

    try {
      // Capture the item before removal for undo
      final deleted = state.categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => throw StateError('Category $categoryId not found'),
      );

      await _dataSource.deleteCategory(categoryId);

      // Remove from list entirely (real delete, not just isActive=false)
      final updatedCategories = state.categories.where((c) => c.id != categoryId).toList();

      // Clear selection if the deleted category was selected
      final clearSelection = state.selectedCategory?.id == categoryId;

      state = state.copyWith(
        categories: updatedCategories,
        isSaving: false,
        selectedCategory: clearSelection ? null : state.selectedCategory,
        phrases: clearSelection ? const [] : state.phrases,
      );

      _ref.read(configProvider.notifier).refreshConfig();
      return deleted;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _parseError(e));
      return null;
    }
  }

  /// Restore a previously deleted phrase category (undo).
  Future<bool> restoreCategory(PhraseCategoryModel item) async {
    state = state.copyWith(isSaving: true);

    try {
      await _dataSource.restoreCategory(item.id);

      // Re-insert the item into the list
      final updatedCategories = [...state.categories, item]
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      state = state.copyWith(categories: updatedCategories, isSaving: false);

      _ref.read(configProvider.notifier).refreshConfig();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> createPhrase(String value) async {
    if (state.selectedCategory == null) {
      state = state.copyWith(error: 'Please select a category first');
      return false;
    }

    final category = state.selectedCategory!;

    // CRITICAL: Validate that the category ID is a real UUID, not a seed placeholder
    // Seed categories have IDs like "seed-property-type" which will cause 500 errors
    if (!_isValidUuid(category.id)) {
      developer.log(
        'AdminPhrasesNotifier: Cannot add phrase to seed category "${category.slug}" - '
        'create a real category first',
        name: 'admin',
      );
      state = state.copyWith(
        error: 'Cannot add phrases to placeholder categories. '
            'Please create a new category using the folder icon first.',
      );
      return false;
    }

    // Validate input
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      state = state.copyWith(error: 'Phrase value cannot be empty');
      return false;
    }

    state = state.copyWith(isSaving: true);

    try {
      developer.log(
        'AdminPhrasesNotifier: creating phrase "$trimmedValue" in category ${category.slug} (id: ${category.id})',
        name: 'admin',
      );

      final newPhrase = await _dataSource.createPhrase(
        categoryId: category.id, // Now guaranteed to be a valid UUID
        value: trimmedValue,
      );

      final updatedPhrases = [...state.phrases, newPhrase];
      state = state.copyWith(phrases: updatedPhrases, isSaving: false);

      // Refresh global config
      developer.log('AdminPhrasesNotifier: phrase created, refreshing config', name: 'admin');
      _ref.read(configProvider.notifier).refreshConfig();

      return true;
    } catch (e) {
      developer.log('AdminPhrasesNotifier: createPhrase failed: $e', name: 'admin');
      state = state.copyWith(isSaving: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> updatePhrase(String phraseId, {String? value, bool? isActive, bool? isDefault}) async {
    state = state.copyWith(isSaving: true);

    try {
      final updatedPhrase = await _dataSource.updatePhrase(
        phraseId,
        value: value,
        isActive: isActive,
        isDefault: isDefault,
      );

      final updatedPhrases = state.phrases.map((p) {
        if (p.id == phraseId) return updatedPhrase;
        return p;
      }).toList();

      state = state.copyWith(phrases: updatedPhrases, isSaving: false);

      // Refresh global config
      _ref.read(configProvider.notifier).refreshConfig();

      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> togglePhrase(Phrase phrase) async => updatePhrase(phrase.id, isActive: !phrase.isActive);

  Future<bool> deletePhrase(String phraseId) async {
    state = state.copyWith(isSaving: true);

    try {
      await _dataSource.deletePhrase(phraseId);

      // Update local state - mark as inactive (soft delete)
      final updatedPhrases = state.phrases.map((p) {
        if (p.id == phraseId) return p.copyWith(isActive: false);
        return p;
      }).toList();

      state = state.copyWith(phrases: updatedPhrases, isSaving: false);

      // Refresh global config
      _ref.read(configProvider.notifier).refreshConfig();

      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> reorderPhrases(int oldIndex, int newIndex) async {
    if (state.selectedCategory == null) return false;

    // Adjust index for removal
    if (newIndex > oldIndex) newIndex--;

    // Optimistic update
    final reorderedPhrases = List<Phrase>.from(state.phrases);
    final item = reorderedPhrases.removeAt(oldIndex);
    reorderedPhrases.insert(newIndex, item);

    state = state.copyWith(phrases: reorderedPhrases, isSaving: true);

    try {
      final phraseIds = reorderedPhrases.map((p) => p.id).toList();
      await _dataSource.reorderPhrases(state.selectedCategory!.id, phraseIds);

      state = state.copyWith(isSaving: false);

      // Refresh global config
      _ref.read(configProvider.notifier).refreshConfig();

      return true;
    } catch (e) {
      // Revert on failure - reload from server
      await selectCategory(state.selectedCategory!);
      state = state.copyWith(isSaving: false, error: _parseError(e));
      return false;
    }
  }

  String _parseError(dynamic e) {
    final errorStr = e.toString();
    if (errorStr.contains('409') || errorStr.contains('Conflict')) {
      return 'This phrase already exists in the category';
    }
    if (errorStr.contains('404')) {
      return 'Item not found';
    }
    return 'An error occurred. Please try again.';
  }
}

final adminPhrasesProvider = StateNotifierProvider<AdminPhrasesNotifier, AdminPhrasesState>((ref) => AdminPhrasesNotifier(
    ref.watch(adminRemoteDataSourceProvider),
    ref,
  ),);

// ============================================
// Field Definition Management
// ============================================

class AdminFieldsState {
  const AdminFieldsState({
    this.fields = const [],
    this.selectedSectionType,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  final List<FieldDefinition> fields;
  final String? selectedSectionType;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  AdminFieldsState copyWith({
    List<FieldDefinition>? fields,
    String? selectedSectionType,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) => AdminFieldsState(
      fields: fields ?? this.fields,
      selectedSectionType: selectedSectionType ?? this.selectedSectionType,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
}

class AdminFieldsNotifier extends StateNotifier<AdminFieldsState> {
  AdminFieldsNotifier(this._dataSource, this._ref) : super(const AdminFieldsState());

  final AdminRemoteDataSource _dataSource;
  final Ref _ref;

  Future<void> loadAllFields() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      final fields = await _dataSource.getFields(includeInactive: true);
      state = state.copyWith(fields: fields, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> selectSection(String sectionType) async {
    state = state.copyWith(selectedSectionType: sectionType, isLoading: true);

    try {
      // Filter from already loaded fields or fetch new
      if (state.fields.isNotEmpty) {
        state = state.copyWith(isLoading: false);
      } else {
        final fields = await _dataSource.getFields(includeInactive: true);
        state = state.copyWith(fields: fields, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  List<FieldDefinition> getFieldsForSection(String sectionType) => state.fields
        .where((f) => f.sectionType == sectionType)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

  Future<bool> createField({
    required String sectionType,
    required String fieldKey,
    required FieldType fieldType,
    required String label,
    String? placeholder,
    String? hint,
    bool? isRequired,
    String? phraseCategoryId,
    String? fieldGroup,
    String? conditionalOn,
    String? conditionalValue,
    String? description,
  }) async {
    state = state.copyWith(isSaving: true);

    try {
      final newField = await _dataSource.createField(
        sectionType: sectionType,
        fieldKey: fieldKey,
        fieldType: fieldType,
        label: label,
        placeholder: placeholder,
        hint: hint,
        isRequired: isRequired,
        phraseCategoryId: phraseCategoryId,
        fieldGroup: fieldGroup,
        conditionalOn: conditionalOn,
        conditionalValue: conditionalValue,
        description: description,
      );

      final updatedFields = [...state.fields, newField];
      state = state.copyWith(fields: updatedFields, isSaving: false);

      // Refresh global config so inspection UI picks up changes
      developer.log(
        'AdminFieldsNotifier: field created "${newField.fieldKey}" in $sectionType, refreshing config',
        name: 'admin',
      );
      _ref.read(configProvider.notifier).refreshConfig();

      return true;
    } catch (e) {
      developer.log('AdminFieldsNotifier: createField failed: $e', name: 'admin');
      state = state.copyWith(isSaving: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> updateField(
    String fieldId, {
    FieldType? fieldType,
    String? label,
    String? placeholder,
    String? hint,
    bool? isRequired,
    String? phraseCategoryId,
    String? fieldGroup,
    String? conditionalOn,
    String? conditionalValue,
    String? description,
    bool? isActive,
  }) async {
    state = state.copyWith(isSaving: true);

    try {
      final updatedField = await _dataSource.updateField(
        fieldId,
        fieldType: fieldType,
        label: label,
        placeholder: placeholder,
        hint: hint,
        isRequired: isRequired,
        phraseCategoryId: phraseCategoryId,
        fieldGroup: fieldGroup,
        conditionalOn: conditionalOn,
        conditionalValue: conditionalValue,
        description: description,
        isActive: isActive,
      );

      final updatedFields = state.fields.map((f) {
        if (f.id == fieldId) return updatedField;
        return f;
      }).toList();

      state = state.copyWith(fields: updatedFields, isSaving: false);

      // Refresh global config so inspection UI picks up changes
      developer.log(
        'AdminFieldsNotifier: field updated "$fieldId", refreshing config',
        name: 'admin',
      );
      _ref.read(configProvider.notifier).refreshConfig();

      return true;
    } catch (e) {
      developer.log('AdminFieldsNotifier: updateField failed: $e', name: 'admin');
      state = state.copyWith(isSaving: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> toggleField(FieldDefinition field) async => updateField(field.id, isActive: !field.isActive);

  Future<bool> deleteField(String fieldId) async {
    state = state.copyWith(isSaving: true);

    try {
      await _dataSource.deleteField(fieldId);

      // Update local state - mark as inactive (soft delete)
      final updatedFields = state.fields.map((f) {
        if (f.id == fieldId) return f.copyWith(isActive: false);
        return f;
      }).toList();

      state = state.copyWith(fields: updatedFields, isSaving: false);

      // Refresh global config
      _ref.read(configProvider.notifier).refreshConfig();

      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> reorderFields(String sectionType, int oldIndex, int newIndex) async {
    // Adjust index for removal
    if (newIndex > oldIndex) newIndex--;

    // Get fields for this section
    final sectionFields = getFieldsForSection(sectionType);
    final reorderedFields = List<FieldDefinition>.from(sectionFields);
    final item = reorderedFields.removeAt(oldIndex);
    reorderedFields.insert(newIndex, item);

    // Optimistic update - rebuild full list
    final updatedAllFields = state.fields.map((f) {
      if (f.sectionType != sectionType) return f;
      final idx = reorderedFields.indexWhere((rf) => rf.id == f.id);
      if (idx >= 0) return f.copyWith(displayOrder: idx);
      return f;
    }).toList();

    state = state.copyWith(fields: updatedAllFields, isSaving: true);

    try {
      final fieldIds = reorderedFields.map((f) => f.id).toList();
      await _dataSource.reorderFields(sectionType, fieldIds);

      state = state.copyWith(isSaving: false);

      // Refresh global config
      _ref.read(configProvider.notifier).refreshConfig();

      return true;
    } catch (e) {
      // Revert on failure - reload from server
      await loadAllFields();
      state = state.copyWith(isSaving: false, error: _parseError(e));
      return false;
    }
  }

  String _parseError(dynamic e) {
    final errorStr = e.toString();
    if (errorStr.contains('409') || errorStr.contains('Conflict')) {
      return 'This field key already exists in the section';
    }
    if (errorStr.contains('404')) {
      return 'Item not found';
    }
    return 'An error occurred. Please try again.';
  }
}

final adminFieldsProvider = StateNotifierProvider<AdminFieldsNotifier, AdminFieldsState>((ref) => AdminFieldsNotifier(
    ref.watch(adminRemoteDataSourceProvider),
    ref,
  ),);

// ============================================
// Section Type Definition Management
// ============================================

class AdminSectionTypesState {
  const AdminSectionTypesState({
    this.sectionTypes = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  final List<SectionTypeModel> sectionTypes;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  AdminSectionTypesState copyWith({
    List<SectionTypeModel>? sectionTypes,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) => AdminSectionTypesState(
      sectionTypes: sectionTypes ?? this.sectionTypes,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );

  List<SectionTypeModel> get activeSectionTypes =>
      sectionTypes.where((s) => s.isActive).toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
}

class AdminSectionTypesNotifier extends StateNotifier<AdminSectionTypesState> {
  AdminSectionTypesNotifier(this._dataSource, this._ref)
      : super(const AdminSectionTypesState());

  final AdminRemoteDataSource _dataSource;
  final Ref _ref;

  Future<void> loadSectionTypes() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      final sectionTypes = await _dataSource.getSectionTypes(includeInactive: true);
      state = state.copyWith(sectionTypes: sectionTypes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createSectionType({
    required String key,
    required String label,
    String? description,
    String? icon,
    List<String>? surveyTypes,
  }) async {
    state = state.copyWith(isSaving: true);

    try {
      final newType = await _dataSource.createSectionType(
        key: key,
        label: label,
        description: description,
        icon: icon,
        surveyTypes: surveyTypes,
      );

      final updated = [...state.sectionTypes, newType];
      state = state.copyWith(sectionTypes: updated, isSaving: false);

      _ref.read(configProvider.notifier).refreshConfig();
      return true;
    } catch (e) {
      developer.log('AdminSectionTypesNotifier: create failed: $e', name: 'admin');
      state = state.copyWith(isSaving: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> updateSectionType(
    String id, {
    String? label,
    String? description,
    String? icon,
    List<String>? surveyTypes,
    bool? isActive,
  }) async {
    state = state.copyWith(isSaving: true);

    try {
      final updated = await _dataSource.updateSectionType(
        id,
        label: label,
        description: description,
        icon: icon,
        surveyTypes: surveyTypes,
        isActive: isActive,
      );

      final updatedList = state.sectionTypes.map((s) {
        if (s.id == id) return updated;
        return s;
      }).toList();

      state = state.copyWith(sectionTypes: updatedList, isSaving: false);

      _ref.read(configProvider.notifier).refreshConfig();
      return true;
    } catch (e) {
      developer.log('AdminSectionTypesNotifier: update failed: $e', name: 'admin');
      state = state.copyWith(isSaving: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> toggleSectionType(SectionTypeModel sectionType) async =>
      updateSectionType(sectionType.id, isActive: !sectionType.isActive);

  /// Delete a section type (real soft-delete via deletedAt).
  /// Returns the deleted [SectionTypeModel] so the caller can offer undo.
  Future<SectionTypeModel?> deleteSectionType(String id) async {
    state = state.copyWith(isSaving: true);

    try {
      // Capture the item before removal for undo
      final deleted = state.sectionTypes.firstWhere(
        (s) => s.id == id,
        orElse: () => throw StateError('Section type $id not found'),
      );

      await _dataSource.deleteSectionType(id);

      // Remove from list entirely (real delete, not just isActive=false)
      final updated = state.sectionTypes.where((s) => s.id != id).toList();
      state = state.copyWith(sectionTypes: updated, isSaving: false);

      _ref.read(configProvider.notifier).refreshConfig();
      return deleted;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _parseError(e));
      return null;
    }
  }

  /// Restore a previously deleted section type (undo).
  Future<bool> restoreSectionType(SectionTypeModel item) async {
    state = state.copyWith(isSaving: true);

    try {
      await _dataSource.restoreSectionType(item.id);

      // Re-insert the item into the list
      final updated = [...state.sectionTypes, item]
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      state = state.copyWith(sectionTypes: updated, isSaving: false);

      _ref.read(configProvider.notifier).refreshConfig();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> reorderSectionTypes(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;

    final active = state.activeSectionTypes;
    final reordered = List<SectionTypeModel>.from(active);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    // Optimistic update
    final updatedAll = state.sectionTypes.map((s) {
      if (!s.isActive) return s;
      final idx = reordered.indexWhere((r) => r.id == s.id);
      if (idx >= 0) return s.copyWith(displayOrder: idx);
      return s;
    }).toList();

    state = state.copyWith(sectionTypes: updatedAll, isSaving: true);

    try {
      final ids = reordered.map((s) => s.id).toList();
      await _dataSource.reorderSectionTypes(ids);

      state = state.copyWith(isSaving: false);
      _ref.read(configProvider.notifier).refreshConfig();
      return true;
    } catch (e) {
      await loadSectionTypes();
      state = state.copyWith(isSaving: false, error: _parseError(e));
      return false;
    }
  }

  String _parseError(dynamic e) {
    final errorStr = e.toString();
    if (errorStr.contains('409') || errorStr.contains('Conflict')) {
      return 'This section type key already exists';
    }
    if (errorStr.contains('404')) {
      return 'Section type not found';
    }
    return 'An error occurred. Please try again.';
  }
}

final adminSectionTypesProvider =
    StateNotifierProvider<AdminSectionTypesNotifier, AdminSectionTypesState>(
  (ref) => AdminSectionTypesNotifier(
    ref.watch(adminRemoteDataSourceProvider),
    ref,
  ),
);
