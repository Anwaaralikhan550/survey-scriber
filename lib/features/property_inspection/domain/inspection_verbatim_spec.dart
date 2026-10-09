part of 'inspection_phrase_engine.dart';

/// Data-driven phrase rules for the PDF-verbatim completion work.
///
/// A rule says: "when this screen is built, take the approved bank sentence
/// `master::sub`, fill its `{TOKEN}`s from the form, and emit it". Tokens are
/// filled from checkbox groups (joined "a, b and c"), a dropdown or a text
/// field. A rule fires only when every token has a value, so an untouched
/// screen emits nothing.
///
/// Every rule also records the PDF's own option list (`pdfOptions`), which the
/// generated test (`inspection_verbatim_spec_test.dart`) compares with the form
/// definition, so the options a surveyor can pick are exactly the PDF's.

/// How a `{TOKEN}` is filled.
class VerbatimToken {
  const VerbatimToken(
    this.token, {
    this.options = const {},
    this.legacy = const {},
    this.otherCheckbox,
    this.otherText,
    this.dropdown,
    this.dropdownOptions = const [],
    this.text,
    this.lower = false,
    this.pdfOptions = const [],
  });

  /// Placeholder in the bank sentence, e.g. `{CS_STACK_CONSTRUCTION}`.
  final String token;

  /// Checkbox id -> label printed in the sentence (the PDF option text).
  final Map<String, String> options;

  /// Old checkbox ids still rendered for previously saved surveys.
  final Map<String, String> legacy;

  /// "Other" checkbox id and its typed-text field id.
  final String? otherCheckbox;
  final String? otherText;

  /// Single-choice dropdown field id; its value is printed as selected.
  final String? dropdown;

  /// Dropdown values as defined in the form (checked against the PDF).
  final List<String> dropdownOptions;

  /// Free-text field id.
  final String? text;

  /// Print the selected dropdown value in lower case (form labels may be
  /// capitalised for display while the PDF sentence is lower case).
  final bool lower;

  /// The option list exactly as the PDF prints it (without "other").
  final List<String> pdfOptions;
}

/// One approved sentence and where its values come from.
class VerbatimRule {
  const VerbatimRule(
    this.id,
    this.screen,
    this.master,
    this.sub,
    this.tokens, {
    this.pdf,
    this.first = false,
  });

  /// Stable name used in test output.
  final String id;
  final String screen;

  /// Bank master code, or `@chimney` to pick the single/multi stack master
  /// from the answers.
  final String master;
  final String sub;
  final List<VerbatimToken> tokens;

  /// The PDF sentence this rule implements, exactly as the PDF prints it
  /// (option list included). The ledger uses it to mark that option-list row
  /// verified once the generated tests pass.
  final String? pdf;

  /// Emit before the screen's hand-written handler output (PDF order).
  final bool first;
}

/// All PDF-verbatim rules. Grouped by PDF section; keep PDF order.
const List<VerbatimRule> kVerbatimRules = <VerbatimRule>[
  // ── E1 Chimney stacks ────────────────────────────────────────────────
  VerbatimRule(
    'e1_stack_construction',
    'activity_outside_property_stacks',
    '@chimney',
    '{STACK_CONSTRUCTION}',
    [
      VerbatimToken(
        '{CS_STACK_CONSTRUCTION}',
        options: {
          'st_brick': 'brick',
          'st_stone': 'stone',
          'st_rendered_masonry': 'rendered masonry',
        },
        otherCheckbox: 'st_other',
        otherText: 'et_stack_other',
        pdfOptions: ['brick', 'stone', 'rendered masonry'],
      ),
    ],
    pdf:
        'Description: The chimney stack(s) are constructed of brick, stone, rendered masonry, other construction.',
  ),
  VerbatimRule(
    'e1_stack_appearance',
    'activity_outside_property_stacks',
    '@chimney',
    '{STACK_APPEARANCE}',
    [
      VerbatimToken(
        '{CS_STACK_APPEARANCE}',
        dropdown: 'actv_stack_appearance',
        dropdownOptions: ['original', 'replaced', 'rebuilt'],
        pdfOptions: ['original', 'replaced', 'rebuilt'],
      ),
    ],
    pdf:
        'The chimney stack(s) appear original, replaced, rebuilt.',
  ),
  VerbatimRule(
    'e1_stack_pots',
    'activity_outside_property_stacks',
    '@chimney',
    '{STACK_POTS}',
    [
      VerbatimToken(
        '{CS_STACK_POT_TYPES}',
        options: {
          'pot_clay': 'clay pots',
          'pot_terracotta': 'terracotta pots',
          'pot_metal_flues': 'metal flues',
          'pot_cowls': 'cowls',
          'pot_caps': 'caps',
        },
        otherCheckbox: 'pot_other',
        otherText: 'et_pot_other',
        pdfOptions: [
          'clay pots',
          'terracotta pots',
          'metal flues',
          'cowls',
          'caps',
        ],
      ),
    ],
    pdf:
        'Pots: The chimney stack(s) are fitted with clay pots, terracotta pots, metal flues, cowls, caps, other pot(s).',
  ),
  VerbatimRule(
    'e1_partial_view',
    'activity_outside_property_chimney_partial_view',
    '{E_CS_CHIMNEY_INSPECTION_STATUS}',
    '{PARTIAL_VIEW}',
    [
      VerbatimToken(
        '{CS_PARTIAL_REASONS}',
        options: {
          'pv_height': 'height',
          'pv_restricted_access': 'restricted access',
          'pv_adjacent_buildings': 'adjacent buildings',
          'pv_roof_configuration': 'roof configuration',
          'pv_health_safety': 'health and safety restrictions',
        },
        pdfOptions: [
          'height',
          'restricted access',
          'adjacent buildings',
          'roof configuration',
          'health and safety restrictions',
        ],
      ),
    ],
    pdf:
        'Not fully inspected: The chimney stack(s) could not be fully inspected because of height, restricted access, adjacent buildings, roof configuration, health and safety restrictions.',
  ),
  VerbatimRule(
    'e1_flashing_formed',
    'activity_outside_property_water_proofing',
    '@chimney',
    '{WATERPROOFING_FLASHING}',
    [
      VerbatimToken(
        '{CS_WATERPROOFING_FLASHING_FORMED_IN}',
        options: {
          'ch1': 'lead',
          'ch_flashing_lead_substitute': 'lead substitute',
          'ch2': 'mortar',
          'ch_flashing_bricks': 'bricks',
          'ch4': 'tiles',
        },
        legacy: {'ch3': 'lead and mortar'},
        otherCheckbox: 'ch5',
        otherText: 'etGroundTypeOther',
        pdfOptions: ['lead', 'lead substitute', 'mortar', 'bricks', 'tiles'],
      ),
    ],
    pdf:
        'Flashings: The waterproofing between the chimney stack and the roof covering (called the flashing) appears to be formed in lead, lead substitute, mortar, bricks, tiles, other material.',
  ),
  VerbatimRule(
    'e1_flashing_condition',
    'activity_outside_property_water_proofing',
    '@chimney',
    '{WATERPROOFING_FLASHING_CONDITION}',
    [
      VerbatimToken(
        '{CS_WATERPROOFING_FLASHING_CONDITION}',
        dropdown: 'actv_flashing_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Poor', 'Defective'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'poor', 'defective'],
      ),
    ],
    pdf:
        'Condition: Where visible, the flashings appear in good, reasonable, poor, defective condition.',
  ),
  VerbatimRule(
    'e1_flaunching_formed',
    'activity_outside_property_water_proofing',
    '@chimney',
    '{WATERPROOFING_FLAUNCHING}',
    [
      VerbatimToken(
        '{CS_WATERPROOFING_FLAUNCHING_FORMED_IN}',
        options: {
          'ch7': 'mortar',
          'ch_flaunching_bricks': 'bricks',
          'ch_flaunching_concrete': 'concrete',
          'ch9': 'tiles',
        },
        legacy: {'ch6': 'lead', 'ch8': 'lead and mortar'},
        otherCheckbox: 'ch10',
        otherText: 'etFlaunchingOther',
        pdfOptions: ['mortar', 'bricks', 'concrete', 'tiles'],
      ),
    ],
    pdf:
        'Flaunching: The cement bedding around the base of the chimney pot (called flaunching) appears to be formed in mortar, bricks, concrete, tiles, other material.',
  ),
  VerbatimRule(
    'e1_flaunching_condition',
    'activity_outside_property_water_proofing',
    '@chimney',
    '{WATERPROOFING_FLAUNCHING_CONDITION}',
    [
      VerbatimToken(
        '{CS_WATERPROOFING_FLAUNCHING_CONDITION}',
        dropdown: 'actv_flaunching_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Poor', 'Defective'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'poor', 'defective'],
      ),
    ],
    pdf:
        'Condition: Where visible, the flaunching appears in good, reasonable, poor, defective condition.',
  ),
  VerbatimRule(
    'e1_pointing_condition',
    'activity_outside_property_water_proofing',
    '@chimney',
    '{POINTING_CONDITION}',
    [
      VerbatimToken(
        '{CS_POINTING_CONDITION}',
        options: {
          'pt_good': 'good',
          'pt_reasonable': 'reasonable',
          'pt_weathered': 'weathered',
          'pt_eroded': 'eroded',
          'pt_poor': 'poor',
        },
        otherCheckbox: 'pt_other',
        otherText: 'et_pointing_other',
        pdfOptions: ['good', 'reasonable', 'weathered', 'eroded', 'poor'],
      ),
    ],
    pdf:
        'Pointing Condition: The mortar joints to the chimney stack appear in good, reasonable, weathered, eroded, poor, other condition(s).',
  ),
  VerbatimRule(
    'e1_pots_condition',
    'activity_outside_property_water_proofing',
    '@chimney',
    '{POTS_CONDITION}',
    [
      VerbatimToken(
        '{CS_POTS_CONDITION}',
        options: {
          'pc_secure': 'secure',
          'pc_weathered': 'weathered',
          'pc_cracked': 'cracked',
          'pc_damaged': 'damaged',
          'pc_missing': 'missing',
        },
        otherCheckbox: 'pc_other',
        otherText: 'et_pots_other',
        pdfOptions: ['secure', 'weathered', 'cracked', 'damaged', 'missing'],
      ),
    ],
    pdf:
        'Damaged chimney pots: The chimney pots appear secure, weathered, cracked, damaged, missing, other.',
  ),
  VerbatimRule(
    'e1_leaning_degree',
    'activity_outside_property_leaning_chimney',
    '@chimney',
    '{LEANING_CHIMNEY}',
    [
      VerbatimToken(
        '{CS_LEANING_DEGREE}',
        dropdown: 'actv_leaning_degree',
        dropdownOptions: ['slightly leaning', 'significantly leaning'],
        pdfOptions: ['slightly leaning', 'significantly leaning'],
      ),
    ],
    pdf:
        'Leaning chimney: The chimney stack appears slightly leaning, significantly leaning.',
    first: true,
  ),
];

extension _VerbatimSpec on InspectionPhraseEngine {
  List<String> _verbatimPhrases(
    String screenId,
    Map<String, String> answers, {
    required bool first,
  }) {
    final out = <String>[];
    for (final rule in kVerbatimRules) {
      if (rule.screen != screenId || rule.first != first) continue;
      final master = rule.master == '@chimney'
          ? InspectionPhraseEngine._chimneyPhraseCodeFromAnswers(
              answers,
              fallbackIsMulti: false,
            )
          : rule.master;
      var text = _phraseTexts['$master::${rule.sub}'] ?? '';
      if (text.isEmpty) continue;
      var complete = true;
      for (final token in rule.tokens) {
        final value = _verbatimTokenValue(token, answers);
        if (value.isEmpty) {
          complete = false;
          break;
        }
        text = text.replaceAll(token.token, value);
      }
      if (!complete) continue;
      out.addAll(InspectionPhraseEngine._split(
        InspectionPhraseEngine._normalize(text),
      ));
    }
    return out;
  }

  String _verbatimTokenValue(VerbatimToken token, Map<String, String> answers) {
    if (token.dropdown != null) {
      final v = (answers[token.dropdown] ?? '').trim();
      return token.lower ? v.toLowerCase() : v;
    }
    if (token.text != null) {
      return (answers[token.text] ?? '').trim();
    }
    final labels = <String, String>{...token.legacy, ...token.options};
    final items = InspectionPhraseEngine._labelsFor(
      labels.keys.toList(),
      answers,
      labels,
    );
    if (token.otherCheckbox != null && token.otherText != null) {
      InspectionPhraseEngine._addOther(
        answers,
        token.otherCheckbox!,
        token.otherText!,
        items,
      );
    }
    return InspectionPhraseEngine._toWords(items);
  }
}
