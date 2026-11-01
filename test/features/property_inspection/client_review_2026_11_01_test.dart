// Client review fixes (1 Nov 2026): tree arrangement, labels, completion rules.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/core/database/app_database.dart';
import 'package:survey_scriber/features/property_inspection/domain/group_completion.dart';
import 'package:survey_scriber/features/property_inspection/presentation/providers/inspection_providers.dart';

void main() {
  final tree = jsonDecode(
    File('assets/property_inspection/inspection_tree.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final nodes = <Map<String, dynamic>>[
    for (final s in tree['sections'] as List)
      for (final n in (s as Map)['nodes'] as List) n as Map<String, dynamic>,
  ];
  final byId = {for (final n in nodes) n['id'] as String: n};
  List<Map<String, dynamic>> childrenOf(String id) =>
      nodes.where((n) => n['parentId'] == id).toList();
  List<String> landing(String id) =>
      childrenOf(id).map((n) => n['title'] as String).toList();
  Map<String, dynamic> header(String groupId) => childrenOf(groupId)
      .singleWhere((n) => n['inlinePosition'] == 'header',
          orElse: () => throw StateError('no header screen in $groupId'));

  group('landing screens follow the Roof Covering arrangement', () {
    test('Roof Covering (reference): main group, Repairs, Not inspected', () {
      expect(landing('group_e2_roof_covering_9'),
          ['Roof Covering', 'Repairs', 'Not Inspected']);
      expect(header('group_roof_covering_10')['order'], -1);
    });

    test('Chimney', () {
      expect(landing('group_e1_chimney_5'), ['Chimney', 'Repairs', 'Not Inspected']);
      expect(header('group_chimney_6')['id'], 'activity_outside_property_chimney_main_screen');
    });

    test('Outside Doors', () {
      expect(landing('group_e6_outside_doors_23'), ['Outside doors', 'Repairs']);
      expect(header('group_outside_doors_24')['id'],
          'activity_outside_property_outside_doors_main_screen');
    });

    test('Conservatory and Porches', () {
      expect(landing('group_e7_conservatory_and_porches_26'),
          ['Conservatory and Porch', 'Repairs', 'Not inspected']);
      expect(header('group_conservatory_and_porch_27')['id'],
          'activity_outside_property_conservatory_porch_main_screen');
    });

    test('Other Joinery and Finishes', () {
      expect(landing('group_e8_other_joinery_and_finishes_31'),
          ['Other Joinery and Finishes', 'Repairs', 'Not inspected']);
      expect(header('group_other_joinery_and_finishes_82')['id'],
          'activity_outside_property_other_joinery_and_finishes_main_screen');
    });

    test('Other Outside Property', () {
      expect(header('group_other_area_33')['id'],
          'activity_outside_property_other_main_screen');
    });

    test('Fireplaces (one word) with repairs under Repairs', () {
      expect(byId['group_fire_places_70']!['title'], 'Fireplaces');
      expect(landing('group_f5_fireplaces_and_chimneys_69'), ['Fireplaces', 'Repairs']);
      expect(header('group_fire_places_70')['id'],
          'activity_inside_property_fireplaces_main_screen');
      expect(landing('group_repairs_71'), containsAll(['Blocked Fireplace', 'Removed CB', 'Boiler Flue']));
      expect(nodes.where((n) => n['title'] == 'Fire Places'), isEmpty);
    });

    test('Built In Fittings, Woodwork, Bathroom Fittings', () {
      expect(landing('group_f6_built_in_fittings_72'), ['Built In Fittings', 'Repairs']);
      expect(header('group_built_in_fittings_83')['id'],
          'activity_inside_property_built_in_fittings_main_screen');
      expect(landing('group_f7_woodwork_74'), ['Woodwork', 'Repairs']);
      expect(header('group_wood_work_75')['id'], 'activity_inside_property_woodwork_main_screen');
      expect(landing('group_f8_bathroom_fittings_77'), ['Bathroom Fittings', 'Repairs']);
      expect(header('group_bathroom_fitting_78')['id'],
          'activity_inside_property_bathroom_fittings_main_screen');
    });

    test('main group is placed before Repairs in the file (the app orders by placement)', () {
      // The section page sorts tiles by displayOrder, which is the node's index
      // in the JSON, not its "order" attribute. Found in the 1 Nov E2E run:
      // E9 showed [Repairs, Other Area].
      final raw = File('assets/property_inspection/inspection_tree.json').readAsStringSync();
      int placement(String id) => raw.indexOf('"id": "$id"');
      for (final landing in [
        'group_e1_chimney_5', 'group_e2_roof_covering_9', 'group_e6_outside_doors_23',
        'group_e7_conservatory_and_porches_26', 'group_e8_other_joinery_and_finishes_31',
        'group_e9_other_area_32', 'group_f5_fireplaces_and_chimneys_69',
        'group_f6_built_in_fittings_72', 'group_f7_woodwork_74', 'group_f8_bathroom_fittings_77',
      ]) {
        final kids = childrenOf(landing);
        final repairs = kids.singleWhere((n) => n['title'] == 'Repairs');
        final main = kids.firstWhere((n) => n['type'] == 'group' && n['title'] != 'Repairs');
        expect(placement(main['id'] as String), lessThan(placement(repairs['id'] as String)),
            reason: '$landing: ${main['title']} must be placed before Repairs');
      }
    });

    test('every element landing has exactly one header screen in its main group', () {
      for (final g in [
        'group_chimney_6', 'group_roof_covering_10', 'group_outside_doors_24',
        'group_conservatory_and_porch_27', 'group_other_joinery_and_finishes_82',
        'group_other_area_33', 'group_fire_places_70', 'group_built_in_fittings_83',
        'group_wood_work_75', 'group_bathroom_fitting_78',
      ]) {
        expect(header(g)['order'], -1, reason: g);
      }
    });
  });

  group('repair timescales and duplicate condition', () {
    test('no repair dropdown is still labelled "Condition"', () {
      final offenders = <String>[];
      for (final n in nodes) {
        for (final f in (n['fields'] as List? ?? const [])) {
          final opts = ((f as Map)['options'] as List? ?? const []).map((o) => '$o'.toLowerCase());
          final isTimescale = opts.any((o) => o.contains('repair') && (o.contains('soon') || o.contains('now')));
          if (isTimescale && f['label'] == 'Condition') offenders.add('${n['id']}/${f['id']}');
        }
      }
      expect(offenders, isEmpty);
      final relabelled = nodes
          .expand((n) => (n['fields'] as List? ?? const []))
          .where((f) => (f as Map)['label'] == 'Repair Timescales')
          .length;
      expect(relabelled, greaterThanOrEqualTo(15));
    });

    test('Roof Covering landing no longer has the duplicate Condition screen', () {
      expect(byId.containsKey('outside_property_roof_covering_weathered_layout'), isFalse);
      expect(childrenOf('group_roof_covering_10').where((n) => n['title'] == 'Condition'), isEmpty);
    });
  });

  group('mark complete validation', () {
    test('only "Other without text" still blocks', () {
      expect(isBlockingValidation('Enter Other chimney text or uncheck Other.'), isTrue);
      expect(isBlockingValidation('Select at least one Chimney option.'), isFalse);
      expect(isBlockingValidation('Select Weathered.'), isFalse);
      expect(isBlockingValidation('Select condition.'), isFalse);
      expect(isBlockingValidation('Condition is required.'), isFalse);
    });
  });

  group('group completion tick', () {
    InspectionV2Screen row(String id, String parent,
        {String type = 'screen', bool done = false, bool touched = false}) {
      return InspectionV2Screen(
        id: id,
        surveyId: 's',
        sectionKey: 'D',
        screenId: id,
        title: id,
        nodeType: type,
        parentId: parent,
        displayOrder: 0,
        isCompleted: done,
        phraseEditedManually: false,
        createdAt: DateTime(2026),
        updatedAt: touched ? DateTime(2026, 1, 2) : null,
      );
    }

    test('ticks when the applicable screens are done and the rest untouched', () {
      final rows = [
        row('ground', '', type: 'group'),
        row('area', 'ground', done: true),
        row('topography', 'ground', done: true),
        row('communal_garden', 'ground'), // not applicable, never opened
        row('gated', 'ground'),
      ];
      expect(isGroupComplete('ground', rows), isTrue);
    });

    test('does not tick while a touched screen is still open', () {
      final rows = [
        row('ground', '', type: 'group'),
        row('area', 'ground', done: true),
        row('front_garden', 'ground', touched: true),
      ];
      expect(isGroupComplete('ground', rows), isFalse);
    });

    test('does not tick when nothing is done, and walks nested groups', () {
      expect(isGroupComplete('g', [row('g', '', type: 'group'), row('a', 'g')]), isFalse);
      final nested = [
        row('e2', '', type: 'group'),
        row('inner', 'e2', type: 'group'),
        row('main', 'inner', done: true),
        row('repairs', 'e2', type: 'group'),
        row('tiles', 'repairs'),
      ];
      expect(isGroupComplete('e2', nested), isTrue);
    });
  });
}
