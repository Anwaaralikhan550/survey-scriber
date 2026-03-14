import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';
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
    Map<String, List<String>>? persistedPhrases,
    Map<String, bool>? persistedPhraseManualFlags,
  }) {
    return V2RawReportData(
      survey: survey ?? testSurvey,
      tree: tree ?? minimalTree,
      allAnswers: allAnswers ?? {},
      screenStates: screenStates ?? {},
      photoFilePaths: [],
      signatureRows: [],
      persistedPhrases: persistedPhrases ?? const {},
      persistedPhraseManualFlags: persistedPhraseManualFlags ?? const {},
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
      expect(
          doc.surveyMeta.surveyDuration, const Duration(hours: 2, minutes: 30));
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
          allAnswers: {
            'screen1': {'data_field': 'value'}
          },
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
          allAnswers: {
            'screen1': {'cb_field': 'true'}
          },
        ),
        const ExportConfig(includePhrases: false),
      );
      expect(doc.sections.first.screens.first.fields.first.displayValue, 'Yes');

      // With includePhrases: true (default), checkbox is converted to a
      // fallback phrase listing the checked label.
      final doc2 = builder.build(
        _makeRawData(
          tree: treeWithCheckbox,
          allAnswers: {
            'screen1': {'cb_field': 'true'}
          },
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
          allAnswers: {
            'screen1': {'f1': 'data'}
          },
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

    test('uses concise legacy-style phrases for Section D construction merge',
        () {
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
      expect(merged.phrases, hasLength(4));
      expect(merged.phrases.first, contains('Alpha'));
      expect(merged.phrases[1], contains('Beta'));
      expect(merged.phrases[2], contains('Gamma'));
      expect(merged.phrases.last, contains('Delta'));
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
          'Year Extended',
          'Construction',
        ]),
      );
    });

    test('keeps roof covering summary/main screens at end of merged E2 group',
        () {
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'E',
            title: 'Outside Property',
            description: '',
            nodes: [
              const InspectionNodeDefinition(
                id: 'group_e2_roof_covering_9',
                title: 'Roof Covering',
                type: InspectionNodeType.group,
                parentId: null,
                fields: [],
              ),
              const InspectionNodeDefinition(
                id: 'activity_outside_property_roof_covering_main',
                title: 'Roof Covering',
                type: InspectionNodeType.screen,
                parentId: 'group_e2_roof_covering_9',
                fields: [
                  InspectionFieldDefinition(
                    id: 'main_field',
                    label: 'Main Field',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
              const InspectionNodeDefinition(
                id: 'outside_property_roof_covering_weather_layout',
                title: 'Weather',
                type: InspectionNodeType.screen,
                parentId: 'group_e2_roof_covering_9',
                fields: [
                  InspectionFieldDefinition(
                    id: 'weather_field',
                    label: 'Weather Field',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
              const InspectionNodeDefinition(
                id: 'activity_outside_property_roof_covering_summary',
                title: 'Roof Covering Summary',
                type: InspectionNodeType.screen,
                parentId: 'group_e2_roof_covering_9',
                fields: [
                  InspectionFieldDefinition(
                    id: 'summary_field',
                    label: 'Summary Field',
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
            'activity_outside_property_roof_covering_main': {
              'main_field': 'main',
            },
            'outside_property_roof_covering_weather_layout': {
              'weather_field': 'weather',
            },
            'activity_outside_property_roof_covering_summary': {
              'summary_field': 'summary',
            },
          },
        ),
        const ExportConfig(includePhrases: false),
      );

      final merged = doc.sections.single.screens.single;
      expect(merged.isMergedGroup, isTrue);
      expect(
        merged.fields.map((f) => f.label).toList(),
        equals(['Weather Field', 'Main Field', 'Summary Field']),
      );
    });

    test('keeps rainwater-goods main screen at end of merged E3 group', () {
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'E',
            title: 'Outside Property',
            description: '',
            nodes: [
              const InspectionNodeDefinition(
                id: 'group_e3_rain_water_goods_13',
                title: 'Rain Water Goods',
                type: InspectionNodeType.group,
                parentId: null,
                fields: [],
              ),
              const InspectionNodeDefinition(
                id: 'group_rainwater_goods_14',
                title: 'Rainwater Goods',
                type: InspectionNodeType.group,
                parentId: 'group_e3_rain_water_goods_13',
                fields: [],
              ),
              const InspectionNodeDefinition(
                id: 'activity_outside_property_rainwater_goods_main_screen',
                title: 'Rain Water Goods',
                type: InspectionNodeType.screen,
                parentId: 'group_rainwater_goods_14',
                fields: [
                  InspectionFieldDefinition(
                    id: 'main_field',
                    label: 'Main Field',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
              const InspectionNodeDefinition(
                id: 'activity_rwg_weather_condition',
                title: 'Weather',
                type: InspectionNodeType.screen,
                parentId: 'group_rainwater_goods_14',
                fields: [
                  InspectionFieldDefinition(
                    id: 'weather_field',
                    label: 'Weather Field',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
              const InspectionNodeDefinition(
                id: 'activity_outside_property_rwg_about',
                title: 'About RWG',
                type: InspectionNodeType.screen,
                parentId: 'group_rainwater_goods_14',
                fields: [
                  InspectionFieldDefinition(
                    id: 'about_field',
                    label: 'About Field',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
              const InspectionNodeDefinition(
                id: 'activity_outside_property_rwg__repair_pipes_gutters',
                title: 'Repairs',
                type: InspectionNodeType.screen,
                parentId: 'group_e3_rain_water_goods_13',
                fields: [
                  InspectionFieldDefinition(
                    id: 'repair_field',
                    label: 'Repair Field',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
              const InspectionNodeDefinition(
                id: 'activity_outside_property_rain_water_goods_not_inspected',
                title: 'Not Inspected',
                type: InspectionNodeType.screen,
                parentId: 'group_e3_rain_water_goods_13',
                fields: [
                  InspectionFieldDefinition(
                    id: 'ni_field',
                    label: 'NI Field',
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
            'activity_outside_property_rainwater_goods_main_screen': {
              'main_field': 'main',
            },
            'activity_rwg_weather_condition': {
              'weather_field': 'weather',
            },
            'activity_outside_property_rwg_about': {
              'about_field': 'about',
            },
            'activity_outside_property_rwg__repair_pipes_gutters': {
              'repair_field': 'repair',
            },
            'activity_outside_property_rain_water_goods_not_inspected': {
              'ni_field': 'ni',
            },
          },
        ),
        const ExportConfig(includePhrases: false),
      );

      final merged = doc.sections.single.screens.single;
      expect(merged.isMergedGroup, isTrue);
      expect(
        merged.fields.map((f) => f.label).toList(),
        equals([
          'Weather Field',
          'About Field',
          'Repair Field',
          'NI Field',
          'Main Field',
        ]),
      );
    });

    test(
        'orders merged descendant screens by node order (not JSON insertion order)',
        () {
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'E',
            title: 'Outside Property',
            description: '',
            nodes: [
              const InspectionNodeDefinition(
                id: 'group_e1_test_1',
                title: 'Test Group',
                type: InspectionNodeType.group,
                parentId: null,
                fields: [],
              ),
              // Intentionally placed first in JSON, but higher order.
              const InspectionNodeDefinition(
                id: 'screen_high',
                title: 'High',
                type: InspectionNodeType.screen,
                parentId: 'group_e1_test_1',
                order: 10,
                fields: [
                  InspectionFieldDefinition(
                    id: 'high_field',
                    label: 'High Field',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
              // Intentionally placed later in JSON, but lower order.
              const InspectionNodeDefinition(
                id: 'screen_low',
                title: 'Low',
                type: InspectionNodeType.screen,
                parentId: 'group_e1_test_1',
                order: 1,
                fields: [
                  InspectionFieldDefinition(
                    id: 'low_field',
                    label: 'Low Field',
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
            'screen_high': {'high_field': 'high'},
            'screen_low': {'low_field': 'low'},
          },
        ),
        const ExportConfig(includePhrases: false),
      );

      final merged = doc.sections.single.screens.single;
      expect(merged.isMergedGroup, isTrue);
      expect(
        merged.fields.map((f) => f.label).toList(),
        equals(['Low Field', 'High Field']),
      );
    });

    test('does not add merged descendant subheadings in Section E', () {
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'E',
            title: 'Outside Property',
            description: '',
            nodes: const [
              InspectionNodeDefinition(
                id: 'group_e2_roof_covering_9',
                title: 'Roof Covering',
                type: InspectionNodeType.group,
                parentId: null,
                fields: [],
              ),
              InspectionNodeDefinition(
                id: 'outside_property_roof_covering_weather_layout',
                title: 'Weather',
                type: InspectionNodeType.screen,
                parentId: 'group_e2_roof_covering_9',
                fields: [
                  InspectionFieldDefinition(
                    id: 'weather_field',
                    label: 'Weather Field',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
              InspectionNodeDefinition(
                id: 'activity_outside_property_roof_covering_main',
                title: 'Roof Covering',
                type: InspectionNodeType.screen,
                parentId: 'group_e2_roof_covering_9',
                fields: [
                  InspectionFieldDefinition(
                    id: 'main_field',
                    label: 'Main Field',
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
            'outside_property_roof_covering_weather_layout': {
              'weather_field': 'Dry',
            },
            'activity_outside_property_roof_covering_main': {
              'main_field': 'Pitched',
            },
          },
        ),
        const ExportConfig(),
      );

      final merged = doc.sections.single.screens.single;
      expect(merged.isMergedGroup, isTrue);
      expect(
        merged.phrases.where((p) => p.startsWith('[[SUBHEADING]] ')),
        isEmpty,
      );
    });

    test('does not add merged descendant subheadings in Section F', () {
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'F',
            title: 'Inside Property',
            description: '',
            nodes: const [
              InspectionNodeDefinition(
                id: 'group_f5_fireplaces_1',
                title: 'Fireplaces and Chimneys',
                type: InspectionNodeType.group,
                parentId: null,
                fields: [],
              ),
              InspectionNodeDefinition(
                id: 'activity_in_side_property_fire_places',
                title: 'An open fire',
                type: InspectionNodeType.screen,
                parentId: 'group_f5_fireplaces_1',
                fields: [
                  InspectionFieldDefinition(
                    id: 'open_fire_field',
                    label: 'Open Fire Field',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
              InspectionNodeDefinition(
                id: 'activity_in_side_property_fire_places_repair_blocked_fireplace',
                title: 'Blocked Fireplace',
                type: InspectionNodeType.screen,
                parentId: 'group_f5_fireplaces_1',
                fields: [
                  InspectionFieldDefinition(
                    id: 'blocked_field',
                    label: 'Blocked Field',
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
            'activity_in_side_property_fire_places': {
              'open_fire_field': 'Open fire',
            },
            'activity_in_side_property_fire_places_repair_blocked_fireplace': {
              'blocked_field': 'Blocked fireplace',
            },
          },
        ),
        const ExportConfig(),
      );

      final merged = doc.sections.single.screens.single;
      expect(merged.isMergedGroup, isTrue);
      expect(
        merged.phrases.where((p) => p.startsWith('[[SUBHEADING]] ')),
        isEmpty,
      );
    });

    test('cleans merged phrases and removes placeholders', () {
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'E',
            title: 'Outside Property',
            description: '',
            nodes: const [
              InspectionNodeDefinition(
                id: 'group_e1_test_cleanup',
                title: 'Cleanup Group',
                type: InspectionNodeType.group,
                parentId: null,
                fields: [],
              ),
              InspectionNodeDefinition(
                id: 'screen_cleanup_a',
                title: 'Alpha',
                type: InspectionNodeType.screen,
                parentId: 'group_e1_test_cleanup',
                fields: [],
              ),
              InspectionNodeDefinition(
                id: 'screen_cleanup_b',
                title: 'Beta',
                type: InspectionNodeType.screen,
                parentId: 'group_e1_test_cleanup',
                fields: [],
              ),
            ],
          ),
        ],
      );

      final rawData = _makeRawData(tree: tree);
      final withPersisted = V2RawReportData(
        survey: rawData.survey,
        tree: rawData.tree,
        allAnswers: rawData.allAnswers,
        screenStates: rawData.screenStates,
        photoFilePaths: rawData.photoFilePaths,
        signatureRows: rawData.signatureRows,
        persistedPhrases: {
          'screen_cleanup_a': [
            'Not inspected phrase.',
            'The issue is other and other defects.',
          ],
          'screen_cleanup_b': [
            'The issue is other and other defects.',
            'Condition rating is 2..',
          ],
        },
        persistedPhraseManualFlags: const {
          'screen_cleanup_a': true,
          'screen_cleanup_b': true,
        },
      );

      final doc = builder.build(withPersisted, const ExportConfig());
      final merged = doc.sections.single.screens.single;
      final issuePhrases = merged.phrases
          .where((p) => p == 'The issue is other defects.')
          .toList();

      expect(merged.isMergedGroup, isTrue);
      expect(merged.phrases, isNot(contains('Not inspected phrase.')));
      expect(merged.phrases, contains('The issue is other defects.'));
      expect(issuePhrases, hasLength(1));
      expect(merged.phrases, contains('Condition rating is 2.'));
    });

    test('keeps listed building separate from construction using alias answers',
        () {
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'D',
            title: 'About Property',
            description: '',
            nodes: [
              const InspectionNodeDefinition(
                id: 'group_construction_2',
                title: 'Construction',
                type: InspectionNodeType.group,
                parentId: null,
                fields: [],
              ),
              const InspectionNodeDefinition(
                id: 'activity_construction_roof',
                title: 'Roof',
                type: InspectionNodeType.screen,
                parentId: 'group_construction_2',
                fields: [
                  InspectionFieldDefinition(
                    id: 'roof_status',
                    label: 'Status',
                    type: InspectionFieldType.dropdown,
                    options: ['Good', 'Poor'],
                  ),
                ],
              ),
              const InspectionNodeDefinition(
                id: 'activity_listed_building',
                title: 'Listed Building',
                type: InspectionNodeType.screen,
                parentId: 'group_construction_2',
                fields: [
                  InspectionFieldDefinition(
                    id: 'android_material_design_spinner',
                    label: 'Status',
                    type: InspectionFieldType.dropdown,
                    options: ['Yes', 'No'],
                  ),
                ],
              ),
              const InspectionNodeDefinition(
                id: 'activity_listed_building__listed_building',
                title: 'Listed Building',
                type: InspectionNodeType.screen,
                parentId: null,
                fields: [
                  InspectionFieldDefinition(
                    id: 'android_material_design_spinner',
                    label: 'Status',
                    type: InspectionFieldType.dropdown,
                    options: ['Yes', 'No'],
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
            'activity_construction_roof': {'roof_status': 'Good'},
            // Only grouped ID has data; report should still render standalone
            // listed-building screen via alias fallback.
            'activity_listed_building': {
              'android_material_design_spinner': 'Yes'
            },
          },
        ),
        const ExportConfig(includePhrases: false),
      );

      final section = doc.sections.single;
      expect(
          section.screens.map((s) => s.title).toList(),
          equals([
            'Construction',
            'Listed Building',
          ]));
      expect(section.screens.first.fields.any((f) => f.displayValue == 'Yes'),
          isFalse);
      expect(section.screens.last.fields.any((f) => f.displayValue == 'Yes'),
          isTrue);
    });

    test('merges Section D energy screens into one Energy heading', () {
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'D',
            title: 'About Property',
            description: '',
            nodes: [
              const InspectionNodeDefinition(
                id: 'activity_energy_effiency',
                title: 'Energy',
                type: InspectionNodeType.screen,
                parentId: null,
                fields: [
                  InspectionFieldDefinition(
                    id: 'android_material_design_spinner',
                    label: 'Current',
                    type: InspectionFieldType.text,
                  ),
                  InspectionFieldDefinition(
                    id: 'android_material_design_spinner2',
                    label: 'Potential',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
              const InspectionNodeDefinition(
                id: 'activity_energy_environment_impect',
                title: 'Environmental Impact',
                type: InspectionNodeType.screen,
                parentId: null,
                fields: [
                  InspectionFieldDefinition(
                    id: 'android_material_design_spinner',
                    label: 'Current',
                    type: InspectionFieldType.text,
                  ),
                  InspectionFieldDefinition(
                    id: 'android_material_design_spinner2',
                    label: 'Potential',
                    type: InspectionFieldType.text,
                  ),
                ],
              ),
              const InspectionNodeDefinition(
                id: 'activity_other_service',
                title: 'Other Service',
                type: InspectionNodeType.screen,
                parentId: null,
                fields: [
                  InspectionFieldDefinition(
                    id: 'ch1',
                    label: 'Solar Electricity',
                    type: InspectionFieldType.checkbox,
                  ),
                  InspectionFieldDefinition(
                    id: 'ch2',
                    label: 'Solar Hot Water',
                    type: InspectionFieldType.checkbox,
                  ),
                ],
              ),
              const InspectionNodeDefinition(
                id: 'activity_after_energy',
                title: 'After Energy',
                type: InspectionNodeType.screen,
                parentId: null,
                fields: [
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
          tree: tree,
          allAnswers: {
            'activity_energy_effiency': {
              'android_material_design_spinner': '61',
              'android_material_design_spinner2': '78',
            },
            'activity_energy_environment_impect': {
              'android_material_design_spinner': '58',
              'android_material_design_spinner2': '76',
            },
            'activity_other_service': {
              'ch1': 'true',
            },
            'activity_after_energy': {'f': 'ok'},
          },
        ),
        const ExportConfig(),
      );

      final screens = doc.sections.single.screens;
      expect(screens.map((s) => s.title).toList(),
          equals(['Energy', 'After Energy']));
      expect(screens.first.isMergedGroup, isTrue);
      expect(
        screens.first.phrases
            .any((p) => p.toLowerCase().contains('current 61')),
        isTrue,
      );
      expect(
        screens.first.phrases
            .any((p) => p.toLowerCase().contains('potential 76')),
        isTrue,
      );
      expect(
        screens.first.phrases.any(
          (p) =>
              p.toLowerCase().contains('solar') ||
              p.toLowerCase().contains('photovoltaic'),
        ),
        isTrue,
      );
    });

    test('merges Section E chimney group into Chimney Stacks heading', () {
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'E',
            title: 'Outside Property',
            description: '',
            nodes: const [
              InspectionNodeDefinition(
                id: 'group_e1_chimney_5',
                title: 'Chimney',
                type: InspectionNodeType.group,
                parentId: null,
                fields: [],
              ),
              InspectionNodeDefinition(
                id: 'group_chimney_6',
                title: 'Chimney',
                type: InspectionNodeType.group,
                parentId: 'group_e1_chimney_5',
                fields: [],
              ),
              InspectionNodeDefinition(
                id: 'activity_outside_property_stacks',
                title: 'Stacks',
                type: InspectionNodeType.screen,
                parentId: 'group_chimney_6',
                fields: [
                  InspectionFieldDefinition(
                    id: 'android_material_design_spinner3',
                    label: 'Stacks',
                    type: InspectionFieldType.dropdown,
                    options: ['Single', 'Multiple'],
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
            'activity_outside_property_stacks': {
              'android_material_design_spinner3': 'Single',
            },
          },
        ),
        const ExportConfig(includePhrases: false),
      );

      final screens = doc.sections.single.screens;
      expect(screens, hasLength(1));
      expect(screens.first.title, 'Chimney Stacks');
      expect(screens.first.isMergedGroup, isTrue);
    });

    test(
        'maps standalone chimney stacks screen title to Chimney Stacks in Section E',
        () {
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'E',
            title: 'Outside Property',
            description: '',
            nodes: const [
              InspectionNodeDefinition(
                id: 'activity_outside_property_stacks',
                title: 'Stacks',
                type: InspectionNodeType.screen,
                parentId: null,
                fields: [
                  InspectionFieldDefinition(
                    id: 'android_material_design_spinner3',
                    label: 'Stacks',
                    type: InspectionFieldType.dropdown,
                    options: ['Single', 'Multiple'],
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
            'activity_outside_property_stacks': {
              'android_material_design_spinner3': 'Single',
            },
          },
        ),
        const ExportConfig(includePhrases: false),
      );

      final screen = doc.sections.single.screens.single;
      expect(screen.title, 'Chimney Stacks');
      expect(screen.isMergedGroup, isFalse);
    });

    test('regenerates chimney phrases when persisted phrase list is empty', () {
      final phraseEngine = InspectionPhraseEngine({
        '{E_CHIMNEY_SINGLE_STACK}::{STACK}': 'Single-stack narrative.',
        '{E_CHIMNEY_SINGLE_STACK}::{STACK_POTS}': 'Pots {CS_POTS}.',
        '{E_CHIMNEY_SINGLE_STACK}::{STACK_RENDERING}':
            'Rendered {CS_RENDERING}.',
      });
      final customBuilder = ReportBuilder(inspectionPhraseEngine: phraseEngine);
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'E',
            title: 'Outside Property',
            description: '',
            nodes: const [
              InspectionNodeDefinition(
                id: 'activity_outside_property_stacks',
                title: 'Stacks',
                type: InspectionNodeType.screen,
                parentId: null,
                fields: [
                  InspectionFieldDefinition(
                    id: 'android_material_design_spinner3',
                    label: 'Stacks',
                    type: InspectionFieldType.dropdown,
                    options: ['Single', 'Multiple'],
                  ),
                  InspectionFieldDefinition(
                    id: 'android_material_design_spinner2',
                    label: 'Pots',
                    type: InspectionFieldType.dropdown,
                    options: ['1', '2', '3'],
                  ),
                  InspectionFieldDefinition(
                    id: 'android_material_design_spinner4',
                    label: 'Rendered Stack(s)',
                    type: InspectionFieldType.dropdown,
                    options: ['Single', 'Multiple'],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final rawData = _makeRawData(
        tree: tree,
        allAnswers: {
          'activity_outside_property_stacks': {
            'android_material_design_spinner3': 'Single',
            'android_material_design_spinner2': '2',
            'android_material_design_spinner4': 'Single',
          },
        },
      );
      final dataWithEmptyPersistedPhrases = V2RawReportData(
        survey: rawData.survey,
        tree: rawData.tree,
        allAnswers: rawData.allAnswers,
        screenStates: rawData.screenStates,
        photoFilePaths: rawData.photoFilePaths,
        signatureRows: rawData.signatureRows,
        persistedPhrases: {
          'activity_outside_property_stacks': ['...', ''],
        },
      );

      final doc = customBuilder.build(
          dataWithEmptyPersistedPhrases, const ExportConfig());
      final screen = doc.sections.single.screens.single;
      expect(screen.phrases, isNotEmpty);
      expect(screen.phrases.join(' '), contains('Single-stack narrative.'));
      expect(screen.phrases.join(' '), isNot(contains('Stacks:')));
    });

    test(
        'regenerates fireplaces other condition from answers when persisted phrase is stale',
        () {
      final phraseEngine = InspectionPhraseEngine({
        '{F_FIREPLACES_AND_CHIMNEYS}::{OTHER_CONDITION}':
            'These appear in {FAC_FP_OTH_CONDITION} condition. No repair is currently needed. The property must be maintained in the normal way.',
      });
      final customBuilder = ReportBuilder(inspectionPhraseEngine: phraseEngine);
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'F',
            title: 'Inside Property',
            description: '',
            nodes: const [
              InspectionNodeDefinition(
                id: 'activity_in_side_property_fire_places__other',
                title: 'Other',
                type: InspectionNodeType.screen,
                parentId: null,
                fields: [
                  InspectionFieldDefinition(
                    id: 'actv_condition',
                    label: 'Condition',
                    type: InspectionFieldType.dropdown,
                    options: ['Reasonable', 'Satisfactory'],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final rawData = _makeRawData(
        tree: tree,
        allAnswers: {
          'activity_in_side_property_fire_places__other': {
            'actv_condition': 'Reasonable',
          },
        },
      );
      final stalePersisted = V2RawReportData(
        survey: rawData.survey,
        tree: rawData.tree,
        allAnswers: rawData.allAnswers,
        screenStates: rawData.screenStates,
        photoFilePaths: rawData.photoFilePaths,
        signatureRows: rawData.signatureRows,
        persistedPhrases: {
          'activity_in_side_property_fire_places__other': [
            'The fireplace in the lounge incorporates a .',
          ],
        },
        persistedPhraseManualFlags: const {
          'activity_in_side_property_fire_places__other': false,
        },
      );

      final doc = customBuilder.build(stalePersisted, const ExportConfig());
      final screen = doc.sections.single.screens.single;
      expect(
        screen.phrases.join(' '),
        contains('These appear in reasonable condition.'),
      );
      expect(
        screen.phrases.join(' '),
        isNot(contains('incorporates a .')),
      );
    });

    test(
        'keeps persisted fireplace condition when forced regeneration misses it',
        () {
      final phraseEngine = InspectionPhraseEngine(const {
        // Simulate the live failure mode where regeneration drops the condition.
      });
      final customBuilder = ReportBuilder(inspectionPhraseEngine: phraseEngine);
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'F',
            title: 'Inside Property',
            description: '',
            nodes: const [
              InspectionNodeDefinition(
                id: 'activity_in_side_property_fire_places__other',
                title: 'Other',
                type: InspectionNodeType.screen,
                parentId: null,
                fields: [
                  InspectionFieldDefinition(
                    id: 'actv_condition',
                    label: 'Condition',
                    type: InspectionFieldType.dropdown,
                    options: ['Reasonable', 'Satisfactory'],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final rawData = _makeRawData(
        tree: tree,
        allAnswers: {
          'activity_in_side_property_fire_places__other': {
            'actv_condition': 'Reasonable',
          },
        },
      );
      final stalePersisted = V2RawReportData(
        survey: rawData.survey,
        tree: rawData.tree,
        allAnswers: rawData.allAnswers,
        screenStates: rawData.screenStates,
        photoFilePaths: rawData.photoFilePaths,
        signatureRows: rawData.signatureRows,
        persistedPhrases: {
          'activity_in_side_property_fire_places__other': [
            'The fireplace in the lounge incorporates a .',
            'These appear in reasonable condition. No repair is currently needed. The property must be maintained in the normal way.',
          ],
        },
        persistedPhraseManualFlags: const {
          'activity_in_side_property_fire_places__other': false,
        },
      );

      final doc = customBuilder.build(stalePersisted, const ExportConfig());
      final screen = doc.sections.single.screens.single;
      expect(
        screen.phrases.join(' '),
        contains('These appear in reasonable condition.'),
      );
      expect(
        screen.phrases.join(' '),
        isNot(contains('incorporates a .')),
      );
    });

    test('preserves manually edited persisted phrases in reports', () {
      final phraseEngine = InspectionPhraseEngine(const {
        '{F_FIREPLACES_AND_CHIMNEYS}::{OTHER_CONDITION}':
            'These appear in {FAC_FP_OTH_CONDITION} condition. No repair is currently needed. The property must be maintained in the normal way.',
      });
      final customBuilder = ReportBuilder(inspectionPhraseEngine: phraseEngine);
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'F',
            title: 'Inside Property',
            description: '',
            nodes: const [
              InspectionNodeDefinition(
                id: 'activity_in_side_property_fire_places__other',
                title: 'Other',
                type: InspectionNodeType.screen,
                parentId: null,
                fields: [
                  InspectionFieldDefinition(
                    id: 'actv_condition',
                    label: 'Condition',
                    type: InspectionFieldType.dropdown,
                    options: ['Reasonable', 'Satisfactory'],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final rawData = _makeRawData(
        tree: tree,
        allAnswers: {
          'activity_in_side_property_fire_places__other': {
            'actv_condition': 'Reasonable',
          },
        },
      );
      final withManualPersisted = V2RawReportData(
        survey: rawData.survey,
        tree: rawData.tree,
        allAnswers: rawData.allAnswers,
        screenStates: rawData.screenStates,
        photoFilePaths: rawData.photoFilePaths,
        signatureRows: rawData.signatureRows,
        persistedPhrases: {
          'activity_in_side_property_fire_places__other': [
            'Manual override sentence.',
          ],
        },
        persistedPhraseManualFlags: const {
          'activity_in_side_property_fire_places__other': true,
        },
      );

      final doc =
          customBuilder.build(withManualPersisted, const ExportConfig());
      final screen = doc.sections.single.screens.single;
      expect(screen.phrases, contains('Manual override sentence.'));
      expect(
        screen.phrases.join(' '),
        isNot(contains('These appear in reasonable condition.')),
      );
    });

    test(
        'does not use raw field fallback for roof structure insect infestation when phrase engine emits nothing',
        () {
      final customBuilder = ReportBuilder(
        inspectionPhraseEngine: const InspectionPhraseEngine({}),
      );
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'F',
            title: 'Inside Property',
            description: '',
            nodes: const [
              InspectionNodeDefinition(
                id: 'group_roof_structure_58',
                title: 'F1 Roof Structure',
                type: InspectionNodeType.group,
                parentId: null,
                fields: [],
              ),
              InspectionNodeDefinition(
                id: 'activity_inside_property_repair_insect_infestation',
                title: 'Insect infestation',
                type: InspectionNodeType.screen,
                parentId: 'group_roof_structure_58',
                fields: [
                  InspectionFieldDefinition(
                    id: 'actv_insect_infestation',
                    label: 'Insect infestation',
                    type: InspectionFieldType.dropdown,
                    options: ['None', 'Minor', 'Severe'],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final rawData = _makeRawData(
        tree: tree,
        allAnswers: {
          'activity_inside_property_repair_insect_infestation': {
            'actv_insect_infestation': 'Partly missing',
          },
        },
      );

      final doc = customBuilder.build(rawData, const ExportConfig());
      final screen = doc.sections.single.screens.single;
      expect(
        screen.phrases.join(' '),
        isNot(contains('Insect infestation: Partly missing')),
      );
    });

    test(
        'does not use raw field fallback for movement cracks when saved value is non-legacy',
        () {
      final customBuilder = ReportBuilder(
        inspectionPhraseEngine: const InspectionPhraseEngine({}),
      );
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'F',
            title: 'Inside Property',
            description: '',
            nodes: const [
              InspectionNodeDefinition(
                id: 'group_walls_and_partitions_64',
                title: 'F3 Walls and Partitions',
                type: InspectionNodeType.group,
                parentId: null,
                fields: [],
              ),
              InspectionNodeDefinition(
                id: 'activity_in_side_property_wap_movement_cracks',
                title: 'Movement Cracks',
                type: InspectionNodeType.screen,
                parentId: 'group_walls_and_partitions_64',
                fields: [
                  InspectionFieldDefinition(
                    id: 'android_material_design_spinner3',
                    label: 'Condition',
                    type: InspectionFieldType.dropdown,
                    options: ['None', 'Normal', 'Multiple locations'],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final rawData = _makeRawData(
        tree: tree,
        allAnswers: {
          'activity_in_side_property_wap_movement_cracks': {
            'android_material_design_spinner3': 'Reasonable',
          },
        },
      );

      final doc = customBuilder.build(rawData, const ExportConfig());
      final screen = doc.sections.single.screens.single;
      expect(
        screen.phrases.join(' '),
        isNot(contains('Condition: Reasonable')),
      );
    });

    test(
        'does not use raw field fallback for floor ventilation when poor problem detail is missing',
        () {
      final customBuilder = ReportBuilder(
        inspectionPhraseEngine: const InspectionPhraseEngine({}),
      );
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'F',
            title: 'Inside Property',
            description: '',
            nodes: const [
              InspectionNodeDefinition(
                id: 'group_floors_67',
                title: 'F4 Floors',
                type: InspectionNodeType.group,
                parentId: null,
                fields: [],
              ),
              InspectionNodeDefinition(
                id: 'activity_in_side_property_floors_floor_ventilation',
                title: 'Floor ventilation',
                type: InspectionNodeType.screen,
                parentId: 'group_floors_67',
                fields: [
                  InspectionFieldDefinition(
                    id: 'actv_condition',
                    label: 'Condition',
                    type: InspectionFieldType.dropdown,
                    options: ['Ok', 'Poor'],
                  ),
                  InspectionFieldDefinition(
                    id: 'et_describe_problem',
                    label: 'Condition',
                    type: InspectionFieldType.dropdown,
                    options: [
                      'condensation',
                      'moulding',
                      'timber rot',
                      'other'
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final rawData = _makeRawData(
        tree: tree,
        allAnswers: {
          'activity_in_side_property_floors_floor_ventilation': {
            'actv_condition': 'Poor',
          },
        },
      );

      final doc = customBuilder.build(rawData, const ExportConfig());
      final screen = doc.sections.single.screens.single;
      expect(
        screen.phrases.join(' '),
        isNot(contains('Condition: Poor')),
      );
    });

    test('condenses chimney stacks phrases into one paragraph', () {
      final phraseEngine = InspectionPhraseEngine({
        '{E_CHIMNEY_SINGLE_STACK}::{STACK}':
            'The property has one chimney stack.',
        '{E_CHIMNEY_SINGLE_STACK}::{STACK_POTS}':
            'The chimney stack is fitted with 4 pot(s).',
        '{E_CHIMNEY_SINGLE_STACK}::{STACK_RENDERING}':
            'The outer faces of the chimney stack is single rendered.',
      });
      final customBuilder = ReportBuilder(inspectionPhraseEngine: phraseEngine);
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'E',
            title: 'Outside Property',
            description: '',
            nodes: const [
              InspectionNodeDefinition(
                id: 'activity_outside_property_stacks',
                title: 'Stacks',
                type: InspectionNodeType.screen,
                parentId: null,
                fields: [
                  InspectionFieldDefinition(
                    id: 'android_material_design_spinner3',
                    label: 'Stacks',
                    type: InspectionFieldType.dropdown,
                    options: ['Single', 'Multiple'],
                  ),
                  InspectionFieldDefinition(
                    id: 'android_material_design_spinner2',
                    label: 'Pots',
                    type: InspectionFieldType.dropdown,
                    options: ['1', '2', '3', '4'],
                  ),
                  InspectionFieldDefinition(
                    id: 'android_material_design_spinner4',
                    label: 'Rendered Stack(s)',
                    type: InspectionFieldType.dropdown,
                    options: ['Single', 'Multiple'],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final doc = customBuilder.build(
        _makeRawData(
          tree: tree,
          allAnswers: {
            'activity_outside_property_stacks': {
              'android_material_design_spinner3': 'Single',
              'android_material_design_spinner2': '4',
              'android_material_design_spinner4': 'Single',
            },
          },
        ),
        const ExportConfig(),
      );

      final screen = doc.sections.single.screens.single;
      expect(screen.phrases, hasLength(1));
      expect(screen.phrases.single,
          contains('The property has one chimney stack.'));
      expect(
        screen.phrases.single,
        contains('The chimney stack is fitted with 4 pot(s).'),
      );
      expect(
        screen.phrases.single,
        contains('The outer faces of the chimney stack is single rendered.'),
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
          allAnswers: {
            'screen1': {'trigger': 'No', 'detail': 'should be hidden'}
          },
        ),
        const ExportConfig(),
      );
      final fields = doc.sections.first.screens.first.fields;
      expect(fields.where((f) => f.fieldId == 'detail'), isEmpty);
    });

    test('marks isCompleted on report screens from screenStates', () {
      final doc = builder.build(
        _makeRawData(
          allAnswers: {
            'activity_roof': {'field_condition': '1'}
          },
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
        allAnswers: {
          'activity_roof': {'field_condition': '1'}
        },
        screenStates: {},
        photoFilePaths: ['/path/to/photo.jpg'],
        signatureRows: [],
      );
      final doc =
          builder.build(rawData, const ExportConfig(includePhotos: false));
      expect(doc.photoFilePaths, isEmpty);
    });

    test('excludes signatures when includeSignatures is false', () {
      final rawData = V2RawReportData(
        survey: testSurvey,
        tree: minimalTree,
        allAnswers: {
          'activity_roof': {'field_condition': '1'}
        },
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
      final doc =
          builder.build(rawData, const ExportConfig(includeSignatures: false));
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

    test(
        'injects legacy Section F building risk phrases into J1 and creates J2',
        () {
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'J',
            title: 'J Risks',
            description: '',
            nodes: [
              InspectionNodeDefinition(
                id: 'activity_risks_risk_to_building_',
                title: 'J1 Risk To Building',
                type: InspectionNodeType.screen,
                fields: const [
                  InspectionFieldDefinition(
                    id: 'actv_movement_status',
                    label: 'Movement status',
                    type: InspectionFieldType.dropdown,
                    options: ['None', 'Noted'],
                  ),
                ],
              ),
              InspectionNodeDefinition(
                id: 'activity_risks_other_',
                title: 'J4 Other',
                type: InspectionNodeType.screen,
                fields: const [
                  InspectionFieldDefinition(
                    id: 'cb_not_applicable',
                    label: 'Not Applicable',
                    type: InspectionFieldType.checkbox,
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
            'activity_risks_risk_to_building_': {
              'actv_movement_status': 'None',
            },
            'activity_in_side_property_wood_work': {
              'cb_out_of_square_doors': 'true',
              'cb_glazed_internal_doors': 'true',
            },
            'activity_in_side_property_bathroom_fittings_leaking': {
              'cb_bathtub': 'true',
            },
          },
        ),
        const ExportConfig(),
      );

      final section = doc.sections.firstWhere((s) => s.key == 'J');
      final j1 = section.screens
          .firstWhere((s) => s.screenId == 'activity_risks_risk_to_building_');
      expect(
        j1.phrases.join(' ').toLowerCase(),
        contains('some internal doors and frame are distorted'),
      );
      expect(
        j1.phrases.join(' ').toLowerCase(),
        contains('the bathtub is leaking and causing dampness'),
      );

      final j2 = section.screens
          .firstWhere((s) => s.screenId == 'derived_j2_risk_to_people');
      expect(j2.title, 'J2 Risk To People');
      expect(
        j2.phrases.join(' ').toLowerCase(),
        contains('one or more internal doors are glazed'),
      );
    });

    test('injects legacy Section F guarantee phrase into I2', () {
      final tree = InspectionTreePayload(
        sections: [
          InspectionSectionDefinition(
            key: 'I',
            title: 'I Issues',
            description: '',
            nodes: [
              InspectionNodeDefinition(
                id: 'activity_issues_glazed_sections',
                title: 'I2 Guarantees',
                type: InspectionNodeType.screen,
                fields: const [
                  InspectionFieldDefinition(
                    id: 'cb_chimney_stack',
                    label: 'windows',
                    type: InspectionFieldType.checkbox,
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
            'activity_issues_glazed_sections': {
              'cb_chimney_stack': 'true',
            },
            'activity_inside_property_other_celler_damp': {
              'cb_serious_dump': 'true',
            },
          },
        ),
        const ExportConfig(),
      );

      final screen = doc.sections.first.screens.first;
      expect(
        screen.phrases.join(' ').toLowerCase(),
        contains('dampness problem repair is covered by any guarantees'),
      );
    });
  });
}
