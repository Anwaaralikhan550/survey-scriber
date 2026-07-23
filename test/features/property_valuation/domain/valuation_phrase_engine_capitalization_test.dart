import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_catalog.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_engine.dart';

/// Phase 6b regression suite: free-text fields typed lowercase by a
/// surveyor on site must not produce a lowercase sentence subject or a
/// lowercase sentence following a full stop in the assembled RICS report.
void main() {
  final engine = ValuationPhraseEngine();

  group('ValuationPhraseEngine - free-text capitalization', () {
    test('other roof name is capitalized when used as sentence subject', () {
      final phrases = engine.buildPhrases('val_other_roof', {
        'et_other_roof_name': 'the old barn roof',
        'cb_tile_or': 'true',
      });

      expect(phrases, isNotEmpty);
      expect(phrases.first, startsWith('The old barn roof is covered with'));
    });

    test('other roof falls back to default label when name is empty', () {
      final phrases = engine.buildPhrases('val_other_roof', {
        'cb_tile_or': 'true',
      });

      expect(phrases, isNotEmpty);
      expect(phrases.first, startsWith('The secondary roof is covered with'));
    });

    test('other-matters note is capitalized when appended mid-sentence', () {
      final phrases = engine.buildPhrases('other_matters', {
        'cb_building_regs': 'true',
        'et_notes_building_regs': 'permit was granted in 2019',
      });

      expect(phrases, hasLength(1));
      expect(phrases.first, contains('. Permit was granted in 2019'));
      expect(phrases.first, isNot(contains('. permit was granted')));
    });

    test('condition notes are capitalized as their own sentence', () {
      final phrases = engine.buildPhrases('val_pitched_roof', {
        'cb_tile': 'true',
        'actv_condition_pitched_roof': 'Unsatisfactory',
        'et_notes_pitched_roof': 'water ingress noted at ridge line',
      });

      expect(phrases, isNotEmpty);
      expect(
        phrases.any((p) => p.startsWith('Water ingress noted at ridge line')),
        isTrue,
      );
    });

    test('general remarks are capitalized', () {
      final phrases = engine.buildPhrases('general_remarks', {
        'et_general_remarks': 'client requested early completion',
      });

      expect(phrases, hasLength(1));
      expect(phrases.first, 'Client requested early completion');
    });

    test('empty free text remains empty (no crash on empty string index)', () {
      final phrases = engine.buildPhrases('general_remarks', {
        'et_general_remarks': '',
      });

      expect(phrases, isEmpty);
    });

    test('already-capitalized free text is left unchanged', () {
      final phrases = engine.buildPhrases('general_remarks', {
        'et_general_remarks': 'Already capitalized text.',
      });

      expect(phrases, hasLength(1));
      expect(phrases.first, 'Already capitalized text.');
    });

    test('raw option and impossible flat wording are suppressed', () {
      final phrases = engine.buildPhrases('general_details', {
        'actv_status': 'Occupied',
        'actv_finishes': 'Fully furnished',
        'actv_weather': 'Snow',
        'actv_type': 'Flat',
        'actv_sub_type': 'Detached',
        'actv_flat_type': 'Flat',
        'actv_build_type': 'Purpose built',
        'actv_vl_reason': 'Other',
      });

      final joined = phrases.join('\n');
      expect(joined, isNot(contains('property was with')));
      expect(joined, isNot(contains('detached flat')));
      expect(joined, isNot(contains('flat type')));
      expect(joined, isNot(contains('weather conditions were snow.')));
      expect(joined, isNot(contains('purpose of this valuation is for Other')));
    });

    test('generic other warranty is not emitted without a real warranty name',
        () {
      final phrases = engine.buildPhrases('new_build_property', {
        'actv_work_stage': 'Complete',
        'actv_warranty': 'Other',
      });

      final joined = phrases.join('\n');
      expect(joined, isNot(contains('Other structural warranty')));
      expect(joined, contains('construction works were complete'));
      expect(joined, isNot(contains('complete stage')));
    });
  });

  test('phrase catalog does not approve arbitrary prose through free text', () {
    final catalog = ValuationPhraseCatalog.fromLegacyMap(const {
      'NOTE': '[free text]',
      'VALID': 'The agreed purchase price is [free text].',
    });

    expect(
      catalog.matchTemplateId('The spaceship engine requires replacement.'),
      isNull,
    );
    expect(
      catalog.matchTemplateId('The agreed purchase price is £250,000.'),
      'VALID',
    );
  });
}
