// Client edit list "Survey Scriber Edit Oct 2026.docx" (2 Nov 2026): the app screens.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';

void main() {
  final tree = InspectionTreePayload.fromJson(
    File('assets/property_inspection/inspection_tree.json').readAsStringSync(),
  );
  final nodes = {
    for (final s in tree.sections)
      for (final n in s.nodes) n.id: n,
  };

  test('Overall Opinion spelling', () {
    expect(nodes['activity_over_all_openion']!.title, 'Overall Opinion');
  });

  test('Kitchen: the defects list under Repairs is titled Defects', () {
    expect(nodes['activity_in_side_property_built_in_fittings_repair_moulding_noted']!.title, 'Defects');
  });

  test('Solar water heating: only the standalone screen remains', () {
    final about = nodes['activity_services_water_heating_gas_heating']!;
    expect(about.fields.map((f) => f.id), isNot(contains('cb_wh_solar')));
    expect(nodes['activity_services_water_heating_solar_power']!.title, 'Solar water heating');
  });

  test('Listed Building appears once, not inside Construction', () {
    expect(nodes.containsKey('activity_listed_building'), isFalse);
    expect(nodes['activity_listed_building__listed_building']!.parentId, isNull);
  });

  test('Area and its repeated gardens are gone; Location density and the garden screens stay', () {
    for (final id in ['activity_property_ground_area', 'group_area_4', 'activity_garden', 'activity_parking']) {
      expect(nodes.containsKey(id), isFalse, reason: id);
    }
    for (final id in ['activity_property_location', 'activity_front_garden', 'activity_rear_garden',
      'activity_communal_garden', 'activity_parking__parking']) {
      expect(nodes.containsKey(id), isTrue, reason: id);
    }
    expect(kVerbatimRules.where((r) => r.id == 'a4_conservation').single.screen, 'activity_property_location');
  });

  test('Ground tile comes straight after Construction', () {
    final d = tree.sections.firstWhere((s) => s.key == 'D');
    final tiles = d.nodes.where((n) => n.parentId == null).map((n) => n.id).toList();
    expect(tiles.indexOf('group_ground_3'), tiles.indexOf('group_construction_2') + 1);
  });
}
