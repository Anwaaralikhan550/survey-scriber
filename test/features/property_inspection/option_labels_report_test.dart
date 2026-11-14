// An admin renames a dropdown option. For every option of every dropdown in both
// trees: the report prints the new words wherever it printed the old ones, and no
// sentence appears or disappears.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/property_inspection/domain/option_labels.dart';
import 'package:survey_scriber/features/property_inspection/presentation/widgets/inspection_fields.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_engine.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_catalog.dart';
import 'package:survey_scriber/features/report_export/data/services/report_builder.dart';
import 'package:survey_scriber/features/report_export/data/services/report_data_service.dart';
import 'package:survey_scriber/features/report_export/domain/models/export_config.dart';
import 'package:survey_scriber/features/report_export/domain/models/report_document.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

const _mark = 'ZQLABELZQ';

Map<String, String> _baseAnswers(List<InspectionFieldDefinition> fields) {
  final out = <String, String>{};
  for (final f in fields) {
    switch (f.type) {
      case InspectionFieldType.checkbox:
        out[f.id] = 'true';
      case InspectionFieldType.dropdown:
        final o = f.options ?? const <String>[];
        if (o.isNotEmpty) out[f.id] = o.first;
      case InspectionFieldType.number:
        out[f.id] = '2';
      case InspectionFieldType.text:
        out[f.id] = 'Test text';
      case InspectionFieldType.label:
        break;
    }
  }
  return out;
}

OptionLabels _labelsFor(String screen, String field, String option) => OptionLabels({
      screen: {
        field: {option: _mark},
      },
    });

/// Words that hold the option text, ignoring case.
bool _holds(List<String> phrases, String option) {
  final escaped = RegExp.escape(option.trim());
  final re = RegExp('(?<![A-Za-z0-9])$escaped(?![A-Za-z0-9])', caseSensitive: false);
  return phrases.any(re.hasMatch);
}

/// The option picks a sentence written in full, in the phrase bank or the valuation
/// engine; its words are not the answer printed back. Renaming the option leaves
/// that sentence as it is: the portal says so, and points to the phrase editor.
const _picksAWrittenSentence = {
  'activity_outside_property_conservatory_porch_repairs/actv_cp/Conservatory',
  'activity_outside_property_conservatory_porch_repairs/actv_cp/Porch',
  'val_sub_floor_vents/actv_sub_floor_vents/Adequate',
  'val_gas/actv_gas_supply/Mains',
  'val_water/actv_water_supply/Mains',
  'val_water/actv_water_supply/Private',
  'overall_condition/actv_overall_condition/Good',
  'overall_condition/actv_overall_condition/Average',
  // Condition sentences of the valuation are written in the engine (client, 13 Nov 2026).
  'val_pitched_roof/actv_condition_pitched_roof/Good',
  'val_pitched_roof/actv_condition_pitched_roof/Reasonable',
  'val_pitched_roof/actv_condition_pitched_roof/Fair',
  'val_pitched_roof/actv_condition_pitched_roof/Very poor',
  'val_flat_roof/actv_condition_flat_roof/Good',
  'val_flat_roof/actv_condition_flat_roof/Reasonable',
  'val_flat_roof/actv_condition_flat_roof/Fair',
  'val_flat_roof/actv_condition_flat_roof/Very poor',
  'val_other_roof/actv_condition_other_roof/Good',
  'val_other_roof/actv_condition_other_roof/Reasonable',
  'val_other_roof/actv_condition_other_roof/Fair',
  'val_other_roof/actv_condition_other_roof/Very poor',
  'val_flashings/actv_condition_flashings/Good',
  'val_flashings/actv_condition_flashings/Reasonable',
  'val_flashings/actv_condition_flashings/Fair',
  'val_flashings/actv_condition_flashings/Very poor',
  'val_rainwater_goods/actv_condition_rainwater/Good',
  'val_rainwater_goods/actv_condition_rainwater/Reasonable',
  'val_rainwater_goods/actv_condition_rainwater/Fair',
  'val_rainwater_goods/actv_condition_rainwater/Very poor',
  'val_chimney_stacks/actv_condition_chimney/Good',
  'val_chimney_stacks/actv_condition_chimney/Reasonable',
  'val_chimney_stacks/actv_condition_chimney/Fair',
  'val_chimney_stacks/actv_condition_chimney/Very poor',
  'val_walls_type/actv_condition_walls/Good',
  'val_walls_type/actv_condition_walls/Reasonable',
  'val_walls_type/actv_condition_walls/Fair',
  'val_walls_type/actv_condition_walls/Very poor',
  'val_floor_ext/actv_condition_floor_ext/Good',
  'val_floor_ext/actv_condition_floor_ext/Reasonable',
  'val_floor_ext/actv_condition_floor_ext/Fair',
  'val_floor_ext/actv_condition_floor_ext/Very poor',
  'val_floor_ext/actv_condition_upper_floor/Good',
  'val_floor_ext/actv_condition_upper_floor/Reasonable',
  'val_floor_ext/actv_condition_upper_floor/Fair',
  'val_floor_ext/actv_condition_upper_floor/Very poor',
  'val_dpc/actv_condition_dpc/Good',
  'val_dpc/actv_condition_dpc/Reasonable',
  'val_dpc/actv_condition_dpc/Fair',
  'val_dpc/actv_condition_dpc/Very poor',
  'val_sub_floor_vents/actv_condition_sub_floor/Good',
  'val_sub_floor_vents/actv_condition_sub_floor/Reasonable',
  'val_sub_floor_vents/actv_condition_sub_floor/Fair',
  'val_sub_floor_vents/actv_condition_sub_floor/Very poor',
  'val_decorations_ext/actv_condition_dec_ext/Good',
  'val_decorations_ext/actv_condition_dec_ext/Reasonable',
  'val_decorations_ext/actv_condition_dec_ext/Fair',
  'val_decorations_ext/actv_condition_dec_ext/Very poor',
  'val_garage/actv_condition_garage/Good',
  'val_garage/actv_condition_garage/Reasonable',
  'val_garage/actv_condition_garage/Fair',
  'val_garage/actv_condition_garage/Very poor',
  'val_outbuildings/actv_condition_outbuildings/Good',
  'val_outbuildings/actv_condition_outbuildings/Reasonable',
  'val_outbuildings/actv_condition_outbuildings/Fair',
  'val_outbuildings/actv_condition_outbuildings/Very poor',
  'val_site/actv_condition_site/Good',
  'val_site/actv_condition_site/Reasonable',
  'val_site/actv_condition_site/Fair',
  'val_site/actv_condition_site/Very poor',
  'val_drainage/actv_condition_drainage/Good',
  'val_drainage/actv_condition_drainage/Reasonable',
  'val_drainage/actv_condition_drainage/Fair',
  'val_drainage/actv_condition_drainage/Very poor',
  'val_roof_space/actv_condition_roof_space/Good',
  'val_roof_space/actv_condition_roof_space/Reasonable',
  'val_roof_space/actv_condition_roof_space/Fair',
  'val_roof_space/actv_condition_roof_space/Very poor',
  'val_ceilings/actv_condition_ceilings/Good',
  'val_ceilings/actv_condition_ceilings/Reasonable',
  'val_ceilings/actv_condition_ceilings/Fair',
  'val_ceilings/actv_condition_ceilings/Very poor',
  'val_walls_internal/actv_condition_walls_int/Good',
  'val_walls_internal/actv_condition_walls_int/Reasonable',
  'val_walls_internal/actv_condition_walls_int/Fair',
  'val_walls_internal/actv_condition_walls_int/Very poor',
  'val_chimney_breasts/actv_condition_chimney_br/Good',
  'val_chimney_breasts/actv_condition_chimney_br/Reasonable',
  'val_chimney_breasts/actv_condition_chimney_br/Fair',
  'val_chimney_breasts/actv_condition_chimney_br/Very poor',
  'val_external_joinery/actv_condition_ext_joinery/Good',
  'val_external_joinery/actv_condition_ext_joinery/Reasonable',
  'val_external_joinery/actv_condition_ext_joinery/Fair',
  'val_external_joinery/actv_condition_ext_joinery/Very poor',
  'val_internal_fittings/actv_condition_int_fittings/Good',
  'val_internal_fittings/actv_condition_int_fittings/Reasonable',
  'val_internal_fittings/actv_condition_int_fittings/Fair',
  'val_internal_fittings/actv_condition_int_fittings/Very poor',
  'val_decorations_int/actv_condition_dec_int/Good',
  'val_decorations_int/actv_condition_dec_int/Reasonable',
  'val_decorations_int/actv_condition_dec_int/Fair',
  'val_decorations_int/actv_condition_dec_int/Very poor',
  'val_damp_meter/actv_condition_damp/Good',
  'val_damp_meter/actv_condition_damp/Reasonable',
  'val_damp_meter/actv_condition_damp/Fair',
  'val_damp_meter/actv_condition_damp/Very poor',
  'val_timber_defects/actv_condition_timber/Good',
  'val_timber_defects/actv_condition_timber/Reasonable',
  'val_timber_defects/actv_condition_timber/Fair',
  'val_timber_defects/actv_condition_timber/Very poor',
  'val_electric_material/actv_condition_electric/Good',
  'val_electric_material/actv_condition_electric/Reasonable',
  'val_electric_material/actv_condition_electric/Fair',
  'val_electric_material/actv_condition_electric/Very poor',
  'val_gas/actv_condition_gas/Good',
  'val_gas/actv_condition_gas/Reasonable',
  'val_gas/actv_condition_gas/Fair',
  'val_gas/actv_condition_gas/Very poor',
  'val_water/actv_condition_water/Good',
  'val_water/actv_condition_water/Reasonable',
  'val_water/actv_condition_water/Fair',
  'val_water/actv_condition_water/Very poor',
  'val_hot_water_central_heating/actv_condition_hw_ch/Good',
  'val_hot_water_central_heating/actv_condition_hw_ch/Reasonable',
  'val_hot_water_central_heating/actv_condition_hw_ch/Fair',
  'val_hot_water_central_heating/actv_condition_hw_ch/Very poor',
};

class _Miss {
  _Miss(this.screen, this.field, this.option, this.problem);
  final String screen;
  final String field;
  final String option;
  final String problem;
  @override
  String toString() => '$screen / $field / "$option": $problem';
}

/// The option's words come from the phrase bank's own sentence, chosen by a rule,
/// not from the answer. That wording is edited in the phrase editor.
bool _isBankWording(List<String> phrases, String option, Iterable<String> bank) {
  if (bank.isEmpty) return false;
  final escaped = RegExp.escape(option.trim());
  final re = RegExp('(?<![A-Za-z0-9])$escaped(?![A-Za-z0-9])', caseSensitive: false);
  for (final phrase in phrases) {
    for (final m in re.allMatches(phrase)) {
      final from = (m.start - 6).clamp(0, phrase.length);
      final to = (m.end + 6).clamp(0, phrase.length);
      final window = phrase.substring(from, to).toLowerCase();
      if (!bank.any((text) => text.contains(window))) return false;
    }
  }
  return true;
}

List<_Miss> _sweep(
  InspectionTreePayload tree,
  Iterable<String> bank,
  List<String> Function(String screen, Map<String, String> answers, OptionLabels labels) build,
) {
  final misses = <_Miss>[];
  for (final section in tree.sections) {
    for (final node in section.nodes) {
      final fields = sanitizeInspectionFieldsForScreen(node.id, node.fields);
      final base = _baseAnswers(fields);
      for (final field in fields) {
        if (field.type != InspectionFieldType.dropdown) continue;
        for (final option in field.options ?? const <String>[]) {
          final answers = {...base, field.id: option};
          final plain = build(node.id, answers, OptionLabels.empty);
          final labelled = build(node.id, answers, _labelsFor(node.id, field.id, option));

          // The same sentences, with only the option's words changed.
          if (plain.length != labelled.length) {
            misses.add(_Miss(node.id, field.id, option, 'sentence count ${plain.length} -> ${labelled.length}'));
            continue;
          }
          final differs = <int>[
            for (var i = 0; i < plain.length; i++)
              if (plain[i] != labelled[i]) i,
          ];
          for (final i in differs) {
            if (!labelled[i].toLowerCase().contains(_mark.toLowerCase())) {
              misses.add(_Miss(node.id, field.id, option, 'a sentence changed without the new words: ${plain[i]}'));
            }
          }

          // Printed from the answer? Then the new words must be there. Fixed wording
          // that merely holds the same word stays the same with any other option.
          if (!_holds(plain, option)) continue;
          final other = (field.options ?? const <String>[]).firstWhere(
            (o) => !o.toLowerCase().contains(option.toLowerCase()) && !option.toLowerCase().contains(o.toLowerCase()),
            orElse: () => '',
          );
          if (other.isEmpty) continue;
          final withOther = build(node.id, {...base, field.id: other}, OptionLabels.empty);
          if (_holds(withOther, option)) continue; // fixed wording, not this answer
          if (_picksAWrittenSentence.contains('${node.id}/${field.id}/$option')) continue;
          if (_isBankWording(plain, option, bank)) continue;
          if (!labelled.any((p) => p.toLowerCase().contains(_mark.toLowerCase()))) {
            misses.add(_Miss(node.id, field.id, option, 'old words still printed: ${plain.firstWhere((p) => _holds([p], option))}'));
          }
        }
      }
    }
  }
  return misses;
}

void main() {
  test('Home survey: every option of every dropdown', () {
    final tree = InspectionTreePayload.fromJson(
      File('assets/property_inspection/inspection_tree.json').readAsStringSync(),
    );
    final texts = (jsonDecode(
      File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
    ) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v?.toString() ?? ''));
    final bank = texts.values.map((t) => t.toLowerCase()).toList();
    final misses = _sweep(
      tree,
      bank,
      (screen, answers, labels) =>
          InspectionPhraseEngine(texts, optionLabels: labels).buildPhrases(screen, answers),
    );
    File('tmp/client-edits-2026-11-04/proof/w5_inspection_misses.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync(misses.join('\n'));
    expect(misses, isEmpty, reason: misses.take(40).join('\n'));
  });

  test('Valuation: every option of every dropdown', () {
    final tree = InspectionTreePayload.fromJson(
      File('assets/property_valuation/valuation_tree.json').readAsStringSync(),
    );
    final catalog = ValuationPhraseCatalog.fromJson(
      jsonDecode(File('assets/property_valuation/phrase_texts.json').readAsStringSync()) as Map<String, dynamic>,
    );
    final misses = _sweep(
      tree,
      const <String>[],
      (screen, answers, labels) =>
          ValuationPhraseEngine.catalog(catalog, optionLabels: labels).buildPhrases(screen, answers),
    );
    File('tmp/client-edits-2026-11-04/proof/w5_valuation_misses.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync(misses.join('\n'));
    expect(misses, isEmpty, reason: misses.take(40).join('\n'));
  });

  group('a whole report with every option renamed', () {
    const tag = 'ZQTAG';

    InspectionTreePayload renamedTree(String rawJson) {
      final data = jsonDecode(rawJson) as Map<String, dynamic>;
      for (final section in data['sections'] as List) {
        for (final node in section['nodes'] as List) {
          for (final field in (node['fields'] as List?) ?? const []) {
            final options = field['options'] as List?;
            if (options == null) continue;
            field['optionLabels'] = {for (final o in options) o as String: '$o $tag'};
          }
        }
      }
      return InspectionTreePayload.fromJson(jsonEncode(data));
    }

    Map<String, Map<String, String>> answersFor(InspectionTreePayload tree, bool last) => {
          for (final section in tree.sections)
            for (final node in section.nodes)
              if (node.type == InspectionNodeType.screen)
                node.id: {
                  for (final f in node.fields)
                    if (f.type == InspectionFieldType.checkbox)
                      f.id: 'true'
                    else if (f.type == InspectionFieldType.dropdown && (f.options ?? const []).isNotEmpty)
                      f.id: last ? f.options!.last : f.options!.first
                    else if (f.type == InspectionFieldType.number)
                      f.id: '2'
                    else if (f.type == InspectionFieldType.text)
                      f.id: 'Test text',
                },
        };

    String flatten(ReportDocument doc) => [
          for (final s in doc.sections)
            for (final screen in s.screens) ...[
              '--- ${screen.title}',
              ...screen.phrases,
            ],
        ].join('\n');

    for (final (name, treePath, last) in [
      ('home survey, first options', 'assets/property_inspection/inspection_tree.json', false),
      ('home survey, last options', 'assets/property_inspection/inspection_tree.json', true),
      ('valuation, first options', 'assets/property_valuation/valuation_tree.json', false),
      ('valuation, last options', 'assets/property_valuation/valuation_tree.json', true),
    ]) {
      test(name, () {
        final raw = File(treePath).readAsStringSync();
        final plainTree = InspectionTreePayload.fromJson(raw);
        final namedTree = renamedTree(raw);
        final isValuation = treePath.contains('valuation');
        final texts = (jsonDecode(File('assets/property_inspection/phrase_texts.json').readAsStringSync())
                as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v?.toString() ?? ''));
        final catalog = ValuationPhraseCatalog.fromJson(
          jsonDecode(File('assets/property_valuation/phrase_texts.json').readAsStringSync()) as Map<String, dynamic>,
        );
        final builder = ReportBuilder(
          inspectionPhraseEngine: InspectionPhraseEngine(texts),
          valuationPhraseEngine: ValuationPhraseEngine.catalog(catalog),
        );
        final survey = Survey(
          id: 's',
          title: 'T',
          type: isValuation ? SurveyType.valuation : SurveyType.inspection,
          status: SurveyStatus.completed,
          createdAt: DateTime(2026, 11, 1),
        );
        ReportDocument build(InspectionTreePayload tree) => builder.build(
              V2RawReportData(
                survey: survey,
                tree: tree,
                allAnswers: answersFor(plainTree, last),
                screenStates: {
                  for (final s in plainTree.sections)
                    for (final n in s.nodes) n.id: true,
                },
                photoFilePaths: const [],
                signatureRows: const [],
              ),
              const ExportConfig(),
            );

        final plain = flatten(build(plainTree));
        final named = flatten(build(namedTree));
        expect(named.toLowerCase(), contains(tag.toLowerCase()));
        // Take the new words back out: the report is the same, sentence for sentence.
        final restored = named.replaceAll(RegExp(' $tag', caseSensitive: false), '');
        // One tidy-up in the valuation engine only knows the stored word: "snow" -> "snowy".
        String same(String t) => t.toLowerCase().replaceAll('conditions were snowy.', 'conditions were snow.');
        expect(same(restored), same(plain));
      });
    }
  });

  test('nothing renamed: the engines print exactly what they printed before', () {
    final tree = InspectionTreePayload.fromJson(
      File('assets/property_inspection/inspection_tree.json').readAsStringSync(),
    );
    final texts = (jsonDecode(
      File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
    ) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v?.toString() ?? ''));
    final engine = InspectionPhraseEngine(texts);
    final withEmpty = InspectionPhraseEngine(texts, optionLabels: OptionLabels.empty);
    for (final section in tree.sections) {
      for (final node in section.nodes) {
        final answers = _baseAnswers(node.fields);
        expect(withEmpty.buildPhrases(node.id, answers), engine.buildPhrases(node.id, answers));
      }
    }
  });
}
