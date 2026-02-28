import 'package:flutter/foundation.dart';

import '../../../property_inspection/domain/field_phrase_processor.dart';
import '../../../property_inspection/domain/inspection_phrase_engine.dart';
import '../../../property_inspection/domain/models/inspection_models.dart';
import '../../../property_inspection/domain/narrative_enhancer.dart';
import '../../../property_inspection/presentation/widgets/inspection_fields.dart'
    show shouldShowInspectionField;
import '../../../property_valuation/domain/valuation_phrase_engine.dart';
import '../../domain/models/export_config.dart';
import '../../domain/models/report_document.dart';
import 'report_data_service.dart';

/// Transforms [V2RawReportData] into a format-agnostic [ReportDocument]
/// by walking the tree, applying conditional visibility, expanding phrases,
/// and formatting display values.
class ReportBuilder {
  ReportBuilder({
    this.inspectionPhraseEngine,
    this.valuationPhraseEngine,
  });

  final InspectionPhraseEngine? inspectionPhraseEngine;
  final ValuationPhraseEngine? valuationPhraseEngine;

  // Match inspection overview ordering in app UI.
  static const List<String> _inspectionSectionOrder = <String>[
    'A',
    'D',
    'E',
    'H',
    'F',
    'G',
    'R',
    'I',
    'J',
    'K',
    'O',
  ];

  ReportDocument build(
    V2RawReportData rawData,
    ExportConfig config, {
    Duration? surveyDuration,
  }) {
    final isInspection = rawData.survey.type.isInspection;

    final orderedSectionDefs = _orderedSectionsForReport(
      rawData.tree.sections,
      isInspection: isInspection,
    );

    final sections = <ReportSection>[];
    for (var i = 0; i < orderedSectionDefs.length; i++) {
      final sectionDef = orderedSectionDefs[i];
      final reportSection = _buildSection(
        sectionDef,
        rawData,
        config,
        isInspection,
        i,
      );
      if (reportSection != null) {
        sections.add(reportSection);
      }
    }

    final signatures = rawData.signatureRows
        .map((s) => ReportSignature(
              signerName: s.signerName,
              signerRole: s.signerRole,
              filePath: s.filePath,
              signedAt: s.signedAt,
            ))
        .toList();

    return ReportDocument(
      reportType: isInspection ? ReportType.inspection : ReportType.valuation,
      title: rawData.survey.title,
      generatedAt: DateTime.now(),
      surveyMeta: SurveyMeta(
        surveyId: rawData.survey.id,
        title: rawData.survey.title,
        address: rawData.survey.address,
        jobRef: rawData.survey.jobRef,
        clientName: rawData.survey.clientName,
        inspectionDate: rawData.survey.createdAt,
        startedAt: rawData.survey.startedAt,
        completedAt: rawData.survey.completedAt,
        surveyDuration: surveyDuration,
      ),
      sections: sections,
      signatures: config.includeSignatures ? signatures : [],
      photoFilePaths: config.includePhotos ? rawData.photoFilePaths : [],
    );
  }

  List<InspectionSectionDefinition> _orderedSectionsForReport(
    List<InspectionSectionDefinition> input, {
    required bool isInspection,
  }) {
    if (!isInspection) return input;

    final indexByKey = <String, int>{
      for (var i = 0; i < _inspectionSectionOrder.length; i++)
        _inspectionSectionOrder[i]: i,
    };

    final known = <InspectionSectionDefinition>[];
    final unknown = <InspectionSectionDefinition>[];
    for (final section in input) {
      if (indexByKey.containsKey(section.key)) {
        known.add(section);
      } else {
        unknown.add(section);
      }
    }

    known.sort((a, b) =>
        indexByKey[a.key]!.compareTo(indexByKey[b.key]!));

    // Keep unknown sections stable by original tree order and append them.
    return [...known, ...unknown];
  }

  /// Pattern matching numbered sub-section groups like "E1 Chimney",
  /// "F3 Walls and Partitions", "G6 Drainage", "H2 Other".
  static final _numberedGroupPattern = RegExp(r'^[A-Z]\d');

  /// Legacy parity:
  /// In Section D, "Construction" should render as one consolidated
  /// heading in the final report (not per-screen headings).
  bool _shouldMergeTopLevelGroup(
    InspectionSectionDefinition sectionDef,
    InspectionNodeDefinition node,
  ) {
    if (node.type != InspectionNodeType.group || node.parentId != null) {
      return false;
    }
    if (_numberedGroupPattern.hasMatch(node.title)) {
      return true;
    }

    final sectionKey = sectionDef.key.trim().toUpperCase();
    final groupId = node.id.trim().toLowerCase();
    final groupTitle = node.title.trim().toLowerCase();
    final isConstructionGroup =
        groupId == 'group_construction_2' || groupTitle == 'construction';

    return sectionKey == 'D' && isConstructionGroup;
  }

  bool _isSectionDConstructionGroup(
    InspectionSectionDefinition sectionDef,
    InspectionNodeDefinition group,
  ) {
    final sectionKey = sectionDef.key.trim().toUpperCase();
    final groupId = group.id.trim().toLowerCase();
    final groupTitle = group.title.trim().toLowerCase();
    return sectionKey == 'D' &&
        (groupId == 'group_construction_2' || groupTitle == 'construction');
  }

  ReportSection? _buildSection(
    InspectionSectionDefinition sectionDef,
    V2RawReportData rawData,
    ExportConfig config,
    bool isInspection,
    int displayOrder,
  ) {
    final screens = <ReportScreen>[];

    // ── Build parent→children map for group hierarchy ──────────────
    final childrenOf = <String, List<InspectionNodeDefinition>>{};
    for (final node in sectionDef.nodes) {
      final pid = node.parentId ?? '_root_';
      childrenOf.putIfAbsent(pid, () => []).add(node);
    }

    // ── Identify top-level groups that should be merged in report output ──
    final topLevelGroups = sectionDef.nodes
        .where((n) => _shouldMergeTopLevelGroup(sectionDef, n))
        .toList();

    // Track which screens are consumed by merged groups so we don't
    // duplicate them as standalone entries.
    final consumedScreenIds = <String>{};

    if (topLevelGroups.isNotEmpty) {
      // Walk the original node list to preserve tree ordering — we emit
      // a merged group entry at the position of the first node that
      // belongs to each top-level group, and standalone screens at their
      // own positions.
      final topGroupIds = topLevelGroups.map((g) => g.id).toSet();

      // Pre-compute descendant screen IDs per top-level group.
      final groupDescendants = <String, List<InspectionNodeDefinition>>{};
      for (final group in topLevelGroups) {
        groupDescendants[group.id] =
            _collectDescendantScreens(group.id, childrenOf);
        for (final s in groupDescendants[group.id]!) {
          consumedScreenIds.add(s.id);
        }
      }

      // Track which groups have already been emitted.
      final emittedGroups = <String>{};

      // Pre-build node lookup for parent-chain walking.
      final nodeMap = <String, InspectionNodeDefinition>{
        for (final n in sectionDef.nodes) n.id: n,
      };

      for (final node in sectionDef.nodes) {
        // ── If this node belongs to a top-level group, emit the merged
        //    group (once) at the position of the first encountered node.
        final ownerGroupId = _findOwnerGroup(node, nodeMap, topGroupIds);
        if (ownerGroupId != null) {
          // Emit merged groups at their own node position (same ordering as
          // the section UI), not at the first descendant screen position.
          if (node.id != ownerGroupId) {
            continue;
          }
          if (emittedGroups.contains(ownerGroupId)) continue;
          emittedGroups.add(ownerGroupId);

          final group =
              topLevelGroups.firstWhere((g) => g.id == ownerGroupId);
          final descendants = groupDescendants[ownerGroupId]!;
          final isLegacyConstructionSummary =
              _isSectionDConstructionGroup(sectionDef, group);

          final mergedPhrases = <String>[];
          final mergedNotes = <String>[];
          final mergedFields = <ReportField>[];

          for (final screen in descendants) {
            final note = rawData.persistedUserNotes[screen.id] ?? '';
            if (note.isNotEmpty) mergedNotes.add(note);

            final answers = rawData.allAnswers[screen.id] ?? {};
            final fields = _buildFields(screen, answers);

            if (config.includePhrases) {
              final screenPhrases =
                  _phrasesForScreen(screen, rawData, isInspection);
              if (screenPhrases.isNotEmpty) {
                if (isLegacyConstructionSummary) {
                  mergedPhrases.add(screenPhrases.first);
                } else {
                  mergedPhrases.addAll(screenPhrases);
                }
              } else {
                // No phrase handler — convert fields to narrative phrases
                // so data is not lost when other screens do have phrases.
                final fallback = _fieldsToPhrases(fields);
                if (fallback.isNotEmpty) {
                  if (isLegacyConstructionSummary) {
                    mergedPhrases.add(fallback.first);
                  } else {
                    mergedPhrases.addAll(fallback);
                  }
                } else if (fields.any((f) => f.displayValue.isNotEmpty)) {
                  mergedFields.addAll(fields);
                }
              }
            } else if (fields.any((f) => f.displayValue.isNotEmpty)) {
              mergedFields.addAll(fields);
            }
          }

          // Skip truly empty groups (no phrases, no fields, no notes)
          if (mergedPhrases.isEmpty &&
              mergedFields.isEmpty &&
              mergedNotes.isEmpty &&
              !config.includeEmptyScreens) {
            continue;
          }

          // When phrases exist, use them (professional style).
          // When phrases are empty but fields have data, fall back to
          // field table so no user data is silently dropped.
          screens.add(ReportScreen(
            screenId: group.id,
            title: group.title,
            fields: mergedPhrases.isNotEmpty ? const [] : mergedFields,
            phrases: mergedPhrases,
            userNote: mergedNotes.join('\n'),
            isMergedGroup: true,
          ));
          continue;
        }

        // ── Standalone screen (not consumed by any group) ─────────
        if (node.type != InspectionNodeType.screen) continue;
        if (consumedScreenIds.contains(node.id)) continue;

        final entry = _buildScreenEntry(node, rawData, config, isInspection);
        if (entry != null) screens.add(entry);
      }
    } else {
      // ── No numbered groups in this section — flat mode (unchanged) ──
      for (final node in sectionDef.nodes) {
        if (node.type != InspectionNodeType.screen) continue;
        final entry = _buildScreenEntry(node, rawData, config, isInspection);
        if (entry != null) screens.add(entry);
      }
    }

    if (screens.isEmpty && !config.includeEmptyScreens) return null;

    // Apply NarrativeEnhancer to each screen's phrases
    if (config.includePhrases) {
      for (var i = 0; i < screens.length; i++) {
        final screen = screens[i];
        if (screen.phrases.isEmpty) continue;
        final enhanced = NarrativeEnhancer.enhance(
          screen.phrases,
          sectionKey: sectionDef.key,
          screenId: screen.screenId,
          isFirstScreenInSection: i == 0,
        );
        if (enhanced != screen.phrases) {
          screens[i] = ReportScreen(
            screenId: screen.screenId,
            title: screen.title,
            fields: screen.fields,
            phrases: enhanced,
            userNote: screen.userNote,
            parentId: screen.parentId,
            isCompleted: screen.isCompleted,
            isMergedGroup: screen.isMergedGroup,
          );
        }
      }
    }

    return ReportSection(
      key: sectionDef.key,
      title: sectionDef.title,
      description: sectionDef.description,
      screens: screens,
      displayOrder: displayOrder,
    );
  }

  /// Build a single [ReportScreen] for a standalone (non-grouped) screen node.
  ReportScreen? _buildScreenEntry(
    InspectionNodeDefinition node,
    V2RawReportData rawData,
    ExportConfig config,
    bool isInspection,
  ) {
    final answers = rawData.allAnswers[node.id] ?? {};
    final isCompleted = rawData.screenStates[node.id] ?? false;

    var fields = _buildFields(node, answers);
    List<String> phrases;
    if (!config.includePhrases) {
      phrases = const [];
    } else {
      phrases = _phrasesForScreen(node, rawData, isInspection);
    }

    // When no engine phrases exist but fields have data, convert fields to
    // simple narrative phrases so the report avoids raw "Yes/No" tables.
    if (phrases.isEmpty &&
        config.includePhrases &&
        fields.any((f) => f.displayValue.isNotEmpty)) {
      final fallback = _fieldsToPhrases(fields);
      if (fallback.isNotEmpty) {
        phrases = fallback;
        fields = const []; // Suppress raw table — phrases cover the data.
      }
    }

    final userNote = rawData.persistedUserNotes[node.id] ?? '';

    final hasData = fields.any((f) => f.displayValue.isNotEmpty) ||
        phrases.isNotEmpty ||
        userNote.isNotEmpty;
    if (!hasData && !config.includeEmptyScreens) return null;

    return ReportScreen(
      screenId: node.id,
      title: node.title,
      fields: fields,
      phrases: phrases,
      userNote: userNote,
      parentId: node.parentId,
      isCompleted: isCompleted,
    );
  }

  /// Get phrases for a screen — prefers persisted DB phrases, falls back to
  /// live engine regeneration.
  ///
  /// Returns empty if the user never interacted with this screen (no answers
  /// in the DB).  This prevents unconditional boilerplate text from the phrase
  /// engine from pulling unvisited screens into the report.
  List<String> _phrasesForScreen(
    InspectionNodeDefinition node,
    V2RawReportData rawData,
    bool isInspection,
  ) {
    final persisted = rawData.persistedPhrases[node.id];
    if (persisted != null) return persisted;

    // No persisted phrases and no user answers — screen was never visited.
    if (!rawData.allAnswers.containsKey(node.id)) return const [];

    final answers = rawData.allAnswers[node.id]!;
    final enginePhrases = _buildPhrases(node.id, answers, isInspection);
    final fieldPhrases =
        FieldPhraseProcessor.buildFieldPhrases(node.fields, answers);
    return [...enginePhrases, ...fieldPhrases];
  }

  /// Recursively collect all descendant screen nodes under [groupId].
  List<InspectionNodeDefinition> _collectDescendantScreens(
    String groupId,
    Map<String, List<InspectionNodeDefinition>> childrenOf,
  ) {
    final result = <InspectionNodeDefinition>[];
    final children = childrenOf[groupId] ?? const [];
    for (final child in children) {
      if (child.type == InspectionNodeType.screen) {
        result.add(child);
      } else if (child.type == InspectionNodeType.group) {
        result.addAll(_collectDescendantScreens(child.id, childrenOf));
      }
    }
    return result;
  }

  /// Walk up the parentId chain to find which top-level group (if any) owns
  /// this node.  Returns the group ID or null if the node is standalone.
  String? _findOwnerGroup(
    InspectionNodeDefinition node,
    Map<String, InspectionNodeDefinition> nodeMap,
    Set<String> topGroupIds,
  ) {
    // Direct match — the node IS a top-level group
    if (topGroupIds.contains(node.id)) return node.id;

    // Walk up parentId chain
    var current = node;
    for (var depth = 0; depth < 10; depth++) {
      final pid = current.parentId;
      if (pid == null) return null;
      if (topGroupIds.contains(pid)) return pid;
      final parent = nodeMap[pid];
      if (parent == null) return null;
      current = parent;
    }
    return null;
  }

  /// Convert a list of [ReportField]s into simple narrative phrases as a
  /// fallback when no phrase engine handler exists for a screen.
  ///
  /// - Checked checkboxes are collected and listed in a comma-separated
  ///   sentence (unchecked items and empty values are omitted).
  /// - Text / number / dropdown values are included as "Label: value".
  /// - Returns empty if no meaningful data is present.
  static List<String> _fieldsToPhrases(List<ReportField> fields) {
    final checked = <String>[];
    final entries = <String>[];

    for (final field in fields) {
      if (field.displayValue.isEmpty) continue;

      if (field.type == ReportFieldType.checkbox) {
        if (field.displayValue == 'Yes') {
          checked.add(field.label);
        }
        // Skip "No" — unchecked items are not noteworthy.
      } else {
        entries.add('${field.label}: ${field.displayValue}');
      }
    }

    final phrases = <String>[];
    if (checked.isNotEmpty) {
      phrases.add('${checked.join(', ')}.');
    }
    phrases.addAll(entries);
    return phrases;
  }

  List<ReportField> _buildFields(
    InspectionNodeDefinition node,
    Map<String, String> answers,
  ) {
    final result = <ReportField>[];

    for (final field in node.fields) {
      // Skip label-type fields — they are headings, not data
      if (field.type == InspectionFieldType.label) continue;

      // Apply conditional visibility filtering
      if (!shouldShowInspectionField(field, answers)) continue;

      final rawValue = answers[field.id] ?? '';
      final displayValue = _formatDisplayValue(rawValue, field.type);

      result.add(ReportField(
        fieldId: field.id,
        label: field.label,
        type: _mapFieldType(field.type),
        displayValue: displayValue,
        rawValue: rawValue,
        options: field.options,
        isConditional: field.conditionalOn != null,
      ));
    }

    return result;
  }

  String _formatDisplayValue(String rawValue, InspectionFieldType type) {
    if (rawValue.isEmpty) return '';

    if (type == InspectionFieldType.checkbox) {
      return rawValue.toLowerCase() == 'true' ? 'Yes' : 'No';
    }

    // Truncate very long text values
    if (rawValue.length > 50000) {
      return '${rawValue.substring(0, 50000)}... [truncated]';
    }

    return rawValue;
  }

  ReportFieldType _mapFieldType(InspectionFieldType type) {
    return switch (type) {
      InspectionFieldType.text => ReportFieldType.text,
      InspectionFieldType.number => ReportFieldType.number,
      InspectionFieldType.checkbox => ReportFieldType.checkbox,
      InspectionFieldType.dropdown => ReportFieldType.dropdown,
      InspectionFieldType.label => ReportFieldType.label,
    };
  }

  List<String> _buildPhrases(
    String screenId,
    Map<String, String> answers,
    bool isInspection,
  ) {
    try {
      if (isInspection && inspectionPhraseEngine != null) {
        return inspectionPhraseEngine!.buildPhrases(screenId, answers);
      }
      if (!isInspection && valuationPhraseEngine != null) {
        return valuationPhraseEngine!.buildPhrases(screenId, answers);
      }
    } catch (e, stack) {
      // Phrase generation is best-effort — don't fail the whole report
      debugPrint('[ReportBuilder] Phrase generation failed for screen $screenId: $e\n$stack');
    }
    return [];
  }
}
