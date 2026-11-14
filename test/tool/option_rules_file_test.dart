// The admin portal warns when an option chooses a written sentence. It reads that from
// tool/phrase_portal/public/assets/trees/option_rules.json, generated from the rules here.
// To regenerate: UPDATE_OPTION_RULES=1 flutter test test/tool/option_rules_file_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/property_inspection/presentation/widgets/inspection_fields.dart';

const _file = 'tool/phrase_portal/public/assets/trees/option_rules.json';

/// The valuation report's sentences are written in its engine, not in rules.
const _valuation = <String, Map<String, List<String>>>{
  'val_sub_floor_vents': {'actv_sub_floor_vents': ['Adequate', 'Inadequate'], 'actv_condition_sub_floor': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_gas': {'actv_gas_supply': ['Mains', 'None'], 'actv_condition_gas': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_water': {'actv_water_supply': ['Mains', 'Private'], 'actv_condition_water': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_damp_meter': {'actv_damp_meter': ['Damp Found', 'No damp'], 'actv_condition_damp': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'overall_condition': {'actv_overall_condition': ['Good', 'Average', 'Poor']},
  'val_pitched_roof': {'actv_condition_pitched_roof': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_flat_roof': {'actv_condition_flat_roof': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_other_roof': {'actv_condition_other_roof': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_flashings': {'actv_condition_flashings': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_rainwater_goods': {'actv_condition_rainwater': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_chimney_stacks': {'actv_condition_chimney': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_walls_type': {'actv_condition_walls': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_floor_ext': {'actv_condition_floor_ext': ['Good', 'Reasonable', 'Fair', 'Very poor'], 'actv_condition_upper_floor': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_dpc': {'actv_condition_dpc': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_decorations_ext': {'actv_condition_dec_ext': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_garage': {'actv_condition_garage': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_outbuildings': {'actv_condition_outbuildings': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_site': {'actv_condition_site': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_drainage': {'actv_condition_drainage': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_roof_space': {'actv_condition_roof_space': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_ceilings': {'actv_condition_ceilings': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_walls_internal': {'actv_condition_walls_int': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_chimney_breasts': {'actv_condition_chimney_br': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_external_joinery': {'actv_condition_ext_joinery': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_internal_fittings': {'actv_condition_int_fittings': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_decorations_int': {'actv_condition_dec_int': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_timber_defects': {'actv_condition_timber': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_electric_material': {'actv_condition_electric': ['Good', 'Reasonable', 'Fair', 'Very poor']},
  'val_hot_water_central_heating': {'actv_condition_hw_ch': ['Good', 'Reasonable', 'Fair', 'Very poor']},
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

/// Screens where a field added in the portal would never show: the app picks the
/// fields itself, or draws the whole screen.
Map<String, List<String>> _fixedScreens() {
  const probe = InspectionFieldDefinition(
    id: 'portal_probe',
    label: 'Probe',
    type: InspectionFieldType.text,
  );
  List<String> fixedIn(String treePath, Set<String> drawnByTheApp) {
    final tree = InspectionTreePayload.fromJson(File(treePath).readAsStringSync());
    return [
      for (final section in tree.sections)
        for (final node in section.nodes)
          if (node.type != InspectionNodeType.group &&
              (drawnByTheApp.contains(node.id) ||
                  !sanitizeInspectionFieldsForScreen(node.id, [...node.fields, probe])
                      .any((f) => f.id == probe.id)))
            node.id,
    ]..sort();
  }

  return {
    'inspection': fixedIn(
      'assets/property_inspection/inspection_tree.json',
      {'activity_capture_floor_site_plan_sketches'},
    ),
    'valuation': fixedIn('assets/property_valuation/valuation_tree.json', {}),
  };
}

void main() {
  test('the portal knows which screens cannot take a new field', () {
    final current = const JsonEncoder.withIndent(' ').convert(_fixedScreens());
    final file = File('tool/phrase_portal/public/assets/trees/fixed_screens.json');
    if (Platform.environment['UPDATE_OPTION_RULES'] == '1') file.writeAsStringSync('$current\n');
    expect(file.readAsStringSync().trim().replaceAll('\r\n', '\n'), current);
  });

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
