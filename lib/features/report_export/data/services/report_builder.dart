import 'package:flutter/foundation.dart';

import '../../../property_inspection/domain/field_phrase_processor.dart';
import '../../../property_inspection/domain/inspection_phrase_engine.dart';
import '../../../property_inspection/domain/models/inspection_models.dart';
import '../../../property_inspection/presentation/widgets/inspection_fields.dart'
    show shouldShowInspectionField, sanitizeInspectionFieldsForScreen;
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

  // Section D has duplicate node IDs for Listed Building across legacy/new
  // tree variants. Treat them as aliases for report export.
  static const Set<String> _listedBuildingScreenIds = <String>{
    'activity_listed_building',
    'activity_listed_building__listed_building',
  };

  // Legacy Section D energy output is one consolidated block composed from
  // three screens.
  static const List<String> _sectionDEnergyScreenOrder = <String>[
    'activity_energy_effiency',
    'activity_energy_environment_impect',
    'activity_other_service',
  ];

  // Section D summary-style screens should render as narrative-only blocks
  // when phrases exist (legacy-style report output).
  static const Set<String> _sectionDSummaryNarrativeScreenIds = <String>{
    'activity_property_location',
    'activity_property_facelities',
    'activity_property_local_environment',
    'activity_property_private_road',
    'activity_property_is_noisy_area',
  };
  static const Set<String> _alwaysRegenerateFromAnswersScreenIds = <String>{
    ..._sectionDSummaryNarrativeScreenIds,
    'activity_issues_regulation',
    'activity_issues_glazed_sections',
    'activity_issues_other_matters',
    'activity_risks_risk_to_building_',
    'activity_risks_other_',
    'activity_risks_repair_or_improve',
    'activity_in_side_property_fire_places__other',
  };
  static const String _mergedSubheadingPrefix = '[[SUBHEADING]] ';

  static const Set<String> _genericAmbiguousScreenTitles = <String>{
    'construction',
    'roof',
    'wall',
    'floor',
    'floors',
    'flat',
    'windows',
    'doors',
    'door',
    'location',
    'other',
    'condition',
    'condition rating',
    'not inspected',
    'location and construction',
  };

  static const List<String> _legacyGLimitationsPhrases = <String>[
    'I have not carried out any testing of any of the service or installations, and my assessment is based on a visual inspection only.',
    'Condition ratings assume that current compliance certificates are available for all services and should be verified. In the absence of appropriate certification, condition ratings would by default reduce to the lowest level, which is condition rating 3.',
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

    known.sort((a, b) => indexByKey[a.key]!.compareTo(indexByKey[b.key]!));

    // Keep unknown sections stable by original tree order and append them.
    return [...known, ...unknown];
  }

  /// Pattern matching numbered sub-section groups like "E1 Chimney",
  /// "F3 Walls and Partitions", "G6 Drainage", "H2 Other".
  static final _numberedGroupPattern = RegExp(r'^[A-Z]\d');
  static final _numberedGroupIdPattern = RegExp(r'^group_[a-z]\d_');

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
    if (_numberedGroupIdPattern.hasMatch(groupId)) {
      return true;
    }
    final groupTitle = node.title.trim().toLowerCase();
    final isConstructionGroup =
        groupId == 'group_construction_2' || groupTitle == 'construction';
    return sectionKey == 'D' && isConstructionGroup;
  }

  String _reportTitleForNode(
    String sectionKey,
    InspectionNodeDefinition node,
  ) {
    final key = sectionKey.trim().toUpperCase();
    final id = node.id.trim().toLowerCase();

    if (key == 'D' && id == 'activity_property_location') {
      return 'Location';
    }
    if (key == 'E' && id == 'group_e1_chimney_5') {
      return 'Chimney Stacks';
    }
    if (key == 'E' && id == 'activity_outside_property_stacks') {
      return 'Chimney Stacks';
    }

    return node.title;
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

  bool _isSectionGLegacyGroup(
    InspectionSectionDefinition sectionDef,
    InspectionNodeDefinition group,
  ) {
    final sectionKey = sectionDef.key.trim().toUpperCase();
    final groupId = group.id.trim().toLowerCase();
    return sectionKey == 'G' &&
        group.parentId == null &&
        group.type == InspectionNodeType.group &&
        groupId.startsWith('group_g');
  }

  bool _shouldShowMergedDescendantSubheadings(
    InspectionSectionDefinition sectionDef,
    InspectionNodeDefinition group,
    List<InspectionNodeDefinition> descendants,
  ) {
    if (descendants.length <= 1) return false;
    // Legacy parity: merged Section E, F and G groups are paragraph-first and do
    // not render per-child subheadings from the Flutter tree.
    final sectionKey = sectionDef.key.trim().toUpperCase();
    if (sectionKey == 'E' || sectionKey == 'F' || sectionKey == 'G') {
      return false;
    }
    if (_isSectionDConstructionGroup(sectionDef, group)) return false;
    return true;
  }

  ReportScreen _legacyGLimitationsScreen() {
    final phraseEngine = inspectionPhraseEngine;
    if (phraseEngine != null) {
      final phrases = phraseEngine.buildStaticSubPhrases(
          '{G_LIMITATIONS_STANDARD_TEXT}', '');
      if (phrases.isNotEmpty) {
        return ReportScreen(
          screenId: 'derived_g_limitations',
          title: 'Limitations',
          fields: const <ReportField>[],
          phrases: phrases,
        );
      }
    }
    return const ReportScreen(
      screenId: 'derived_g_limitations',
      title: 'Limitations',
      fields: <ReportField>[],
      phrases: _legacyGLimitationsPhrases,
    );
  }

  ({List<String> body, List<String> rating, List<String> notes})
      _splitMainScreenPhrases(List<String> phrases) {
    final body = <String>[];
    final rating = <String>[];
    final notes = <String>[];
    for (final phrase in phrases) {
      final lower = phrase.trim().toLowerCase();
      if (lower.startsWith('condition rating is:')) {
        rating.add(phrase);
      } else if (lower.startsWith('note:') || lower.startsWith('notes:')) {
        notes.add(phrase);
      } else {
        body.add(phrase);
      }
    }
    return (body: body, rating: rating, notes: notes);
  }

  List<String> _dedupeOrderedPhrases(List<String> phrases) {
    final seen = <String>{};
    final result = <String>[];
    for (final phrase in phrases) {
      final key = phrase
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .trim();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      result.add(phrase);
    }
    return result;
  }

  List<String> _withoutMatchingPhrases(
    List<String> source,
    List<String> removal,
  ) {
    if (source.isEmpty || removal.isEmpty) return source;
    final removalKeys = removal
        .map((p) => p.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '))
        .toSet();
    return source
        .where((phrase) => !removalKeys.contains(
            phrase.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ')))
        .toList();
  }

  List<String> _buildPhrasesForScreenId(
    V2RawReportData rawData,
    String screenId,
    bool isInspection,
  ) {
    final answers = _answersForScreen(rawData, screenId);
    return _buildPhrases(screenId, answers, isInspection);
  }

  List<String> _legacySectionGGroupPhrases(
    InspectionNodeDefinition group,
    V2RawReportData rawData,
    bool isInspection,
  ) {
    if (!isInspection || inspectionPhraseEngine == null) return const [];

    final engine = inspectionPhraseEngine!;
    final groupId = group.id.trim().toLowerCase();

    List<String> withRepairHeading(String heading, List<String> phrases) {
      if (phrases.isEmpty) return const [];
      return <String>[_mergedSubheading(heading), ...phrases];
    }

    switch (groupId) {
      case 'group_g1_electricity_85':
        final notInspected = _buildPhrasesForScreenId(
          rawData,
          'activity_services_electricity_not_inspected',
          isInspection,
        );
        if (notInspected.isNotEmpty) return notInspected;

        final main = _splitMainScreenPhrases(_buildPhrasesForScreenId(
          rawData,
          'activity_services_electricity_main_screen',
          isInspection,
        ));
        final standard2 = engine.buildStaticSubPhrases(
            '{G_ELECTRICITY}', '{STANDARD_TEXT_2}');
        final repairs = <String>[
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_electricity_repair_loose_panels',
            isInspection,
          ),
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_electricity_repair_electrical_hazard',
            isInspection,
          ),
        ];
        return _dedupeOrderedPhrases([
          ...main.body,
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_service_about_electricity',
            isInspection,
          ),
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_solar_power',
            isInspection,
          ),
          ...withRepairHeading('Electricity Repair', repairs),
          ...standard2,
          ...main.rating,
          ...main.notes,
        ]);

      case 'group_g2_gas_and_oil_88':
        final notInspected = _buildPhrasesForScreenId(
          rawData,
          'activity_services_gas_oil_not_inspected',
          isInspection,
        );
        if (notInspected.isNotEmpty) return notInspected;

        final main = _splitMainScreenPhrases(_buildPhrasesForScreenId(
          rawData,
          'activity_services_gas_oil_main_screen',
          isInspection,
        ));
        final repairs = <String>[
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_gas_oil_repair_gas_meter',
            isInspection,
          ),
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_gas_oil_repair_storage_tank_pipework',
            isInspection,
          ),
        ];
        return _dedupeOrderedPhrases([
          ...main.body,
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_main_gas',
            isInspection,
          ),
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_oil',
            isInspection,
          ),
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_gas_oil',
            isInspection,
          ),
          ...withRepairHeading('Gas and Oil Repair', repairs),
          ...main.rating,
          ...main.notes,
        ]);

      case 'group_g3_water_91':
        final notInspected = _buildPhrasesForScreenId(
          rawData,
          'activity_services_water_not_inspected',
          isInspection,
        );
        if (notInspected.isNotEmpty) return notInspected;

        final main = _splitMainScreenPhrases(_buildPhrasesForScreenId(
          rawData,
          'activity_services_water_main_screen',
          isInspection,
        ));
        final standard2 =
            engine.buildStaticSubPhrases('{G_WATER}', '{STANDARD_TEXT_2}');
        final body = _withoutMatchingPhrases(main.body, standard2);
        return _dedupeOrderedPhrases([
          ...body,
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_water_main_water',
            isInspection,
          ),
          ...standard2,
          ...main.rating,
          ...main.notes,
        ]);

      case 'group_g4_heating_92':
        final notInspected = _buildPhrasesForScreenId(
          rawData,
          'activity_services_heating_not_inspected',
          isInspection,
        );
        if (notInspected.isNotEmpty) return notInspected;

        final main = _splitMainScreenPhrases(_buildPhrasesForScreenId(
          rawData,
          'activity_services_heating_main_screen',
          isInspection,
        ));
        final standard2 =
            engine.buildStaticSubPhrases('{G_HEATING}', '{STANDARD_TEXT_2}');
        final repairs = _buildPhrasesForScreenId(
          rawData,
          'activity_services_heating_repair_main_screen',
          isInspection,
        );
        return _dedupeOrderedPhrases([
          ...main.body,
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_heating_about_heating',
            isInspection,
          ),
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_heating_radiators',
            isInspection,
          ),
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_heating_other_heating',
            isInspection,
          ),
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_heating_old_boiler',
            isInspection,
          ),
          ...withRepairHeading('Heating Repair', repairs),
          ...standard2,
          ...main.rating,
          ...main.notes,
        ]);

      case 'group_g5_water_heating_93':
        final notInspected = _buildPhrasesForScreenId(
          rawData,
          'activity_services_water_heating_not_inspected',
          isInspection,
        );
        if (notInspected.isNotEmpty) return notInspected;

        final main = _splitMainScreenPhrases(_buildPhrasesForScreenId(
          rawData,
          'activity_services_water_heating_main_screen',
          isInspection,
        ));
        final standard2 = engine.buildStaticSubPhrases(
          '{G_WATER_HEATING}',
          '{STANDARD_TEXT_2}',
        );
        final body = _withoutMatchingPhrases(main.body, standard2);
        final repairs = <String>[
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_water_heating_repair_leaking_cylinder',
            isInspection,
          ),
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_water_heating_repair_loose_panels',
            isInspection,
          ),
        ];
        return _dedupeOrderedPhrases([
          ...body,
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_water_heating_communal_hot_water',
            isInspection,
          ),
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_water_heating_gas_heating',
            isInspection,
          ),
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_water_heating_electric_heating',
            isInspection,
          ),
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_water_heating_cylinder',
            isInspection,
          ),
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_water_heating_solar_power',
            isInspection,
          ),
          ...withRepairHeading('Water Heating Repair', repairs),
          ...standard2,
          ...main.rating,
          ...main.notes,
        ]);

      case 'group_g6_drainage_96':
        final notInspected = _buildPhrasesForScreenId(
          rawData,
          'activity_services_drainage_not_inspected',
          isInspection,
        );
        if (notInspected.isNotEmpty) return notInspected;

        final main = _splitMainScreenPhrases(_buildPhrasesForScreenId(
          rawData,
          'activity_services_drainage_main_screen',
          isInspection,
        ));
        final standard2 =
            engine.buildStaticSubPhrases('{G_DRAINAGE}', '{STANDARD_TEXT_2}');
        final body = _withoutMatchingPhrases(main.body, standard2);
        final repairs = <String>[
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_drainage_repair_chamber_cover',
            isInspection,
          ),
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_drainage_repair_chamber_walls',
            isInspection,
          ),
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_drainage_repair_chamber_pipes',
            isInspection,
          ),
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_drainage_repair_soil_and_vent',
            isInspection,
          ),
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_drainage_repair_roots_in_chamber',
            isInspection,
          ),
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_drainage_repair_gullies',
            isInspection,
          ),
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_drainage_repair_defect_dampness',
            isInspection,
          ),
        ];
        return _dedupeOrderedPhrases([
          ...body,
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_drainage',
            isInspection,
          ),
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_drainage_chamber_lids',
            isInspection,
          ),
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_drainage_public_system',
            isInspection,
          ),
          ...withRepairHeading('Drainage Repair', repairs),
          ...standard2,
          ...main.rating,
          ...main.notes,
        ]);

      case 'group_g7_common_services_98':
        final notInspected = _buildPhrasesForScreenId(
          rawData,
          'activity_services_shared_services_not_inspected',
          isInspection,
        );
        if (notInspected.isNotEmpty) return notInspected;

        final main = _splitMainScreenPhrases(_buildPhrasesForScreenId(
          rawData,
          'activity_services_common_services_main_screen',
          isInspection,
        ));
        return _dedupeOrderedPhrases([
          ..._buildPhrasesForScreenId(
            rawData,
            'activity_services_shared_services',
            isInspection,
          ),
          ...main.rating,
          ...main.notes,
        ]);
    }

    return const [];
  }

  bool _startsWithTitle(List<String> phrases, String title) {
    if (phrases.isEmpty) return false;
    final first = phrases.first.trim().toLowerCase();
    final normalizedTitle = title.trim().toLowerCase();
    if (normalizedTitle.isEmpty) return false;
    return first == normalizedTitle || first.startsWith('$normalizedTitle:');
  }

  bool _sameTitle(String a, String b) {
    final left = a.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final right = b.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (left.isEmpty || right.isEmpty) return false;
    return left == right;
  }

  List<String> _sectionDSummaryNarrativeFromAnswers(
    String screenId,
    Map<String, String> answers,
  ) {
    final id = screenId.trim().toLowerCase();
    if (id == 'activity_property_location') {
      final from = (answers['android_material_design_spinner2'] ?? '').trim();
      final to = (answers['android_material_design_spinner20'] ?? '').trim();
      final area = (answers['android_material_design_spinner'] ?? '').trim();
      if (from.isNotEmpty && to.isNotEmpty) {
        return [
          'The property is located in an established area with surrounding density ranging from ${from.toLowerCase()} to ${to.toLowerCase()}.'
        ];
      }
      if (from.isNotEmpty || to.isNotEmpty) {
        final density = (from.isNotEmpty ? from : to).toLowerCase();
        return [
          'The property is located in an established area with surrounding density described as $density.'
        ];
      }
      if (area.isNotEmpty && area.toLowerCase() != 'yes') {
        return ['The property is located in a ${area.toLowerCase()} area.'];
      }
      return const [];
    }
    if (id == 'activity_property_facelities') {
      final value = (answers['android_material_design_spinner7'] ?? '')
          .trim()
          .toLowerCase();
      if (value == 'accessible') {
        return const [
          'The local facilities include schools, shops and transport links and appear to be reasonably accessible from the property.'
        ];
      }
      if (value == 'remote') {
        return const [
          'The property is located in a more remote setting and some day-to-day facilities may be further away than usual.'
        ];
      }
      return const [];
    }
    if (id == 'activity_property_local_environment') {
      final status = (answers['android_material_design_spinner8'] ?? '')
          .trim()
          .toLowerCase();
      if (status.contains('no adverse')) {
        return const [
          'There are no known or apparent adverse local environmental features that are likely to materially affect the property.'
        ];
      }
    }
    if (id == 'activity_property_private_road') {
      final status = (answers['android_material_design_spinner3'] ?? '')
          .trim()
          .toLowerCase();
      if (status == 'yes' || status == 'true' || status == 'private') {
        return const [
          'The road outside the property is likely to be a private road and maintenance responsibility should be confirmed by your legal adviser.'
        ];
      }
      if (status == 'no' || status == 'false') {
        return const [
          'The road outside the property is not understood to be private.'
        ];
      }
    }
    if (id == 'activity_property_is_noisy_area') {
      final status = (answers['android_material_design_spinner4'] ?? '')
          .trim()
          .toLowerCase();
      if (status == 'yes' || status == 'true' || status == 'fully') {
        return const [
          'The property is in an area where external noise influences may affect day-to-day enjoyment, saleability and value.'
        ];
      }
    }
    return const [];
  }

  List<String> _sectionDSummaryNarrativeFromFields(
    String screenId,
    List<ReportField> fields,
  ) {
    final id = screenId.trim().toLowerCase();
    String? value(String label) {
      for (final f in fields) {
        if (f.label.trim().toLowerCase() == label.toLowerCase() &&
            f.displayValue.isNotEmpty &&
            f.displayValue != '-') {
          return f.displayValue;
        }
      }
      return null;
    }

    if (id == 'activity_property_location') {
      final from = value('From');
      final to = value('To');
      if (from != null && to != null) {
        return [
          'The property is located in an established area with surrounding density ranging from ${from.toLowerCase()} to ${to.toLowerCase()}.'
        ];
      }
      final one = from ?? to;
      if (one != null) {
        return [
          'The property is located in an established area with surrounding density described as ${one.toLowerCase()}.'
        ];
      }
    }

    if (id == 'activity_property_facelities') {
      final remote = value('Remote');
      if (remote != null) {
        final n = remote.toLowerCase();
        if (n == 'accessible') {
          return const [
            'The local facilities include schools, shops and transport links and appear to be reasonably accessible from the property.'
          ];
        }
        return [
          'Local facilities are recorded as $n for this property location.'
        ];
      }
    }

    if (id == 'activity_property_local_environment') {
      final flooding = value('Flooding');
      if (flooding != null && flooding.toLowerCase() == 'no adverse') {
        return const [
          'There are no known or apparent adverse local environmental features that are likely to materially affect the property.'
        ];
      }
      if (flooding != null) {
        return [
          'Local environmental factors were noted, including flooding risk recorded as ${flooding.toLowerCase()}.'
        ];
      }
    }

    if (id == 'activity_property_private_road') {
      final status = value('Status');
      if (status != null) {
        final s = status.toLowerCase();
        if (s == 'yes') {
          return const [
            'The road outside the property is likely to be a private road and maintenance responsibility should be confirmed by your legal adviser.'
          ];
        }
        if (s == 'no') {
          return const [
            'The road outside the property is not understood to be private.'
          ];
        }
      }
    }

    if (id == 'activity_property_is_noisy_area') {
      final status = value('Status');
      if (status != null && status.toLowerCase() != 'no') {
        return const [
          'The property is in an area where external noise influences may affect day-to-day enjoyment, saleability and value.'
        ];
      }
    }
    return const [];
  }

  List<String> _narrativeFallbackForIssuesRisks(
    String screenTitle,
    List<ReportField> fields,
  ) {
    final points = <String>[];
    for (final f in fields) {
      if (f.displayValue.isEmpty || f.displayValue == '-') continue;
      if (f.type == ReportFieldType.checkbox) {
        if (f.displayValue == 'Yes') {
          points.add(f.label.trim().replaceFirst(RegExp(r'[.,;:!?]+\s*$'), ''));
        }
      } else {
        final label = f.label.trim().replaceFirst(RegExp(r'[.,;:!?]+\s*$'), '');
        final value =
            f.displayValue.trim().replaceFirst(RegExp(r'[.,;:!?]+\s*$'), '');
        points.add('$label: $value');
      }
    }
    if (points.isEmpty) return const [];
    final body = points.join(', ').replaceFirst(RegExp(r'[.,;:!?]+\s*$'), '');
    return ['The following matters were identified in $screenTitle: $body.'];
  }

  List<String> _legacyDerivedSectionFIssueGuarantees(V2RawReportData rawData) {
    final phrases = <String>[];
    final cellar = _answersForScreen(
        rawData, 'activity_inside_property_other_celler_damp');
    final basement = _answersForScreen(
        rawData, 'activity_inside_property_other_celler_damp__serious_damp');

    if (_isCheckedValue(cellar['cb_serious_dump'])) {
      phrases.add(
          'You should check with your legal adviser to see if the dampness problem repair is covered by any guarantees or warranties.');
    }
    if (_isCheckedValue(basement['cb_serious_dump'])) {
      phrases.add(
          'You should check with your legal adviser to see if the dampness problem is covered by any guarantees or warranties.');
    }
    return _cleanupPhrases(phrases);
  }

  List<String> _legacyDerivedSectionFRiskToBuilding(V2RawReportData rawData) {
    final phrases = <String>[];

    final woodMain =
        _answersForScreen(rawData, 'activity_in_side_property_wood_work');
    if (_isCheckedValue(woodMain['cb_out_of_square_doors'])) {
      phrases.add(
          'Some internal doors and frame are distorted and do not shut properly. This may have been affected by past settlement.');
    }

    final infestation = _answersForScreen(
        rawData, 'activity_in_side_property_wood_work_repair_infestation');
    final severity =
        (infestation['actv_condition'] ?? infestation['llMainContainer'] ?? '')
            .trim()
            .toLowerCase();
    final infestationParts = _labelsForAnswerMap(
      infestation,
      const <String, String>{
        'cb_staircase': 'staircase',
        'cb_floorboards': 'floorboards',
        'cb_skirting': 'skirting',
        'cb_under_stairs': 'under stairs',
        'cb_cupboards': 'cupboards',
        'cb_other_1032': 'other',
      },
      otherCheckboxId: 'cb_other_1032',
      otherTextId: 'et_other_728',
    );
    final infestationLocations = _labelsForAnswerMap(
      infestation,
      const <String, String>{
        'cb_plastic': 'lounge',
        'cb_cast_iron': 'reception',
        'cb_asbestos_cement': 'dining room',
        'cb_concrete': 'kitchen',
        'cb_Bedroom': 'bedroom',
        'cb_other_697': 'other',
      },
      otherCheckboxId: 'cb_other_697',
      otherTextId: 'et_other_427',
    );
    if (severity == 'minor' &&
        infestationParts.isNotEmpty &&
        infestationLocations.isNotEmpty) {
      phrases.add(
          'I found an active infestation of wood-boring insects in parts of the ${_toLegacyWords(infestationParts)} timber in the ${_toLegacyWords(infestationLocations)}.');
    } else if (severity == 'major' &&
        infestationParts.isNotEmpty &&
        infestationLocations.isNotEmpty) {
      phrases.add(
          'I found a large and active infestation of wood-boring insects in parts of the staircase timber.');
    }

    final dampTimber = _answersForScreen(
        rawData, 'activity_in_side_property_wood_work_repair_damp_timber');
    final dampComponents = _labelsForAnswerMap(
      dampTimber,
      const <String, String>{
        'cb_staircase': 'staircase',
        'cb_floorboards': 'floorboards',
        'cb_skirting': 'skirting',
        'cb_under_stairs': 'under stairs',
        'cb_cupboards': 'cupboards',
        'cb_other_270': 'other',
      },
      otherCheckboxId: 'cb_other_270',
      otherTextId: 'et_other_516',
    );
    final dampLocations = _labelsForAnswerMap(
      dampTimber,
      const <String, String>{
        'cb_lounge_72': 'lounge',
        'cb_reception_49': 'reception',
        'cb_dining_room_84': 'dining room',
        'cb_kitchen_72': 'kitchen',
        'cb_bedroom_44': 'bedroom',
        'cb_other_750': 'other',
      },
      otherCheckboxId: 'cb_other_750',
      otherTextId: 'et_other_302',
    );
    final dampDefects = _labelsForAnswerMap(
      dampTimber,
      const <String, String>{
        'cb_damp': 'damp',
        'cb_rotten': 'rotten',
        'cb_other_498': 'other',
      },
      otherCheckboxId: 'cb_other_498',
      otherTextId: 'et_other_534',
    );
    if (dampComponents.isNotEmpty &&
        dampLocations.isNotEmpty &&
        dampDefects.isNotEmpty) {
      phrases.add(
          'The timber ${_toLegacyWords(dampComponents)} in the ${_toLegacyWords(dampLocations)} is ${_toLegacyWords(dampDefects)}.');
    }

    final leaking = _answersForScreen(
        rawData, 'activity_in_side_property_bathroom_fittings_leaking');
    final leakingLocations = _labelsForAnswerMap(
      leaking,
      const <String, String>{
        'cb_bathtub': 'bathtub',
        'cb_shower': 'shower',
        'cb_wc': 'wc',
        'cb_wash_hand_basin': 'wash hand basin',
        'cb_urinal': 'urinal',
        'cb_other_937': 'other',
      },
      otherCheckboxId: 'cb_other_937',
      otherTextId: 'et_other_861',
    );
    if (leakingLocations.isNotEmpty) {
      final locationsText = _toLegacyWords(leakingLocations);
      phrases.add(
          'The $locationsText ${_legacyIsAre(leakingLocations)} leaking and causing dampness to nearby elements.');
    }

    return _cleanupPhrases(phrases);
  }

  List<String> _legacyDerivedSectionFRiskToPeople(V2RawReportData rawData) {
    final phrases = <String>[];

    final woodMain =
        _answersForScreen(rawData, 'activity_in_side_property_wood_work');
    if (_isCheckedValue(woodMain['cb_glazed_internal_doors'])) {
      phrases.add(
          'One or more internal doors are glazed, and it is not possible to confirm whether safety glass has been fitted.');
    }
    if (_isCheckedValue(woodMain['cb_no_stairs_handrails'])) {
      phrases.add(
          'There are no handrails installed to the staircase, and this is safety hazards as anyone, especially children, can fall off the edge of the stairs.');
    }

    final balusters = _answersForScreen(
        rawData, 'activity_in_side_property_wood_work_repair_balusters');
    final balusterDefects = _labelsForAnswerMap(
      balusters,
      const <String, String>{
        'cb_too_far_apart_93': 'too far apart',
        'cb_missing_47': 'missing',
        'cb_broken_89': 'broken',
        'cb_other_890': 'other',
      },
      otherCheckboxId: 'cb_other_890',
      otherTextId: 'et_other_516',
    );
    if (balusterDefects.isNotEmpty) {
      phrases.add(
          'The balusters are ${_toLegacyWords(balusterDefects)} and are a safety hazard because they could allow small children to fall through or become trapped.');
    }

    final noSafetyGlass = _answersForScreen(
        rawData, 'activity_in_side_property_cubicle_safety_glass_rating');
    final noSafetyLocations = _labelsForAnswerMap(
      noSafetyGlass,
      const <String, String>{
        'cb_shower_cubicle': 'shower cubicle',
        'cb_bathtub': 'bathtub screen',
        'cb_other_1084': 'other',
      },
      otherCheckboxId: 'cb_other_1084',
      otherTextId: 'et_other_843',
    );
    if (noSafetyLocations.isNotEmpty) {
      phrases.add(
          'I could not find evidence that the glass screen to the ${_toLegacyWords(noSafetyLocations)} is safety glass. Anyone falling against the glass serene may get hurt.');
    }

    final bathroomRepair = _answersForScreen(
        rawData, 'activity_in_side_property_bathroom_fittings_repair');
    final repairType = (bathroomRepair['actv_repair_type'] ??
            bathroomRepair['llMainContainer'] ??
            '')
        .trim()
        .toLowerCase();
    final repairLocations = _labelsForAnswerMap(
      bathroomRepair,
      const <String, String>{
        'cb_bathtub_52': 'bathtub',
        'cb_shower_tray_31': 'shower tray',
        'cb_shower_glass_cubicle_24': 'shower glass cubicle',
        'cb_wc_89': 'wc',
        'cb_wash_hand_basin_60': 'wash hand basin',
        'cb_urinal_90': 'urinal',
        'cb_bidet_13': 'bidet',
        'cb_other_609': 'other',
      },
      otherCheckboxId: 'cb_other_609',
      otherTextId: 'et_other_791',
    );
    final repairDefects = _labelsForAnswerMap(
      bathroomRepair,
      const <String, String>{
        'cb_badly_leaking_38': 'badly leaking',
        'cb_very_loose_28': 'very loose',
        'cb_badly_cracked_62': 'badly cracked',
        'cb_not_working_33': 'not working',
        'cb_not_connected_98': 'not connected',
        'cb_poorly_secured_48': 'poorly secured',
        'cb_blocked_34': 'blocked',
        'cb_other_398': 'other',
      },
      otherCheckboxId: 'cb_other_398',
      otherTextId: 'et_other_824',
    );
    final hasRiskDefect =
        _isCheckedValue(bathroomRepair['cb_badly_cracked_62']) ||
            _isCheckedValue(bathroomRepair['cb_poorly_secured_48']);
    if (repairType.contains('now') &&
        hasRiskDefect &&
        repairLocations.isNotEmpty &&
        repairDefects.isNotEmpty) {
      phrases.add(
          'The ${_toLegacyWords(repairLocations)} is ${_toLegacyWords(repairDefects)}.');
    }

    return _cleanupPhrases(phrases);
  }

  List<String> _labelsForAnswerMap(
    Map<String, String> answers,
    Map<String, String> mapping, {
    String? otherCheckboxId,
    String? otherTextId,
  }) {
    final labels = <String>[];
    for (final entry in mapping.entries) {
      if (_isCheckedValue(answers[entry.key])) {
        labels.add(entry.value);
      }
    }
    if (otherCheckboxId != null &&
        otherTextId != null &&
        _isCheckedValue(answers[otherCheckboxId])) {
      final other = (answers[otherTextId] ?? '').trim();
      if (other.isNotEmpty) labels.add(other.toLowerCase());
    }
    return labels;
  }

  String _toLegacyWords(List<String> items) {
    final cleaned = items
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (cleaned.isEmpty) return '';
    if (cleaned.length == 1) return cleaned.first;
    if (cleaned.length == 2) return '${cleaned.first} and ${cleaned.last}';
    return '${cleaned.sublist(0, cleaned.length - 1).join(', ')} and ${cleaned.last}';
  }

  String _legacyIsAre(List<String> items) => items.length > 1 ? 'are' : 'is';

  String _mergedSubheading(String title) =>
      '$_mergedSubheadingPrefix${title.trim()}';

  int _sectionDScreenSortRank(ReportScreen screen) {
    final id = screen.screenId.trim().toLowerCase();
    if (id == 'activity_property_type') return 10;
    if (id == 'activity_property_built_year' ||
        id == 'activity_property_built') {
      return 20;
    }
    if (id == 'activity_property_extended') return 30;
    if (id == 'activity_property_converted') return 40;
    if (id == 'activity_property_flate') return 50;
    if (id == 'group_construction_2') return 60;
    if (_isListedBuildingScreenId(id)) return 70;
    if (id == 'section_d_energy_merged') return 80;
    if (id == 'activity_property_location') return 90;
    if (id == 'activity_property_facelities') return 100;
    if (id == 'activity_property_local_environment') return 110;
    if (id == 'activity_property_private_road') return 120;
    if (id == 'activity_property_is_noisy_area') return 130;
    return 1000;
  }

  List<String> _legacyStyleSectionDConstructionPhrases(List<String> phrases) {
    if (phrases.isEmpty) return const <String>[];

    final labelValues = <String, String>{};
    final narrative = <String>[];
    final labelPattern = RegExp(r'^\s*([^:]+):\s*(.+?)\s*$');

    for (final phrase in phrases) {
      final m = labelPattern.firstMatch(phrase);
      if (m == null) {
        narrative.add(phrase.trim());
        continue;
      }
      final key = (m.group(1) ?? '').trim().toLowerCase();
      final value = _cleanConstructionValue(m.group(2) ?? '');
      if (key.isEmpty || value.isEmpty) {
        narrative.add(phrase.trim());
        continue;
      }
      labelValues[key] = value;
    }

    // If there are no known construction labels, keep original phrasing.
    const knownKeys = <String>{
      'roof type',
      'roof material',
      'cover type',
      'extension walls',
      'finishes',
      'internal walls',
      'floors',
      'windows',
      'window material',
    };
    if (!labelValues.keys.any(knownKeys.contains)) {
      return List<String>.from(phrases);
    }

    final out = <String>[];
    if (narrative.isNotEmpty) {
      out.add(narrative.first);
    }

    final roofType = labelValues['roof type'];
    final roofMaterial = labelValues['roof material'];
    final coverType = labelValues['cover type'];
    if ((roofType ?? '').isNotEmpty ||
        (roofMaterial ?? '').isNotEmpty ||
        (coverType ?? '').isNotEmpty) {
      final bits = <String>[];
      if ((roofType ?? '').isNotEmpty) bits.add('The roof type is $roofType');
      if ((roofMaterial ?? '').isNotEmpty) {
        bits.add('the roof material is $roofMaterial');
      }
      if ((coverType ?? '').isNotEmpty)
        bits.add('the roof cover is $coverType');
      out.add('${bits.join(', ')}.');
    }

    final extensionWalls = labelValues['extension walls'];
    if ((extensionWalls ?? '').isNotEmpty) {
      out.add('The main external walls are built of $extensionWalls.');
    }

    final finishes = labelValues['finishes'];
    if ((finishes ?? '').isNotEmpty) {
      out.add('The external wall finishes are $finishes.');
    }

    final internalWalls = labelValues['internal walls'];
    if ((internalWalls ?? '').isNotEmpty) {
      out.add('The internal walls are built of $internalWalls.');
    }

    final floors = labelValues['floors'];
    if ((floors ?? '').isNotEmpty) {
      out.add('The floors are built of $floors.');
    }

    final windows = labelValues['windows'];
    final windowMaterial = labelValues['window material'];
    if ((windows ?? '').isNotEmpty || (windowMaterial ?? '').isNotEmpty) {
      if ((windows ?? '').isNotEmpty && (windowMaterial ?? '').isNotEmpty) {
        out.add(
            'The windows are mainly $windows and are formed in $windowMaterial.');
      } else if ((windows ?? '').isNotEmpty) {
        out.add('The windows are mainly $windows.');
      } else {
        out.add('The windows are formed in $windowMaterial.');
      }
    }

    return _cleanupPhrases(out);
  }

  String _cleanConstructionValue(String raw) {
    var v = raw.trim();
    if (v.isEmpty) return '';
    if (RegExp(r'^\.+$').hasMatch(v)) return '';
    v = v.replaceAll(RegExp(r'\s+'), ' ');
    v = v.replaceAll(RegExp(r'\.\.+'), '.');
    v = v.replaceAll(RegExp(r'^\.+|\.+$'), '');
    v = v.replaceAll(
      RegExp(r'\bmainly of mainly of\b', caseSensitive: false),
      'mainly of',
    );
    v = v.replaceAll(
      RegExp(r'\bmainly mainly\b', caseSensitive: false),
      'mainly',
    );
    return v.trim();
  }

  List<String> _cleanupPhrases(List<String> phrases) {
    final out = <String>[];
    final seen = <String>{};
    for (final phrase in phrases) {
      final cleaned = _cleanupPhrase(phrase);
      if (cleaned.isEmpty) continue;
      final key = cleaned
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .trim();
      if (key.isEmpty) continue;
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(cleaned);
    }
    return out;
  }

  String _cleanupPhrase(String phrase) {
    var v = phrase.trim();
    if (v.isEmpty) return '';
    v = v.replaceAll(RegExp(r'\.\.+'), '.');
    v = v.replaceAll(RegExp(r'\s+'), ' ');
    v = v.replaceAll(
      RegExp(r'\bother\s+and\s+other\b', caseSensitive: false),
      'other',
    );
    v = v.replaceAll(RegExp(r'\s+([,.;:])'), r'$1');
    v = v.replaceAll(RegExp(r'([,;:])\.'), '.');
    v = v.replaceAll(RegExp(r'\.\s*\.'), '.');
    v = v.trim();
    if (RegExp(r'^not inspected phrase\.?$', caseSensitive: false)
        .hasMatch(v)) {
      return '';
    }
    if (RegExp(r'^[^:]{1,80}:\s*$').hasMatch(v)) return '';
    if (RegExp(r'^\.+$').hasMatch(v)) return '';
    if (_looksLikeRawOptionDump(v)) return '';
    return v;
  }

  bool _shouldCondensePhrasesAsParagraph(String normalizedScreenId) =>
      normalizedScreenId == 'activity_outside_property_stacks';

  List<String> _condenseIfNeeded(
    String normalizedScreenId,
    List<String> phrases,
  ) {
    if (!_shouldCondensePhrasesAsParagraph(normalizedScreenId)) {
      return phrases;
    }
    if (phrases.length <= 1) return phrases;
    final paragraph = phrases.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return paragraph.isEmpty ? const [] : <String>[paragraph];
  }

  bool _looksLikeRawOptionDump(String phrase) {
    final normalized = phrase.trim();
    if (normalized.isEmpty) return false;
    final commaCount = ','.allMatches(normalized).length;
    final lower = normalized.toLowerCase();
    if (commaCount < 3) return false;
    if (lower.contains(':')) return false;

    const sentenceStarts = <String>[
      'the ',
      'there ',
      'it ',
      'this ',
      'we ',
      'you ',
      'i ',
    ];
    if (sentenceStarts.any(lower.startsWith)) return false;

    const verbHints = <String>[
      ' should ',
      ' recommend',
      ' because ',
      ' therefore ',
      ' however ',
      ' although ',
      ' during ',
      ' where ',
    ];
    if (verbHints.any(lower.contains)) return false;

    final stripped = lower.replaceAll(RegExp(r'[.;:]$'), '');
    final parts = stripped
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.length < 4) return false;

    final longPartCount =
        parts.where((p) => p.split(RegExp(r'\s+')).length > 4).length;
    final shortPartCount = parts.length - longPartCount;
    final mostlyShort = shortPartCount / parts.length >= 0.8;
    if (!mostlyShort) return false;

    return true;
  }

  bool _isListedBuildingScreenId(String screenId) =>
      _listedBuildingScreenIds.contains(screenId.trim().toLowerCase());

  List<String> _screenIdCandidates(String screenId) {
    final id = screenId.trim().toLowerCase();
    if (id == 'activity_listed_building') {
      return const <String>[
        'activity_listed_building',
        'activity_listed_building__listed_building',
      ];
    }
    if (id == 'activity_listed_building__listed_building') {
      return const <String>[
        'activity_listed_building__listed_building',
        'activity_listed_building',
      ];
    }
    return <String>[screenId];
  }

  Map<String, String> _answersForScreen(
      V2RawReportData rawData, String screenId) {
    for (final candidate in _screenIdCandidates(screenId)) {
      final answers = rawData.allAnswers[candidate];
      if (answers != null) return answers;
    }
    return const <String, String>{};
  }

  List<String>? _persistedPhrasesForScreen(
      V2RawReportData rawData, String screenId) {
    for (final candidate in _screenIdCandidates(screenId)) {
      final phrases = rawData.persistedPhrases[candidate];
      if (phrases != null) return phrases;
    }
    return null;
  }

  String _noteForScreen(V2RawReportData rawData, String screenId) {
    for (final candidate in _screenIdCandidates(screenId)) {
      final note = rawData.persistedUserNotes[candidate];
      if (note != null && note.isNotEmpty) return note;
    }
    return '';
  }

  bool _isSectionDEnergyScreen(
    InspectionSectionDefinition sectionDef,
    InspectionNodeDefinition node,
  ) {
    if (node.type != InspectionNodeType.screen) return false;
    if (sectionDef.key.trim().toUpperCase() != 'D') return false;
    return _sectionDEnergyScreenOrder.contains(node.id.trim().toLowerCase());
  }

  static bool _isCheckedValue(String? value) {
    final v = (value ?? '').trim().toLowerCase();
    return v == 'true' || v == '1' || v == 'yes';
  }

  List<String> _buildLegacySectionDEnergyPhrases(V2RawReportData rawData) {
    final energyAnswers =
        _answersForScreen(rawData, 'activity_energy_effiency');
    final impactAnswers =
        _answersForScreen(rawData, 'activity_energy_environment_impect');
    final otherAnswers = _answersForScreen(rawData, 'activity_other_service');

    final energyCurrent =
        (energyAnswers['android_material_design_spinner'] ?? '').trim();
    final energyPotential =
        (energyAnswers['android_material_design_spinner2'] ?? '').trim();
    final impactCurrent =
        (impactAnswers['android_material_design_spinner'] ?? '').trim();
    final impactPotential =
        (impactAnswers['android_material_design_spinner2'] ?? '').trim();
    final hasSolarElectricity = _isCheckedValue(otherAnswers['ch1']);
    final hasSolarHotWater = _isCheckedValue(otherAnswers['ch2']);

    final hasAnyData = energyCurrent.isNotEmpty ||
        energyPotential.isNotEmpty ||
        impactCurrent.isNotEmpty ||
        impactPotential.isNotEmpty ||
        hasSolarElectricity ||
        hasSolarHotWater;
    if (!hasAnyData) return const [];

    String ratingSentence({
      required String label,
      required String current,
      required String potential,
    }) {
      if (current.isEmpty && potential.isEmpty) {
        return '$label data was not available from the EPC records at the time of inspection.';
      }
      if (current.isEmpty) {
        return "$label is recorded as potential $potential (current rating not available).";
      }
      if (potential.isEmpty) {
        return "$label is recorded as current $current (potential rating not available).";
      }
      return '$label is recorded as current $current and potential $potential.';
    }

    final phrases = <String>[
      "We are advised that the property's current energy performance, as recorded in the EPC, is as follows.",
      ratingSentence(
        label: 'Energy performance rating',
        current: energyCurrent,
        potential: energyPotential,
      ),
      ratingSentence(
        label: 'Environmental impact rating',
        current: impactCurrent,
        potential: impactPotential,
      ),
      'Other services:',
    ];

    if (!hasSolarElectricity && !hasSolarHotWater) {
      phrases.add(
        'No other energy-related services were identified at the time of inspection.',
      );
      return phrases;
    }

    if (hasSolarElectricity) {
      phrases.add(
        'The property has photovoltaic panels designed to produce electricity from sunlight installed on the roof slope(s).',
      );
    }
    if (hasSolarHotWater) {
      phrases.add(
        'The property has solar water heating panels installed on the roof slope(s).',
      );
    }
    return phrases;
  }

  ReportScreen? _buildMergedSectionDEnergyScreen(
    InspectionSectionDefinition sectionDef,
    V2RawReportData rawData,
    ExportConfig config,
    bool isInspection,
  ) {
    final nodesById = <String, InspectionNodeDefinition>{
      for (final n in sectionDef.nodes) n.id.trim().toLowerCase(): n,
    };
    final screens = <InspectionNodeDefinition>[];
    for (final id in _sectionDEnergyScreenOrder) {
      final node = nodesById[id];
      if (node != null) screens.add(node);
    }
    if (screens.isEmpty) return null;

    final mergedPhrases = <String>[];
    final mergedFields = <ReportField>[];
    final mergedNotes = <String>[];

    if (config.includePhrases) {
      final legacyPhrases = _buildLegacySectionDEnergyPhrases(rawData);
      if (legacyPhrases.isNotEmpty) {
        mergedPhrases.addAll(legacyPhrases);
      }
    }

    for (final screen in screens) {
      final note = _noteForScreen(rawData, screen.id);
      if (note.isNotEmpty) mergedNotes.add(note);

      final answers = _answersForScreen(rawData, screen.id);
      final fields = _buildFields(screen, answers);

      if (config.includePhrases && mergedPhrases.isEmpty) {
        final screenPhrases = _phrasesForScreen(screen, rawData, isInspection);
        if (screenPhrases.isNotEmpty) {
          mergedPhrases.addAll(screenPhrases);
        } else {
          final fallback = _fieldsToPhrases(fields);
          if (fallback.isNotEmpty) {
            mergedPhrases.addAll(fallback);
          } else if (fields.any((f) => f.displayValue.isNotEmpty)) {
            mergedFields.addAll(fields);
          }
        }
      } else if (fields.any((f) => f.displayValue.isNotEmpty)) {
        mergedFields.addAll(fields);
      }
    }

    if (mergedPhrases.isEmpty &&
        mergedFields.isEmpty &&
        mergedNotes.isEmpty &&
        !config.includeEmptyScreens) {
      return null;
    }

    final title = screens.first.title;
    return ReportScreen(
      screenId: 'section_d_energy_merged',
      title: title,
      fields: mergedPhrases.isNotEmpty ? const [] : mergedFields,
      phrases: mergedPhrases,
      userNote: mergedNotes.join('\n'),
      isMergedGroup: true,
    );
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
    final nodeIndexById = <String, int>{
      for (var i = 0; i < sectionDef.nodes.length; i++)
        sectionDef.nodes[i].id: i,
    };
    for (final node in sectionDef.nodes) {
      final pid = node.parentId ?? '_root_';
      childrenOf.putIfAbsent(pid, () => []).add(node);
    }
    // Preserve tree intent: descendants should follow explicit node.order,
    // not arbitrary JSON placement. Keep sort stable via source index.
    for (final list in childrenOf.values) {
      list.sort((a, b) {
        final orderA = a.order ?? 9999;
        final orderB = b.order ?? 9999;
        if (orderA != orderB) return orderA.compareTo(orderB);
        final idxA = nodeIndexById[a.id] ?? 0;
        final idxB = nodeIndexById[b.id] ?? 0;
        return idxA.compareTo(idxB);
      });
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
      var emittedSectionDEnergy = false;
      var emittedListedBuilding = false;

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

          final group = topLevelGroups.firstWhere((g) => g.id == ownerGroupId);
          final descendants = _orderedMergedGroupDescendants(
            sectionDef,
            group,
            groupDescendants[ownerGroupId]!,
          );
          final isLegacyConstructionSummary =
              _isSectionDConstructionGroup(sectionDef, group);
          final isLegacySectionGSummary =
              _isSectionGLegacyGroup(sectionDef, group);
          final useLegacySectionGComposite = config.includePhrases &&
              isLegacySectionGSummary &&
              inspectionPhraseEngine != null;
          final includeSubheadings = _shouldShowMergedDescendantSubheadings(
            sectionDef,
            group,
            descendants,
          );
          final groupReportTitle = _reportTitleForNode(sectionDef.key, group);

          final mergedPhrases = <String>[];
          final mergedNotes = <String>[];
          final mergedFields = <ReportField>[];

          if (useLegacySectionGComposite) {
            mergedPhrases.addAll(
              _legacySectionGGroupPhrases(group, rawData, isInspection),
            );
          }

          for (final screen in descendants) {
            if (useLegacySectionGComposite) {
              final note = rawData.persistedUserNotes[screen.id] ?? '';
              if (note.isNotEmpty) mergedNotes.add(note);
              continue;
            }
            // Legacy report keeps listed building as a standalone item.
            if (isLegacyConstructionSummary &&
                _isListedBuildingScreenId(screen.id)) {
              continue;
            }
            final note = rawData.persistedUserNotes[screen.id] ?? '';
            if (note.isNotEmpty) mergedNotes.add(note);

            final answers = _answersForScreen(rawData, screen.id);
            final fields = _buildFields(screen, answers);

            if (config.includePhrases) {
              final screenPhrases =
                  _phrasesForScreen(screen, rawData, isInspection);
              final screenReportTitle = _reportTitleForNode(
                sectionDef.key,
                screen,
              );
              if (screenPhrases.isNotEmpty) {
                if (includeSubheadings &&
                    screenReportTitle.trim().isNotEmpty &&
                    !_sameTitle(screenReportTitle, groupReportTitle) &&
                    !_startsWithTitle(screenPhrases, screenReportTitle)) {
                  mergedPhrases.add(_mergedSubheading(screenReportTitle));
                }
                if (isLegacyConstructionSummary) {
                  mergedPhrases.addAll(screenPhrases.take(2));
                } else {
                  mergedPhrases.addAll(screenPhrases);
                }
              } else {
                // No phrase handler — convert fields to narrative phrases
                // so data is not lost when other screens do have phrases.
                final fallback = _shouldUseRawFieldFallback(screen.id)
                    ? _fieldsToPhrases(fields)
                    : const <String>[];
                if (fallback.isNotEmpty) {
                  if (includeSubheadings &&
                      screenReportTitle.trim().isNotEmpty &&
                      !_sameTitle(screenReportTitle, groupReportTitle) &&
                      !_startsWithTitle(fallback, screenReportTitle)) {
                    mergedPhrases.add(_mergedSubheading(screenReportTitle));
                  }
                  if (isLegacyConstructionSummary) {
                    mergedPhrases.addAll(fallback.take(2));
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

          // Safety fallback: if Construction still has no phrases, regenerate
          // compact narrative directly from saved answers per child screen.
          if (isLegacyConstructionSummary && mergedPhrases.isEmpty) {
            for (final screen in descendants) {
              final answers = _answersForScreen(rawData, screen.id);
              if (answers.isEmpty) continue;
              final regenerated =
                  _buildPhrases(screen.id, answers, isInspection);
              if (regenerated.isNotEmpty) {
                mergedPhrases.addAll(regenerated.take(2));
                continue;
              }
              final fallbackFields = _buildFields(screen, answers);
              final fallbackPhrases = _fieldsToPhrases(fallbackFields);
              if (fallbackPhrases.isNotEmpty) {
                mergedPhrases.addAll(fallbackPhrases.take(2));
              }
            }
          }

          if (isLegacyConstructionSummary && mergedPhrases.isNotEmpty) {
            final rewritten =
                _legacyStyleSectionDConstructionPhrases(mergedPhrases);
            mergedPhrases
              ..clear()
              ..addAll(rewritten);
          }

          final cleanedMergedPhrases = _cleanupPhrases(mergedPhrases);

          // Skip truly empty groups (no phrases, no fields, no notes)
          // Legacy structural parity: keep About Property's
          // Construction heading in report flow.
          final keepEmptySectionDGroup = isLegacyConstructionSummary;
          if (cleanedMergedPhrases.isEmpty &&
              mergedFields.isEmpty &&
              mergedNotes.isEmpty &&
              !keepEmptySectionDGroup &&
              !config.includeEmptyScreens) {
            continue;
          }

          // When phrases exist, use them (professional style).
          // When phrases are empty but fields have data, fall back to
          // field table so no user data is silently dropped.
          screens.add(ReportScreen(
            screenId: group.id,
            title: _reportTitleForNode(sectionDef.key, group),
            fields: cleanedMergedPhrases.isNotEmpty ? const [] : mergedFields,
            phrases: cleanedMergedPhrases,
            userNote: mergedNotes.join('\n'),
            isMergedGroup: true,
          ));
          continue;
        }

        // ── Standalone screen (not consumed by any group) ─────────
        if (node.type != InspectionNodeType.screen) continue;
        if (consumedScreenIds.contains(node.id)) continue;
        if (_isListedBuildingScreenId(node.id)) {
          if (emittedListedBuilding) continue;
          emittedListedBuilding = true;
        }
        if (_isSectionDEnergyScreen(sectionDef, node)) {
          if (emittedSectionDEnergy) continue;
          emittedSectionDEnergy = true;
          final mergedEnergy = _buildMergedSectionDEnergyScreen(
            sectionDef,
            rawData,
            config,
            isInspection,
          );
          if (mergedEnergy != null) screens.add(mergedEnergy);
          continue;
        }

        final entry = _buildScreenEntry(
          sectionDef.key,
          node,
          rawData,
          config,
          isInspection,
        );
        if (entry != null) screens.add(entry);
      }
    } else {
      // ── No numbered groups in this section — flat mode (unchanged) ──
      var emittedSectionDEnergy = false;
      var emittedListedBuilding = false;
      for (final node in sectionDef.nodes) {
        if (node.type != InspectionNodeType.screen) continue;
        if (_isListedBuildingScreenId(node.id)) {
          if (emittedListedBuilding) continue;
          emittedListedBuilding = true;
        }
        if (_isSectionDEnergyScreen(sectionDef, node)) {
          if (emittedSectionDEnergy) continue;
          emittedSectionDEnergy = true;
          final mergedEnergy = _buildMergedSectionDEnergyScreen(
            sectionDef,
            rawData,
            config,
            isInspection,
          );
          if (mergedEnergy != null) screens.add(mergedEnergy);
          continue;
        }
        final entry = _buildScreenEntry(
          sectionDef.key,
          node,
          rawData,
          config,
          isInspection,
        );
        if (entry != null) screens.add(entry);
      }
    }

    if (sectionDef.key.trim().toUpperCase() == 'D') {
      final indexed = screens.asMap().entries.toList();
      indexed.sort((a, b) {
        final ra = _sectionDScreenSortRank(a.value);
        final rb = _sectionDScreenSortRank(b.value);
        if (ra != rb) return ra.compareTo(rb);
        return a.key.compareTo(b.key);
      });
      screens
        ..clear()
        ..addAll(indexed.map((e) => e.value));
    }

    final sectionKey = sectionDef.key.trim().toUpperCase();

    if (isInspection && sectionKey == 'G') {
      screens.insert(0, _legacyGLimitationsScreen());
    }

    if (sectionKey == 'J') {
      final riskToPeople = _legacyDerivedSectionFRiskToPeople(rawData);
      if (riskToPeople.isNotEmpty) {
        final j2Screen = ReportScreen(
          screenId: 'derived_j2_risk_to_people',
          title: 'J2 Risk To People',
          fields: const <ReportField>[],
          phrases: riskToPeople,
        );
        final insertAt = screens.indexWhere(
          (s) => s.screenId.trim().toLowerCase() == 'activity_risks_other_',
        );
        if (insertAt >= 0) {
          screens.insert(insertAt, j2Screen);
        } else {
          screens.add(j2Screen);
        }
      }
    }

    _disambiguateGenericScreenTitles(screens, sectionDef.nodes);

    if (screens.isEmpty &&
        !config.includeEmptyScreens &&
        isInspection &&
        sectionDef.key.trim().toUpperCase() == 'K') {
      return ReportSection(
        key: 'K',
        title: 'K – Additional assumption(s)',
        description: sectionDef.description,
        displayOrder: displayOrder,
        screens: const <ReportScreen>[
          ReportScreen(
            screenId: 'k_additional_assumptions_default',
            title: 'K – Additional assumption(s)',
            fields: <ReportField>[],
            phrases: <String>[
              'My opinion has been arrived at largely on the basis of the standard assumptions governing residential valuations. (These are outlined in this section and under market value in the description of the Home Survey Service).',
              'The purchase price provided is a reflection of current market conditions and the result of shortages of properties with too many buyers in the market and is considered to be the maximum likely to be achieved under present market conditions. Any deterioration in condition or downturn in market activity could lead to this figure not being achieved on early resale.',
            ],
          ),
          ReportScreen(
            screenId: 'k_other_considerations_default',
            title: 'K - Other Considerations',
            fields: <ReportField>[],
            phrases: <String>['No further comments.'],
          ),
        ],
      );
    }

    if (screens.isEmpty && !config.includeEmptyScreens) return null;

    return ReportSection(
      key: sectionDef.key,
      title: sectionDef.title,
      description: sectionDef.description,
      screens: screens,
      displayOrder: displayOrder,
    );
  }

  void _disambiguateGenericScreenTitles(
    List<ReportScreen> screens,
    List<InspectionNodeDefinition> sectionNodes,
  ) {
    if (screens.isEmpty) return;

    final nodeById = <String, InspectionNodeDefinition>{
      for (final n in sectionNodes) n.id.trim().toLowerCase(): n,
    };

    final titleCounts = <String, int>{};
    for (final screen in screens) {
      final t = screen.title.trim().toLowerCase();
      if (t.isEmpty) continue;
      titleCounts[t] = (titleCounts[t] ?? 0) + 1;
    }

    for (var i = 0; i < screens.length; i++) {
      final screen = screens[i];
      if (screen.isMergedGroup) continue;

      final currentTitle = screen.title.trim();
      if (currentTitle.isEmpty) continue;
      final currentTitleLower = currentTitle.toLowerCase();
      final duplicated = (titleCounts[currentTitleLower] ?? 0) > 1;
      if (!duplicated) {
        continue;
      }

      final node = nodeById[screen.screenId.trim().toLowerCase()];
      if (node == null) continue;

      final parentTitle = _nearestMeaningfulParentTitle(node, nodeById);
      if (parentTitle == null) continue;

      final replacement = currentTitleLower == 'construction'
          ? parentTitle
          : '$parentTitle $currentTitle';
      if (currentTitleLower != 'construction' &&
          currentTitleLower.startsWith(parentTitle.toLowerCase())) {
        continue;
      }
      if (replacement.trim().toLowerCase() == currentTitleLower) continue;

      screens[i] = ReportScreen(
        screenId: screen.screenId,
        title: replacement,
        fields: screen.fields,
        phrases: screen.phrases,
        userNote: screen.userNote,
        parentId: screen.parentId,
        isCompleted: screen.isCompleted,
        isMergedGroup: screen.isMergedGroup,
      );
    }
  }

  String? _nearestMeaningfulParentTitle(
    InspectionNodeDefinition node,
    Map<String, InspectionNodeDefinition> nodeById,
  ) {
    var parentId = node.parentId;
    for (var depth = 0; depth < 12; depth++) {
      if (parentId == null || parentId.isEmpty) return null;
      final parent = nodeById[parentId.trim().toLowerCase()];
      if (parent == null) return null;

      final title = parent.title.trim();
      final lower = title.toLowerCase();
      if (title.isNotEmpty &&
          !_genericAmbiguousScreenTitles.contains(lower) &&
          lower != 'repairs' &&
          lower != 'not inspected') {
        return title;
      }

      parentId = parent.parentId;
    }
    return null;
  }

  /// Build a single [ReportScreen] for a standalone (non-grouped) screen node.
  ReportScreen? _buildScreenEntry(
    String _sectionKey,
    InspectionNodeDefinition node,
    V2RawReportData rawData,
    ExportConfig config,
    bool isInspection,
  ) {
    final normalizedId = node.id.trim().toLowerCase();
    final answers = _answersForScreen(rawData, node.id);
    final isCompleted = rawData.screenStates[node.id] ?? false;

    var fields = _buildFields(node, answers);
    List<String> phrases;
    if (!config.includePhrases) {
      phrases = const [];
    } else {
      phrases = _phrasesForScreen(node, rawData, isInspection);
      if (_sectionDSummaryNarrativeScreenIds.contains(normalizedId)) {
        final hardNarrative =
            _sectionDSummaryNarrativeFromAnswers(node.id, answers);
        if (hardNarrative.isNotEmpty) {
          phrases = _cleanupPhrases(hardNarrative);
        } else {
          final fromFields =
              _sectionDSummaryNarrativeFromFields(node.id, fields);
          if (fromFields.isNotEmpty) {
            phrases = _cleanupPhrases(fromFields);
          }
        }
      }
    }

    // When no engine phrases exist but fields have data, convert fields to
    // simple narrative phrases so the report avoids raw "Yes/No" tables.
    if (phrases.isEmpty &&
        config.includePhrases &&
        fields.any((f) => f.displayValue.isNotEmpty)) {
      if (_alwaysRegenerateFromAnswersScreenIds.contains(normalizedId) &&
          !_sectionDSummaryNarrativeScreenIds.contains(normalizedId)) {
        final narrative = _narrativeFallbackForIssuesRisks(node.title, fields);
        if (narrative.isNotEmpty) {
          phrases = _cleanupPhrases(narrative);
          fields = const [];
        }
      }
    }

    if (phrases.isEmpty &&
        config.includePhrases &&
        fields.any((f) => f.displayValue.isNotEmpty)) {
      final fallback = _shouldUseRawFieldFallback(node.id)
          ? _fieldsToPhrases(fields)
          : const <String>[];
      final cleanedFallback = _cleanupPhrases(fallback);
      if (cleanedFallback.isNotEmpty) {
        phrases = cleanedFallback;
        fields = const []; // Suppress raw table — phrases cover the data.
      }
    }

    if (phrases.isNotEmpty &&
        _sectionDSummaryNarrativeScreenIds.contains(normalizedId)) {
      fields = const [];
    }

    final userNote = _noteForScreen(rawData, node.id);

    final hasData = fields.any((f) => f.displayValue.isNotEmpty) ||
        phrases.isNotEmpty ||
        userNote.isNotEmpty;
    if (!hasData && !config.includeEmptyScreens) return null;

    return ReportScreen(
      screenId: node.id,
      title: _reportTitleForNode(_sectionKey, node),
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
    final normalizedId = node.id.trim().toLowerCase();
    final persistedWasManual =
        rawData.persistedPhraseManualFlags[node.id] ?? false;

    final persisted = _persistedPhrasesForScreen(rawData, node.id);
    if (persisted != null && persistedWasManual) {
      final cleanedPersisted = _cleanupPhrases(persisted);
      if (cleanedPersisted.isNotEmpty) {
        return _condenseIfNeeded(normalizedId, cleanedPersisted);
      }
    }

    // No persisted phrases and no user answers — screen was never visited.
    final answers = _answersForScreen(rawData, node.id);
    if (answers.isEmpty) return const [];

    final enginePhrases = _buildPhrases(node.id, answers, isInspection);
    if (_alwaysRegenerateFromAnswersScreenIds.contains(normalizedId)) {
      var cleaned = _cleanupPhrases(enginePhrases);
      if (normalizedId == 'activity_issues_glazed_sections') {
        cleaned = _cleanupPhrases([
          ...cleaned,
          ..._legacyDerivedSectionFIssueGuarantees(rawData),
        ]);
      } else if (normalizedId == 'activity_risks_risk_to_building_') {
        cleaned = _cleanupPhrases([
          ...cleaned,
          ..._legacyDerivedSectionFRiskToBuilding(rawData),
        ]);
      }
      if (normalizedId == 'activity_in_side_property_fire_places__other') {
        final hasConditionPhrase = cleaned.any(
            (phrase) => phrase.toLowerCase().startsWith('these appear in '));
        if (!hasConditionPhrase && persisted != null) {
          final persistedCondition = _cleanupPhrases(persisted).where(
              (phrase) => phrase.toLowerCase().startsWith('these appear in '));
          if (persistedCondition.isNotEmpty) {
            cleaned = _cleanupPhrases([
              ...cleaned,
              persistedCondition.first,
            ]);
          }
        }
      }
      return _condenseIfNeeded(normalizedId, cleaned);
    }
    final normalizedFields =
        sanitizeInspectionFieldsForScreen(node.id, node.fields);
    final fieldPhrases =
        FieldPhraseProcessor.buildFieldPhrases(normalizedFields, answers);
    final cleaned = _cleanupPhrases([...enginePhrases, ...fieldPhrases]);
    return _condenseIfNeeded(normalizedId, cleaned);
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

  List<InspectionNodeDefinition> _orderedMergedGroupDescendants(
    InspectionSectionDefinition sectionDef,
    InspectionNodeDefinition group,
    List<InspectionNodeDefinition> descendants,
  ) {
    final sectionKey = sectionDef.key.trim().toUpperCase();
    if (sectionKey != 'E') {
      return descendants;
    }

    // Legacy parity: in Section E, detailed screens should lead while
    // aggregate main/summary screens render at the end of each merged group.
    int rankFor(String screenId) {
      final id = screenId.trim().toLowerCase();
      final isSummary = id.contains('_summary');
      final isMain = id.endsWith('_main') || id.endsWith('_main_screen');
      if (isMain) {
        return 1;
      }
      if (isSummary) {
        return 2;
      }
      return 0;
    }

    final indexed = descendants.asMap().entries.toList();
    indexed.sort((a, b) {
      final rankA = rankFor(a.value.id);
      final rankB = rankFor(b.value.id);
      if (rankA != rankB) return rankA.compareTo(rankB);
      return a.key.compareTo(b.key);
    });
    return indexed.map((e) => e.value).toList(growable: false);
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

  bool _shouldUseRawFieldFallback(String screenId) {
    final normalizedId = screenId.trim().toLowerCase();

    // Legacy roof-structure insect-infestation output is phrase-driven only.
    // Raw "Label: value" fallback leaks stale invalid values such as
    // "Partly missing" into the final report, which the legacy report does
    // not do.
    if (normalizedId == 'activity_inside_property_repair_insect_infestation' ||
        normalizedId == 'activity_in_side_property_wap_movement_cracks' ||
        normalizedId == 'activity_in_side_property_floors_floor_ventilation') {
      return false;
    }

    return true;
  }

  List<ReportField> _buildFields(
    InspectionNodeDefinition node,
    Map<String, String> answers,
  ) {
    final result = <ReportField>[];
    final normalizedFields =
        sanitizeInspectionFieldsForScreen(node.id, node.fields);

    for (final field in normalizedFields) {
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
      debugPrint(
          '[ReportBuilder] Phrase generation failed for screen $screenId: $e\n$stack');
    }
    return [];
  }
}
