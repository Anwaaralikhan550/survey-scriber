import 'package:equatable/equatable.dart';

class Phrase extends Equatable {
  const Phrase({
    required this.id,
    required this.categoryId,
    required this.value,
    required this.displayOrder,
    required this.isActive,
    required this.isDefault,
    this.metadata,
  });

  final String id;
  final String categoryId;
  final String value;
  final int displayOrder;
  final bool isActive;
  final bool isDefault;
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [
        id,
        categoryId,
        value,
        displayOrder,
        isActive,
        isDefault,
        metadata,
      ];

  Phrase copyWith({
    String? id,
    String? categoryId,
    String? value,
    int? displayOrder,
    bool? isActive,
    bool? isDefault,
    Map<String, dynamic>? metadata,
  }) => Phrase(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      value: value ?? this.value,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      metadata: metadata ?? this.metadata,
    );
}
