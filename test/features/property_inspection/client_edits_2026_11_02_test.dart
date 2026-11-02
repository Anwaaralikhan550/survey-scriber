// Client edit list "Survey Scriber Edit Oct 2026.docx" (2 Nov 2026): the app screens.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
}
