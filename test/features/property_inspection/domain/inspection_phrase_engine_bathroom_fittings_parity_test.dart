import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - F8 Bathroom Fittings parity', () {
    const phraseTexts = <String, String>{
      '{F_BATHROOM_FITTINGS}::{BATHROOM_FITTINGS}':
          'about=loc:{BF_BF_LOCATION}/madeup:{BF_BF_MADE_UP}/fittings:{BF_BF_FITTINGS}/condition:{BF_BF_CONDITION}',
      '{F_BATHROOM_FITTINGS}::{EXTRACTOR_FAN_INSTALLED_OK}':
          'fan-ok=loc:{BF_EF_EFI_OK_LOCATION}/tested:{BF_EF_EFI_OK_TESTED}',
      '{F_BATHROOM_FITTINGS}::{EXTRACTOR_FAN_INSTALLED_REPLACE}':
          'fan-replace=loc:{BF_EF_EFI_REPLACE_LOCATION}/defect:{BF_EF_EFI_REPLACE_DEFECT}',
      '{F_BATHROOM_FITTINGS}::{EXTRACTOR_FAN_CONDENSATION_NOTED}':
          'no-fan-condensation={BF_EF_NEFI_LOCATION}',
      '{F_BATHROOM_FITTINGS}::{EXTRACTOR_FAN_NO_INSTALLED}':
          'no-fan-ok={BF_EF_NEFI_LOCATION}',
      '{F_BATHROOM_FITTINGS}::{LEAKING_SEALANTS}':
          'leaking={BF_LS_LOCATION}/{IS_ARE}',
      '{F_BATHROOM_FITTINGS}::{SEALANT_CONDITION}':
          'sealant=around:{BF_SC_SEALANTS_AROUND}/defect:{BF_SC_DEFECT}',
      '{F_BATHROOM_FITTINGS}::{MOULDING}': 'moulding={BF_MOULDING_NOTED}',
      '{F_BATHROOM_FITTINGS}::{WOOD_ROT}':
          'wood-rot=item:{BF_WR_ITEM}/loc:{BF_WR_LOCATION}/defect:{BF_WR_DEFECT}',
      '{F_BATHROOM_FITTINGS}::{NO_CUBICAL_SG_RATING}':
          'no-sg-rating={BF_NCS_GR_MARK_NOTED}',
      '{F_BATHROOM_FITTINGS}::{IF_CRACKED_OR_POORLY_SECURED_IS_SELECTED}':
          'safety-hazard',
      '{F_BATHROOM_FITTINGS}::{BATHROOM_FITTINGS_REPAIR_SOON}':
          'repair-soon=loc:{BFR_SOON_LOCATION}/defect:{BFR_SOON_DEFECT}/{IS_ARE}',
      '{F_BATHROOM_FITTINGS}::{BATHROOM_FITTINGS_REPAIR_NOW}':
          'repair-now=loc:{BFR_NOW_LOCATION}/defect:{BFR_NOW_DEFECT}/{IS_ARE}',
      '{F_BATHROOM_FITTINGS}::{NOT_INSPECTED}': 'not-inspected',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('about bathroom fittings resolves location, made-up, fittings and condition', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_bathroom_fittings_second',
        {
          'cb_bathroom': 'true',
          'cb_modern_72': 'true',
          'cb_bathtub_32': 'true',
          'android_material_design_spinner3': 'Reasonable',
        },
      );
      expect(phrases, hasLength(1));
      final all = phrases.first.toLowerCase();
      expect(all, contains('loc:bathroom'));
      expect(all, contains('madeup:modern'));
      expect(all, contains('fittings:bathtub'));
      expect(all, contains('condition:reasonable'));
    });

    test('about bathroom fittings with nothing answered emits nothing', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_bathroom_fittings_second',
        const <String, String>{},
      );
      expect(phrases, isEmpty);
    });

    test('extractor fan ok vs replace', () {
      final ok = engine.buildPhrases(
        'activity_in_side_property_bathroom_fittings_extractor_fan',
        {
          'actv_status': 'OK',
          'cb_bathroom_56': 'true',
          'cb_was_switched_on_and_it_was_35': 'true',
        },
      );
      expect(ok.single.toLowerCase(), contains('fan-ok=loc:bathroom'));

      final replace = engine.buildPhrases(
        'activity_in_side_property_bathroom_fittings_extractor_fan',
        {
          'actv_status': 'Replace',
          'cb_bathroom_56': 'true',
          'cb_was_not_working': 'true',
        },
      );
      expect(replace.single.toLowerCase(),
          contains('fan-replace=loc:bathroom/defect:was not working'));
    });

    test('no extractor fan installed - condensation noted vs no condensation', () {
      final noted = engine.buildPhrases(
        'activity_in_side_property_bathroom_fittings_extractor_fan__no_extractor_fan_installed',
        {
          'actv_status_new': 'condensation noted',
          'cb_bathroom_56_wef': 'true',
        },
      );
      expect(noted.single.toLowerCase(),
          contains('no-fan-condensation=bathroom'));

      final none = engine.buildPhrases(
        'activity_in_side_property_bathroom_fittings_extractor_fan__no_extractor_fan_installed',
        {
          'actv_status_new': 'no condensation',
          'cb_bathroom_56_wef': 'true',
        },
      );
      expect(none.single.toLowerCase(), contains('no-fan-ok=bathroom'));
    });

    test('leaking sealants resolves location', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_bathroom_fittings_leaking',
        {'cb_bathtub': 'true'},
      );
      expect(phrases.single.toLowerCase(), contains('leaking=bathtub'));
    });

    test('sealant condition resolves area and defect', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_bathroom_fittings_sealant',
        {
          'cb_bathtub': 'true',
          'cb_partly_missing': 'true',
        },
      );
      expect(phrases.single.toLowerCase(),
          contains('sealant=around:bathtub/defect:partly missing'));
    });

    test('moulding resolves location', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_bathroom_fittings_mould',
        {'cb_wash_hand_basin': 'true'},
      );
      expect(
          phrases.single.toLowerCase(), contains('moulding=wash hand basin'));
    });

    test('wood rot resolves item, location and defect', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_bathroom_fittings_wood_rot',
        {
          'cb_cupboards': 'true',
          'cb_bathtub_37': 'true',
          'cb_partly_rotted_20': 'true',
        },
      );
      expect(
        phrases.single.toLowerCase(),
        contains('wood-rot=item:cupboards/loc:bathtub/defect:partly rotted'),
      );
    });

    test('cubicle safety glass rating resolves location', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_cubicle_safety_glass_rating',
        {'cb_shower_cubicle': 'true'},
      );
      expect(phrases.single.toLowerCase(),
          contains('no-sg-rating=shower cubicle'));
    });

    test('repair now appends safety hazard when badly cracked is selected', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_bathroom_fittings_repair',
        {
          'actv_repair_type': 'Repair now',
          'cb_bathtub_52': 'true',
          'cb_badly_cracked_62': 'true',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('repair-now=loc:bathtub'));
      expect(all, contains('safety-hazard'));
    });

    test('repair soon resolves location and defect', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_bathroom_fittings_repair',
        {
          'actv_repair_type': 'Repair soon',
          'cb_bathtub': 'true',
          'cb_worn': 'true',
        },
      );
      expect(phrases.single.toLowerCase(),
          contains('repair-soon=loc:bathtub/defect:worn'));
    });

    test('not inspected is gated on its checkbox', () {
      final checked = engine.buildPhrases(
        'activity_in_side_property_bathroom_fitting_not_inspected',
        {'cb_not_inspected': 'true'},
      );
      expect(checked, hasLength(1));
      expect(checked.first.toLowerCase(), contains('not-inspected'));

      final unchecked = engine.buildPhrases(
        'activity_in_side_property_bathroom_fitting_not_inspected',
        const <String, String>{},
      );
      expect(unchecked, isEmpty);
    });
  });
}
