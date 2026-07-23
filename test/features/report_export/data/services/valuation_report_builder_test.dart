import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_engine.dart';
import 'package:survey_scriber/features/report_export/data/services/report_builder.dart';
import 'package:survey_scriber/features/report_export/data/services/report_data_service.dart';
import 'package:survey_scriber/features/report_export/domain/models/export_config.dart';
import 'package:survey_scriber/features/report_export/domain/models/report_document.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

void main() {
  final survey = Survey(
    id: 'valuation-report-test',
    title: 'Valuation Test Property',
    type: SurveyType.valuation,
    status: SurveyStatus.inProgress,
    createdAt: DateTime(2026, 7, 12),
  );

  final tree = InspectionTreePayload(
    sections: [
      InspectionSectionDefinition(
        key: 'property_assessment',
        title: 'Property Assessment',
        description: '',
        nodes: const [
          InspectionNodeDefinition(
            id: 'no_of_rooms',
            title: 'Number of Rooms',
            type: InspectionNodeType.screen,
            fields: [
              InspectionFieldDefinition(
                id: 'et_liv',
                label: 'Living Rooms',
                type: InspectionFieldType.number,
              ),
              InspectionFieldDefinition(
                id: 'et_bed',
                label: 'Bedrooms',
                type: InspectionFieldType.number,
              ),
              InspectionFieldDefinition(
                id: 'et_other_name',
                label: 'Other Rooms',
                type: InspectionFieldType.text,
              ),
              InspectionFieldDefinition(
                id: 'et_other',
                label: 'Other Count',
                type: InspectionFieldType.number,
              ),
            ],
          ),
        ],
      ),
    ],
  );

  V2RawReportData rawData(Map<String, Map<String, String>> answers) =>
      V2RawReportData(
        survey: survey,
        tree: tree,
        allAnswers: answers,
        screenStates: const {},
        photoFilePaths: const [],
        signatureRows: const [],
      );

  test('exports valuation accommodation through the structured schedule', () {
    final builder = ReportBuilder(
      valuationPhraseEngine: ValuationPhraseEngine(),
    );
    final document = builder.build(
      rawData({
        'no_of_rooms': {
          'et_liv': '2',
          'et_bed': '3',
          'et_other': '1',
          'et_other_name': 'Study',
        },
      }),
      const ExportConfig(),
    );

    expect(document.reportType, ReportType.valuation);
    expect(document.accommodationSchedule, hasLength(1));
    expect(document.accommodationSchedule.single.floor, 'Property total');
    expect(document.accommodationSchedule.single.livingRooms, '2');
    expect(document.accommodationSchedule.single.bedrooms, '3');
    expect(document.accommodationSchedule.single.otherRooms, '1 Study');
    final roomScreen = document.sections.single.screens.single;
    expect(roomScreen.screenId, 'no_of_rooms');
    expect(roomScreen.phrases, isEmpty);
  });
}
