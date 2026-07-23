// Temporary scratch script: simulates one full, realistic property
// inspection and renders it through the REAL app pipeline
// (InspectionPhraseEngine -> ReportBuilder -> PdfGeneratorService), the
// exact same code path a normal user's completed inspection export uses.
// Not a permanent test; delete after use. No production code is modified.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/data/inspection_repository.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/report_export/data/services/pdf_generator_service.dart';
import 'package:survey_scriber/features/report_export/data/services/report_builder.dart';
import 'package:survey_scriber/features/report_export/data/services/report_data_service.dart';
import 'package:survey_scriber/features/report_export/domain/models/export_config.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

const String _scratchRoot =
    r'C:\Users\DELL\AppData\Local\Temp\claude\C--Users-DELL--claude\f78106f7-eaad-4726-8b3a-b341e2e38587\scratchpad';

// Numbered repeat-group duplicate slots (activity_x__y__2 .. __6) - a normal
// single-property inspection never touches these; they only exist for
// properties with multiple instances of the same element.
final RegExp _repeatSlotSuffix = RegExp(r'__\d+$');

// Keywords that mark a screen as a defect/repair/negative-state branch.
// Skipped by default (no defect) unless explicitly whitelisted below.
const List<String> _defectKeywords = [
  'repair',
  'disrepair',
  'leaking',
  'damage',
  'damaged',
  'not_inspected',
  'flooded',
  'decay',
  'infestation',
  'no_access',
  'not_habitable',
  'poor_condition',
  'safety_hazard',
  'hazard',
  'removed',
  'movement',
  'cracks',
  'condensation',
  'not_in_use',
  'no_safety_glass',
  'inadequate',
  'undersize',
  'spreading',
  'no_fire_escape',
];

// Facts mirror the client-supplied reference report (FBSHB1747, 3 Murray
// Crescent) as closely as the tree's field structure allows, so this run
// reflects a single, real, non-exhaustive inspection rather than the
// "every checkbox at once" stress-test used in the earlier run.
final Map<String, Map<String, String>> _curatedIssues = {
  // Phase 2B Gate 3: exercise E2 roof-covering defects that cross-inject
  // into J1 (Risk to Building) and J3 (Risk to People).
  'activity_outside_property_roof_repair_tiles': {
    'actv_condition': 'Repair now',
    'cb_roof_40': 'true',
    'cb_ridge_16': 'true',
    'cb_hip_42': 'true',
    'cb_are_damaged_65': 'true',
  },
  'outside_property_roof_covering_roof_structure_layout': {
    'cb_main_building_22': 'true',
    'actv_status': 'Investigate',
    'cb_front_39': 'true',
  },
  'activity_outside_property_roof_repair_flat_roof': {
    'actv_condition': 'Repair now',
    'cb_torn_78': 'true',
  },
  'activity_outside_property_roof_spreading_repair': {
    'actv_status': 'Yes',
  },
  'activity_outside_property_roof_repair_parapet_wall': {
    'actv_condition': 'Repair now',
    'cb_rendering_16': 'true',
    'cb_flashing_83': 'true',
    'cb_badly_damaged_70': 'true',
    'cb_safety_hazard': 'true',
  },

  // Phase 2B Gate 3: exercise E1 chimney defects that cross-inject into
  // J1 (Risk to Building) and J3 (Risk to People, currently "J2" screen id).
  'activity_outside_property_repair_flashing': {
    'android_material_design_spinner4': 'Repair now',
    'ch1': 'true',
    'ch8': 'true',
    'cb_is_causing_dump': 'true',
  },
  'activity_outside_property_chimney_repair_flaunching': {
    'actv_condition': 'Repair now',
    'cb_main_building_28': 'true',
    'cb_badly_cracked': 'true',
    'cb_is_causing_dump': 'true',
  },
  'activity_outside_property_repair_chimney_repointing': {
    'actv_condition': 'Repair now',
    'cb_main_building_79': 'true',
    'cb_badly_eroded': 'true',
    'cb_is_causing_dump': 'true',
  },
  'activity_outside_property_leaning_chimney': {
    'ch1': 'true',
    'android_material_design_spinner4': 'Repair soon',
  },
  'activity_outside_property_repair_chimney_disrepair': {
    'cb_repair_soon_70': 'true',
    'cb_main_building_21': 'true',
  },
  'activity_outside_property_repair_chimney_pots': {
    'actv_condition': 'Repair now',
    'cb_main_building_91': 'true',
    'cb_badly_broken': 'true',
    'cb_is_safety_hazard': 'true',
  },
  'activity_outside_property_repair_chimney_dish_aerial': {
    'actv_type': 'Aerial',
    'actv_condition': 'Repair now',
    'cb_very_loose': 'true',
    'cb_is_safety_hazard': 'true',
  },
  'activity_property_weather': {
    'android_material_design_spinner': 'Dry',
    'android_material_design_spinner2': 'Wet',
  },
  'activity_property_status': {
    'android_material_design_spinner': 'Occupied',
    'android_material_design_spinner2': 'Fully furnished',
    'android_material_design_spinner3': 'Fully covered',
  },
  'activity_property_facing': {'android_material_design_spinner': 'Southwest'},
  'activity_over_all_openion': {
    'android_material_design_spinner5': 'Reasonable',
    'android_material_design_spinner': '1190000',
  },
  'activity_property_type': {
    'android_material_design_spinner': 'House',
    'android_material_design_spinner3': 'Detached',
    'android_material_design_spinner4': '4',
  },
  'activity_property_built_year': {
    'android_material_design_spinner': '1930',
    'android_material_design_spinner5': 'I think',
  },
  'activity_property_extended': {'android_material_design_spinner': 'Unknown'},
  'activity_property_converted': {'android_material_design_spinner': 'Not converted'},

  // ── Construction group (D) ──
  'activity_property_construction': {
    'ch1': 'true', 'ch2': 'true', 'ch3': 'true',
  },
  'activity_property_roof': {
    'ch2': 'true', // Pitched
    'ch9': 'true', // Clay
    'ch6': 'true', // Tiles
  },
  'activity_extended_wall': {
    'ch2': 'true', 'ch3': 'true', // Cavity brick wall + Solid wall
    'android_material_design_spinner': 'Partially',
    'android_material_design_spinner2': 'Smooth',
    'ch7': 'true', // Painted
  },
  'activity_internal_wall': {'ch1': 'true', 'ch2': 'true'}, // Stud + Solid
  'activity_construction_floor': {
    'android_material_design_spinner': 'Of a mixture of',
    'ch1': 'true', 'ch2': 'true', // Suspended timber + Solid
  },
  'activity_construction_window': {
    'android_material_design_spinner': 'Mainly of',
    'ch2': 'true', // Double
    'ch5': 'true', // PVC
  },

  // ── Grounds/garden (D+H) ──
  'activity_grounds_other_grounds': {'actv_type': 'Relatively level'},
  'activity_garden': {
    'android_material_design_spinner': 'Paved',
    'android_material_design_spinner2': 'Brick wall',
    'android_material_design_spinner3': 'Paved',
    'android_material_design_spinner4': 'Timber',
  },

  // ── E1 Chimney ──
  'activity_outside_property_water_proofing': {
    'ch1': 'true', 'ch6': 'true', // lead flashing, lead flaunching
  },
  'activity_outside_property_condition': {
    'android_material_design_spinner3': 'Reasonable',
  },

  // ── E2 Roof covering ──
  'outside_property_about_roof_layout': {
    'cb_main_building': 'true',
    'cb_original': 'true', 'cb_clay': 'true', 'cb_tiles': 'true',
    'actv_condition': 'Reasonable',
  },
  'activity_outside_property_roof_covering_main': {
    'android_material_design_spinner4': '2',
  },

  // ── E3 Rainwater goods ──
  'activity_rwg_weather_condition': {'actv_weather_condition': 'Dry'},
  'activity_outside_property_rwg_about': {
    'actv_rainwater_goods_are_made_up': 'Mainly of',
    'cb_plastic': 'true',
    'actv_condition': 'Reasonable',
  },
  // Phase 2B Gate 3: exercise E3 rainwater-goods "Repair now - if causing
  // damp" branch that cross-injects into J1 (Risk to Building).
  'activity_outside_property_rwg__repair_pipes_gutters': {
    'actv_condition': 'Repair now - if causing damp',
    'cb_gutters_59': 'true',
    'cb_are_rusted_18': 'true',
  },
  'activity_outside_property_rainwater_goods_main_screen': {
    'actv_condition_rating': '3',
    'ar_etNote':
        'Overflowing rainwater from the slipped ridge tile over the bay window is causing dampness to part of the tile cladding and clay tile windowsill underneath including peeled plinth rendering.',
  },

  // ── E4 Main walls ──
  'activity_outside_property_main_walls_dpc': {
    'actv_status': 'Not Visible',
    'actv_not_visible_because_of': 'Rendered plinth',
    'cb_felt_73': 'true', 'cb_slates_45': 'true',
  },
  'activity_outside_property_main_walls_damp': {
    'actv_status': 'Present',
    'et_location_677': 'rear kitchen wall',
    'cb_penetrating_damp': 'true',
    'cb_overflowing_gutter': 'true',
    'cb_install_french_gutters': 'true',
  },
  'activity_outside_property_main_wall_repairs_lintel': {
    'actv_condition': 'Repair now',
    'cb_front_27': 'true',
    'cb_main_building_67': 'true',
    'cb_eroded_49': 'true',
  },
  'activity_outside_property_main_wall_repairs_window_sills': {
    'actv_condition': 'Repair now',
    'cb_front_27': 'true',
    'cb_main_building_67': 'true',
    'cb_eroded_49': 'true',
  },
  'activity_outside_property_main_wall_repairs_render': {
    'actv_condition': 'Repair now',
    'cb_front_62': 'true',
    'cb_main_building_87': 'true',
    'cb_cracked_101': 'true',
    'cb_causing_damp': 'true',
    'cb_hazard': 'true',
  },
  'activity_outside_property_main_walls_main_screen': {
    'android_material_design_spinner4': '2',
  },

  // ── E5 Windows ──
  'activity_outside_property_windows_aboutwindow': {
    'actv_made_up_of': 'Mainly',
    'cb_is_replacement': 'true',
    'cb_pvc': 'true',
    'cb_double': 'true',
    'actv_status': 'No SG Rating',
    'actv_condition': 'Reasonable',
  },
  'activity_outside_property_windows_sill_projection': {
    'actv_projection_type': 'Adequate',
    'actv_condition': 'Properly',
  },
  'activity_outside_property_windows_repairs_repair_window': {
    'cb_ch2': 'true',
    'cb_lounge_79': 'true',
    'cb_bedroom_35': 'true',
    'cb_have_broken_panes_14': 'true',
    'cb_are_in_disrepair_33': 'true',
    'cb_safety_hazard': 'true',
  },
  'activity_outside_property_windows_repairs_no_fire_escape_risk': {
    'cb_bedroom_43': 'true',
    'cb_no_opening_63': 'true',
  },
  'activity_outside_property_windows_main_screen': {
    'android_material_design_spinner4': '2',
  },

  // ── E6 Outside doors ──
  'activity_outside_property_out_side_doors_about_doors__timber': {
    'cb_main': 'true',
    'cb_replacement': 'true',
    'cb_double': 'true',
    'actv_status': 'Noted',
    'actv_condition': 'Reasonable',
    'actv_status_security': 'Properly',
    'actv_seciruty_offered': 'Reasonable',
  },
  'activity_outside_property_outside_doors_main_screen': {
    'android_material_design_spinner4': '2',
  },

  // ── H1 Garage (none - client's reference report has no garages) ──
  'activity_grounds_garage': <String, String>{}, // skip: no garage to describe
  'activity_grounds_garage_not_inspected': {
    'cb_not_inspected': 'true',
    'cb_not_inspected_no_garage': 'true',
  },

  // ── F section ──
  'activity_inside_property_about_roof_structure': {
    'actv_construction': 'Built of traditional cut timber',
    'actv_underlining': 'Underlining',
    'cb_sacking_felt': 'true',
    'actv_insulation': 'Adequate',
    'actv_roof_structure_condition': 'Reasonable',
  },
  'activity_inside_property_roof_structure_main_screen': {
    'android_material_design_spinner4': '2',
  },
  'inside_property_ceilings_about_ceilings': {
    'actv_made_up': 'mainly of ',
    'cb_modern_plasterboard': 'true',
    'cb_painted': 'true',
    'actv_condition': 'Reasonable',
  },
  'activity_inside_property_ceilings_main_screen': {
    'android_material_design_spinner4': '1',
  },
  'activity_inside_property_wap_walls': {
    'cb_solid': 'true', 'cb_stud': 'true',
    'actv_condition': 'Reasonable',
  },
  'activity_inside_property_walls_and_partitions_main_screen': {
    'android_material_design_spinner4': '1',
  },
  'activity_in_side_property_floors_about_floor': {
    'actv_construction': 'All solid',
    'actv_covered_with': 'with a mixture of',
    'cb_carpets': 'true', 'cb_wood_flooring': 'true', 'cb_ceramic_tiles': 'true',
    'actv_condition': 'Reasonable',
  },
  'activity_inside_property_floors_main_screen': {
    'android_material_design_spinner4': '1',
  },
  'activity_in_side_property_fire_places__gas_fire': {
    'cb_lounge': 'true',
    'actv_condition': 'Reasonable',
  },
  'activity_in_side_property_built_in_fittings': {
    'cb_kitchen': 'true',
    'cb_timber_83': 'true',
    'cb_timber': 'true',
    'android_material_design_spinner3': 'Reasonable',
  },
  'activity_inside_property_built_in_fittings_main_screen': {
    'android_material_design_spinner4': '2',
  },
  'activity_inside_property_bathroom_fittings_main_screen': {
    'android_material_design_spinner4': '2',
  },

  // ── G Services ──
  'activity_service_about_electricity': {
    'cb_under_the_stairs_40': 'true',
    'cb_in_an_outside_box_54': 'true',
    'cb_dated_electrical_system': 'true',
  },
  'activity_services_electricity_main_screen': {
    'cb_dated_electrical_system': 'true',
    'android_material_design_spinner4': '3',
  },
  'activity_services_main_gas': {
    'actv_condition': 'Ok',
    'actv_location': 'is in an outside box',
  },
  'activity_services_water_main_screen': {'android_material_design_spinner4': '1'},
  'activity_services_heating_main_screen': {'android_material_design_spinner4': '3'},
  'activity_services_water_heating_main_screen': {
    'android_material_design_spinner4': '3',
  },
  'activity_services_drainage_main_screen': {
    'android_material_design_spinner4': '1',
  },
};

final Map<String, String> _preferredVariant = {
  'activity_outside_property_main_walls_about_wall':
      'activity_outside_property_main_walls_about_wall__cavity_brick_wall',
  'activity_outside_property_out_side_doors_about_doors':
      'activity_outside_property_out_side_doors_about_doors__timber',
  'activity_in_side_property_fire_places':
      'activity_in_side_property_fire_places__gas_fire',
  'outside_property_about_roof_layout': 'outside_property_about_roof_layout',
};

bool _isDefectScreen(String id, String title) {
  final lower = '$id $title'.toLowerCase();
  return _defectKeywords.any(lower.contains);
}

String? _pickDropdownValue(InspectionFieldDefinition field) {
  final options = field.options ?? const <String>[];
  if (options.isEmpty) return null;
  final negative = RegExp(
    r'not inspected|none|no |^no$|not applicable|not present',
    caseSensitive: false,
  );
  for (final o in options) {
    if (!negative.hasMatch(o)) return o;
  }
  return options.first;
}

String _textValueFor(InspectionFieldDefinition field) {
  final label = field.label.toLowerCase();
  if (label.contains('note')) {
    return 'No significant additional observations for this element.';
  }
  if (label.contains('location')) return 'Kitchen';
  if (label.contains('date')) return '2015';
  if (label.contains('other')) return 'N/A';
  return 'sample detail';
}

Map<String, String> _answersFor(InspectionNodeDefinition screen) {
  final answers = <String, String>{};
  for (final field in screen.fields) {
    switch (field.type) {
      case InspectionFieldType.checkbox:
        answers[field.id] = 'true';
      case InspectionFieldType.dropdown:
        final v = _pickDropdownValue(field);
        if (v != null) answers[field.id] = v;
      case InspectionFieldType.text:
        answers[field.id] = _textValueFor(field);
      case InspectionFieldType.number:
        answers[field.id] = '2';
      case InspectionFieldType.label:
        break;
    }
  }
  return answers;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Real path_provider plugin channel isn't registered under `flutter
  // test` (no platform embedding) - mock it to point PdfGeneratorService's
  // font cache lookup at a scratch dir pre-populated with real TTF bytes,
  // so it hits the cache and never attempts the network Google Fonts
  // download (which is blocked/unreliable under the test HttpClient).
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathChannel, (call) async {
    if (call.method == 'getApplicationDocumentsDirectory') {
      return '$_scratchRoot\\appdocs';
    }
    return null;
  });

  test('generate one full realistic inspection PDF via real app pipeline',
      () async {
    final rawJson = File('assets/property_inspection/inspection_tree.json')
        .readAsStringSync();
    final tree = InspectionTreePayload.fromJson(rawJson);

    final skipBases = _preferredVariant.keys.toSet();
    final allowedVariant = _preferredVariant.values.toSet();
    final screens = <InspectionNodeDefinition>[];
    for (final section in tree.sections) {
      for (final node in section.nodes) {
        if (node.type != InspectionNodeType.screen) continue;
        final id = node.id;
        if (_repeatSlotSuffix.hasMatch(id)) continue;
        if (id.contains('__')) {
          final base = id.split('__').first;
          if (skipBases.contains(base) && !allowedVariant.contains(id)) {
            continue;
          }
        }
        screens.add(node);
      }
    }

    final allAnswers = <String, Map<String, String>>{};
    final screenStates = <String, bool>{};
    var filled = 0;
    var skippedDefect = 0;
    for (final screen in screens) {
      if (_curatedIssues.containsKey(screen.id)) {
        allAnswers[screen.id] = _curatedIssues[screen.id]!;
        screenStates[screen.id] = true;
        filled++;
        continue;
      }
      if (_isDefectScreen(screen.id, screen.title)) {
        skippedDefect++;
        continue;
      }
      final answers = _answersFor(screen);
      if (answers.isNotEmpty) {
        allAnswers[screen.id] = answers;
        screenStates[screen.id] = true;
        filled++;
      }
    }

    stderr.writeln(
        'Screens total=${screens.length} filled=$filled skippedDefect=$skippedDefect curated=${_curatedIssues.length}');

    final survey = Survey(
      id: 'scratch-survey-1',
      title: '12 Example Avenue, Anytown, AN1 2YT',
      type: SurveyType.inspection,
      status: SurveyStatus.completed,
      createdAt: DateTime(2026, 7, 1),
      address: '12 Example Avenue, Anytown, AN1 2YT',
      clientName: 'Mr & Mrs Sample Client',
    );

    final rawData = V2RawReportData(
      survey: survey,
      tree: tree,
      allAnswers: allAnswers,
      screenStates: screenStates,
      photoFilePaths: const [],
      signatureRows: const [],
    );

    final phraseTexts = (jsonDecode(
      File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
    ) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v?.toString() ?? ''));

    final builder = ReportBuilder(
      inspectionPhraseEngine: InspectionPhraseEngine(phraseTexts),
      valuationPhraseEngine: null,
    );

    const config = ExportConfig();
    final doc = builder.build(rawData, config);

    stderr.writeln(
        'Document built: sections=${doc.sections.length} totalScreens=${doc.totalScreens} totalFields=${doc.totalFields}');

    // Plain-text dump too, for quick cross-reference against the PDF.
    final buffer = StringBuffer();
    buffer.writeln('TITLE: ${doc.title}');
    for (final section in doc.sections) {
      buffer.writeln('\n=== SECTION ${section.key}: ${section.title} ===');
      for (final scr in section.screens) {
        if (scr.phrases.isEmpty && scr.fields.isEmpty) continue;
        buffer.writeln('--- ${scr.title} (${scr.screenId}) ---');
        for (final p in scr.phrases) {
          buffer.writeln(p);
        }
      }
    }
    File('$_scratchRoot\\real_app_report_text.txt')
        .writeAsStringSync(buffer.toString());

    // The REAL app PDF renderer - same class/method a normal user's export
    // button calls.
    final pdfService = PdfGeneratorService(config);
    pdfService.onProgress =
        (p) => stderr.writeln('PROGRESS: ${p.stage} ${p.percent}');
    final result = await pdfService.generatePdf(doc);
    stderr.writeln('PDF bytes: ${result.bytes.length}, path=${result.path}');
    File('$_scratchRoot\\real_app_inspection_report.pdf')
        .writeAsBytesSync(result.bytes);

    expect(result.bytes.length, greaterThan(0));
  }, timeout: const Timeout(Duration(minutes: 15)));
}
