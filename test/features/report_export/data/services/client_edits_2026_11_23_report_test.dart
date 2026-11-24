// Client edit list, 23 Nov 2026, item 6: the order of the E8 Other Joinery and Finishes paragraphs.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/report_export/data/services/client_paragraph_rules.dart';
import 'package:survey_scriber/features/report_export/data/services/report_builder.dart';
import 'package:survey_scriber/features/report_export/data/services/report_data_service.dart';
import 'package:survey_scriber/features/report_export/domain/models/export_config.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

void main() {
  const e8Group = 'group_e8_other_joinery_and_finishes_31';
  const main = 'activity_outside_property_other_joinery_and_finishes_main_screen';
  const repairs = 'activity_outside_property_other_joinery_and_finishes_repairs';
  const notInspected = 'activity_outside_property_other_joinery_finishes_not_inspected';
  const weathering = 'activity_outside_property_other_joinery_and_finishes_timber_weathering';
  const decay = 'activity_outside_property_other_joinery_and_finishes_timber_decay';
  const defective = 'activity_outside_property_other_joinery_and_finishes_defective_joinery';

  final tree = InspectionTreePayload.fromJson(File('assets/property_inspection/inspection_tree.json').readAsStringSync());
  final bank = (jsonDecode(File('assets/property_inspection/phrase_texts.json').readAsStringSync()) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v?.toString() ?? ''));
  final builder = ReportBuilder(inspectionPhraseEngine: InspectionPhraseEngine(bank), valuationPhraseEngine: null);

  // Every item of the E8 element, answered the way a surveyor would tick them.
  const answers = <String, Map<String, String>>{
    main: {
      'e8m_timber': 'true',
      'actv_condition': '2',
      'actv_decorations': 'Good',
      'actv_joinery_condition': 'Fair',
      'cb_open_runoffs': 'true',
      'cb_general_maintenance': 'true',
      'cb_property_is_flat': 'true',
    },
    notInspected: {'cb_not_inspected': 'true'},
    weathering: {'actv_weathering': 'Minor'},
    decay: {'e8td_localised_wet_rot': 'true'},
    defective: {'e8dj_loose_fascias': 'true', 'e8dj_open_joints': 'true'},
    repairs: {
      'e8i_fascias': 'true',
      'e8l_back_addition': 'true',
      'e8d_rotted': 'true',
      'cb_safety_hazard': 'true',
    },
  };

  List<String> e8Paragraphs(Map<String, Map<String, String>> given) {
    final raw = V2RawReportData(
      survey: Survey(
        id: 'e8',
        title: '1 Test Road',
        type: SurveyType.inspection,
        status: SurveyStatus.completed,
        createdAt: DateTime(2026, 11, 24),
        address: '1 Test Road',
      ),
      tree: tree,
      allAnswers: given,
      screenStates: {for (final k in given.keys) k: true},
      photoFilePaths: const [],
      signatureRows: const [],
    );
    final doc = builder.build(raw, const ExportConfig());
    final screen = [for (final s in doc.sections) ...s.screens].firstWhere((s) => s.screenId == e8Group);
    return screen.phrases;
  }

  int at(List<String> p, String start) => p.indexWhere((x) => x.trimLeft().startsWith(start));

  group('6 E8 Other Joinery and Finishes: paragraph order', () {
    test('the client order, from Inspected down to Repair', () {
      final p = e8Paragraphs(answers);
      final order = [
        'Inspected: ',
        'Not Inspected: ',
        'Description: ',
        'Decorations: ',
        'Condition: ',
        'Timber Weathering: ',
        'Timber Decay: ',
        'Defective Joinery',
        'Asbestos Cement Components: ',
        'General Maintenance: ',
        'Repair: ',
        'Hazards: ',
      ];
      final positions = [for (final o in order) at(p, o)];
      expect(positions, everyElement(greaterThanOrEqualTo(0)), reason: p.map((x) => x.split(':').first).toString());
      expect(positions, [...positions]..sort(), reason: p.map((x) => x.split(':').first).toString());
    });
    test('Inspected and Not Inspected are the first two paragraphs after the condition rating', () {
      final p = e8Paragraphs(answers);
      final ratingFirst = p.first.startsWith('Condition rating is:');
      final lead = ratingFirst ? p.skip(1).take(2).toList() : p.take(2).toList();
      expect(lead[0], startsWith('Inspected: '));
      expect(lead[1], startsWith('Not Inspected: '));
    });
    test('the three timber items come after Condition and before Asbestos Cement Components', () {
      final p = e8Paragraphs(answers);
      final condition = at(p, 'Condition: ');
      final asbestos = at(p, 'Asbestos Cement Components: ');
      for (final label in ['Timber Weathering: ', 'Timber Decay: ', 'Defective Joinery']) {
        expect(at(p, label), allOf(greaterThan(condition), lessThan(asbestos)), reason: label);
      }
    });
    test('Repair is the last paragraph but its Hazards line, and nothing is lost or repeated', () {
      final p = e8Paragraphs(answers);
      expect(p.last, startsWith('Hazards: '));
      expect(p[p.length - 2], startsWith('Repair: '));
      expect(p.where((x) => x.startsWith('Repair: ')), hasLength(1));
      expect(p.toSet().length, p.length);
    });
    test('the paragraphs themselves are unchanged, only their order moved', () {
      final p = e8Paragraphs(answers);
      expect(p.firstWhere((x) => x.startsWith('Timber Weathering: ')), startsWith('Timber Weathering: Exposed timber joinery exhibits minor weathering.'));
      expect(p.firstWhere((x) => x.startsWith('Repair: ')), contains('Repairs should be carried out as soon as practicable'));
    });
    test('with only some items answered the same order holds', () {
      final p = e8Paragraphs({
        main: {'e8m_timber': 'true', 'actv_joinery_condition': 'Good'},
        repairs: answers[repairs]!,
        weathering: answers[weathering]!,
      });
      expect(at(p, 'Description: '), lessThan(at(p, 'Timber Weathering: ')));
      expect(at(p, 'Timber Weathering: '), lessThan(at(p, 'Repair: ')));
    });
    test('applyClientParagraphRules puts a leasehold paragraph after General Maintenance and before Repair', () {
      final out = applyClientParagraphRules(e8Group, [
        'Repair: The soffits are rotted. Repairs should be carried out.',
        'As this is a leasehold property, your legal adviser should confirm.',
        'General Maintenance: External joinery should be inspected periodically.',
        'Description: The external eaves-level joinery comprises timber materials.',
        'Inspected: Inspection was carried out from ground level.',
      ]);
      expect([for (final x in out) x.split(':').first], [
        'Inspected',
        'Description',
        'General Maintenance',
        'As this is a leasehold property, your legal adviser should confirm.',
        'Repair',
      ]);
    });
  });
}
