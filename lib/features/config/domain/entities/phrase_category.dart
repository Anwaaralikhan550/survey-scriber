import 'package:equatable/equatable.dart';
import 'phrase.dart';

class PhraseCategory extends Equatable {
  const PhraseCategory({
    required this.id,
    required this.slug,
    required this.displayName,
    this.description,
    required this.isSystem,
    required this.isActive,
    required this.displayOrder,
    this.phrases = const [],
  });

  final String id;
  final String slug;
  final String displayName;
  final String? description;
  final bool isSystem;
  final bool isActive;
  final int displayOrder;
  final List<Phrase> phrases;

  @override
  List<Object?> get props => [
        id,
        slug,
        displayName,
        description,
        isSystem,
        isActive,
        displayOrder,
        phrases,
      ];

  PhraseCategory copyWith({
    String? id,
    String? slug,
    String? displayName,
    String? description,
    bool? isSystem,
    bool? isActive,
    int? displayOrder,
    List<Phrase>? phrases,
  }) => PhraseCategory(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      isSystem: isSystem ?? this.isSystem,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      phrases: phrases ?? this.phrases,
    );
}
