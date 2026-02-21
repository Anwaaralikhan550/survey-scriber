import 'package:equatable/equatable.dart';

import '../../../../shared/domain/entities/survey.dart';
import '../../../../shared/domain/entities/survey_section.dart';
import '../../../media/domain/entities/media_item.dart';
import '../../../signature/domain/entities/signature_item.dart';

/// Types of changes between surveys
enum ChangeType {
  added,
  modified,
  unchanged,
  removed,
}

/// Extension to provide display properties for ChangeType
extension ChangeTypeX on ChangeType {
  String get label => switch (this) {
        ChangeType.added => 'Added',
        ChangeType.modified => 'Modified',
        ChangeType.unchanged => 'Unchanged',
        ChangeType.removed => 'Removed',
      };

  bool get hasChange => this != ChangeType.unchanged;
}

/// Represents a diff for a single answer field
class AnswerDiff extends Equatable {
  const AnswerDiff({
    required this.fieldKey,
    required this.changeType,
    this.previousValue,
    this.currentValue,
  });

  final String fieldKey;
  final ChangeType changeType;
  final String? previousValue;
  final String? currentValue;

  /// Human-readable field name
  String get fieldLabel => _formatFieldKey(fieldKey);

  /// Whether the value actually changed
  bool get hasValueChange =>
      changeType != ChangeType.unchanged &&
      previousValue != currentValue;

  String _formatFieldKey(String key) => key
        .replaceAllMapped(RegExp('([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '',)
        .join(' ')
        .trim();

  @override
  List<Object?> get props => [fieldKey, changeType, previousValue, currentValue];
}

/// Represents a diff for a media item (photo, audio, video)
class MediaDiff extends Equatable {
  const MediaDiff({
    required this.changeType,
    this.previousMedia,
    this.currentMedia,
  });

  final ChangeType changeType;
  final MediaItem? previousMedia;
  final MediaItem? currentMedia;

  /// Get the media item to display (current if available, else previous)
  MediaItem? get displayMedia => currentMedia ?? previousMedia;

  /// Whether this is a photo comparison
  bool get isPhoto => displayMedia is PhotoItem;

  @override
  List<Object?> get props => [changeType, previousMedia, currentMedia];
}

/// Represents a diff for a signature
class SignatureDiff extends Equatable {
  const SignatureDiff({
    required this.changeType,
    this.previousSignature,
    this.currentSignature,
  });

  final ChangeType changeType;
  final SignatureItem? previousSignature;
  final SignatureItem? currentSignature;

  /// Get the signature to display (current if available, else previous)
  SignatureItem? get displaySignature => currentSignature ?? previousSignature;

  @override
  List<Object?> get props => [changeType, previousSignature, currentSignature];
}

/// Represents a diff for an entire section
class SectionDiff extends Equatable {
  const SectionDiff({
    required this.sectionId,
    required this.changeType,
    this.previousSection,
    this.currentSection,
    this.answerDiffs = const [],
    this.mediaDiffs = const [],
  });

  final String sectionId;
  final ChangeType changeType;
  final SurveySection? previousSection;
  final SurveySection? currentSection;
  final List<AnswerDiff> answerDiffs;
  final List<MediaDiff> mediaDiffs;

  /// Get the section to display (current if available, else previous)
  SurveySection? get displaySection => currentSection ?? previousSection;

  /// Section title
  String get title => displaySection?.title ?? 'Unknown Section';

  /// Total number of changes in this section
  int get totalChanges =>
      answerDiffs.where((d) => d.changeType != ChangeType.unchanged).length +
      mediaDiffs.where((d) => d.changeType != ChangeType.unchanged).length;

  /// Whether any field changed in this section
  bool get hasFieldChanges =>
      answerDiffs.any((d) => d.changeType != ChangeType.unchanged);

  /// Whether any media changed in this section
  bool get hasMediaChanges =>
      mediaDiffs.any((d) => d.changeType != ChangeType.unchanged);

  /// Get only changed answer diffs
  List<AnswerDiff> get changedAnswers =>
      answerDiffs.where((d) => d.changeType != ChangeType.unchanged).toList();

  /// Get only changed media diffs
  List<MediaDiff> get changedMedia =>
      mediaDiffs.where((d) => d.changeType != ChangeType.unchanged).toList();

  @override
  List<Object?> get props => [
        sectionId,
        changeType,
        previousSection,
        currentSection,
        answerDiffs,
        mediaDiffs,
      ];
}

/// Complete comparison result between two surveys
class ComparisonResult extends Equatable {
  const ComparisonResult({
    required this.previousSurvey,
    required this.currentSurvey,
    required this.sectionDiffs,
    required this.signatureDiffs,
    required this.comparedAt,
  });

  final Survey previousSurvey;
  final Survey currentSurvey;
  final List<SectionDiff> sectionDiffs;
  final List<SignatureDiff> signatureDiffs;
  final DateTime comparedAt;

  /// Total sections with changes
  int get sectionsWithChanges =>
      sectionDiffs.where((d) => d.changeType != ChangeType.unchanged).length;

  /// Total answer changes across all sections
  int get totalAnswerChanges => sectionDiffs.fold(
        0,
        (sum, section) =>
            sum +
            section.answerDiffs
                .where((d) => d.changeType != ChangeType.unchanged)
                .length,
      );

  /// Total media changes across all sections
  int get totalMediaChanges => sectionDiffs.fold(
        0,
        (sum, section) =>
            sum +
            section.mediaDiffs
                .where((d) => d.changeType != ChangeType.unchanged)
                .length,
      );

  /// Total signature changes
  int get totalSignatureChanges =>
      signatureDiffs.where((d) => d.changeType != ChangeType.unchanged).length;

  /// Whether there are any changes at all
  bool get hasAnyChanges =>
      sectionsWithChanges > 0 ||
      totalAnswerChanges > 0 ||
      totalMediaChanges > 0 ||
      totalSignatureChanges > 0;

  /// Get only sections with changes
  List<SectionDiff> get changedSections =>
      sectionDiffs.where((d) => d.changeType != ChangeType.unchanged || d.totalChanges > 0).toList();

  /// Get sections added in current survey
  List<SectionDiff> get addedSections =>
      sectionDiffs.where((d) => d.changeType == ChangeType.added).toList();

  /// Get sections removed from current survey
  List<SectionDiff> get removedSections =>
      sectionDiffs.where((d) => d.changeType == ChangeType.removed).toList();

  /// Get sections with modified content
  List<SectionDiff> get modifiedSections =>
      sectionDiffs.where((d) => d.changeType == ChangeType.modified || d.totalChanges > 0).toList();

  /// Summary statistics
  ComparisonSummary get summary => ComparisonSummary(
        previousSurveyTitle: previousSurvey.title,
        currentSurveyTitle: currentSurvey.title,
        previousDate: previousSurvey.createdAt,
        currentDate: currentSurvey.createdAt,
        totalSections: sectionDiffs.length,
        sectionsWithChanges: sectionsWithChanges,
        totalAnswerChanges: totalAnswerChanges,
        totalMediaChanges: totalMediaChanges,
        totalSignatureChanges: totalSignatureChanges,
      );

  @override
  List<Object?> get props => [
        previousSurvey,
        currentSurvey,
        sectionDiffs,
        signatureDiffs,
        comparedAt,
      ];
}

/// Summary statistics for a comparison
class ComparisonSummary extends Equatable {
  const ComparisonSummary({
    required this.previousSurveyTitle,
    required this.currentSurveyTitle,
    required this.previousDate,
    required this.currentDate,
    required this.totalSections,
    required this.sectionsWithChanges,
    required this.totalAnswerChanges,
    required this.totalMediaChanges,
    required this.totalSignatureChanges,
  });

  final String previousSurveyTitle;
  final String currentSurveyTitle;
  final DateTime previousDate;
  final DateTime currentDate;
  final int totalSections;
  final int sectionsWithChanges;
  final int totalAnswerChanges;
  final int totalMediaChanges;
  final int totalSignatureChanges;

  /// Total changes across all categories
  int get totalChanges =>
      totalAnswerChanges + totalMediaChanges + totalSignatureChanges;

  /// Percentage of sections with changes
  double get changePercentage =>
      totalSections > 0 ? (sectionsWithChanges / totalSections) * 100 : 0;

  @override
  List<Object?> get props => [
        previousSurveyTitle,
        currentSurveyTitle,
        previousDate,
        currentDate,
        totalSections,
        sectionsWithChanges,
        totalAnswerChanges,
        totalMediaChanges,
        totalSignatureChanges,
      ];
}
