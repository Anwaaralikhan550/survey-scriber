import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/report_export/data/services/paragraph_composer.dart';

void main() {
  late ParagraphComposer composer;

  setUpAll(() {
    final phraseTexts = (jsonDecode(
      File('assets/property_inspection/phrase_texts.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v.toString()));
    composer = ParagraphComposer(phraseTexts);
  });

  group('ParagraphComposer - client-reported porch example', () {
    test('porch element sentences merge into a single paragraph', () {
      // Exact sentences from the client's Home Survey report feedback:
      // "This should be a paragraph and not separate sentences as they
      //  belong to the same element." Updated (Phase 2B, E7) to the RICS
      // L2 wording that replaced the original pre-migration sentences.
      final input = <String>[
        'Description: The porch is located to the front of the building. '
            'The walls comprise brick walls and timber double glazed '
            'sections. The porch appears to be a later addition to the '
            'property. Your legal adviser should confirm whether any '
            'necessary Building Regulation approval or exemption applies, '
            'together with any guarantees or warranties available.',
        'Roof: The roof over the porch is formed in concrete tiles.',
        'Doors and Windows: The porch comprises double glazed pvc framed '
            'door(s).',
        'The porch also comprises double glazed pvc framed window(s).',
        'Floor: The porch floor is covered with tiles and laminate flooring.',
      ];

      final output = composer.compose(input);

      // Master template {E_CONSERVATORY_PORCHES} paragraph groups:
      //   {PORCH_LOCATION_CONSTRUCTION} {PORCH_SAFETY_GLASS_RATING}
      //   <br/><br/>
      //   {PORCH_ROOF} {PORCH_DOORS} {PORCH_WINDOWS} {PORCH_FLOOR} ...
      // So: location+construction is its own paragraph; roof/doors/windows/
      // floor merge into one.
      expect(output.length, lessThan(input.length),
          reason: 'same-element sentences must merge');
      final roofParagraph =
          output.firstWhere((p) => p.contains('Roof: The roof over the porch'));
      expect(roofParagraph, contains('door(s)'));
      expect(roofParagraph, contains('window(s)'));
      expect(roofParagraph, contains('Floor: The porch floor is covered with'));
    });

    test('open-to-building stays its own paragraph', () {
      final input = <String>[
        'Roof: The roof over the porch is formed in concrete tiles.',
        'Doors and Windows: The porch comprises double glazed pvc framed '
            'door(s).',
        'The porch is open to the main part of the property, and this will '
            'result in a high rate of heat loss from the property. A '
            'separating door should be fitted between them soon.',
      ];

      final output = composer.compose(input);

      expect(
        output.length,
        2,
        reason: 'roof+doors merge; open-to-building is a separate '
            'paragraph group in the master template',
      );
      expect(output.last, startsWith('The porch is open to the main part'));
    });
  });

  group('ParagraphComposer - client-reported construction example', () {
    test('D_CONSTRUCTION element sentences merge into one paragraph', () {
      // From the client's report sample under "Construction".
      final input = <String>[
        'The property is believed to be constructed using cavity wall '
            'construction.',
        'The external walls are constructed of cavity brick wall '
            'construction.',
        'Internal walls are formed in stud and solid partitions.',
        'The windows are fitted with uPVC frames incorporating double '
            'glazing.',
      ];

      final output = composer.compose(input);

      expect(output, hasLength(1),
          reason: 'all D_CONSTRUCTION sentences share one paragraph group');
      expect(output.single, contains('cavity wall construction'));
      expect(output.single, contains('Internal walls'));
      expect(output.single, contains('windows'));
    });
  });

  group('ParagraphComposer - protected lines', () {
    test('subheadings, ratings and notes never merge', () {
      final input = <String>[
        '[[SUBHEADING]] Porch',
        'Roof: The roof over the porch is formed in concrete tiles.',
        'Doors and Windows: The porch comprises double glazed pvc framed '
            'door(s).',
        'Condition rating is: 2.',
        'Notes: check flashing next visit.',
      ];

      final output = composer.compose(input);

      expect(output.first, '[[SUBHEADING]] Porch');
      expect(output, contains('Condition rating is: 2.'));
      expect(output, contains('Notes: check flashing next visit.'));
      // Roof + doors merge; protected lines stay standalone.
      expect(output, hasLength(4));
    });

    test('unrecognised phrases pass through untouched', () {
      final input = <String>[
        'Completely custom surveyor remark with no bank counterpart.',
        'Another free-form remark.',
      ];

      expect(composer.compose(input), equals(input));
    });

    test('single phrase list returned as-is', () {
      final input = <String>['Only one sentence.'];
      expect(composer.compose(input), equals(input));
    });

    test('sentences from different masters do not merge', () {
      final input = <String>[
        'Roof: The roof over the porch is formed in concrete tiles.',
        'The internal walls are built of stud partitions.',
      ];

      final output = composer.compose(input);
      expect(
        output,
        hasLength(2),
        reason: 'porch roof and D_CONSTRUCTION belong to different '
            'master templates',
      );
    });
  });
}
