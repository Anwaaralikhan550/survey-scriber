import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - F6 Built-in Fittings parity', () {
    const phraseTexts = <String, String>{
      '{F_BUILT_IN_FITTINGS}::{BUILT_IN_FITTINGS}':
          'about=loc:{BIF_LOCATION}/worktop:{BIF_WORKTOPS}/cabinet:{BIF_WALL_CABINET}/condition:{BIF_CONDITION}',
      '{F_BUILT_IN_FITTINGS}::{REPAIR_FITTING_NOW}':
          'repair-now=loc:{BIFR_RF_NOW_LOCATION}/defect:{BIFR_RF_NOW_DEFECT}',
      '{F_BUILT_IN_FITTINGS}::{REPAIR_FITTING_SOON}':
          'repair-soon=loc:{BIFR_RF_SOON_LOCATION}/defect:{BIFR_RF_SOON_DEFECT}',
      '{F_BUILT_IN_FITTINGS}::{IF_PARTLY_ROTTED_IS_SELECTED}': 'rot-advice',
      '{F_BUILT_IN_FITTINGS}::{DEFECTIVE_SEALANTS}':
          'sealants=loc:{BIFR_DS_LOCATION}/defect:{BIFR_DS_DEFECT}',
      '{F_BUILT_IN_FITTINGS}::{MOULDING_NOTED}':
          'moulding=loc:{BIFR_MN_LOCATION}',
      '{F_BUILT_IN_FITTINGS}::{REPAIR_WATER_SEEPAGE}':
          'water-seepage=loc:{BIFR_WS_LOCATION}',
      '{F_BUILT_IN_FITTINGS}::{NOT_INSPECTED}': 'not-inspected',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('about built-in fittings resolves location, worktop, cabinet and condition', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_built_in_fittings',
        {
          'cb_kitchen': 'true',
          'cb_timber_83': 'true',
          'cb_timber': 'true',
          'android_material_design_spinner3': 'Reasonable',
        },
      );
      expect(phrases, hasLength(1));
      final all = phrases.first.toLowerCase();
      expect(all, contains('loc:kitchen'));
      expect(all, contains('worktop:timber'));
      expect(all, contains('cabinet:timber'));
      expect(all, contains('condition:reasonable'));
    });

    test('about built-in fittings with nothing answered emits nothing', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_built_in_fittings',
        const <String, String>{},
      );
      expect(phrases, isEmpty);
    });

    test('repair now appends rot advice when partly rotted is selected', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_built_in_fittings_repair_fittings',
        {
          'actv_repair_type': 'Repair now',
          'cb_kitchen': 'true',
          'cb_partly_rotted_19': 'true',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('repair-now=loc:kitchen/defect:partly rotted'));
      expect(all, contains('rot-advice'));
    });

    test('repair now without rot defect does not append rot advice', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_built_in_fittings_repair_fittings',
        {
          'actv_repair_type': 'Repair now',
          'cb_kitchen': 'true',
          'cb_badly_worn_16': 'true',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('defect:badly worn'));
      expect(all, isNot(contains('rot-advice')));
    });

    test('repair soon resolves location and defect', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_built_in_fittings_repair_fittings',
        {
          'actv_repair_type': 'Repair soon',
          'cb_kitchen_51': 'true',
          'cb_worn': 'true',
        },
      );
      expect(phrases.single.toLowerCase(),
          contains('repair-soon=loc:kitchen/defect:worn'));
    });

    test('defective sealants resolves location and defect', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_built_in_fittings_repair_defective_sealants',
        {
          'cb_kitchen_sink': 'true',
          'cb_damaged_38': 'true',
        },
      );
      expect(phrases.single.toLowerCase(),
          contains('sealants=loc:kitchen sink/defect:damaged'));
    });

    test('moulding noted resolves location', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_built_in_fittings_repair_moulding_noted',
        {'cb_kitchen_sink': 'true'},
      );
      expect(phrases.single.toLowerCase(), contains('moulding=loc:kitchen sink'));
    });

    test('water seepage resolves location', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_built_in_fittings_repair_water_seepage',
        {'cb_Hidden_parts': 'true'},
      );
      expect(
          phrases.single.toLowerCase(), contains('water-seepage=loc:hidden parts'));
    });

    test('not inspected is gated on its checkbox', () {
      final checked = engine.buildPhrases(
        'activity_in_side_property_built_in_fittings_not_inspected',
        {'cb_not_inspected': 'true'},
      );
      expect(checked, hasLength(1));
      expect(checked.first.toLowerCase(), contains('not-inspected'));

      final unchecked = engine.buildPhrases(
        'activity_in_side_property_built_in_fittings_not_inspected',
        const <String, String>{},
      );
      expect(unchecked, isEmpty);
    });
  });
}
