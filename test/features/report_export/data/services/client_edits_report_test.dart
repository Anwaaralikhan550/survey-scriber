// Client edits 2 Nov 2026, through the real report builder and the real tree.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/data/inspection_repository.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/report_export/data/services/report_builder.dart';
import 'package:survey_scriber/features/report_export/data/services/report_data_service.dart';
import 'package:survey_scriber/features/report_export/domain/models/export_config.dart';
import 'package:survey_scriber/features/report_export/domain/models/report_document.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

ReportDocument _build(Map<String, Map<String, String>> answers) {
  final tree = InspectionTreePayload.fromJson(
    File('assets/property_inspection/inspection_tree.json').readAsStringSync(),
  );
  final texts = (jsonDecode(File('assets/property_inspection/phrase_texts.json').readAsStringSync())
          as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v?.toString() ?? ''));
  return ReportBuilder(
    inspectionPhraseEngine: InspectionPhraseEngine(texts),
    valuationPhraseEngine: null,
  ).build(
    V2RawReportData(
      survey: Survey(
        id: 's1',
        title: 'Inspection - ref-354',
        type: SurveyType.inspection,
        status: SurveyStatus.completed,
        createdAt: DateTime(2026, 11, 2),
      ),
      tree: tree,
      allAnswers: answers,
      screenStates: {for (final id in answers.keys) id: true},
      photoFilePaths: const [],
      signatureRows: const [],
    ),
    const ExportConfig(),
  );
}

List<String> _phrases(ReportDocument doc, String sectionKey) => [
      for (final section in doc.sections)
        if (section.key == sectionKey)
          for (final screen in section.screens) ...screen.phrases,
    ];

void main() {
  group('J2 Slope', () {
    const grounds = 'activity_grounds_other_grounds';

    String? sloping(Map<String, String> answers) {
      final phrases = _phrases(_build({grounds: answers}), 'J');
      return phrases.where((p) => p.startsWith('Sloping Ground:')).firstOrNull;
    }

    test('a chosen slope prints, whatever the ground type says', () {
      expect(sloping({'actv_j2_slope': 'Steeply'}), contains('steeply sloping'));
      expect(sloping({'actv_type': 'Level', 'actv_j2_slope': 'Gently'}), contains('gently sloping'));
      expect(sloping({'actv_type': 'Undulating', 'actv_j2_slope': 'Moderately'}), contains('moderately sloping'));
    });

    test('level ground with no slope prints nothing', () {
      expect(sloping({'actv_type': 'Level'}), isNull);
    });
  });

  test('Outside Property header has no letter; other sections keep theirs', () {
    final doc = _build({
      'activity_outside_property_windows_sill_projection': {'actv_condition': 'Properly'},
      'activity_grounds_other_grounds': {'actv_type': 'Level'},
    });
    final titles = {for (final s in doc.sections) s.key: s.title};
    expect(titles['E'], 'Outside Property');
    expect(titles['H'], 'H Grounds');
  });

  test('Ground items come straight after Construction', () {
    final doc = _build({
      'activity_property_type': {'actv_type': 'House'},
      'activity_rear_garden': {'rear_type_0_lawn': 'true'},
      'activity_listed_building__listed_building': {'android_material_design_spinner': 'Yes'},
      'activity_property_location': {'cb_a4_location': 'true', 'a4_location_0_rural_location': 'true'},
    });
    final ids = doc.sections.firstWhere((s) => s.key == 'D').screens.map((s) => s.screenId).toList();
    expect(ids.indexOf('activity_rear_garden'), lessThan(ids.indexOf('activity_listed_building__listed_building')));
    expect(ids.indexOf('activity_rear_garden'), lessThan(ids.indexOf('activity_property_location')));
  });

  test('conservation tick on Property Location density prints the conservation sentence', () {
    final phrases = _phrases(
      _build({
        'activity_property_location': {'cb_a4_location': 'true', 'a4_location_0_conservation': 'true'},
      }),
      'D',
    );
    expect(phrases.join(' '), contains('Conservation area:'));
  });
}
