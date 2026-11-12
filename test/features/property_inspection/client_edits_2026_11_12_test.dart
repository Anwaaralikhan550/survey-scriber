// Client file (6), 12 Nov 2026: the clear items.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';

void main() {
  final phraseTexts = (jsonDecode(
    File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
  ) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v?.toString() ?? ''));
  final engine = InspectionPhraseEngine(phraseTexts);
  final tree = InspectionTreePayload.fromJson(File('assets/property_inspection/inspection_tree.json').readAsStringSync());
  final nodes = {for (final s in tree.sections) for (final n in s.nodes) n.id: n};

  Map<String, String> ticks(List<String> ids, [Map<String, String> extra = const {}]) =>
      {for (final i in ids) i: 'true', ...extra};
  String say(String screen, Map<String, String> answers) => engine.buildPhrases(screen, answers).join(' ');
  List<String> labels(String screen) => nodes[screen]!.fields.map((f) => f.label).toList();

  group('N1 Property Type: house and flat', () {
    test('two new ticks at the end, before Other', () {
      final l = labels('activity_property_type');
      expect(l.indexOf('house'), l.indexOf('cottage') + 1);
      expect(l.indexOf('flat'), l.indexOf('house') + 1);
      expect(l.indexOf('Other'), l.indexOf('flat') + 1);
    });
    test('they print in the sentence', () {
      final out = say('activity_property_type', ticks(['cb_a2_type', 'a2t_house'], {'actv_a2_bedrooms': 'Three'}));
      expect(out, contains('The property is a house'));
      final both = say('activity_property_type', ticks(['cb_a2_type', 'a2t_detached', 'a2t_flat'], {'actv_a2_bedrooms': 'Two'}));
      expect(both, contains('detached and flat'));
    });
  });
}
