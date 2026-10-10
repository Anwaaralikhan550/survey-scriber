// Temporary: five coverage reports through the REAL pipeline
// (InspectionPhraseEngine -> ReportBuilder -> PdfGeneratorService).
// Scenario s ticks every checkbox except one in five, picks dropdown option (s mod n), honours conditionalOn,
// fills text fields with sample text. Writes report text, PDF, a per-sentence JSON (for t6check.py) and a coverage file.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/report_export/data/services/pdf_generator_service.dart';
import 'package:survey_scriber/features/report_export/data/services/report_builder.dart';
import 'package:survey_scriber/features/report_export/data/services/report_data_service.dart';
import 'package:survey_scriber/features/report_export/domain/models/export_config.dart';
import 'package:survey_scriber/features/report_export/domain/models/report_document.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

const String _fontCache =
    r'C:\Users\DELL\AppData\Local\Temp\claude\C--Users-DELL--claude\cbb88d3d-2ca7-4db8-b434-9a4f047ceffa\scratchpad';
const String _out = 'tool/phrase_audit/output/master_report';
const int _scenarios = 8;

bool _term(String term, Map<String, String> a) {
  var t = term.trim();
  var neg = false;
  if (t.startsWith('!')) {
    neg = true;
    t = t.substring(1);
  }
  bool r;
  final eq = t.indexOf('=');
  if (eq > 0) {
    final id = t.substring(0, eq);
    final want = t.substring(eq + 1).split('|').map((e) => e.trim().toLowerCase());
    r = want.contains((a[id] ?? '').trim().toLowerCase());
  } else {
    final v = (a[t] ?? '').trim().toLowerCase();
    r = v.isNotEmpty && v != 'false';
  }
  return neg ? !r : r;
}

bool _visible(InspectionFieldDefinition f, Map<String, String> a) {
  final c = f.conditionalOn;
  if (c == null || c.isEmpty) return true;
  bool r;
  if (c.contains('=') || c.contains('&') || c.startsWith('!')) {
    r = c.split('&').every((t) => _term(t, a));
  } else {
    final v = (a[c] ?? '').trim();
    final want = (f.conditionalValue ?? '').trim().toLowerCase();
    r = want.isEmpty ? v.isNotEmpty && v.toLowerCase() != 'false' : v.toLowerCase() == want;
  }
  return f.conditionalMode == 'hide' ? !r : r;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(pathChannel, (call) async {
    if (call.method == 'getApplicationDocumentsDirectory') return '$_fontCache\\appdocs';
    return null;
  });

  test('five coverage reports via the real pipeline', () async {
    Directory(_out).createSync(recursive: true);
    final tree = InspectionTreePayload.fromJson(File('assets/property_inspection/inspection_tree.json').readAsStringSync());
    final phraseTexts = (jsonDecode(File('assets/property_inspection/phrase_texts.json').readAsStringSync())
            as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v?.toString() ?? ''));
    final engine = InspectionPhraseEngine(phraseTexts);
    final builder = ReportBuilder(inspectionPhraseEngine: engine, valuationPhraseEngine: null);

    final screens = <InspectionNodeDefinition>[];
    for (final section in tree.sections) {
      for (final n in section.nodes) {
        if (n.type == InspectionNodeType.screen && n.fields.isNotEmpty) screens.add(n);
      }
    }

    final tickedEver = <String>{};
    final allChecks = <String>{};
    final pickedEver = <String, Set<String>>{};
    final allOptions = <String, List<String>>{};
    final summary = StringBuffer();
    final docs = <ReportDocument>[];

    for (var s = 0; s < _scenarios; s++) {
      final allAnswers = <String, Map<String, String>>{};
      final states = <String, bool>{};
      var counter = 0;
      for (final screen in screens) {
        final a = <String, String>{};
        for (final f in screen.fields) {
          counter++;
          if (f.type == InspectionFieldType.label) continue;
          if (!_visible(f, a)) continue;
          final key = '${screen.id}/${f.id}';
          switch (f.type) {
            case InspectionFieldType.checkbox:
              allChecks.add(key);
              if (!tickedEver.contains(key) || (counter + s) % _scenarios != 0) {
                a[f.id] = 'true';
                tickedEver.add(key);
              }
            case InspectionFieldType.dropdown:
              final o = f.options ?? const <String>[];
              if (o.isEmpty) break;
              allOptions[key] = o;
              final seen = pickedEver[key] ?? <String>{};
              final fresh = o.where((x) => !seen.contains(x)).toList();
              final v = o.length > _scenarios
                  ? o[(s * o.length) ~/ _scenarios]
                  : fresh.isNotEmpty ? fresh[s % fresh.length == 0 ? 0 : (s % fresh.length)] : o[(s + counter) % o.length];
              a[f.id] = v;
              (pickedEver[key] ??= <String>{}).add(v);
            case InspectionFieldType.text:
              final l = f.label.toLowerCase();
              a[f.id] = l.contains('year') ? '1965' : (l.contains('price') || l.contains('amount') ? '390500' : 'sample detail ${s + 1}');
            case InspectionFieldType.number:
              final l = f.label.toLowerCase();
              a[f.id] = (l.contains('price') || l.contains('amount')) ? '390500' : '2';
            case InspectionFieldType.label:
              break;
          }
        }
        if (a.isNotEmpty) {
          allAnswers[screen.id] = a;
          states[screen.id] = true;
        }
      }
      final survey = Survey(
        id: 'cov-$s',
        title: '${12 + s} Example Avenue, Anytown, AN1 2YT',
        type: SurveyType.inspection,
        status: SurveyStatus.completed,
        createdAt: DateTime(2026, 7, 1),
        address: '${12 + s} Example Avenue, Anytown, AN1 2YT',
        clientName: 'Mr & Mrs Sample Client ${s + 1}',
      );
      final raw = V2RawReportData(
        survey: survey,
        tree: tree,
        allAnswers: allAnswers,
        screenStates: states,
        photoFilePaths: const [],
        signatureRows: const [],
      );
      final doc = builder.build(raw, const ExportConfig());

      docs.add(doc);
      summary.writeln('scenario ${s + 1}: ${allAnswers.length} screens answered');
    }

    // Merge: per section/screen keep every distinct phrase from all scenarios, in order of first appearance.
    final base = docs.first;
    final order = <String>[];
    final secTitle = <String, ReportSection>{};
    final screenOrder = <String, List<String>>{};
    final screenProto = <String, ReportScreen>{};
    final phrasesOf = <String, List<String>>{};
    for (final d in docs) {
      for (final sec in d.sections) {
        if (!secTitle.containsKey(sec.key)) {
          order.add(sec.key);
          secTitle[sec.key] = sec;
          screenOrder[sec.key] = <String>[];
        }
        for (final scr in sec.screens) {
          final k = '${sec.key}/${scr.screenId}';
          if (!screenProto.containsKey(k)) {
            screenProto[k] = scr;
            screenOrder[sec.key]!.add(k);
            phrasesOf[k] = <String>[];
          }
          for (final p in scr.phrases) {
            if (!phrasesOf[k]!.contains(p)) phrasesOf[k]!.add(p);
          }
        }
      }
    }
    final mergedSections = <ReportSection>[
      for (final key in order)
        ReportSection(
          key: key,
          title: secTitle[key]!.title,
          description: secTitle[key]!.description,
          displayOrder: secTitle[key]!.displayOrder,
          screens: [
            for (final k in screenOrder[key]!)
              ReportScreen(
                screenId: screenProto[k]!.screenId,
                title: screenProto[k]!.title,
                fields: const <ReportField>[],
                phrases: phrasesOf[k]!,
                userNote: screenProto[k]!.userNote,
                parentId: screenProto[k]!.parentId,
                isCompleted: screenProto[k]!.isCompleted,
                isMergedGroup: screenProto[k]!.isMergedGroup,
              ),
          ],
        ),
    ];
    final master = base.copyWith(title: 'Master coverage report - every phrase path (scenarios 1-$_scenarios merged)', sections: mergedSections);
    final txt = StringBuffer('TITLE: ${master.title}\n');
    final jsonOut = <Map<String, Object?>>[];
    var total = 0;
    for (final sec in master.sections) {
      txt.writeln('\n=== SECTION ${sec.key}: ${sec.title} ===');
      for (final scr in sec.screens) {
        if (scr.phrases.isEmpty) continue;
        txt.writeln('--- ${scr.title} (${scr.screenId}) ---');
        for (final p in scr.phrases) {
          txt.writeln(p);
          total++;
        }
        jsonOut.add({'section': sec.key, 'screen': scr.screenId, 'phrases': scr.phrases});
      }
    }
    File('$_out/master_report.txt').writeAsStringSync(txt.toString());
    File('$_out/master_report.json')
        .writeAsStringSync(const JsonEncoder.withIndent(' ').convert({'report': jsonOut, 'screens': <Object>[]}));
    final result = await PdfGeneratorService(const ExportConfig()).generatePdf(master);
    File('$_out/master_report.pdf').writeAsBytesSync(result.bytes);
    summary.writeln('MASTER: $total phrase lines, PDF ${result.bytes.length} bytes');

    final unticked = allChecks.difference(tickedEver).toList()..sort();
    final uncovered = <String>[];
    allOptions.forEach((k, o) {
      final miss = o.where((x) => !(pickedEver[k] ?? <String>{}).contains(x)).toList();
      if (miss.isNotEmpty) uncovered.add('$k  -> never picked: ${miss.join(' | ')}');
    });
    uncovered.sort();
    final cov = StringBuffer()
      ..writeln(summary)
      ..writeln('checkboxes: ${allChecks.length} total, ${tickedEver.length} ticked in at least one report, ${unticked.length} never ticked')
      ..writeln('dropdowns: ${allOptions.length} total, ${allOptions.length - uncovered.length} with every option picked, ${uncovered.length} with options never picked')
      ..writeln('\nNEVER TICKED (conditional parent never set, or hidden):')
      ..writeln(unticked.join('\n'))
      ..writeln('\nDROPDOWN OPTIONS NEVER PICKED (more than $_scenarios options, or hidden by a condition):')
      ..writeln(uncovered.join('\n'));
    File('$_out/coverage.txt').writeAsStringSync(cov.toString());
    expect(File('$_out/master_report.pdf').existsSync(), isTrue);
  }, timeout: const Timeout(Duration(minutes: 20)));
}
