import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - F2 Ceilings parity', () {
    const phraseTexts = <String, String>{
      '{F_CEILINGS}':
          '{STANDARD_TEXT}<br />\\r\\n<br />\\r\\n{ABOUT_CONSTRUCTION} {ABOUT_FINISHES} {ABOUT_CONDITION}<br />\\r\\n<br />\\r\\n{CRACKS}<br />\\r\\n<br />\\r\\n{CONTAINS_ASBESTOS}<br />\\r\\n<br />\\r\\n{POLYSTYRENE}<br />\\r\\n<br />\\r\\n{HEAVY_PAPER_LINING}<br />\\r\\n<br />\\r\\n{REPAIRS_CELLINGS_SOON}<br />\\r\\n<br />\\r\\n{REPAIRS_CELLINGS_NOW}<br />\\r\\n<br />\\r\\n{IF_LATH_AND_PLASTER_IS_SELECTED}<br />\\r\\n<br />\\r\\n{IF_TEXTURED_IS_SELECTED}<br />\\r\\n<br />\\r\\n{ORNAMENTAL_PLASTER}<br />\\r\\n<br />\\r\\n{CONDITION_RATING}<br />\\r\\n<br />\\r\\n{NOTES}',
      '{F_CEILINGS}::{ABOUT_CONSTRUCTION}':
          'construction={CE_AC_MADE_UP}/{CE_AC_MATERIAL}',
      '{F_CEILINGS}::{ABOUT_FINISHES}': 'finishes={CE_AC_FINISHES_TYPE}',
      '{F_CEILINGS}::{ABOUT_CONDITION}': 'condition={CE_AC_CONDITION}',
      '{F_CEILINGS}::{CRACKS}': 'cracks={CE_CR_NOTED}',
      '{F_CEILINGS}::{CONTAINS_ASBESTOS}': 'asbestos={CE_CA_LOCATION}',
      '{F_CEILINGS}::{POLYSTYRENE}': 'polystyrene',
      '{F_CEILINGS}::{HEAVY_PAPER_LINING}': 'heavy-paper',
      '{F_CEILINGS}::{REPAIRS_CELLINGS_SOON}':
          'repair-soon=loc:{CER_RC_SOON_LOCATION}/defect:{CER_RC_SOON_DEFECT}',
      '{F_CEILINGS}::{REPAIRS_CELLINGS_NOW}':
          'repair-now=loc:{CER_RC_NOW_LOCATION}/defect:{CER_RC_NOW_DEFECT}',
      '{F_CEILINGS}::{ORNAMENTAL_PLASTER}': 'ornamental={CER_OP_DEFECT}',
      '{F_CEILINGS}::{NOT_INSPECTED}': 'not-inspected',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('about ceilings emits construction, finishes and condition', () {
      final phrases = engine.buildPhrases(
        'inside_property_ceilings_about_ceilings',
        {
          'actv_made_up': 'mainly of ',
          'cb_modern_plasterboard': 'true',
          'cb_painted': 'true',
          'actv_condition': 'Reasonable',
        },
      );
      expect(phrases, hasLength(1));
      final all = phrases.first.toLowerCase();
      expect(all, contains('construction=mainly of/modern plasterboard'));
      expect(all, contains('finishes=painted'));
      expect(all, contains('condition=reasonable'));
    });

    test('about ceilings with nothing answered emits nothing', () {
      final phrases = engine.buildPhrases(
        'inside_property_ceilings_about_ceilings',
        const <String, String>{},
      );
      expect(phrases, isEmpty);
    });

    test('cracks resolves the checked locations', () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_ceilings_cracks',
        {'cb_ceiling_junction_with_walls': 'true', 'cb_plasterboard_joints': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(),
          contains('cracks=ceiling junction with walls and plasterboard joints'));
    });

    test('contains asbestos resolves the checked rooms', () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_ceilings_contains_asbestos',
        {'cb_kitchen': 'true', 'cb_bathroom': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('asbestos=kitchen and bathroom'));
    });

    test('polystyrene fires only when its checkbox is checked', () {
      final checked = engine.buildPhrases(
        'activity_inside_property_ceilings_polystyrene',
        {'cb_not_inspected': 'true'},
      );
      expect(checked, hasLength(1));
      expect(checked.first.toLowerCase(), contains('polystyrene'));

      final unchecked = engine.buildPhrases(
        'activity_inside_property_ceilings_polystyrene',
        const <String, String>{},
      );
      expect(unchecked, isEmpty);
    });

    test('heavy paper lining fires only when its checkbox is checked', () {
      final checked = engine.buildPhrases(
        'activity_inside_property_ceilings_heavy_paper_lining',
        {'cb_not_inspected': 'true'},
      );
      expect(checked, hasLength(1));
      expect(checked.first.toLowerCase(), contains('heavy-paper'));
    });

    test('repair now resolves location and defect', () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_ceilings_repairs_ceilings',
        {
          'actv_status': 'Repair now',
          'cb_lounge': 'true',
          'cb_badly_cracked': 'true',
        },
      );
      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(),
          contains('repair-now=loc:lounge/defect:badly cracked'));
    });

    test('repair soon resolves location and defect', () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_ceilings_repairs_ceilings',
        {
          'actv_status': 'Repair soon',
          'cb_bedroom_61': 'true',
          'cb_sagging_45': 'true',
        },
      );
      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(),
          contains('repair-soon=loc:bedroom/defect:sagging'));
    });

    test('ornamental plaster resolves the checked defect', () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_ceilings_repairs_ornamental_plaster',
        {'cb_badly_cracked_88': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('ornamental=badly cracked'));
    });

    test('not inspected is gated on its checkbox', () {
      final checked = engine.buildPhrases(
        'activity_inside_property_ceilings_not_inspected',
        {'cb_not_inspected': 'true'},
      );
      expect(checked, hasLength(1));
      expect(checked.first.toLowerCase(), contains('not-inspected'));

      final unchecked = engine.buildPhrases(
        'activity_inside_property_ceilings_not_inspected',
        const <String, String>{},
      );
      expect(unchecked, isEmpty);
    });
  });
}
