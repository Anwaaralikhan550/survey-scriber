import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/report_export/data/services/report_builder.dart';
import 'package:survey_scriber/features/report_export/data/services/report_data_service.dart';
import 'package:survey_scriber/features/report_export/domain/models/export_config.dart';
import 'package:survey_scriber/features/report_export/domain/models/report_document.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

void main() {
  late ReportBuilder builder;
  late Survey testSurvey;
  late InspectionTreePayload minimalTree;

  setUp(() {
    builder = ReportBuilder();

    testSurvey = Survey(
      id: 'test-survey-1',
      title: 'Test Property',
      type: SurveyType.inspection,
      status: SurveyStatus.inProgress,
      createdAt: DateTime(2026, 2, 19),
      address: '123 Test Street',
      clientName: 'John Doe',
    );

    minimalTree = InspectionTreePayload(
      sections: [
        InspectionSectionDefinition(
          key: 'E',
          title: 'Outside Property',
          description: 'External',
          nodes: [
            InspectionNodeDefinition(
              id: 'activity_roof',
              title: 'Roof',
              type: InspectionNodeType.screen,
              fields: [
                InspectionFieldDefinition(
                  id: 'field_condition',
                  label: 'Condition Rating',
                  type: InspectionFieldType.dropdown,
                  options: ['1', '2', '3'],
                ),
                InspectionFieldDefinition(
                  id: 'field_notes',
                  label: 'Notes',
                  type: InspectionFieldType.text,
                ),
              ],
            ),
            InspectionNodeDefinition(
              id: 'activity_walls',
              title: 'Walls',
              type: InspectionNodeType.screen,
              fields: [
                InspectionFieldDefinition(
                  id: 'wall_condition',
                  label: 'Condition',
                  type: InspectionFieldType.dropdown,
                  options: ['1', '2', '3'],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  });

  V2RawReportData _makeRawData({
    Survey? survey,
    InspectionTreePayload? tree,
    Map<String, Map<String, String>>? allAnswers,
    Map<String, bool>? screenStates,
  }) {
    return V2RawReportData(
      survey: survey ?? testSurvey,
      tree: tree ?? minimalTree,
      allAnswers: allAnswers ?? {},
      screenStates: screenStates ?? {},
      photoFilePaths: [],
      signatureRows: [],
    );
  }

  group('ReportBuilder.build', () {
    test('orders inspection sections to match app flow', () {
      final shuffledTree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'D',
            title: 'About Property',
            description: '',
            nodes: [
              InspectionNodeDefinition(
                id: 'd1',
                title: 'D1',
                type: InspectionNodeType.screen,
                fields: const [
                  InspectionFieldDefinition(
                    id: 'f',
                    label: 'Field',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
            ],
          ),
          InspectionSectionDefinition(
            key: 'A',
            title: 'About Inspection',
            description: '',
            nodes: [
              InspectionNodeDefinition(
                id: 'a1',
                title: 'A1',
                type: InspectionNodeType.screen,
                fields: const [
                  InspectionFieldDefinition(
                    id: 'f',
                    label: 'Field',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
            ],
          ),
          InspectionSectionDefinition(
            key: 'F',
            title: 'Inside',
            description: '',
            nodes: [
              InspectionNodeDefinition(
                id: 'f1',
                title: 'F1',
                type: InspectionNodeType.screen,
                fields: const [
                  InspectionFieldDefinition(
                    id: 'f',
                    label: 'Field',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
            ],
          ),
          InspectionSectionDefinition(
            key: 'E',
            title: 'Outside',
            description: '',
            nodes: [
              InspectionNodeDefinition(
                id: 'e1',
                title: 'E1',
                type: InspectionNodeType.screen,
                fields: const [
                  InspectionFieldDefinition(
                    id: 'f',
                    label: 'Field',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final doc = builder.build(
        _makeRawData(
          tree: shuffledTree,
          allAnswers: {
            'd1': {'f': 'd'},
            'a1': {'f': 'a'},
            'f1': {'f': 'f'},
            'e1': {'f': 'e'},
          },
        ),
        const ExportConfig(includePhrases: false),
      );

      expect(
        doc.sections.map((s) => s.key).toList(),
        equals(['A', 'D', 'E', 'F']),
      );
    });

    test('produces correct report type for inspection surveys', () {
      final doc = builder.build(_makeRawData(), const ExportConfig());
      expect(doc.reportType, ReportType.inspection);
      expect(doc.title, 'Test Property');
    });

    test('produces correct report type for valuation surveys', () {
      final valSurvey = Survey(
        id: 'val-1',
        title: 'Valuation Test',
        type: SurveyType.valuation,
        status: SurveyStatus.inProgress,
        createdAt: DateTime(2026, 2, 19),
      );
      final doc = builder.build(
        _makeRawData(survey: valSurvey),
        const ExportConfig(),
      );
      expect(doc.reportType, ReportType.valuation);
    });

    test('populates survey meta correctly', () {
      final doc = builder.build(_makeRawData(), const ExportConfig());
      expect(doc.surveyMeta.surveyId, 'test-survey-1');
      expect(doc.surveyMeta.address, '123 Test Street');
      expect(doc.surveyMeta.clientName, 'John Doe');
    });

    test('includes survey duration when provided', () {
      final doc = builder.build(
        _makeRawData(),
        const ExportConfig(),
        surveyDuration: const Duration(hours: 2, minutes: 30),
      );
      expect(doc.surveyMeta.surveyDuration, const Duration(hours: 2, minutes: 30));
    });

    test('includes sections with answered screens', () {
      final doc = builder.build(
        _makeRawData(allAnswers: {
          'activity_roof': {'field_condition': '2', 'field_notes': 'Good'},
        }),
        const ExportConfig(),
      );
      expect(doc.sections, hasLength(1));
      expect(doc.sections.first.key, 'E');
      expect(doc.sections.first.screens, hasLength(1));
      expect(doc.sections.first.screens.first.screenId, 'activity_roof');
    });

    test('skips screens with no data when includeEmptyScreens is false', () {
      final doc = builder.build(
        _makeRawData(allAnswers: {
          'activity_roof': {'field_condition': '2'},
          // activity_walls has NO answers
        }),
        const ExportConfig(includeEmptyScreens: false),
      );
      expect(doc.sections.first.screens, hasLength(1));
      expect(doc.sections.first.screens.first.screenId, 'activity_roof');
    });

    test('includes empty screens when includeEmptyScreens is true', () {
      final doc = builder.build(
        _makeRawData(allAnswers: {
          'activity_roof': {'field_condition': '2'},
        }),
        const ExportConfig(includeEmptyScreens: true),
      );
      expect(doc.sections.first.screens, hasLength(2));
    });

    test('skips entire section when all screens are empty', () {
      final doc = builder.build(
        _makeRawData(allAnswers: {}),
        const ExportConfig(includeEmptyScreens: false),
      );
      expect(doc.sections, isEmpty);
    });

    test('skips label-type fields', () {
      final treeWithLabel = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'E',
            title: 'Outside',
            description: 'External',
            nodes: [
              InspectionNodeDefinition(
                id: 'screen1',
                title: 'Screen 1',
                type: InspectionNodeType.screen,
                fields: [
                  InspectionFieldDefinition(
                    id: 'heading',
                    label: 'Section Heading',
                    type: InspectionFieldType.label,
                  ),
                  InspectionFieldDefinition(
                    id: 'data_field',
                    label: 'Data',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final doc = builder.build(
        _makeRawData(
          tree: treeWithLabel,
          allAnswers: {'screen1': {'data_field': 'value'}},
        ),
        const ExportConfig(),
      );
      final screen = doc.sections.first.screens.first;
      // With includePhrases, fields are converted to fallback phrases —
      // the label field should still be skipped (only 'Data' appears).
      // NarrativeEnhancer may prepend a section preamble, so check any phrase.
      expect(screen.phrases, isNotEmpty);
      expect(screen.phrases.any((p) => p.contains('Data')), isTrue);
      expect(screen.phrases.any((p) => p.contains('Section Heading')), isFalse);
    });

    test('formats checkbox values as Yes/No', () {
      final treeWithCheckbox = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'E',
            title: 'Outside',
            description: 'External',
            nodes: [
              InspectionNodeDefinition(
                id: 'screen1',
                title: 'Screen 1',
                type: InspectionNodeType.screen,
                fields: [
                  InspectionFieldDefinition(
                    id: 'cb_field',
                    label: 'Has Damp',
                    type: InspectionFieldType.checkbox,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      // With includePhrases: false, the raw field table is used.
      final doc = builder.build(
        _makeRawData(
          tree: treeWithCheckbox,
          allAnswers: {'screen1': {'cb_field': 'true'}},
        ),
        const ExportConfig(includePhrases: false),
      );
      expect(doc.sections.first.screens.first.fields.first.displayValue, 'Yes');

      // With includePhrases: true (default), checkbox is converted to a
      // fallback phrase listing the checked label.
      final doc2 = builder.build(
        _makeRawData(
          tree: treeWithCheckbox,
          allAnswers: {'screen1': {'cb_field': 'true'}},
        ),
        const ExportConfig(),
      );
      final screen = doc2.sections.first.screens.first;
      expect(screen.phrases, contains(contains('Has Damp')));
      expect(screen.fields, isEmpty);
    });

    test('skips group-type nodes', () {
      final treeWithGroup = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'E',
            title: 'Outside',
            description: 'External',
            nodes: [
              InspectionNodeDefinition(
                id: 'group1',
                title: 'Roof Group',
                type: InspectionNodeType.group,
                fields: [],
              ),
              InspectionNodeDefinition(
                id: 'screen1',
                title: 'Roof Detail',
                type: InspectionNodeType.screen,
                parentId: 'group1',
                fields: [
                  InspectionFieldDefinition(
                    id: 'f1',
                    label: 'Field',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final doc = builder.build(
        _makeRawData(
          tree: treeWithGroup,
          allAnswers: {'screen1': {'f1': 'data'}},
        ),
        const ExportConfig(),
      );
      expect(doc.sections.first.screens, hasLength(1));
      expect(doc.sections.first.screens.first.title, 'Roof Detail');
    });

    test('merges Section D construction group into one report heading', () {
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'D',
            title: 'About Property',
            description: 'About property details',
            nodes: [
              InspectionNodeDefinition(
                id: 'group_construction_2',
                title: 'Construction',
                type: InspectionNodeType.group,
                fields: const [],
              ),
              InspectionNodeDefinition(
                id: 'activity_property_roof',
                title: 'Roof',
                type: InspectionNodeType.screen,
                parentId: 'group_construction_2',
                fields: const [
                  InspectionFieldDefinition(
                    id: 'roof_field',
                    label: 'Roof Type',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
              InspectionNodeDefinition(
                id: 'activity_construction_window',
                title: 'Window',
                type: InspectionNodeType.screen,
                parentId: 'group_construction_2',
                fields: const [
                  InspectionFieldDefinition(
                    id: 'window_field',
                    label: 'Window Material',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final doc = builder.build(
        _makeRawData(
          tree: tree,
          allAnswers: {
            'activity_property_roof': {'roof_field': 'Pitched'},
            'activity_construction_window': {'window_field': 'PVC'},
          },
        ),
        const ExportConfig(includePhrases: false),
      );

      final screens = doc.sections.first.screens;
      expect(screens, hasLength(1));
      expect(screens.first.title, 'Construction');
      expect(screens.first.isMergedGroup, isTrue);
    });

    test('uses concise legacy-style phrases for Section D construction merge', () {
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'D',
            title: 'About Property',
            description: 'About property details',
            nodes: [
              InspectionNodeDefinition(
                id: 'group_construction_2',
                title: 'Construction',
                type: InspectionNodeType.group,
                fields: const [],
              ),
              InspectionNodeDefinition(
                id: 'screen_roof',
                title: 'Roof',
                type: InspectionNodeType.screen,
                parentId: 'group_construction_2',
                fields: const [
                  InspectionFieldDefinition(
                    id: 'roof_a',
                    label: 'Roof A',
                    type: InspectionFieldType.text,
                  ),
                  InspectionFieldDefinition(
                    id: 'roof_b',
                    label: 'Roof B',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
              InspectionNodeDefinition(
                id: 'screen_window',
                title: 'Window',
                type: InspectionNodeType.screen,
                parentId: 'group_construction_2',
                fields: const [
                  InspectionFieldDefinition(
                    id: 'window_a',
                    label: 'Window A',
                    type: InspectionFieldType.text,
                  ),
                  InspectionFieldDefinition(
                    id: 'window_b',
                    label: 'Window B',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final doc = builder.build(
        _makeRawData(
          tree: tree,
          allAnswers: {
            'screen_roof': {'roof_a': 'Alpha', 'roof_b': 'Beta'},
            'screen_window': {'window_a': 'Gamma', 'window_b': 'Delta'},
          },
        ),
        const ExportConfig(),
      );

      final merged = doc.sections.first.screens.first;
      expect(merged.isMergedGroup, isTrue);
      expect(merged.phrases, hasLength(2));
      expect(merged.phrases.first, contains('Alpha'));
      expect(merged.phrases.first, isNot(contains('Beta')));
      expect(merged.phrases.last, contains('Gamma'));
      expect(merged.phrases.last, isNot(contains('Delta')));
    });

    test('emits merged group at group node position to match app ordering', () {
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'D',
            title: 'About Property',
            description: 'About property details',
            nodes: [
              InspectionNodeDefinition(
                id: 'activity_property_type',
                title: 'Property Type',
                type: InspectionNodeType.screen,
                fields: const [
                  InspectionFieldDefinition(
                    id: 'type',
                    label: 'Type',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
              // Child screen appears before its group in JSON (real tree pattern)
              InspectionNodeDefinition(
                id: 'activity_property_construction',
                title: 'Property',
                type: InspectionNodeType.screen,
                parentId: 'group_construction_2',
                fields: const [
                  InspectionFieldDefinition(
                    id: 'construction',
                    label: 'Construction',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
              InspectionNodeDefinition(
                id: 'activity_property_built',
                title: 'Property Built',
                type: InspectionNodeType.screen,
                fields: const [
                  InspectionFieldDefinition(
                    id: 'built',
                    label: 'Built',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
              InspectionNodeDefinition(
                id: 'group_construction_2',
                title: 'Construction',
                type: InspectionNodeType.group,
                fields: const [],
              ),
              InspectionNodeDefinition(
                id: 'activity_property_extended',
                title: 'Year Extended',
                type: InspectionNodeType.screen,
                fields: const [
                  InspectionFieldDefinition(
                    id: 'extended',
                    label: 'Extended',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final doc = builder.build(
        _makeRawData(
          tree: tree,
          allAnswers: {
            'activity_property_type': {'type': 'House'},
            'activity_property_construction': {'construction': 'Cavity wall'},
            'activity_property_built': {'built': '1990'},
            'activity_property_extended': {'extended': '2005'},
          },
        ),
        const ExportConfig(includePhrases: false),
      );

      final titles = doc.sections.first.screens.map((s) => s.title).toList();
      expect(
        titles,
        equals([
          'Property Type',
          'Property Built',
          'Construction',
          'Year Extended',
        ]),
      );
    });

    test('applies conditional visibility filtering', () {
      final treeWithConditional = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'E',
            title: 'Outside',
            description: 'External',
            nodes: [
              InspectionNodeDefinition(
                id: 'screen1',
                title: 'Screen 1',
                type: InspectionNodeType.screen,
                fields: [
                  InspectionFieldDefinition(
                    id: 'trigger',
                    label: 'Main Select',
                    type: InspectionFieldType.dropdown,
                    options: ['Yes', 'No'],
                  ),
                  InspectionFieldDefinition(
                    id: 'detail',
                    label: 'Details',
                    type: InspectionFieldType.text,
                    conditionalOn: 'trigger',
                    conditionalValue: 'Yes',
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      // When trigger is 'No', the conditional 'detail' field should be hidden
      final doc = builder.build(
        _makeRawData(
          tree: treeWithConditional,
          allAnswers: {'screen1': {'trigger': 'No', 'detail': 'should be hidden'}},
        ),
        const ExportConfig(),
      );
      final fields = doc.sections.first.screens.first.fields;
      expect(fields.where((f) => f.fieldId == 'detail'), isEmpty);
    });

    test('marks isCompleted on report screens from screenStates', () {
      final doc = builder.build(
        _makeRawData(
          allAnswers: {'activity_roof': {'field_condition': '1'}},
          screenStates: {'activity_roof': true},
        ),
        const ExportConfig(),
      );
      expect(doc.sections.first.screens.first.isCompleted, true);
    });

    test('excludes photos when includePhotos is false', () {
      final rawData = V2RawReportData(
        survey: testSurvey,
        tree: minimalTree,
        allAnswers: {'activity_roof': {'field_condition': '1'}},
        screenStates: {},
        photoFilePaths: ['/path/to/photo.jpg'],
        signatureRows: [],
      );
      final doc = builder.build(rawData, const ExportConfig(includePhotos: false));
      expect(doc.photoFilePaths, isEmpty);
    });

    test('excludes signatures when includeSignatures is false', () {
      final rawData = V2RawReportData(
        survey: testSurvey,
        tree: minimalTree,
        allAnswers: {'activity_roof': {'field_condition': '1'}},
        screenStates: {},
        photoFilePaths: [],
        signatureRows: [
          SignatureRow(
            signerName: 'Test',
            signerRole: 'Surveyor',
            filePath: '/sig.png',
            signedAt: DateTime.now(),
          ),
        ],
      );
      final doc = builder.build(rawData, const ExportConfig(includeSignatures: false));
      expect(doc.signatures, isEmpty);
    });

    test('totalFields and totalScreens computed correctly', () {
      // With includePhrases: false, fields stay as raw fields.
      final doc = builder.build(
        _makeRawData(allAnswers: {
          'activity_roof': {'field_condition': '2', 'field_notes': 'Notes'},
          'activity_walls': {'wall_condition': '3'},
        }),
        const ExportConfig(includePhrases: false),
      );
      expect(doc.totalScreens, 2);
      expect(doc.totalFields, 3);

      // With includePhrases: true (default), fields are converted to fallback
      // phrases when no phrase engine handler exists, so totalFields is 0.
      final doc2 = builder.build(
        _makeRawData(allAnswers: {
          'activity_roof': {'field_condition': '2', 'field_notes': 'Notes'},
          'activity_walls': {'wall_condition': '3'},
        }),
        const ExportConfig(),
      );
      expect(doc2.totalScreens, 2);
      expect(doc2.totalFields, 0);
      // Data is now in phrases instead
      expect(doc2.sections.first.screens.first.phrases, isNotEmpty);
    });
  });
}
