import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/core/sync/legacy_main_walls_sync_mapping.dart';

void main() {
  group('LegacyMainWallsSyncMapping', () {
    test('builds legacy remote answers for solid brick wall screen', () {
      final remote = LegacyMainWallsSyncMapping.buildRemoteAnswers(
        LegacyMainWallsSyncMapping.solidBrickScreenId,
        <String, String>{
          'cb_main_building': 'true',
          'cb_extension': 'true',
          'et_thickness': '225',
          'actv_finishes': 'Fully',
          'actv_rendered': 'smooth',
          'cb_painted': 'true',
          'cb_mock_tudor': 'true',
          'cb_is_weathered': 'true',
          'actv_condition': 'Reasonable',
        },
      );

      expect(
        remote,
        equals(<String, String>{
          'mw_sbbw_wall': 'Main building, Extension',
          'mw_sbbw_thickness': '225',
          'mw_sbbw_finishes': 'Fully',
          'mw_sbbw_rendered': 'smooth',
          'mw_sbbw_finishes_type': 'Painted, Mock Tudor Wall',
          'mw_sbbw_wathered_wall': 'true',
          'mw_sbbw_condition': 'Reasonable',
        }),
      );
    });

    test('decodes legacy wall locations back to local answers', () {
      final decoded = LegacyMainWallsSyncMapping.decodeRemoteAnswer(
        'mw_cbrw_wall',
        'Main building, Rear wing',
      );

      expect(decoded, isNotNull);
      expect(
        decoded!.screenId,
        LegacyMainWallsSyncMapping.cavityBrickScreenId,
      );
      expect(
        decoded.localAnswers,
        containsPair('cb_main_building', 'true'),
      );
      expect(decoded.localAnswers, containsPair('cb_other_832', 'true'));
      expect(decoded.localAnswers, containsPair('et_other_133', 'Rear wing'));
    });

    test('decodes legacy finishes types back to local answers', () {
      final decoded = LegacyMainWallsSyncMapping.decodeRemoteAnswer(
        'mw_othw_finishes_type',
        'Pebble dash, Stone slips',
      );

      expect(decoded, isNotNull);
      expect(
        decoded!.screenId,
        LegacyMainWallsSyncMapping.otherScreenId,
      );
      expect(decoded.localAnswers, containsPair('cb_pebble_dash', 'true'));
      expect(decoded.localAnswers, containsPair('cb_other_327', 'true'));
      expect(decoded.localAnswers, containsPair('et_other_444', 'Stone slips'));
    });
  });
}
