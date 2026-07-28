import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - F9 Other (inside) parity', () {
    const phraseTexts = <String, String>{
      '{F_OTHER}::{COMMUNAL_AREA_INSPECTED}':
          'communal-inspected={OTH_CA_INSPECTED_PROPERTY}/{OTH_CA_INSPECTED_DEFECT}/{OTH_CA_INSPECTED_CONDITION}',
      '{F_OTHER}::{COMMUNAL_AREA_NOT_INSPECTED}':
          'communal-not-inspected={OTH_CA_NOT_INSPECTED_BECAUSE}',
      '{F_OTHER}::{CELLAR_NO_ACCESS}': 'cellar-no-access={OTH_CELLAR_NA_BECAUSE}',
      '{F_OTHER}::{BASEMENT_NO_ACCESS}':
          'basement-no-access={OTH_BASEMENT_NA_BECAUSE}',
      '{F_OTHER}::{CELLAR_NOT_IN_USE}': 'cellar-not-in-use',
      '{F_OTHER}::{BASEMENT_NOT_IN_USE}': 'basement-not-in-use',
      '{F_OTHER}::{CELLAR_IN_USE}':
          'cellar-in-use=used:{OTH_CELLAR_UA}/condition:{OTH_CELLAR_UA_CONDITION}',
      '{F_OTHER}::{BASEMENT_IN_USE}':
          'basement-in-use=used:{OTH_BASEMENT_UA}/condition:{OTH_BASEMENT_UA_CONDITION}',
      '{F_OTHER}::{CELLAR_NOT_HABITABLE}':
          'cellar-not-habitable={OTH_CELLAR_NH_BECAUSE}',
      '{F_OTHER}::{BASEMENT_NOT_HABITABLE}':
          'basement-not-habitable={OTH_BASEMENT_NH_BECAUSE}',
      '{F_OTHER}::{CELLAR_FLOODED}': 'cellar-flooded={OTH_CELLAR_FLOODED}',
      '{F_OTHER}::{BASEMENT_FLOODED}': 'basement-flooded={OTH_BASEMENT_FLOODED}',
      '{F_OTHER}::{CELLAR_DAMP}': 'cellar-damp={OTH_CELLAR_DAMP}',
      '{F_OTHER}::{BASEMENT_DAMP}': 'basement-damp={OTH_BASEMENT_DAMP}',
      '{F_OTHER}::{CELLAR_SERIOUS_DAMP}': 'cellar-serious-damp',
      '{F_OTHER}::{BASEMENT_SERIOUS_DAMP}': 'basement-serious-damp',
      '{F_OTHER}::{CELLAR_JOINT_DECAY}': 'cellar-joint-decay',
      '{F_OTHER}::{BASEMENT_JOINT_DECAY}': 'basement-joint-decay',
      '{F_OTHER}::{OTHER_REPAIR_NOW}':
          'repair-now=loc:{OTHR_NOW_LOCATION}/defect:{OTHR_NOW_DEFECT}',
      '{F_OTHER}::{OTHER_REPAIR_SOON}':
          'repair-soon=loc:{OTHR_SOON_LOCATION}/defect:{OTHR_SOON_DEFECT}',
      '{F_OTHER}::{NOT_INSPECTED}': 'not-applicable',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('communal area inspected resolves property, defect and condition', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_other_communal_area',
        {
          'actv_status': 'Inspected',
          'cb_stairs': 'true',
          'cb_usual_wear_and_tear_100': 'true',
          'actv_condition': 'Reasonable',
        },
      );
      expect(phrases, hasLength(1));
      final all = phrases.first.toLowerCase();
      expect(all, contains('communal-inspected=stairs'));
      expect(all, contains('usual wear and tear'));
      expect(all, contains('reasonable'));
    });

    test('communal area not inspected resolves the reason', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_other_communal_area',
        {
          'actv_status': 'Not Inspected',
          'cb_of_limited_access': 'true',
        },
      );
      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(),
          contains('communal-not-inspected=of limited access'));
    });

    test('cellar screen resolves cellar branch (not basement)', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_other_cellar',
        {
          'actv_used_as': 'storage',
          'actv_condition': 'Reasonable',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('cellar-in-use=used:storage/condition:reasonable'));
      expect(all, isNot(contains('basement-in-use')));
    });

    test('basement screen resolves basement branch (not cellar)', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_other_basement',
        {
          'actv_used_as': 'storage',
          'actv_condition': 'Reasonable',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(
          all, contains('basement-in-use=used:storage/condition:reasonable'));
      expect(all, isNot(contains('cellar-in-use')));
    });

    test('cellar damp resolves location and serious-damp addendum', () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_other_celler_damp',
        {
          'cb_throughout': 'true',
          'cb_serious_dump': 'true',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('cellar-damp=throughout'));
      expect(all, contains('cellar-serious-damp'));
    });

    test('basement damp (via the __serious_damp suffixed screen) resolves the basement branch', () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_other_celler_damp__serious_damp',
        {
          'cb_throughout': 'true',
          'cb_serious_dump': 'true',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('basement-damp=throughout'));
      expect(all, contains('basement-serious-damp'));
    });

    test('cellar joist decay vs basement joist decay', () {
      final cellar = engine.buildPhrases(
        'activity_inside_property_other_celler_joists_decay',
        {'cb_joists_decay': 'true'},
      );
      expect(cellar.single.toLowerCase(), contains('cellar-joint-decay'));

      final basement = engine.buildPhrases(
        'activity_inside_property_other_celler_joists_decay__joists_decay',
        {'cb_joists_decay': 'true'},
      );
      expect(basement.single.toLowerCase(), contains('basement-joint-decay'));
    });

    test('cellar not habitable resolves the reason', () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_other_celler_not_habitable',
        {'cb_cast_iron': 'true'},
      );
      expect(phrases.single.toLowerCase(),
          contains('cellar-not-habitable=it is damp'));
    });

    test('other repair soon resolves location and defect', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_other_repair',
        {
          'actv_repair_type': 'Repair soon',
          'cb_stairs': 'true',
          'cb_damaged': 'true',
        },
      );
      expect(phrases.single.toLowerCase(),
          contains('repair-soon=loc:stairs/defect:damaged'));
    });

    test('not inspected fires the not-applicable phrase', () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_other_not_inspected',
        {'cb_not_inspected': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('not-applicable'));
    });
  });
}
