import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/report_export/data/services/report_builder.dart';
import 'package:survey_scriber/features/report_export/data/services/report_data_service.dart';
import 'package:survey_scriber/features/report_export/domain/models/export_config.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

/// T6 (part 1): builds a full report through the real engine -> ReportBuilder path with synthetic answers
/// (every tick-box ticked, first positive option of every dropdown) and dumps every emitted phrase, per
/// section/screen, to tool/phrase_audit/output/t6_report_phrases.json.
/// tool/phrase_audit/verbatim/t6check.py then compares every dumped sentence with the PDF.
void main() {
  final repeatSlot = RegExp(r'__\d+$');

  String? pickDropdown(InspectionFieldDefinition f) {
    final options = f.options ?? const <String>[];
    if (options.isEmpty) return null;
    final negative = RegExp(r'not inspected|none|no |^no$|not applicable|not present', caseSensitive: false);
    for (final o in options) {
      if (!negative.hasMatch(o)) return o;
    }
    return options.first;
  }

  Map<String, String> answersFor(InspectionNodeDefinition screen) {
    final answers = <String, String>{};
    for (final f in screen.fields) {
      switch (f.type) {
        case InspectionFieldType.checkbox:
          final label = f.label.trim().toLowerCase();
          if (label == 'other' || label == 'others') continue;
          answers[f.id] = 'true';
        case InspectionFieldType.dropdown:
          final v = pickDropdown(f);
          if (v != null) answers[f.id] = v;
        case InspectionFieldType.text:
          final label = f.label.toLowerCase();
          if (label.contains('other')) break;
          answers[f.id] = 'sample detail';
        case InspectionFieldType.number:
          answers[f.id] = '2';
        case InspectionFieldType.label:
          break;
      }
    }
    return answers;
  }

  test('T6 dump: full report phrases through the real pipeline', () {
    final tree = InspectionTreePayload.fromJson(
        File('assets/property_inspection/inspection_tree.json').readAsStringSync());
    final allAnswers = <String, Map<String, String>>{};
    final screenStates = <String, bool>{};
    for (final section in tree.sections) {
      for (final node in section.nodes) {
        if (node.type != InspectionNodeType.screen) continue;
        if (repeatSlot.hasMatch(node.id)) continue;
        final a = answersFor(node);
        if (a.isEmpty) continue;
        allAnswers[node.id] = a;
        screenStates[node.id] = true;
      }
    }
    final survey = Survey(
      id: 't6',
      title: '12 Example Avenue, Anytown, AN1 2YT',
      type: SurveyType.inspection,
      status: SurveyStatus.completed,
      createdAt: DateTime(2026, 7, 1),
      address: '12 Example Avenue, Anytown, AN1 2YT',
      clientName: 'Mr & Mrs Sample Client',
    );
    final raw = V2RawReportData(
      survey: survey,
      tree: tree,
      allAnswers: allAnswers,
      screenStates: screenStates,
      photoFilePaths: const [],
      signatureRows: const [],
    );
    final phraseTexts = (jsonDecode(File('assets/property_inspection/phrase_texts.json').readAsStringSync())
            as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v?.toString() ?? ''));
    final engine = InspectionPhraseEngine(phraseTexts);
    final doc = ReportBuilder(
      inspectionPhraseEngine: engine,
      valuationPhraseEngine: null,
    ).build(raw, const ExportConfig());

    // Per-screen engine output (lets t6check.py separate rule-driven screens from legacy handlers).
    final perScreen = <Map<String, Object?>>[];
    for (final section in tree.sections) {
      for (final node in section.nodes) {
        final a = allAnswers[node.id];
        if (a == null) continue;
        final phrases = engine.buildPhrases(node.id, a);
        if (phrases.isEmpty) continue;
        perScreen.add({'section': section.key, 'screen': node.id, 'phrases': phrases});
      }
    }

    final out = <Map<String, Object?>>[];
    for (final section in doc.sections) {
      for (final scr in section.screens) {
        if (scr.phrases.isEmpty) continue;
        out.add({'section': section.key, 'screen': scr.screenId, 'phrases': scr.phrases});
      }
    }
    final f = File('tool/phrase_audit/output/t6_report_phrases.json');
    f.writeAsStringSync(const JsonEncoder.withIndent(' ').convert({'report': out, 'screens': perScreen}));
    expect(out, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
