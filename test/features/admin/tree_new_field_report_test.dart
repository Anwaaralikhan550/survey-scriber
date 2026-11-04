// What a field or screen added in Survey Tree Management does in the report. The web
// page tells the admin the same thing, so it must stay true.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_catalog.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_engine.dart';
import 'package:survey_scriber/features/report_export/data/services/report_builder.dart';
import 'package:survey_scriber/features/report_export/data/services/report_data_service.dart';
import 'package:survey_scriber/features/report_export/domain/models/export_config.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

const _inspection = 'assets/property_inspection/inspection_tree.json';
const _valuation = 'assets/property_valuation/valuation_tree.json';

String _report(
  String treePath,
  void Function(Map<String, dynamic> tree) edit,
  Map<String, Map<String, String>> answers,
) {
  final data = jsonDecode(File(treePath).readAsStringSync()) as Map<String, dynamic>;
  edit(data);
  final tree = InspectionTreePayload.fromJson(jsonEncode(data));
  final texts = (jsonDecode(File('assets/property_inspection/phrase_texts.json').readAsStringSync())
          as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v?.toString() ?? ''));
  final catalog = ValuationPhraseCatalog.fromJson(
    jsonDecode(File('assets/property_valuation/phrase_texts.json').readAsStringSync()) as Map<String, dynamic>,
  );
  final doc = ReportBuilder(
    inspectionPhraseEngine: InspectionPhraseEngine(texts),
    valuationPhraseEngine: ValuationPhraseEngine.catalog(catalog),
  ).build(
    V2RawReportData(
      survey: Survey(
        id: 's',
        title: 'T',
        type: treePath == _valuation ? SurveyType.valuation : SurveyType.inspection,
        status: SurveyStatus.completed,
        createdAt: DateTime(2026, 11, 4),
      ),
      tree: tree,
      allAnswers: answers,
      screenStates: {for (final id in answers.keys) id: true},
      photoFilePaths: const [],
      signatureRows: const [],
    ),
    const ExportConfig(),
  );
  return [
    for (final s in doc.sections)
      for (final screen in s.screens) ...[
        screen.title,
        // The PDF and Word reports list the fields only when a screen has no sentences.
        if (screen.phrases.isNotEmpty) ...screen.phrases else ...[
          for (final f in screen.fields) '${f.label}: ${f.displayValue}',
        ],
      ],
  ].join('\n');
}

Map<String, dynamic> _node(Map<String, dynamic> tree, String id) => (tree['sections'] as List)
    .expand((s) => s['nodes'] as List)
    .cast<Map<String, dynamic>>()
    .firstWhere((n) => n['id'] == id);

void _addField(Map<String, dynamic> tree, String screenId, Map<String, dynamic> field) =>
    (_node(tree, screenId)['fields'] as List).add(field);

void _addScreen(Map<String, dynamic> tree, String sectionKey, Map<String, dynamic> node) {
  final section = (tree['sections'] as List).cast<Map<String, dynamic>>().firstWhere((s) => s['key'] == sectionKey);
  (section['nodes'] as List).add(node);
}

void main() {
  const flat = {
    'cb_a2_flat': 'true',
    'actv_a2_floor': 'Second floor',
    'actv_a2_storeys': 'Four',
    'actv_a2_access': 'Communal door',
    'actv_a2_elevation': 'Rear',
  };

  group('Home survey', () {
    test('a new field with a phrase template prints on a screen that has written sentences', () {
      final text = _report(_inspection, (t) {
        _addField(t, 'activity_property_flate', {
          'id': 'edittext_lift',
          'label': 'Lift',
          'type': 'text',
          'phraseTemplate': 'The lift is {edittext_lift}.',
        });
      }, {
        'activity_property_flate': {...flat, 'edittext_lift': 'working'},
      });
      expect(text, contains('The lift is working.'));
      expect(text, contains('The property is located on the'));
    });

    test('a new field with no phrase template adds nothing to that screen', () {
      final without = _report(_inspection, (t) {}, {'activity_property_flate': flat});
      final withField = _report(_inspection, (t) {
        _addField(t, 'activity_property_flate', {'id': 'edittext_lift', 'label': 'Lift', 'type': 'text'});
      }, {
        'activity_property_flate': {...flat, 'edittext_lift': 'working'},
      });
      expect(withField, without);
    });

    test('a new screen with a template prints; its dropdown prints the new words', () {
      final text = _report(_inspection, (t) {
        _addScreen(t, 'D', {
          'id': 'activity_lift_check',
          'title': 'Lift Check',
          'type': 'screen',
          'parentId': null,
          'fields': [
            {
              'id': 'android_material_design_spinner_state',
              'label': 'State',
              'type': 'dropdown',
              'options': ['Working', 'Broken'],
              'optionLabels': {'Broken': 'Out of order'},
              'phraseTemplate': 'The lift is {android_material_design_spinner_state}.',
            },
          ],
        });
      }, {
        'activity_lift_check': {'android_material_design_spinner_state': 'Broken'},
      });
      expect(text, contains('The lift is Out of order.'));
      expect(text, isNot(contains('The lift is Broken.')));
    });

    test('a renamed screen shows its new title in the report', () {
      final text = _report(_inspection, (t) {
        _node(t, 'activity_property_flate')['title'] = 'Apartment Details';
      }, {'activity_property_flate': flat});
      expect(text, contains('Apartment Details'));
      expect(text, isNot(contains('Flat Maisonettes')));
    });

    test('a new screen with no template shows what was answered', () {
      final text = _report(_inspection, (t) {
        _addScreen(t, 'D', {
          'id': 'activity_lift_check',
          'title': 'Lift Check',
          'type': 'screen',
          'parentId': null,
          'fields': [
            {'id': 'edittext_state', 'label': 'State', 'type': 'text'},
          ],
        });
      }, {
        'activity_lift_check': {'edittext_state': 'Working'},
      });
      expect(text, contains('Lift Check'));
      expect(text, contains('State: Working'));
    });
  });

  group('Valuation', () {
    test('a phrase template does not print; the answer shows when the screen has no sentences', () {
      final raw = jsonDecode(File(_valuation).readAsStringSync()) as Map<String, dynamic>;
      final screen = (raw['sections'] as List)
          .expand((s) => s['nodes'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((n) => n['type'] == 'screen' && (n['fields'] as List?)?.isNotEmpty == true);
      final id = screen['id'] as String;
      final text = _report(_valuation, (t) {
        _addField(t, id, {
          'id': 'edittext_lift',
          'label': 'Lift',
          'type': 'text',
          'phraseTemplate': 'The lift is {edittext_lift}.',
        });
        _addScreen(t, (t['sections'] as List).first['key'] as String, {
          'id': 'activity_lift_check',
          'title': 'Lift Check',
          'type': 'screen',
          'parentId': null,
          'fields': [
            {'id': 'edittext_state', 'label': 'State', 'type': 'text', 'phraseTemplate': 'State is {edittext_state}.'},
          ],
        });
      }, {
        id: {'edittext_lift': 'working'},
        'activity_lift_check': {'edittext_state': 'Working'},
      });
      // Valuation reports do not print phrase templates, only "label: answer".
      expect(text, isNot(contains('The lift is')));
      expect(text, isNot(contains('State is')));
      expect(text, contains('Lift: working'));
      expect(text, contains('State: Working'));
    });
  });
}
