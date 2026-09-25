import 'package:flutter/foundation.dart';

import '../../../property_inspection/domain/field_phrase_processor.dart';
import '../../../property_inspection/domain/inspection_phrase_engine.dart';
import '../../../property_inspection/domain/models/inspection_models.dart';
import '../../../property_inspection/presentation/widgets/inspection_fields.dart'
    show shouldShowInspectionField, sanitizeInspectionFieldsForScreen;
import '../../../property_valuation/domain/valuation_phrase_engine.dart';
import '../../domain/models/export_config.dart';
import '../../domain/models/report_document.dart';
import 'paragraph_composer.dart';
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

  /// Groups adjacent phrases into paragraphs according to the approved
  /// master-template structure (client fix: sentences belonging to the same
  /// element must render as one paragraph, not one sentence per line).
  late final ParagraphComposer? _paragraphComposer = () {
    final texts = inspectionPhraseEngine?.phraseTexts;
    if (texts == null || texts.isEmpty) return null;
    return ParagraphComposer(texts);
  }();

  List<String> _composeParagraphs(List<String> phrases) {
    final composer = _paragraphComposer;
    if (composer == null || phrases.length < 2) return phrases;
    return composer.compose(phrases);
  }

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
      // Section R captures structured room counts. It is exported through
      // [ReportDocument.accommodationSchedule], never as temporary prose.
      if (isInspection && sectionDef.key.trim().toUpperCase() == 'R') {
        continue;
      }
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
      accommodationSchedule: isInspection
          ? _buildAccommodationSchedule(rawData)
          : _buildValuationAccommodationSchedule(rawData),
    );
  }

  List<AccommodationScheduleRow> _buildAccommodationSchedule(
    V2RawReportData rawData,
  ) {
    const floorScreens = <(String, String)>[
      ('activity_no_of_rooms', 'Lower ground'),
      ('activity_no_of_rooms__ground', 'Ground'),
      ('activity_no_of_rooms__first', 'First'),
      ('activity_no_of_rooms__second', 'Second'),
      ('activity_no_of_rooms__third', 'Third'),
      ('activity_no_of_rooms__other', 'Other'),
      ('activity_no_of_rooms__roof_space', 'Roof space'),
    ];

    String count(Map<String, String> answers, String key) {
      final value = (answers[key] ?? '').trim();
      return value == '0' ? '' : value;
    }

    final rows = <AccommodationScheduleRow>[];
    for (final entry in floorScreens) {
      final answers = _answersForScreen(rawData, entry.$1);
      if (answers.isEmpty) continue;
      final otherCount = count(answers, 'etNoOfRoomsOther');
      final otherName = (answers['ar_etNote'] ?? '').trim();
      final other = otherCount.isEmpty
          ? ''
          : otherName.isEmpty
              ? otherCount
              : '$otherCount $otherName';
      final row = AccommodationScheduleRow(
        floor: entry.$2,
        livingRooms: count(answers, 'ar_etFirstName'),
        bedrooms: count(answers, 'ar_etLastName'),
        bathOrShowerRooms: count(answers, 'ar_etAddressLine1'),
        separateToilets: count(answers, 'ar_etCity'),
        kitchens: count(answers, 'ar_etPinCode'),
        utilityRooms: count(answers, 'ar_etCountry'),
        conservatories: count(answers, 'ar_etConservatory'),
        otherRooms: other,
      );
      if (row.hasAnyRooms) rows.add(row);
    }
    return rows;
  }

  List<AccommodationScheduleRow> _buildValuationAccommodationSchedule(
    V2RawReportData rawData,
  ) {
    final answers = _answersForScreen(rawData, 'no_of_rooms');
    if (answers.isEmpty) return const [];

    String count(String key) {
      final value = (answers[key] ?? '').trim();
      return value == '0' ? '' : value;
    }

    final otherCount = count('et_other');
    final otherName = (answers['et_other_name'] ?? '').trim();
    final row = AccommodationScheduleRow(
      floor: 'Property total',
      livingRooms: count('et_liv'),
      bedrooms: count('et_bed'),
      bathOrShowerRooms: count('et_bath'),
      separateToilets: count('et_wc'),
      kitchens: count('et_kit'),
      utilityRooms: count('et_ut'),
      conservatories: count('et_con'),
      otherRooms: otherCount.isEmpty
          ? ''
          : otherName.isEmpty
              ? otherCount
              : '$otherCount $otherName',
    );
    return row.hasAnyRooms ? [row] : const [];
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
        if (from.toLowerCase() == to.toLowerCase()) {
          return [
            'The property is located in an established ${from.toLowerCase()}-density area.'
          ];
        }
        return [
          'The property is located in an established area where surrounding development ranges from ${from.toLowerCase()} to ${to.toLowerCase()} density.'
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
        if (from.toLowerCase() == to.toLowerCase()) {
          return [
            'The property is located in an established ${from.toLowerCase()}-density area.'
          ];
        }
        return [
          'The property is located in an established area where surrounding development ranges from ${from.toLowerCase()} to ${to.toLowerCase()} density.'
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

  // E1's spec text has a cross-inject Phase 2B correctly identified but left
  // unwired at the time ("Add highlighted below text to: Section I3" - I
  // hadn't been rebuilt yet). Section I is now fully migrated (Phase 2F),
  // so this closes that gap: when the surveyor records a shared chimney on
  // E1's dedicated screen, the same spec-mandated sentence about shared
  // rainwater goods and chimney stacks is injected into I3.
  List<String> _legacyDerivedSectionFIssueOtherMattersSharedChimney(
      V2RawReportData rawData) {
    final sharedChimney =
        _answersForScreen(rawData, 'activity_outside_property_shared_chimney');
    final hasSharedChimney = ['ch1', 'ch2', 'ch3', 'ch4', 'cb_other_608']
        .any((id) => _isCheckedValue(sharedChimney[id]));
    if (!hasSharedChimney) return const [];
    return [
      'The rainwater goods and chimney stack(s) are shared. The owner of the neighbouring property or properties may have some legal rights over these shared building parts. You should check with your legal adviser before any work is done.'
    ];
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

    // RICS L2 cross-injections from Section E5 Windows and E6 Outside
    // Doors (Phase 2B): each section's spec text says "Add text to:
    // Section J2 Guarantees" for a PVC-glazed-replacement scenario - "J2"
    // is almost certainly a typo for "I2" (Guarantees is I2 everywhere
    // else in the library; the app has no J2 content at all). Deferred at
    // the time to whoever did I2's own rewrite; wired here (Phase 2F) now
    // that I2 is the active element.
    final windowsAbout = _answersForScreen(
        rawData, 'activity_outside_property_windows_aboutwindow');
    if (_isCheckedValue(windowsAbout['cb_is_replacement']) &&
        _isCheckedValue(windowsAbout['cb_pvc'])) {
      phrases.add(
          'You should ask your legal adviser to confirm whether the PVC glazed sections to the windows were installed by a contractor registered with FENSA. Enquiries should also be made regarding any guarantees or warranties for the double glazing.');
    }

    // The "PVC" outside-doors screen is its own dedicated material
    // variant (separate from the timber/steel/aluminium/other door
    // screens), so its own "Replacement" checkbox alone is the PVC +
    // replacement signal - no separate material checkbox to combine it
    // with, unlike the combined windows screen above.
    final doorsAboutPvc = _answersForScreen(
        rawData, 'activity_outside_property_out_side_doors_about_doors');
    if (_isCheckedValue(doorsAboutPvc['cb_replacement'])) {
      phrases.add(
          'You should ask your legal adviser to confirm whether the PVC glazed sections to the doors were installed by a contractor registered with FENSA. Enquiries should also be made regarding any guarantees or warranties for the double glazing.');
    }

    // Revised-spec cross-injection (Phase 7): where the F1 Roof Structure
    // spray-foam advisory fires (cb_spray_foam on the About Roof Structure
    // screen), the revised I2 Guarantees checklist adds a spray-foam guarantee
    // enquiry. Text mirrors the approved bank key
    // {ISSUE_GUARANTEES}::{GUARANTEES_SPRAY_FOAM}.
    final aboutRoof = _answersForScreen(
        rawData, 'activity_inside_property_about_roof_structure');
    if (_isCheckedValue(aboutRoof['cb_spray_foam'])) {
      phrases.add(
          'You should ask your legal adviser to obtain the spray foam '
          'insulation installation details, guarantees and warranties, together '
          'with confirmation of any lender requirements.');
    }

    // Revised-spec cross-injection (Phase 7): where a renewable-energy
    // installation is present - solar PV (activity_services_solar_power),
    // solar thermal (activity_services_water_heating_solar_power) or the
    // Section D other-services solar flags - the revised I2 Guarantees
    // checklist adds a renewable-energy guarantee enquiry. Text mirrors the
    // approved bank key {ISSUE_GUARANTEES}::{GUARANTEES_RENEWABLE_ENERGY}.
    final solarPv = _answersForScreen(rawData, 'activity_services_solar_power');
    final solarThermal = _answersForScreen(
        rawData, 'activity_services_water_heating_solar_power');
    final otherServices =
        _answersForScreen(rawData, 'activity_other_service');
    final hasRenewable = _isCheckedValue(solarPv['cb_front']) ||
        _isCheckedValue(solarPv['cb_side']) ||
        _isCheckedValue(solarPv['cb_rear']) ||
        _isCheckedValue(solarPv['cb_other_783']) ||
        _isCheckedValue(solarThermal['cb_solar_power']) ||
        _isCheckedValue(otherServices['ch1']) ||
        _isCheckedValue(otherServices['ch2']);
    if (hasRenewable) {
      phrases.add(
          'You should ask your legal adviser to obtain the installation '
          'certificates, ownership details, maintenance agreements, warranties '
          'and any lease or finance agreements for renewable energy '
          'installations, including solar PV, solar thermal, battery storage, '
          'air source heat pumps and ground source heat pumps.');
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

    // RICS L2 cross-injections from Section E1 Chimney stacks (Phase 2B):
    // all 4 spec-required E1 -> J1 injections (flashing-causing-damp,
    // flaunching-causing-damp, repointing-causing-damp, significant-
    // leaning, poor-condition/safety-hazard).
    final flashing = _answersForScreen(
        rawData, 'activity_outside_property_repair_flashing');
    if (_isCheckedValue(flashing['cb_is_causing_dump']) &&
        (flashing['android_material_design_spinner4'] ?? '')
            .toLowerCase()
            .contains('now')) {
      phrases.add(
          'The waterproofing between the chimney stack and the roof covering is damaged or defective and is causing damp penetration to the adjoining building elements (see section E1 - Chimney Stacks).');
    }

    final flaunching = _answersForScreen(
        rawData, 'activity_outside_property_chimney_repair_flaunching');
    if (_isCheckedValue(flaunching['cb_is_causing_dump']) &&
        (flaunching['actv_condition'] ?? '').toLowerCase().contains('now')) {
      phrases.add(
          'The cement bedding around the base of the chimney pot (called flaunching) is damaged or defective and is causing damp penetration to the adjoining building elements (see section E1 - Chimney Stacks).');
    }

    final repointing = _answersForScreen(
        rawData, 'activity_outside_property_repair_chimney_repointing');
    if (_isCheckedValue(repointing['cb_is_causing_dump']) &&
        (repointing['actv_condition'] ?? '').toLowerCase().contains('now')) {
      phrases.add(
          'Some of the mortar between the bricks or stonework (called pointing) to the chimney stack is damaged or defective and is causing damp penetration to the adjoining building elements (see section E1 - Chimney Stacks).');
    }

    final leaning = _answersForScreen(
        rawData, 'activity_outside_property_leaning_chimney');
    if ((leaning['android_material_design_spinner4'] ?? '')
        .toLowerCase()
        .contains('repair')) {
      phrases.add(
          'The chimney stack appears leaning and the movement appears significant, and action is required now (see section E1 - Chimney Stacks).');
    }

    final disrepair = _answersForScreen(
        rawData, 'activity_outside_property_repair_chimney_disrepair');
    if (_isCheckedValue(disrepair['cb_repair_soon_70'])) {
      phrases.add(
          'The chimney stack(s) on the building are in poor condition. This is a safety hazard (see section E1 - Chimney Stacks).');
    }

    // RICS L2 cross-injections from Section E2 Roof Coverings (Phase 2B):
    // 6 of E2's 7 spec-required E2 -> J1 injections that this data model
    // captures (tile defects, significant deflection, ridge tiles damaged,
    // hip tiles damaged, flat-roof damp, roof spreading). The 7th
    // (flashing-at-junction damaged) has no repair-soon/now screen in the
    // current tree - `outside_property_roof_covering_flashing_layout` only
    // captures the description/condition, not a repair branch - so it is
    // intentionally not wired here rather than guessed (same class of gap
    // as E1's chimney-flashing "causing damp" checkbox before that was
    // added; this one still needs its own new field).
    final roofRepairTiles =
        _answersForScreen(rawData, 'activity_outside_property_roof_repair_tiles');
    final roofTilesCondition =
        (roofRepairTiles['actv_condition'] ?? '').toLowerCase();
    if (roofTilesCondition.contains('now')) {
      if (_isCheckedValue(roofRepairTiles['cb_roof_40'])) {
        phrases.add(
            'One or more tiles, slates, or roof covering sections are loose, slipped, cracked, broken, or missing (see section E2 - Roof Coverings).');
      }
      if (_isCheckedValue(roofRepairTiles['cb_ridge_16'])) {
        phrases.add(
            'The covering along the top of the roof structure (called the ridge tiles) is damaged or defective (see section E2 - Roof Coverings).');
      }
      if (_isCheckedValue(roofRepairTiles['cb_hip_42'])) {
        phrases.add(
            'The covering along the slope of the roof structure (called the hip tiles) is damaged or defective (see section E2 - Roof Coverings).');
      }
    }

    final roofStructure = _answersForScreen(
        rawData, 'outside_property_roof_covering_roof_structure_layout');
    if ((roofStructure['actv_status'] ?? '').toLowerCase().contains('investigate')) {
      phrases.add(
          'The surface of the roof slope(s) of the building is significantly distorted, uneven or undulating (see section E2 - Roof Coverings).');
    }

    final flatRoofRepair = _answersForScreen(
        rawData, 'activity_outside_property_roof_repair_flat_roof');
    if ((flatRoofRepair['actv_condition'] ?? '').toLowerCase().contains('now')) {
      phrases.add(
          'The flat roof covering is weathered, blistered, split, torn, worn, ponding, or defective (see section E2 - Roof Coverings).');
    }

    final roofSpreadingRepair = _answersForScreen(
        rawData, 'activity_outside_property_roof_spreading_repair');
    if ((roofSpreadingRepair['actv_status'] ?? '').toLowerCase() == 'yes') {
      phrases.add(
          'The roof slopes appear uneven or undulating, and the adjoining wall appears distorted, cracked, bowing or leaning outwards (see section E2 - Roof Coverings).');
    }

    // RICS L2 cross-injection from Section E3 Rainwater Goods (Phase 2B):
    // the spec's single E3 -> J1 injection, fired for the "now" (causing
    // damp) repair branch.
    final rwgRepair = _answersForScreen(
        rawData, 'activity_outside_property_rwg__repair_pipes_gutters');
    if ((rwgRepair['actv_condition'] ?? '').toLowerCase().contains('now')) {
      phrases.add(
          'One or more defects affecting the rainwater gutters, downpipes, associated fittings and drainage arrangements were noted (see section E3 - Rainwater Goods).');
    }

    // RICS L2 cross-injections from Section E4 Main Walls (Phase 2B): 4 of
    // the spec's 5 wall -> J1 injections that this data model captures
    // (damp-moisture-readings, drainage-guttering, lintel-repair-now,
    // windowsill-repair-now). The 5th (trees showing defects) has no
    // "defects noted" field on the nearby-trees screen in the current
    // tree - only tree size is captured - so it is intentionally not
    // wired here rather than guessed (same class of gap as E2's
    // flashing-at-junction injection above; this one still needs its own
    // new field).
    final mainWallsDamp = _answersForScreen(
        rawData, 'activity_outside_property_main_walls_damp');
    final mainWallsDampLocation =
        (mainWallsDamp['et_location_677'] ?? '').trim();
    if (mainWallsDampLocation.isNotEmpty) {
      phrases.add(
          'Elevated moisture readings were recorded to sections of the internal wall surfaces that include ${mainWallsDampLocation.toLowerCase()} (see section E4 - Main Walls).');
    }
    if (_isCheckedValue(mainWallsDamp['cb_install_french_gutters'])) {
      phrases.add(
          'The external ground levels are high in relation to the building, the damp-proof course (DPC) may be bridged in places, allowing moisture to penetrate the walls (see section E4 - Main Walls).');
    }

    final lintelRepair = _answersForScreen(
        rawData, 'activity_outside_property_main_wall_repairs_lintel');
    if ((lintelRepair['actv_condition'] ??
            lintelRepair['llMainContainer'] ??
            '')
        .toLowerCase()
        .contains('now')) {
      phrases.add(
          'The small beam that spans across the top of the window or door opening including brick arch (called a lintel) is damaged, cracked, distorted (see section E4 - Main Walls).');
    }

    final windowSillRepair = _answersForScreen(
        rawData, 'activity_outside_property_main_wall_repairs_window_sills');
    if ((windowSillRepair['actv_condition'] ??
            windowSillRepair['llMainContainer'] ??
            '')
        .toLowerCase()
        .contains('now')) {
      phrases.add(
          'The small beam that spans across the bottom of the window opening (called a windowsill) is damaged, cracked, distorted (see section E4 - Main Walls).');
    }

    // RICS L2 cross-injection from Section E8 Other Joinery and Finishes
    // (Phase 2B): the spec's single E8 -> J1 injection, gated on the
    // repair screen's own "Rotted" defect checkbox - a direct 1:1 mapping
    // (the spec's cross-inject text is literally "...is rotted"), unlike
    // E6/E7's Repair-Now-tier derivation where no matching checkbox exists.
    for (final screenId in const [
      'activity_outside_property_other_joinery_and_finishes_repairs',
      'activity_outside_property_other_joinery_and_finishes_repairs__repairs',
    ]) {
      final joineryRepair = _answersForScreen(rawData, screenId);
      if (_isCheckedValue(joineryRepair['cb_rotted'])) {
        phrases.add(
            'Parts of the usual work at the eaves level is rotted. This should be repaired to avoid further deterioration (see section E8 - Other Joinery and Finishes).');
      }
    }

    return _cleanupPhrases(phrases);
  }

  /// RICS L2 J2 "Risks to the Grounds" (Phase 2F): the app has no
  /// dedicated J2 screen at all - spec's 4 sub-topics (Trees, Retaining
  /// Walls, Sloping Ground, Boundary Structures) are synthesised from
  /// existing H-section grounds screens, the same "derive from other
  /// sections' data" pattern already used for J3 Risk to People above.
  /// Only emits when a genuine risk-worthy condition exists in the source
  /// data (a defect was logged, or the ground genuinely isn't level) -
  /// mirrors J1/J3's existing behaviour of never fabricating a "no risk
  /// found" default sentence for a sub-topic with no matching screen.
  /// Resolves an approved phrase-bank entry ("{MASTER}::{SUB}") from the
  /// inspection phrase bank, or null when the bank is unavailable (e.g. a
  /// builder constructed without a phrase engine). J2/J3 emit the revised-spec
  /// wording verbatim from the approved bank via this, falling back to their
  /// legacy hardcoded wording only when the bank is not loaded.
  String? _approvedBankPhrase(String key) {
    final texts = inspectionPhraseEngine?.phraseTexts;
    final v = texts == null ? null : texts[key];
    if (v == null || v.trim().isEmpty) return null;
    return v.trim();
  }

  List<String> _legacyDerivedSectionFRiskToGrounds(V2RawReportData rawData) {
    final phrases = <String>[];

    // Sloping Ground: H2's grounds-topography screen.
    final groundsTopo =
        _answersForScreen(rawData, 'activity_grounds_other_grounds');
    final topoType = (groundsTopo['actv_type'] ?? '').trim().toLowerCase();
    if (topoType.isNotEmpty && topoType != 'relatively level') {
      phrases.add(
          _approvedBankPhrase('{RISK_TO_GROUNDS}::{GROUNDS_SLOPING_GROUND}') ??
              'The property occupies a $topoType site. Although no evidence of instability was observed during the inspection, sloping ground can influence drainage and foundations, and should be considered as part of routine maintenance.');
    }

    // Trees: H2's nearby-trees repair screen.
    final nearbyTrees =
        _answersForScreen(rawData, 'activity_other_repair_nearby_trees');
    final treeCondition =
        (nearbyTrees['actv_condition'] ?? '').trim().toLowerCase();
    if (treeCondition == 'problems') {
      final proximity =
          (nearbyTrees['actv_proximity_of_adjacent_tree'] ?? '')
              .trim()
              .toLowerCase();
      final proximityText = proximity.isEmpty ? 'trees' : '$proximity trees';
      final treeIssues = _labelsForAnswerMap(
        nearbyTrees,
        const <String, String>{
          'cb_significant_cracks': 'cracks to the property',
          'cb_subsidence_movement': 'subsidence movement',
          'cb_other_619': 'other issues',
        },
        otherCheckboxId: 'cb_other_619',
        otherTextId: 'et_other_197',
      );
      final v2Trees =
          _approvedBankPhrase('{RISK_TO_GROUNDS}::{GROUNDS_INFLUENCING_TREES}');
      if (v2Trees != null) {
        phrases.add(v2Trees);
      } else if (treeIssues.isNotEmpty) {
        phrases.add(
            'There are $proximityText within influencing distance of the property, and these appear to be causing ${_toLegacyWords(treeIssues)}. Further investigation by an appropriately qualified person is recommended before legal commitment.');
      } else {
        phrases.add(
            'There are $proximityText within influencing distance of the property. Although no evidence of damage was observed during the inspection, trees may influence buildings depending upon soil type, species and proximity. Routine management should be maintained where appropriate.');
      }
    }

    // Retaining Walls: H2's retaining-walls repair screen.
    final retainingWalls =
        _answersForScreen(rawData, 'activity_other_repair_retaining_walls');
    final retainingWallLocations = _labelsForAnswerMap(
      retainingWalls,
      const <String, String>{
        'cb_front': 'front',
        'cb_side': 'side',
        'cb_rear': 'rear',
        'cb_other_411': 'other',
      },
      otherCheckboxId: 'cb_other_411',
      otherTextId: 'et_other_384',
    );
    final retainingWallDefects = _labelsForAnswerMap(
      retainingWalls,
      const <String, String>{
        'cb_cracked': 'cracked',
        'cb_distorted': 'distorted',
        'cb_unstable': 'unstable',
        'cb_damaged': 'damaged',
        'cb_other_394': 'other',
      },
      otherCheckboxId: 'cb_other_394',
      otherTextId: 'et_other_410',
    );
    if (retainingWallLocations.isNotEmpty && retainingWallDefects.isNotEmpty) {
      phrases.add(
          _approvedBankPhrase('{RISK_TO_GROUNDS}::{GROUNDS_RETAINING_WALLS}') ??
              'The retaining wall(s) to the ${_toLegacyWords(retainingWallLocations)} of the property show signs of being ${_toLegacyWords(retainingWallDefects)}. Further investigation should be undertaken where structural stability appears affected.');
    }

    // Boundary Structures: H4's fence-repair screen (already used as the
    // Ownership/Defects source for H4's own element - reused here for
    // J2's Boundary Structures sub-topic, same underlying defect data,
    // different narrative framing).
    final fenceRepair =
        _answersForScreen(rawData, 'activity_grounds_other_repair_fence');
    final fenceGardens = _labelsForAnswerMap(
      fenceRepair,
      const <String, String>{
        'cb_front': 'front',
        'cb_rear': 'rear',
        'cb_side': 'side',
        'cb_communal': 'communal',
        'cb_other_271': 'other',
      },
      otherCheckboxId: 'cb_other_271',
      otherTextId: 'et_other_341',
    );
    final fenceDefects = _labelsForAnswerMap(
      fenceRepair,
      const <String, String>{
        'cb_broken': 'broken',
        'cb_unstable': 'unstable',
        'cb_leaning': 'leaning',
        'cb_loose_in_places': 'loose in places',
        'cb_badly_damaged': 'badly damaged',
        'cb_rotted_in_places': 'rotted in places',
        'cb_missing_in_places': 'missing in places',
        'cb_other_938': 'other',
      },
      otherCheckboxId: 'cb_other_938',
      otherTextId: 'et_other_276',
    );
    if (fenceGardens.isNotEmpty && fenceDefects.isNotEmpty) {
      phrases.add(
          'Parts of the boundary fencing to the ${_toLegacyWords(fenceGardens)} garden are ${_toLegacyWords(fenceDefects)}. Defective boundary structures should be repaired where deterioration affects stability or security.');
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
          'There are no handrails installed to the staircase, and this is a safety hazard as anyone, especially children, can fall off the edge of the stairs.');
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
          'I could not find evidence that the glass screen to the ${_toLegacyWords(noSafetyLocations)} is safety glass. Anyone falling against the glass screen may get hurt.');
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
          'The ${_toLegacyWords(repairLocations)} ${_legacyIsAre(repairLocations)} ${_toLegacyWords(repairDefects)}.');
    }

    // RICS L2 cross-injections from Section E1 Chimney stacks (Phase 2B):
    // 2 of E1's spec-required E1 -> J3 (Risk to People) injections.
    final potsRepair = _answersForScreen(
        rawData, 'activity_outside_property_repair_chimney_pots');
    if (_isCheckedValue(potsRepair['cb_is_safety_hazard']) &&
        (potsRepair['actv_condition'] ?? '').toLowerCase().contains('now')) {
      phrases.add(
          'One or several pots that are fitted to the main building chimney stack are broken and partly missing (see section E1 - Chimney Stacks).');
    }

    for (final screenId in const [
      'activity_outside_property_repair_chimney_dish_aerial',
      'activity_outside_property_repair_chimney_dish_aerial__satellite',
    ]) {
      final aerial = _answersForScreen(rawData, screenId);
      if (_isCheckedValue(aerial['cb_is_safety_hazard']) &&
          (aerial['actv_condition'] ?? '').toLowerCase().contains('now')) {
        final isSatellite = screenId.contains('satellite');
        phrases.add(
            'An ${isSatellite ? 'satellite dish' : 'aerial'} attached to the property is loose, rusted, damaged, dangling, other (see section E1 - Chimney Stacks).');
      }
    }

    // RICS L2 cross-injections from Section E2 Roof Coverings (Phase 2B):
    // 2 of E2's 7 spec-required E2 -> J3 (Risk to People) injections.
    final roofRepairTilesForPeople = _answersForScreen(
        rawData, 'activity_outside_property_roof_repair_tiles');
    if ((roofRepairTilesForPeople['actv_condition'] ?? '')
            .toLowerCase()
            .contains('now') &&
        _isCheckedValue(roofRepairTilesForPeople['cb_roof_40'])) {
      phrases.add(
          'One or more tiles, slates, or roof covering sections are loose, slipped, cracked, broken, or missing (see section E2 - Roof Coverings).');
    }

    final parapetRepair = _answersForScreen(
        rawData, 'activity_outside_property_roof_repair_parapet_wall');
    if (_isCheckedValue(parapetRepair['cb_safety_hazard']) &&
        (parapetRepair['actv_condition'] ?? '').toLowerCase().contains('now')) {
      phrases.add(
          'The rendering, copping, flashing, other of the parapet(s) of the roof are damaged, loose, partly missing, cracked, poorly secured, other (see section E2 - Roof Coverings).');
    }

    // RICS L2 cross-injections from Section E4 Main Walls (Phase 2B): the
    // spec's 2 wall -> J3 (Risk to People) injections (damp-moisture-
    // readings is a dual J1+J3 target, shared with the J1 method above;
    // render-hazard fires alongside the render "now" hazard sentence,
    // since both describe the same falling-render danger to people).
    final mainWallsDampForPeople = _answersForScreen(
        rawData, 'activity_outside_property_main_walls_damp');
    final mainWallsDampLocationForPeople =
        (mainWallsDampForPeople['et_location_677'] ?? '').trim();
    if (mainWallsDampLocationForPeople.isNotEmpty) {
      phrases.add(
          'Elevated moisture readings were recorded to sections of the internal wall surfaces that include ${mainWallsDampLocationForPeople.toLowerCase()} (see section E4 - Main Walls).');
    }

    final renderRepair = _answersForScreen(
        rawData, 'activity_outside_property_main_wall_repairs_render');
    if ((renderRepair['actv_condition'] ??
            renderRepair['llMainContainer'] ??
            '')
            .toLowerCase()
            .contains('now') &&
        _isCheckedValue(renderRepair['cb_hazard'])) {
      phrases.add(
          'Parts of the render coating to the building are eroded, loose, missing, damaged, other (see section E4 - Main Walls).');
    }

    // RICS L2 cross-injections from Section E5 Windows (Phase 2B): 2 of
    // the spec's 3 window -> J3 (Risk to People) injections (repair
    // safety-hazard, fire-trap-risk). The 3rd targets "Section J2
    // Guarantees" per the spec's own text, but this app has no J2 content
    // at all (J1=Building, J3=Risk to People [renamed from a pre-existing
    // mislabelled "J2" - see report_builder's derived_j3_risk_to_people
    // fix], J4=Other) and "Guarantees" is I2 everywhere else in the
    // library, so this is almost certainly a typo in the client's
    // document. Wired as an I2 target (Phase 2F) in
    // _legacyDerivedSectionFIssueGuarantees above, rather than to the
    // wrong section.
    final windowsRepairForPeople = _answersForScreen(
        rawData, 'activity_outside_property_windows_repairs_repair_window');
    final windowsRepairHowMany = _labelsForAnswerMap(
      windowsRepairForPeople,
      const <String, String>{
        'cb_ch1': 'one',
        'cb_ch2': 'some',
        'cb_ch3': 'many',
      },
    );
    if (_isCheckedValue(windowsRepairForPeople['cb_safety_hazard']) &&
        windowsRepairHowMany.isNotEmpty) {
      phrases.add(
          'One or more windows have been affected by single or multiple defects, and this is a health and safety hazard (see section E5 - Windows).');
    }

    final fireEscapeRisk = _answersForScreen(rawData,
        'activity_outside_property_windows_repairs_no_fire_escape_risk');
    final fireEscapeLocations = _labelsForAnswerMap(
      fireEscapeRisk,
      const <String, String>{
        'cb_lounge_84': 'lounge',
        'cb_bedroom_43': 'bedroom',
        'cb_study_61': 'study',
      },
    );
    if (fireEscapeLocations.isNotEmpty) {
      phrases.add(
          'The design of the window(s) does not provide a suitable means of escape in the event of a fire (see section E5 - Windows).');
    }

    // RICS L2 cross-injections from Section E6 Outside Doors (Phase 2B):
    // 1 of the spec's 2 door -> J3 (Risk to People) injections. The 2nd
    // targets "Section J2 Guarantees" per the spec's own text - the same
    // likely typo documented for E5 above (Guarantees is I2 everywhere
    // else in the library) - wired as an I2 target (Phase 2F) in
    // _legacyDerivedSectionFIssueGuarantees above, rather than to the
    // wrong section.
    //
    // The door repair screens have no dedicated safety-hazard/disrepair
    // checkbox (unlike the windows repair screen's cb_safety_hazard), so
    // this fires whenever any door location's repair is in the "Repair
    // now" tier with at least one defect selected - the same signal the
    // engine's own DOORS_DEFECT_IF_IN_DISREPAIR addendum uses.
    for (final screenId in const [
      'activity_outside_property_out_side_doors_repairs_repair_out_side_doors',
      'activity_outside_property_out_side_doors_repairs_repair_out_side_doors__rear_door',
      'activity_outside_property_out_side_doors_repairs_repair_out_side_doors__side_door',
      'activity_outside_property_out_side_doors_repairs_repair_out_side_doors__patio_door',
      'activity_outside_property_out_side_doors_repairs_repair_out_side_doors__garage_door',
      'activity_outside_property_out_side_doors_repairs_repair_out_side_doors__other_door',
    ]) {
      final doorRepair = _answersForScreen(rawData, screenId);
      final repairType = (doorRepair['actv_repair_type'] ??
              doorRepair['llMainContainer'] ??
              '')
          .trim()
          .toLowerCase();
      if (!repairType.contains('now')) continue;
      final nowDefects = _labelsForAnswerMap(
        doorRepair,
        const <String, String>{
          'cb_damaged': 'damaged',
          'cb_rotten': 'rotten',
          'cb_partly_worn': 'partly worn',
          'cb_failed_glazing': 'failed glazing',
          'cb_sticks_against_frame': 'sticks against frame',
          'cb_poorly_fitted': 'poorly fitted',
          'cb_other_837': 'other',
        },
        otherCheckboxId: 'cb_other_837',
        otherTextId: 'et_other_855',
      );
      if (nowDefects.isNotEmpty) {
        phrases.add(
            'One or more doors have been affected by single or multiple defects, and this is a health and safety hazard (see section E6 - Outside Doors).');
        break;
      }
    }

    // RICS L2 cross-injection from Section E9 Other (Phase 2B): the
    // spec's one E9 -> J3 injection (handrail defects). Not present in
    // the digitised library's crossInjects list for this element (a
    // digitiser gap - the raw spec text uses "Add text to J3" without the
    // "Section" wording every other injection in the library uses, which
    // the extraction pattern didn't catch), but confirmed present in the
    // raw spec text and wired here regardless. Checked across the 5
    // numbered handrail-repair screen variants that actually reference
    // {OTHER_REPAIR_HANDRAILS} in their wrapper (roof terrace, balcony,
    // Juliet balcony, external stairs, other - carport and porch canopy
    // have no handrails in the spec or this app's screens).
    for (final screenId in const [
      'activity_outside_property_other_repairs_hand_rails__hand_rails__2',
      'activity_outside_property_other_repairs_hand_rails__hand_rails__3',
      'activity_outside_property_other_repairs_hand_rails__hand_rails__4',
      'activity_outside_property_other_repairs_hand_rails__hand_rails__5',
      'activity_outside_property_other_repairs_hand_rails__hand_rails__6',
    ]) {
      final handrailRepair = _answersForScreen(rawData, screenId);
      final handrailDefects = _labelsForAnswerMap(
        handrailRepair,
        const <String, String>{
          'cb_partly_rotten_65': 'partly rotten',
          'cb_not_strong_enough_51': 'not strong enough',
          'cb_inadequately_designed_43': 'inadequately designed',
        },
      );
      if (handrailDefects.isNotEmpty) {
        phrases.add(
            'The handrail(s) are damaged, inadequate or poorly designed and this presents a safety risk (see section E9 - Other).');
        break;
      }
    }

    return _cleanupPhrases(phrases);
  }

  // J4 Risks to Health (Phase 2F): a brand-new spec element with no
  // dedicated screen. Unlike J1-J3 (silent when no risk is present),
  // spec's own J4 sub-topics are each written as an always-appearing
  // "positive or negative" disclosure (Asbestos/Mould) or an unconditional
  // advisory with no "or" branch at all (Lead/Radon - RICS L2's own text
  // has no alternate wording, because these genuinely cannot be ruled out
  // by visual inspection). So this function always returns 4 phrases,
  // never stays empty, matching spec's structure rather than J1-J3's
  // risk-triggered philosophy.
  List<String> _legacyDerivedSectionFRiskToHealth(V2RawReportData rawData) {
    final phrases = <String>[];

    // Asbestos: RICS L2 treats this as one property-wide finding, not a
    // per-location list, so this checks every screen across Sections E, F,
    // G and H that records an asbestos-containing material and only
    // distinguishes observed-vs-not-observed, matching spec's own
    // two-branch wording exactly. Each of these screens already narrates
    // its own specific asbestos content in place (E2 roof covering, F
    // ceilings/walls, G water/drainage, H garage) - this is a property-wide
    // summary in addition to that detail, the same "component narrates
    // locally, J adds a risk-level summary" pattern J1-J3 already use.
    const asbestosCheckboxSites = <String, List<String>>{
      'activity_grounds_garage': ['cb_corrugated_asbestos_sheets'],
      'activity_services_drainage': ['cb_material_asbestos_cement'],
      'activity_services_water_water_tank': ['cb_asbestos'],
      'activity_services_water_repair_main_screen': ['cb_asbestos_material'],
      'activity_inside_property_ceilings_repairs_ceilings': [
        'cb_contain_asbestos_material'
      ],
      'inside_property_ceilings_about_ceilings': ['cb_textured'],
      'activity_inside_property_water_tank': ['cb_asbestos', 'cb_asbestos_disused'],
      'activity_inside_property_wap_walls': ['cb_textured'],
      'activity_outside_property_rwg_about': ['cb_asbestos_cement'],
      'activity_outside_property_other_joinery_and_finishes_main_screen': [
        'cb_open_runoffs'
      ],
      'outside_property_about_roof_layout': ['cb_composite'],
      'outside_property_about_roof_layout__flat': ['cb_composite'],
      'outside_property_about_roof_layout__mansard': ['cb_composite'],
      'outside_property_about_roof_layout__other': ['cb_composite'],
      'activity_inside_property_ceilings_contains_asbestos': [
        'cb_lounge',
        'cb_bedroom',
        'cb_kitchen',
        'cb_bathroom',
        'cb_Property',
      ],
      'outside_property_roof_covering_asbestos_layout': [
        'cb_roof_covering',
        'cb_verge',
        'cb_soffits',
        'cb_other_654',
      ],
    };
    var asbestosObserved = false;
    for (final entry in asbestosCheckboxSites.entries) {
      final answers = _answersForScreen(rawData, entry.key);
      if (answers.isEmpty) continue;
      if (entry.value.any((id) => _isCheckedValue(answers[id]))) {
        asbestosObserved = true;
        break;
      }
    }
    if (!asbestosObserved) {
      final disusedTank =
          _answersForScreen(rawData, 'activity_services_water_disused_tank');
      if ((disusedTank['actv_tank_formed_in'] ?? '').trim().toLowerCase() ==
          'asbestos') {
        asbestosObserved = true;
      }
    }
    if (asbestosObserved) {
      phrases.add(
          _approvedBankPhrase('{RISK_TO_PEOPLE}::{PEOPLE_ASBESTOS}') ??
              'Materials that may contain asbestos were observed during the inspection. Where these materials remain in good condition and are left undisturbed, they do not normally present a significant health risk. Specialist advice should be obtained before disturbance or removal.');
    } else {
      phrases.add(
          'No materials suspected of containing asbestos were identified during the inspection.');
    }

    // Lead: spec's own text has no "or" branch - it is a single
    // unconditional advisory about older properties in general, not
    // triggered by any specific answer.
    phrases.add(
        'Older properties may contain lead pipework, lead flashings, or lead-based paint. No testing has been undertaken during this inspection. Further advice should be obtained where refurbishment is proposed.');

    // Mould Growth: F-section bathroom fittings and built-in fittings
    // moulding screens.
    var mouldObserved = false;
    final builtInMoulding = _answersForScreen(
        rawData,
        'activity_in_side_property_built_in_fittings_repair_moulding_noted');
    for (final id in const [
      'cb_kitchen_sink',
      'cb_Utility_room_sink',
      'cb_other_717'
    ]) {
      if (_isCheckedValue(builtInMoulding[id])) {
        mouldObserved = true;
        break;
      }
    }
    if (!mouldObserved) {
      final bathroomMoulding = _answersForScreen(
          rawData, 'activity_in_side_property_bathroom_fittings_mould');
      for (final id in const [
        'cb_bathtub',
        'cb_wash_hand_basin',
        'cb_shower_tray',
        'cb_other_1061'
      ]) {
        if (_isCheckedValue(bathroomMoulding[id])) {
          mouldObserved = true;
          break;
        }
      }
    }
    if (mouldObserved) {
      phrases.add(
          _approvedBankPhrase('{RISK_TO_PEOPLE}::{PEOPLE_MOULD_GROWTH}') ??
              'Localised mould growth associated with condensation was observed. Maintaining adequate heating and ventilation should assist in reducing further mould growth.');
    } else {
      phrases.add('No significant mould growth was observed.');
    }

    // Radon: cannot be determined by visual inspection - unconditional per
    // spec, always fires the same as Lead above.
    phrases.add(
        'The presence of radon gas cannot be determined during a visual inspection. Where appropriate, your legal adviser should obtain environmental search information.');

    return _cleanupPhrases(phrases);
  }

  // J5 Risks to the Security of the Property (Phase 2F): another brand-new
  // spec element with no dedicated screen. Spec has 6 sub-topics (External
  // Doors, Windows, External Lighting, Security Systems, Overall Risk
  // Assessment, General Advice). Unlike J4's Asbestos/Mould, a door's or
  // security-system's security LEVEL cannot be safely defaulted to a
  // negative claim when the surveyor never actually recorded it - "no
  // materials suspected of containing asbestos" is a true fact regardless
  // of which checkbox fired, but "the doors provide reasonable security"
  // is not a safe default when no door screen was ever touched. So Doors
  // and Security Systems only fire when real data exists (J1-J3's
  // silence-when-absent philosophy), while General Advice is genuine
  // unconditional spec boilerplate (J4's Lead/Radon philosophy) and always
  // fires. Windows, External Lighting and Overall Risk Assessment have no
  // safe source to derive from at all - see the sign-off packet for why
  // each is a flagged content gap rather than fabricated.
  List<String> _legacyDerivedSectionFRiskToSecurity(V2RawReportData rawData) {
    final phrases = <String>[];

    // External Doors: E6's existing actv_seciruty_offered dropdown, already
    // narrated per-door in Section E6 itself - this is a property-wide
    // summary, same "component narrates locally, J adds a summary"
    // pattern as J4's Asbestos/Mould. Checked across all 5 door-material
    // screen variants; if any door is Inadequate, that is the more
    // safety-relevant fact and takes priority over a Reasonable finding
    // elsewhere on the property.
    const doorScreens = <String>[
      'activity_outside_property_out_side_doors_about_doors',
      'activity_outside_property_out_side_doors_about_doors__timber',
      'activity_outside_property_out_side_doors_about_doors__steel',
      'activity_outside_property_out_side_doors_about_doors__aluminium',
      'activity_outside_property_out_side_doors_about_doors__other',
    ];
    var doorSecurityFound = false;
    var doorSecurityInadequate = false;
    for (final screenId in doorScreens) {
      final answers = _answersForScreen(rawData, screenId);
      final security =
          (answers['actv_seciruty_offered'] ?? '').trim().toLowerCase();
      if (security.isEmpty) continue;
      doorSecurityFound = true;
      if (security.contains('inadequate')) {
        doorSecurityInadequate = true;
        break;
      }
    }
    if (doorSecurityFound) {
      phrases.add(doorSecurityInadequate
          ? 'The accessible external doors appear to offer limited security based upon a visual inspection. The effectiveness of the locks has not been tested.'
          : 'The accessible external doors appear to provide reasonable security based upon a visual inspection. The effectiveness of the locks has not been tested.');
    }

    // Security Systems: the Communal Area screen's amenity checkboxes
    // (CCTV, automatic gates, entry system) are the only security-system
    // data the tree captures anywhere - scoped to properties with a
    // communal area (mainly flats/shared buildings), so this only fires
    // when that screen was genuinely answered, same reasoning as Doors
    // above.
    final communalArea =
        _answersForScreen(rawData, 'activity_outside_property_other_communal_area');
    if (communalArea.isNotEmpty) {
      final hasSecuritySystem = _isCheckedValue(communalArea['cb_cctv']) ||
          _isCheckedValue(communalArea['cb_automatic_gates']) ||
          _isCheckedValue(communalArea['cb_entry_system']);
      phrases.add(hasSecuritySystem
          ? 'The property incorporates a visible security system to the communal areas. These installations were not tested.'
          : 'No visible security system was noted to the communal areas. These installations were not tested.');
    }

    // (General Advice moved: the revised spec places the general-maintenance
    // advisory at the end of J3 Risks to People, not with the security risks.
    // See _riskGeneralMaintenanceAdvice, added to J3 in the section assembly.)

    return _cleanupPhrases(phrases);
  }

  // Revised-spec general-maintenance advisory. Under the revised structure this
  // closes J3 Risks to People (previously it closed the app's J5 Security).
  static const String _riskGeneralMaintenanceAdvice =
      'Buildings require regular inspection and maintenance throughout their '
      'service life. Prompt attention to isolated defects will normally reduce '
      'the likelihood of more extensive deterioration and costly future '
      'repairs. Where specialist inspections have been recommended within this '
      'report, these should be obtained before legal commitment where '
      'practicable.';

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
    var removedIsolatedOption = false;
    final labelPattern = RegExp(r'^\s*([^:]+):\s*(.+?)\s*$');

    for (final phrase in phrases) {
      final m = labelPattern.firstMatch(phrase);
      if (m == null) {
        final value = phrase.trim();
        if (!_isIsolatedConstructionOption(value)) {
          narrative.add(value);
        } else {
          removedIsolatedOption = true;
        }
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
      if (removedIsolatedOption) {
        final cleaned = _cleanupPhrases(narrative);
        return cleaned.isEmpty ? const <String>[] : <String>[cleaned.join(' ')];
      }
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
      if ((coverType ?? '').isNotEmpty) {
        bits.add('the roof cover is $coverType');
      }
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

    final cleaned = _cleanupPhrases(out);
    if (cleaned.isEmpty) return const <String>[];
    // Construction is one logical element. Keep its component sentences in
    // one flowing paragraph rather than exposing isolated option fragments.
    return <String>[cleaned.join(' ')];
  }

  bool _isIsolatedConstructionOption(String phrase) {
    final value =
        phrase.trim().toLowerCase().replaceAll(RegExp(r'[.]+$'), '').trim();
    const rawOptions = <String>{
      'flat',
      'pitched',
      'solid',
      'cavity',
      'timber frame',
      'steel frame',
      'concrete frame',
      'tiles',
      'sheets',
      'slates',
      'coatings',
      'pvc',
      'timber',
      'aluminium',
      'steel',
    };
    return rawOptions.contains(value);
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
    v = v.replaceAllMapped(
      RegExp(r'\s+([,.;:])'),
      (match) => match.group(1) ?? '',
    );
    v = v.replaceAll(RegExp(r'([,;:])\.'), '.');
    v = v.replaceAll(RegExp(r'\.\s*\.'), '.');
    v = v.replaceAll(
      RegExp(r'\bbuilt of\s+mm\s+', caseSensitive: false),
      'built of ',
    );
    v = v.trim();
    if (RegExp(
      r'^(ceilings repair|walls and partitions repair|floors repair|repair)\.?$',
      caseSensitive: false,
    ).hasMatch(v)) {
      return '';
    }
    if (RegExp(r'^not inspected phrase\.?$', caseSensitive: false)
        .hasMatch(v)) {
      return '';
    }
    if (RegExp(r'^[^:]{1,80}:\s*$').hasMatch(v)) return '';
    if (RegExp(r'^\.+$').hasMatch(v)) return '';
    if (_looksLikeRawOptionDump(v)) return '';
    return v;
  }

  bool _shouldCondensePhrasesAsParagraph(String normalizedScreenId) {
    if (normalizedScreenId == 'activity_outside_property_stacks') return true;
    return normalizedScreenId.contains('outside_property_main_walls') ||
        normalizedScreenId.contains('outside_property_windows') ||
        normalizedScreenId.contains('outside_property_doors');
  }

  List<String> _condenseIfNeeded(
    String normalizedScreenId,
    List<String> phrases,
  ) {
    if (!_shouldCondensePhrasesAsParagraph(normalizedScreenId)) {
      // Approved-bank paragraph grammar: join sentences that the master
      // templates place in the same paragraph group.
      return _composeParagraphs(phrases);
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

  /// RICS L2 fix (Gate 3, Phase 2A): this used to hardcode its own English
  /// for the merged D-Energy group instead of reading `phrase_texts.json`,
  /// so a bank rewrite (e.g. {D_ENERGY}, {ENERGY_OTHER_SERVICES}) never
  /// reached the real report - a class of defect a phrase-level probe can't
  /// catch, only a real-app render can. Now routes through the same
  /// phrase-engine handlers used everywhere else so this group can't drift
  /// from the approved bank again.
  List<String> _buildLegacySectionDEnergyPhrases(V2RawReportData rawData) {
    final engine = inspectionPhraseEngine;
    if (engine == null) return const [];

    final energyAnswers =
        _answersForScreen(rawData, 'activity_energy_effiency');
    final impactAnswers =
        _answersForScreen(rawData, 'activity_energy_environment_impect');
    final otherAnswers = _answersForScreen(rawData, 'activity_other_service');

    // This merged group only appears in the report when the surveyor
    // actually opened at least one of its three screens.
    if (energyAnswers.isEmpty &&
        impactAnswers.isEmpty &&
        otherAnswers.isEmpty) {
      return const [];
    }

    return <String>[
      ...engine.buildPhrases('activity_energy_effiency', energyAnswers),
      ...engine.buildPhrases(
          'activity_energy_environment_impect', impactAnswers),
      ...engine.buildPhrases('activity_other_service', otherAnswers),
    ];
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
      final fields = config.includePhrases
          ? _withoutRawBooleanStatuses(_buildFields(screen, answers))
          : _buildFields(screen, answers);

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
    final composedEnergyPhrases = _composeParagraphs(mergedPhrases);
    return ReportScreen(
      screenId: 'section_d_energy_merged',
      title: title,
      fields: composedEnergyPhrases.isNotEmpty ? const [] : mergedFields,
      phrases: composedEnergyPhrases,
      userNote: mergedNotes.join('\n'),
      isMergedGroup: true,
    );
  }

  ({List<String> phrases, Set<String> consumedScreenIds})
      _mainWallConflictSynthesis(
    List<InspectionNodeDefinition> descendants,
    V2RawReportData rawData,
  ) {
    const typeByScreen = <String, String>{
      'activity_outside_property_main_walls_about_wall': 'solid brick wall',
      'activity_outside_property_main_walls_about_wall__cavity_brick_wall':
          'cavity brick wall',
      'activity_outside_property_main_walls_about_wall__cavity_block_wall':
          'cavity block wall',
      'activity_outside_property_main_walls_about_wall__cavity_stud_wall':
          'cavity stud wall',
    };
    const locationFields = <String, String>{
      'cb_main_building': 'main building',
      'cb_back_addition': 'back addition',
      'cb_extension': 'extension',
    };

    final entriesByLocation = <String, List<(String, String)>>{};
    for (final node in descendants) {
      final id = node.id.trim().toLowerCase();
      var type = typeByScreen[id];
      final answers = _answersForScreen(rawData, node.id);
      if (type == null && id.endsWith('__other')) {
        type = (answers['other'] ?? answers['et_other_124'] ?? '').trim();
      }
      if (type == null || type.isEmpty || answers.isEmpty) continue;

      final locations = <String>[
        for (final entry in locationFields.entries)
          if (_isCheckedValue(answers[entry.key])) entry.value,
      ];
      if (_isCheckedValue(answers['cb_other_832'])) {
        final other = (answers['et_other_133'] ?? '').trim().toLowerCase();
        if (other.isNotEmpty) locations.add(other);
      }
      if (locations.isEmpty) continue;
      final key = locations.map((value) => value.toLowerCase()).join('|');
      entriesByLocation
          .putIfAbsent(key, () => <(String, String)>[])
          .add((node.id, type.toLowerCase()));
    }

    final phrases = <String>[];
    final consumed = <String>{};
    for (final entry in entriesByLocation.entries) {
      final types = entry.value.map((value) => value.$2).toSet().toList();
      if (types.length < 2) continue;
      consumed.addAll(entry.value.map((value) => value.$1));
      final locations = entry.key.split('|');
      phrases.add(
        'The external walls to ${_toLegacyWords(locations)} comprise a '
        'mixture of ${_toLegacyWords(types)} construction. The different '
        'wall types should be considered separately when planning future '
        'maintenance or alterations.',
      );
    }
    return (phrases: phrases, consumedScreenIds: consumed);
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
          final wallSynthesis = config.includePhrases &&
                  groupReportTitle.trim().toLowerCase().contains('main walls')
              ? _mainWallConflictSynthesis(descendants, rawData)
              : (phrases: const <String>[], consumedScreenIds: <String>{});
          mergedPhrases.addAll(wallSynthesis.phrases);

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
            if (wallSynthesis.consumedScreenIds.contains(screen.id)) {
              continue;
            }

            final answers = _answersForScreen(rawData, screen.id);
            final fields = config.includePhrases
                ? _withoutRawBooleanStatuses(_buildFields(screen, answers))
                : _buildFields(screen, answers);

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

          final cleanedMergedPhrases =
              _composeParagraphs(_cleanupPhrases(mergedPhrases));

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
      // Revised spec (Phase 7): the Risks section is exactly four subsections -
      // J1 Risks to the Building, J2 Risks to the Grounds, J3 Risks to People,
      // J4 Other risks. The app previously produced five (a separate J4 Risks
      // to Health and J5 Risks to Security). To match the revised spec:
      //  - the former Health risks (asbestos/mould/lead/radon) fold into J3
      //    Risks to People, followed by the general-maintenance advisory;
      //  - the former Security risks (external doors / communal security
      //    systems) fold into J4 Other risks (the native activity_risks_other_
      //    screen, which already carries the proximity risks).
      // Observed content is preserved (folded, not dropped); only the section
      // grouping changes to the revised four-subsection layout.
      const anchorId = 'activity_risks_other_';

      // J2 Risks to the Grounds (synthesized; no native screen).
      final riskToGrounds = _legacyDerivedSectionFRiskToGrounds(rawData);
      if (riskToGrounds.isNotEmpty) {
        final j2InsertAt = screens.indexWhere(
          (s) => s.screenId.trim().toLowerCase() == anchorId,
        );
        final j2Screen = ReportScreen(
          screenId: 'derived_j2_risk_to_grounds',
          title: 'J2 Risk To Grounds',
          fields: const <ReportField>[],
          phrases: riskToGrounds,
        );
        if (j2InsertAt >= 0) {
          screens.insert(j2InsertAt, j2Screen);
        } else {
          screens.add(j2Screen);
        }
      }

      // J3 Risks to People (synthesized): people-safety risks, then the former
      // health risks (asbestos/mould/lead/radon), then the general-maintenance
      // advisory - matching the revised J3 structure. Health always fires, so
      // J3 is always present.
      final j3People = _cleanupPhrases(<String>[
        ..._legacyDerivedSectionFRiskToPeople(rawData),
        ..._legacyDerivedSectionFRiskToHealth(rawData),
        _approvedBankPhrase('{RISK_TO_PEOPLE}::{PEOPLE_GENERAL_ADVICE}') ??
            _riskGeneralMaintenanceAdvice,
      ]);
      if (j3People.isNotEmpty) {
        final insertAt = screens.indexWhere(
          (s) => s.screenId.trim().toLowerCase() == anchorId,
        );
        final j3Screen = ReportScreen(
          screenId: 'derived_j3_risk_to_people',
          title: 'J3 Risk To People',
          fields: const <ReportField>[],
          phrases: j3People,
        );
        if (insertAt >= 0) {
          screens.insert(insertAt, j3Screen);
        } else {
          screens.add(j3Screen);
        }
      }

      // J4 Other risks: enrich the native activity_risks_other_ screen (which
      // carries the proximity risks) with the former J5 security risks. If the
      // native screen is absent, synthesize a J4 entry so the security content
      // is never dropped.
      final riskToSecurity = _legacyDerivedSectionFRiskToSecurity(rawData);
      if (riskToSecurity.isNotEmpty) {
        final j4Index = screens.indexWhere(
          (s) => s.screenId.trim().toLowerCase() == anchorId,
        );
        if (j4Index >= 0) {
          final existing = screens[j4Index];
          screens[j4Index] = ReportScreen(
            screenId: existing.screenId,
            title: existing.title,
            fields: existing.fields,
            phrases: <String>[...existing.phrases, ...riskToSecurity],
            userNote: existing.userNote,
            parentId: existing.parentId,
            isCompleted: existing.isCompleted,
            isMergedGroup: existing.isMergedGroup,
          );
        } else {
          screens.add(ReportScreen(
            screenId: 'derived_j4_other_risks',
            title: 'J4 Other Risks',
            fields: const <ReportField>[],
            phrases: riskToSecurity,
          ));
        }
      }

      // Cross-injected Risk-to-Building content (from E1 chimney and other
      // source screens) only reaches the report via `_phrasesForScreen`'s
      // enrichment of the NATIVE `activity_risks_risk_to_building_` screen -
      // which only runs when that screen has its own answers. When J1's own
      // screen produced nothing but cross-injected content exists, insert it
      // as its own synthesized J1 entry so it is not silently dropped.
      final hasNativeJ1 = screens.any(
        (s) => s.screenId.trim().toLowerCase() == 'activity_risks_risk_to_building_',
      );
      if (!hasNativeJ1) {
        final riskToBuilding = _legacyDerivedSectionFRiskToBuilding(rawData);
        if (riskToBuilding.isNotEmpty) {
          screens.insert(
            0,
            ReportScreen(
              screenId: 'derived_j1_risk_to_building',
              title: 'J1 Risk To Building',
              fields: const <ReportField>[],
              phrases: riskToBuilding,
            ),
          );
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
    if (config.includePhrases) {
      fields = _withoutRawBooleanStatuses(fields);
    }
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
    if (isInspection &&
        phrases.isEmpty &&
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

    if (isInspection &&
        phrases.isEmpty &&
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

    // Valuation room counts are structured accommodation data. Rendering the
    // temporary count prose beside the table is redundant and less readable.
    if (!isInspection && normalizedId == 'no_of_rooms') {
      phrases = const [];
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
      } else if (normalizedId == 'activity_issues_other_matters') {
        cleaned = _cleanupPhrases([
          ...cleaned,
          ..._legacyDerivedSectionFIssueOtherMattersSharedChimney(rawData),
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
    final fieldPhrases = isInspection
        ? FieldPhraseProcessor.buildFieldPhrases(normalizedFields, answers)
        : const <String>[];
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

  bool _isRawBooleanStatus(String label, String rawValue) {
    if (label.trim().toLowerCase() != 'status') return false;
    final value = rawValue.trim().toLowerCase();
    return value == 'yes' ||
        value == 'no' ||
        value == 'true' ||
        value == 'false' ||
        value == '1' ||
        value == '0';
  }

  List<ReportField> _withoutRawBooleanStatuses(List<ReportField> fields) {
    return fields
        .where((field) => !_isRawBooleanStatus(
              field.label,
              field.rawValue ?? field.displayValue,
            ))
        .toList(growable: false);
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
