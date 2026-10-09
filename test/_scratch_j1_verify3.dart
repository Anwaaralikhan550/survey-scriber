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
  test('J1 flashing cross-inject verify', () {
    final rawJson = File('assets/property_inspection/inspection_tree.json').readAsStringSync();
    final tree = InspectionTreePayload.fromJson(rawJson);
    final phraseTexts = (jsonDecode(
      File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
    ) as Map<String, dynamic>).map((k, v) => MapEntry(k, v?.toString() ?? ''));

    final allAnswers = <String, Map<String, String>>{
      'activity_outside_property_repair_flashing': {
        'android_material_design_spinner4': 'Repair now', 'ch1': 'true', 'ch8': 'true', 'cb_is_causing_dump': 'true',
      },
    };
    final screenStates = {for (final k in allAnswers.keys) k: true};

    final survey = Survey(
      id: 'j1-flashing-verify', title: 'Test', type: SurveyType.inspection,
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
