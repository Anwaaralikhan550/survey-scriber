import '../../../../shared/domain/entities/survey.dart';
import '../../../../shared/domain/entities/survey_section.dart';
import '../../../media/domain/entities/media_item.dart';
import '../../../signature/domain/entities/signature_item.dart';
import '../entities/comparison_result.dart';

/// Service for comparing two surveys and generating diff results.
/// Contains pure Dart logic with no UI dependencies.
class SurveyComparisonService {
  const SurveyComparisonService();

  /// Compare two surveys and return a detailed comparison result.
  ///
  /// [previousSurvey] - The original/parent survey
  /// [currentSurvey] - The new re-inspection survey
  /// [previousSections] - Sections from the previous survey
  /// [currentSections] - Sections from the current survey
  /// [previousAnswers] - Answers grouped by section ID from previous survey
  /// [currentAnswers] - Answers grouped by section ID from current survey
  /// [previousMedia] - Media items grouped by section ID from previous survey
  /// [currentMedia] - Media items grouped by section ID from current survey
  /// [previousSignatures] - Signatures from previous survey
  /// [currentSignatures] - Signatures from current survey
  ComparisonResult compareSurveys({
    required Survey previousSurvey,
    required Survey currentSurvey,
    required List<SurveySection> previousSections,
    required List<SurveySection> currentSections,
    required Map<String, Map<String, String>> previousAnswers,
    required Map<String, Map<String, String>> currentAnswers,
    required Map<String, List<MediaItem>> previousMedia,
    required Map<String, List<MediaItem>> currentMedia,
    required List<SignatureItem> previousSignatures,
    required List<SignatureItem> currentSignatures,
  }) {
    // Build section diffs
    final sectionDiffs = _compareSections(
      previousSections: previousSections,
      currentSections: currentSections,
      previousAnswers: previousAnswers,
      currentAnswers: currentAnswers,
      previousMedia: previousMedia,
      currentMedia: currentMedia,
    );

    // Build signature diffs
    final signatureDiffs = _compareSignatures(
      previousSignatures: previousSignatures,
      currentSignatures: currentSignatures,
    );

    return ComparisonResult(
      previousSurvey: previousSurvey,
      currentSurvey: currentSurvey,
      sectionDiffs: sectionDiffs,
      signatureDiffs: signatureDiffs,
      comparedAt: DateTime.now(),
    );
  }

  /// Compare sections between two surveys
  List<SectionDiff> _compareSections({
    required List<SurveySection> previousSections,
    required List<SurveySection> currentSections,
    required Map<String, Map<String, String>> previousAnswers,
    required Map<String, Map<String, String>> currentAnswers,
    required Map<String, List<MediaItem>> previousMedia,
    required Map<String, List<MediaItem>> currentMedia,
  }) {
    final diffs = <SectionDiff>[];

    // Create maps for quick lookup by section type
    final previousByType = {
      for (final s in previousSections) s.sectionType: s,
    };
    final currentByType = {
      for (final s in currentSections) s.sectionType: s,
    };

    // Get all section types from both surveys
    final allTypes = {...previousByType.keys, ...currentByType.keys};

    for (final sectionType in allTypes) {
      final previousSection = previousByType[sectionType];
      final currentSection = currentByType[sectionType];

      if (previousSection == null && currentSection != null) {
        // Section was added in current survey
        diffs.add(SectionDiff(
          sectionId: currentSection.id,
          changeType: ChangeType.added,
          currentSection: currentSection,
          answerDiffs: _buildAnswerDiffsForNewSection(
            currentAnswers[currentSection.id] ?? {},
          ),
          mediaDiffs: _buildMediaDiffsForNewSection(
            currentMedia[currentSection.id] ?? [],
          ),
        ),);
      } else if (previousSection != null && currentSection == null) {
        // Section was removed in current survey
        diffs.add(SectionDiff(
          sectionId: previousSection.id,
          changeType: ChangeType.removed,
          previousSection: previousSection,
          answerDiffs: _buildAnswerDiffsForRemovedSection(
            previousAnswers[previousSection.id] ?? {},
          ),
          mediaDiffs: _buildMediaDiffsForRemovedSection(
            previousMedia[previousSection.id] ?? [],
          ),
        ),);
      } else if (previousSection != null && currentSection != null) {
        // Section exists in both - compare contents
        final answerDiffs = _compareAnswers(
          previousAnswers: previousAnswers[previousSection.id] ?? {},
          currentAnswers: currentAnswers[currentSection.id] ?? {},
        );
        final mediaDiffs = _compareMedia(
          previousMedia: previousMedia[previousSection.id] ?? [],
          currentMedia: currentMedia[currentSection.id] ?? [],
        );

        final hasChanges = answerDiffs.any((d) => d.changeType != ChangeType.unchanged) ||
            mediaDiffs.any((d) => d.changeType != ChangeType.unchanged);

        diffs.add(SectionDiff(
          sectionId: currentSection.id,
          changeType: hasChanges ? ChangeType.modified : ChangeType.unchanged,
          previousSection: previousSection,
          currentSection: currentSection,
          answerDiffs: answerDiffs,
          mediaDiffs: mediaDiffs,
        ),);
      }
    }

    // Sort by section order
    diffs.sort((a, b) {
      final aOrder = a.displaySection?.order ?? 999;
      final bOrder = b.displaySection?.order ?? 999;
      return aOrder.compareTo(bOrder);
    });

    return diffs;
  }

  /// Compare answers between two sections
  List<AnswerDiff> _compareAnswers({
    required Map<String, String> previousAnswers,
    required Map<String, String> currentAnswers,
  }) {
    final diffs = <AnswerDiff>[];

    // Get all field keys from both answer sets
    final allKeys = {...previousAnswers.keys, ...currentAnswers.keys};

    for (final key in allKeys) {
      final previousValue = previousAnswers[key];
      final currentValue = currentAnswers[key];

      if (previousValue == null && currentValue != null) {
        // Answer was added
        diffs.add(AnswerDiff(
          fieldKey: key,
          changeType: ChangeType.added,
          currentValue: currentValue,
        ),);
      } else if (previousValue != null && currentValue == null) {
        // Answer was removed
        diffs.add(AnswerDiff(
          fieldKey: key,
          changeType: ChangeType.removed,
          previousValue: previousValue,
        ),);
      } else if (previousValue != null && currentValue != null) {
        // Both exist - compare values
        final isModified = _isValueDifferent(previousValue, currentValue);
        diffs.add(AnswerDiff(
          fieldKey: key,
          changeType: isModified ? ChangeType.modified : ChangeType.unchanged,
          previousValue: previousValue,
          currentValue: currentValue,
        ),);
      }
    }

    return diffs;
  }

  /// Compare media items between two sections
  List<MediaDiff> _compareMedia({
    required List<MediaItem> previousMedia,
    required List<MediaItem> currentMedia,
  }) {
    final diffs = <MediaDiff>[];

    // Create maps by media ID for quick lookup
    final previousById = {for (final m in previousMedia) m.id: m};

    final processedPrevious = <String>{};
    final processedCurrent = <String>{};

    // First pass: Match by ID
    for (final current in currentMedia) {
      final previous = previousById[current.id];
      if (previous != null) {
        processedPrevious.add(previous.id);
        processedCurrent.add(current.id);

        final isModified = _isMediaDifferent(previous, current);
        diffs.add(MediaDiff(
          changeType: isModified ? ChangeType.modified : ChangeType.unchanged,
          previousMedia: previous,
          currentMedia: current,
        ),);
      }
    }

    // Second pass: Match by similar properties (caption, position)
    for (final current in currentMedia) {
      if (processedCurrent.contains(current.id)) continue;

      // Try to find a matching previous media by caption or similar
      MediaItem? matchingPrevious;
      for (final previous in previousMedia) {
        if (processedPrevious.contains(previous.id)) continue;
        if (previous.type == current.type &&
            previous.caption == current.caption &&
            current.caption != null &&
            current.caption!.isNotEmpty) {
          matchingPrevious = previous;
          break;
        }
      }

      if (matchingPrevious != null) {
        processedPrevious.add(matchingPrevious.id);
        processedCurrent.add(current.id);
        diffs.add(MediaDiff(
          changeType: ChangeType.modified,
          previousMedia: matchingPrevious,
          currentMedia: current,
        ),);
      } else {
        // This is a new media item
        processedCurrent.add(current.id);
        diffs.add(MediaDiff(
          changeType: ChangeType.added,
          currentMedia: current,
        ),);
      }
    }

    // Mark remaining previous media as removed
    for (final previous in previousMedia) {
      if (!processedPrevious.contains(previous.id)) {
        diffs.add(MediaDiff(
          changeType: ChangeType.removed,
          previousMedia: previous,
        ),);
      }
    }

    return diffs;
  }

  /// Compare signatures between two surveys
  List<SignatureDiff> _compareSignatures({
    required List<SignatureItem> previousSignatures,
    required List<SignatureItem> currentSignatures,
  }) {
    final diffs = <SignatureDiff>[];

    // Create maps by signer role for comparison
    final previousByRole = <String, SignatureItem>{};
    for (final sig in previousSignatures) {
      final key = sig.signerRole ?? sig.id;
      previousByRole[key] = sig;
    }

    final currentByRole = <String, SignatureItem>{};
    for (final sig in currentSignatures) {
      final key = sig.signerRole ?? sig.id;
      currentByRole[key] = sig;
    }

    final processedRoles = <String>{};

    // Compare by role
    for (final entry in currentByRole.entries) {
      final role = entry.key;
      final current = entry.value;
      final previous = previousByRole[role];

      processedRoles.add(role);

      if (previous == null) {
        diffs.add(SignatureDiff(
          changeType: ChangeType.added,
          currentSignature: current,
        ),);
      } else {
        // Signatures always considered modified if they exist in both
        // (since each re-inspection requires fresh signatures)
        diffs.add(SignatureDiff(
          changeType: ChangeType.modified,
          previousSignature: previous,
          currentSignature: current,
        ),);
      }
    }

    // Mark remaining previous signatures as removed
    for (final entry in previousByRole.entries) {
      if (!processedRoles.contains(entry.key)) {
        diffs.add(SignatureDiff(
          changeType: ChangeType.removed,
          previousSignature: entry.value,
        ),);
      }
    }

    return diffs;
  }

  /// Build answer diffs for a newly added section
  List<AnswerDiff> _buildAnswerDiffsForNewSection(Map<String, String> answers) => answers.entries
        .map((e) => AnswerDiff(
              fieldKey: e.key,
              changeType: ChangeType.added,
              currentValue: e.value,
            ),)
        .toList();

  /// Build answer diffs for a removed section
  List<AnswerDiff> _buildAnswerDiffsForRemovedSection(Map<String, String> answers) => answers.entries
        .map((e) => AnswerDiff(
              fieldKey: e.key,
              changeType: ChangeType.removed,
              previousValue: e.value,
            ),)
        .toList();

  /// Build media diffs for a newly added section
  List<MediaDiff> _buildMediaDiffsForNewSection(List<MediaItem> media) => media
        .map((m) => MediaDiff(
              changeType: ChangeType.added,
              currentMedia: m,
            ),)
        .toList();

  /// Build media diffs for a removed section
  List<MediaDiff> _buildMediaDiffsForRemovedSection(List<MediaItem> media) => media
        .map((m) => MediaDiff(
              changeType: ChangeType.removed,
              previousMedia: m,
            ),)
        .toList();

  /// Check if two answer values are different
  bool _isValueDifferent(String previous, String current) {
    // Normalize empty strings and whitespace
    final normalizedPrevious = previous.trim();
    final normalizedCurrent = current.trim();

    return normalizedPrevious != normalizedCurrent;
  }

  /// Check if two media items are different
  bool _isMediaDifferent(MediaItem previous, MediaItem current) {
    // Compare key properties
    if (previous.caption != current.caption) return true;
    if (previous.localPath != current.localPath) return true;

    // For photos, check annotation status
    if (previous is PhotoItem && current is PhotoItem) {
      if (previous.hasAnnotations != current.hasAnnotations) return true;
    }

    return false;
  }
}
