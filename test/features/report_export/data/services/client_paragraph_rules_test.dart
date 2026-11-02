// Client edits 2 Nov 2026: his corrected text, word for word.
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/report_export/data/services/client_paragraph_rules.dart';

void main() {
  const chimney = 'group_e1_chimney_5';

  group('Chimney', () {
    test('Description is one paragraph without inner titles', () {
      expect(
        applyClientParagraphRules(chimney, [
          'Description: The chimney stack(s) are constructed of brick. The chimney stack(s) appear '
              'original. Pots: The chimney stack(s) are fitted with clay pots and metal flues. '
              'Number: The property has two stacks(s).',
          'Location: The chimney stack(s) are located to the rear and centre.',
        ]),
        [
          'Description: The chimney stack(s) are constructed of brick. The chimney stack(s) appear '
              'original. The chimney stack(s) are fitted with clay pots and metal flues. The property '
              'has two stack(s), and the chimney stack(s) are located to the rear and centre.',
        ],
      );
    });

    test('Waterproofing: each item its own paragraph, "Condition:" title removed', () {
      expect(
        applyClientParagraphRules(chimney, [
          'Flashings: The waterproofing between the chimney stack and the roof covering (called the '
              'flashing) appears to be formed in lead. Condition: Where visible, the flashings appear '
              'in good condition. Defective flashings may allow water penetration and should be '
              'repaired by an appropriately qualified roofing contractor. Flaunching: The cement '
              'bedding around the base of the chimney pot (called flaunching) appears to be formed in '
              'mortar. Condition: Where visible, the flaunching appears in good condition. Defective '
              'flaunching may permit water penetration and reduce the stability of chimney pots. '
              'Repairs should be undertaken as part of routine maintenance or sooner where '
              'deterioration is significant. Pointing Condition: The mortar joints to the chimney '
              'stack appear in reasonable condition(s). Weathered or eroded pointing should be renewed '
              'to reduce further deterioration and water penetration. Damaged chimney pots: The '
              'chimney pots appear secure and weathered. Damaged or insecure chimney pots should be '
              'repaired or replaced to maintain weather resistance and safety.',
        ]),
        [
          'Flashings: The waterproofing between the chimney stack and the roof covering (called the '
              'flashing) appears to be formed in lead. Where visible, the flashings appear in good '
              'condition. Defective flashings may allow water penetration and should be repaired by '
              'an appropriately qualified roofing contractor.',
          'Flaunching: The cement bedding around the base of the chimney pot (called flaunching) '
              'appears to be formed in mortar. Where visible, the flaunching appears in good '
              'condition. Defective flaunching may permit water penetration and reduce the stability '
              'of chimney pots. Repairs should be undertaken as part of routine maintenance or sooner '
              'where deterioration is significant.',
          'Pointing Condition: The mortar joints to the chimney stack appear in reasonable '
              'condition(s). Weathered or eroded pointing should be renewed to reduce further '
              'deterioration and water penetration.',
          'Damaged chimney pots: The chimney pots appear secure and weathered. Damaged or insecure '
              'chimney pots should be repaired or replaced to maintain weather resistance and safety.',
        ],
      );
    });

    test('Aerials and Chimney Defects are separate; "including:" is not a title', () {
      expect(
        applyClientParagraphRules(chimney, [
          'Aerials and satellite dishes: An aerial is attached to the chimney stack. Where secure, no '
              'action is currently required. Chimney Defects: One or more chimney defects were '
              'observed, including: missing flashings and spalled bricks. Repairs should be undertaken.',
        ]),
        [
          'Aerials and satellite dishes: An aerial is attached to the chimney stack. Where secure, no '
              'action is currently required.',
          'Chimney Defects: One or more chimney defects were observed, including: missing flashings '
              'and spalled bricks. Repairs should be undertaken.',
        ],
      );
    });

    test('the general chimney Condition keeps its title', () {
      const condition = 'Condition: Where visible, the chimney stack(s) appear in good condition.';
      expect(applyClientParagraphRules(chimney, [condition]), [condition]);
    });
  });

  test('Main Walls: the paragraph breaks he marked in red', () {
    expect(
      applyClientParagraphRules('group_e4_main_walls_15', [
        'Description: The external walls of the main building are constructed of 250 mm solid brick. '
            'Condition: Where visible, the walls appear in reasonable condition, consistent with their '
            'age and type of construction. No repair required: No significant defects requiring '
            'immediate attention were identified unless otherwise stated below. Routine maintenance '
            'should be expected. Painted Walls: The external wall surfaces, or parts of them, have '
            'been painted.',
      ]),
      [
        'Description: The external walls of the main building are constructed of 250 mm solid brick.',
        'Condition: Where visible, the walls appear in reasonable condition, consistent with their '
            'age and type of construction.',
        'No repair required: No significant defects requiring immediate attention were identified '
            'unless otherwise stated below. Routine maintenance should be expected.',
        'Painted Walls: The external wall surfaces, or parts of them, have been painted.',
      ],
    );
  });

  test('Rain Water Goods, Conservatory and Other Joinery split the same way', () {
    expect(
      applyClientParagraphRules('group_e3_rain_water_goods_13',
          ['Condition: Where visible, fine. No repair required: None needed.']),
      ['Condition: Where visible, fine.', 'No repair required: None needed.'],
    );
    expect(
      applyClientParagraphRules('group_e7_conservatory_and_porches_26',
          ['Condition: Doors fine. No defects noted: None.']),
      ['Condition: Doors fine.', 'No defects noted: None.'],
    );
    expect(
      applyClientParagraphRules('group_e8_other_joinery_and_finishes_31',
          ['Inspected: Could not inspect. Inspected: From ground level.']),
      ['Inspected: Could not inspect.', 'Inspected: From ground level.'],
    );
  });

  test('condition rating stands alone so it can print bold', () {
    expect(
      applyClientParagraphRules('group_e4_main_walls_15', [
        'Some walls. Condition rating is: 1. The element(s) are performing their intended function.',
      ]),
      [
        'Some walls.',
        'Condition rating is: 1.',
        'The element(s) are performing their intended function.',
      ],
    );
  });

  test('elements he did not name are left alone', () {
    const doors = 'Condition: Doors fine. No defects noted: None.';
    expect(applyClientParagraphRules('group_e6_outside_doors_23', [doors]), [doors]);
    expect(applyClientParagraphRules('group_e2_roof_covering_9', [doors]), [doors]);
  });

  group('Cellar/Basement', () {
    const inside = 'group_f9_other_81';

    test('his heading, his labels and his order', () {
      expect(
        applyClientParagraphRules(inside, [
          'Condition rating is: 2.',
          'General Maintenance: Ancillary internal areas should be inspected periodically.',
          'Description: Internal communal parts to the property comprise a hallway.',
          'Cellar/Basement Not inspected: The property has a cellar or basement, but it could not be inspected.',
          'Walls: The property incorporates a cellar, basement and the walls are formed in bricks materials.',
          'Floor: The floor is constructed of stone.',
          'Condition: Where visible, the cellar appears in good condition. Minor dampness may be expected. '
              'No defects noted: No significant defects requiring immediate attention were identified unless '
              'otherwise stated below. Routine maintenance is recommended.',
          'In use: The cellar or basement has been adapted for use as storage or other uses.',
          'Timber decay: Decay was noted in exposed floor joists within the cellar.',
          'Repair: The landing areas are worn.',
        ]),
        [
          'Condition rating is: 2.',
          'Description: Internal communal parts to the property comprise a hallway.',
          '[[SUBHEADING]] Cellar/Basement',
          'Not inspected: The property has a cellar or basement, but it could not be inspected.',
          'Walls: The property incorporates a cellar, basement and the walls are formed in bricks materials.',
          'Floor: The floor is constructed of stone.',
          'Condition: Where visible, the cellar appears in good condition. Minor dampness may be expected.',
          'No defects noted: No significant defects requiring immediate attention were identified unless '
              'otherwise stated below. Routine maintenance is recommended.',
          'In use: The cellar or basement has been adapted for use as storage or other uses.',
          'Timber decay: Decay was noted in exposed floor joists within the cellar.',
          'General Maintenance: Ancillary internal areas should be inspected periodically.',
          'Repair: The landing areas are worn.',
        ],
      );
    });

    test('no cellar answers: nothing is added or moved', () {
      const phrases = [
        'General Maintenance: Ancillary internal areas should be inspected periodically.',
        'Description: Internal communal parts to the property comprise a hallway.',
      ];
      expect(applyClientParagraphRules(inside, phrases), phrases);
    });
  });
}
