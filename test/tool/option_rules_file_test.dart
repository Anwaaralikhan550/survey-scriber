// The admin portal warns when an option chooses a written sentence. It reads that from
// tool/phrase_portal/public/assets/trees/option_rules.json, generated from the rules here.
// To regenerate: UPDATE_OPTION_RULES=1 flutter test test/tool/option_rules_file_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

const _file = 'tool/phrase_portal/public/assets/trees/option_rules.json';

/// The valuation report's sentences are written in its engine, not in rules.
const _valuation = <String, Map<String, List<String>>>{
  'new_build_property': {'actv_work_stage': ['Complete']},
  'val_sub_floor_vents': {'actv_sub_floor_vents': ['Adequate', 'Inadequate']},
  'val_gas': {'actv_gas_supply': ['Mains', 'None']},
  'val_water': {'actv_water_supply': ['Mains', 'Private']},
  'val_damp_meter': {'actv_damp_meter': ['Damp Found', 'No damp']},
  'overall_condition': {'actv_overall_condition': ['Good', 'Average', 'Poor']},
};

Map<String, dynamic> _generate() {
  final inspection = <String, Map<String, Set<String>>>{};
  void add(String screen, String field, String value) {
    if (value == 'true') return;
    ((inspection[screen] ??= {})[field] ??= <String>{}).add(value);
  }

  for (final rule in kVerbatimRules) {
    if (rule.whenField != null && rule.whenValue != null) {
      add(rule.screen, rule.whenField!, rule.whenValue!);
    }
    for (final pair in rule.whenAny) {
      add(rule.screen, pair[0], pair[1]);
    }
  }
  return {
    'inspection': {
      for (final screen in inspection.keys.toList()..sort())
        screen: {
          for (final field in inspection[screen]!.keys.toList()..sort())
            field: inspection[screen]![field]!.toList()..sort(),
        },
    },
    'valuation': _valuation,
  };
}

/// Tree nodes the app's code asks for by id. Deleting one changes what the report prints.
Map<String, List<String>> _reportNodes() {
  Set<String> idsOf(String treePath) {
    final tree = jsonDecode(File(treePath).readAsStringSync()) as Map<String, dynamic>;
    return {
      for (final section in tree['sections'] as List)
        for (final node in section['nodes'] as List) node['id'] as String,
    };
  }

  final quoted = RegExp(r"""['"]([a-z][a-z0-9_]*)['"]""");
  final used = <String>{};
  for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart') || file.path.endsWith('.g.dart')) continue;
    used.addAll(quoted.allMatches(file.readAsStringSync()).map((m) => m.group(1)!));
  }
  List<String> usedIn(String treePath) => idsOf(treePath).where(used.contains).toList()..sort();
  return {
    'inspection': usedIn('assets/property_inspection/inspection_tree.json'),
    'valuation': usedIn('assets/property_valuation/valuation_tree.json'),
  };
}

void main() {
  test('the portal knows which nodes the report asks for by id', () {
    final current = const JsonEncoder.withIndent(' ').convert(_reportNodes());
    final file = File('tool/phrase_portal/public/assets/trees/report_nodes.json');
    if (Platform.environment['UPDATE_OPTION_RULES'] == '1') file.writeAsStringSync('$current\n');
    expect(file.readAsStringSync().trim().replaceAll('\r\n', '\n'), current);
  });

  test('the portal has the current list of options that choose a sentence', () {
    final current = const JsonEncoder.withIndent(' ').convert(_generate());
    final file = File(_file);
    if (Platform.environment['UPDATE_OPTION_RULES'] == '1') {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('$current\n');
    }
    expect(file.readAsStringSync().trim().replaceAll('\r\n', '\n'), current);
  });
}
