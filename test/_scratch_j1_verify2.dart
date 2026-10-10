import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/data/inspection_repository.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/report_export/data/services/report_builder.dart';
import 'package:survey_scriber/features/report_export/data/services/report_data_service.dart';
import 'package:survey_scriber/features/report_export/domain/models/export_config.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

void main() {
  test('J1/J3 cross-inject verify2', () {
    final rawJson = File('assets/property_inspection/inspection_tree.json').readAsStringSync();
    final tree = InspectionTreePayload.fromJson(rawJson);
    final phraseTexts = (jsonDecode(
      File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
    ) as Map<String, dynamic>).map((k, v) => MapEntry(k, v?.toString() ?? ''));

    final allAnswers = <String, Map<String, String>>{
      'activity_outside_property_chimney_repair_flaunching': {
        'actv_condition': 'Repair now', 'cb_main_building_28': 'true', 'cb_badly_cracked': 'true', 'cb_is_causing_dump': 'true',
      },
      'activity_outside_property_repair_chimney_repointing': {
        'actv_condition': 'Repair now', 'cb_main_building_79': 'true', 'cb_badly_eroded': 'true', 'cb_is_causing_dump': 'true',
      },
      'activity_outside_property_leaning_chimney': {
        'ch1': 'true', 'android_material_design_spinner4': 'Repair soon',
      },
      'activity_outside_property_repair_chimney_disrepair': {
        'cb_repair_soon_70': 'true', 'cb_main_building_21': 'true',
      },
      'activity_outside_property_repair_chimney_pots': {
        'actv_condition': 'Repair now', 'cb_main_building_91': 'true', 'cb_badly_broken': 'true', 'cb_is_safety_hazard': 'true',
      },
      'activity_outside_property_repair_chimney_dish_aerial': {
        'actv_type': 'Aerial', 'actv_condition': 'Repair now', 'cb_very_loose': 'true', 'cb_is_safety_hazard': 'true',
      },
    };
    final screenStates = {for (final k in allAnswers.keys) k: true};

    final survey = Survey(
      id: 'j1-verify2', title: 'Test', type: SurveyType.inspection,
      status: SurveyStatus.completed, createdAt: DateTime(2026, 1, 1),
      address: 'Test', clientName: 'Test',
    );
    final rawData = V2RawReportData(
      survey: survey, tree: tree, allAnswers: allAnswers, screenStates: screenStates,
      photoFilePaths: const [], signatureRows: const [],
    );
    final builder = ReportBuilder(inspectionPhraseEngine: InspectionPhraseEngine(phraseTexts), valuationPhraseEngine: null);
    final doc = builder.build(rawData, const ExportConfig());

    for (final section in doc.sections) {
      if (section.key != 'J') continue;
      for (final scr in section.screens) {
        print('--- ${scr.title} (${scr.screenId}) ---');
        for (final p in scr.phrases) print(p);
      }
    }
  });
}
