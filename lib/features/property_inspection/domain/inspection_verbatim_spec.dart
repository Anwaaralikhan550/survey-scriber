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
    this.cap = false,
    this.constant,
    this.optional = false,
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

  /// Capitalise the first letter of the printed value (token starts a
  /// sentence).
  final bool cap;

  /// Fixed value (e.g. the roof type of a screen) - never asked of the surveyor.
  final String? constant;

  /// An unanswered optional token is replaced by nothing instead of
  /// suppressing the sentence.
  final bool optional;

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
    this.pdfMore = const [],
    this.first = false,
    this.isAre = false,
    this.whenField,
    this.whenValue,
    this.whenAny = const [],
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

  /// Further PDF option-list sentences this rule also implements.
  final List<String> pdfMore;

  /// Emit before the screen's hand-written handler output (PDF order).
  final bool first;

  /// Replace `{IS_ARE}` with is/are from the first token's number of choices.
  final bool isAre;

  /// Fire only when this dropdown holds this value (case-insensitive), e.g.
  /// `actv_condition` = `Repair now`.
  final String? whenField;
  final String? whenValue;

  /// Further `[field, value]` pairs that also make the rule fire (OR with
  /// `whenField`/`whenValue`).
  final List<List<String>> whenAny;
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
  VerbatimRule(
    'e1_aerials_attached',
    'activity_outside_property_chimney_aerials',
    '@chimney',
    '{AERIALS_ATTACHED}',
    [
      VerbatimToken(
        '{CS_ATTACHED_ITEMS}',
        options: {
          'ca_aerial': 'an aerial',
          'ca_satellite': 'a satellite dish',
        },
        pdfOptions: ['an aerial', 'a satellite dish'],
        cap: true,
      ),
    ],
    pdf:
        'Aerials and satellite dishes: An aerial, a satellite dish is attached to the chimney stack.',
    isAre: true,
  ),
  VerbatimRule(
    'e1_chimney_defects',
    'activity_outside_property_chimney_defects',
    '@chimney',
    '{CHIMNEY_DEFECTS}',
    [
      VerbatimToken(
        '{CS_CHIMNEY_DEFECT_LIST}',
        options: {
          'cd_loose_flashings': 'loose flashings',
          'cd_missing_flashings': 'missing flashings',
          'cd_cracked_flaunching': 'cracked flaunching',
          'cd_missing_mortar': 'missing mortar',
          'cd_spalled_bricks': 'spalled bricks',
          'cd_damaged_pointing': 'damaged pointing',
          'cd_loose_chimney_pots': 'loose chimney pots',
          'cd_broken_chimney_pots': 'broken chimney pots',
          'cd_vegetation_growth': 'vegetation growth',
          'cd_open_flues': 'open flues',
          'cd_loose_aerial_fixings': 'loose aerial fixings',
          'cd_loose_satellite_fixings': 'loose satellite dish fixings',
        },
        pdfOptions: ['loose flashings', 'missing flashings', 'cracked flaunching', 'missing mortar', 'spalled bricks', 'damaged pointing', 'loose chimney pots', 'broken chimney pots', 'vegetation growth', 'open flues', 'loose aerial fixings', 'loose satellite dish fixings'],
      ),
    ],
    pdf:
        'Chimney Defects: One or more chimney defects were observed, including: • Loose flashings • Missing flashings • Cracked flaunching • Missing mortar • Spalled bricks • Damaged pointing • Loose chimney pots • Broken chimney pots • Vegetation growth • Open flues • Loose aerial fixings • Loose satellite dish fixings Repairs should be undertaken by an appropriately qualified roofing contractor to prevent further deterioration and water penetration.',
  ),
  VerbatimRule(
    'e2_desc_pitched',
    'outside_property_about_roof_layout',
    '{E_ROOF_COVERING}',
    '{RC_ABOUT_TYPE}',
    [
      VerbatimToken(
        '{RC_TYPE}',
        constant: 'pitched',
      ),
      VerbatimToken(
        '{RC_LOCATION}',
        options: {
          'cb_main_building': 'main building',
          'cb_extension': 'extension',
          'rc_loc_porch': 'porch',
          'cb_bay_window': 'bay window',
        },
        otherCheckbox: 'cb_other_22',
        otherText: 'etRoofLocationOther',
        pdfOptions: ['main building', 'extension', 'porch', 'bay window'],
      ),
      VerbatimToken(
        '{RC_MATERIAL}',
        options: {
          'rc_mat_original_clay': 'original clay tiles',
          'rc_mat_replacement_clay': 'replacement clay tiles',
          'cb_concrete': 'concrete tiles',
          'cb_natural': 'natural slate',
          'rc_mat_artificial_slate': 'artificial slate',
          'rc_mat_fibre_cement': 'fibre cement slates',
          'rc_mat_aluminium': 'aluminium sheets',
          'cb_composite': 'composite slate',
          'rc_mat_asbestos_sheet': 'asbestos sheet',
        },
        otherCheckbox: 'cb_other_78',
        otherText: 'etRoofMaterialOther',
        pdfOptions: ['original clay tiles', 'replacement clay tiles', 'concrete tiles', 'natural slate', 'artificial slate', 'fibre cement slates', 'aluminium sheets', 'composite slate', 'asbestos sheet'],
      ),
    ],
    pdf:
        'Description: The pitched, mansard, flat roof covering to the main building, extension, porch, or bay window, other is formed in original or replacement clay tiles, concrete tiles, natural slate, artificial slate, fibre cement slates, aluminium sheets, composite slate, asbestos sheet, other material.',
  ),
  VerbatimRule(
    'e2_cond_pitched',
    'outside_property_about_roof_layout',
    '{E_ROOF_COVERING}',
    '{RC_ABOUT_TYPE_CONDITION}',
    [
      VerbatimToken(
        '{RC_TYPE_CONDITION}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Condition: Where visible, the covering appears in good, reasonable, fair, poor, very poor condition.',
  ),
  VerbatimRule(
    'e2_old_pitched',
    'outside_property_about_roof_layout',
    '{E_ROOF_COVERING}',
    '{OLD_ROOF_COVERING}',
    [
    ],
    whenField: 'cb_old_roof_covering',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e2_asbestos_pitched',
    'outside_property_about_roof_layout',
    '{E_ROOF_COVERING_MATERIAL}',
    '{MATERIAL_COMPOSITE}',
    [
    ],
    whenField: 'cb_composite',
    whenValue: 'true',
    whenAny: [['rc_mat_asbestos_sheet', 'true']],
  ),
  VerbatimRule(
    'e2_desc_mansard',
    'outside_property_about_roof_layout__mansard',
    '{E_ROOF_COVERING}',
    '{RC_ABOUT_TYPE}',
    [
      VerbatimToken(
        '{RC_TYPE}',
        constant: 'mansard',
      ),
      VerbatimToken(
        '{RC_LOCATION}',
        options: {
          'cb_main_building': 'main building',
          'cb_extension': 'extension',
          'rc_loc_porch': 'porch',
          'cb_bay_window': 'bay window',
        },
        otherCheckbox: 'cb_other_22',
        otherText: 'etRoofLocationOther',
        pdfOptions: ['main building', 'extension', 'porch', 'bay window'],
      ),
      VerbatimToken(
        '{RC_MATERIAL}',
        options: {
          'rc_mat_original_clay': 'original clay tiles',
          'rc_mat_replacement_clay': 'replacement clay tiles',
          'cb_concrete': 'concrete tiles',
          'cb_natural': 'natural slate',
          'rc_mat_artificial_slate': 'artificial slate',
          'rc_mat_fibre_cement': 'fibre cement slates',
          'rc_mat_aluminium': 'aluminium sheets',
          'cb_composite': 'composite slate',
          'rc_mat_asbestos_sheet': 'asbestos sheet',
        },
        otherCheckbox: 'cb_other_78',
        otherText: 'etRoofMaterialOther',
        pdfOptions: ['original clay tiles', 'replacement clay tiles', 'concrete tiles', 'natural slate', 'artificial slate', 'fibre cement slates', 'aluminium sheets', 'composite slate', 'asbestos sheet'],
      ),
    ],
    pdf:
        'Description: The pitched, mansard, flat roof covering to the main building, extension, porch, or bay window, other is formed in original or replacement clay tiles, concrete tiles, natural slate, artificial slate, fibre cement slates, aluminium sheets, composite slate, asbestos sheet, other material.',
  ),
  VerbatimRule(
    'e2_cond_mansard',
    'outside_property_about_roof_layout__mansard',
    '{E_ROOF_COVERING}',
    '{RC_ABOUT_TYPE_CONDITION}',
    [
      VerbatimToken(
        '{RC_TYPE_CONDITION}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Condition: Where visible, the covering appears in good, reasonable, fair, poor, very poor condition.',
  ),
  VerbatimRule(
    'e2_old_mansard',
    'outside_property_about_roof_layout__mansard',
    '{E_ROOF_COVERING}',
    '{OLD_ROOF_COVERING}',
    [
    ],
    whenField: 'cb_old_roof_covering',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e2_asbestos_mansard',
    'outside_property_about_roof_layout__mansard',
    '{E_ROOF_COVERING_MATERIAL}',
    '{MATERIAL_COMPOSITE}',
    [
    ],
    whenField: 'cb_composite',
    whenValue: 'true',
    whenAny: [['rc_mat_asbestos_sheet', 'true']],
  ),
  VerbatimRule(
    'e2_desc_other',
    'outside_property_about_roof_layout__other',
    '{E_ROOF_COVERING}',
    '{RC_ABOUT_TYPE}',
    [
      VerbatimToken(
        '{RC_TYPE}',
        text: 'other',
      ),
      VerbatimToken(
        '{RC_LOCATION}',
        options: {
          'cb_main_building': 'main building',
          'cb_extension': 'extension',
          'rc_loc_porch': 'porch',
          'cb_bay_window': 'bay window',
        },
        otherCheckbox: 'cb_other_22',
        otherText: 'etRoofLocationOther',
        pdfOptions: ['main building', 'extension', 'porch', 'bay window'],
      ),
      VerbatimToken(
        '{RC_MATERIAL}',
        options: {
          'rc_mat_original_clay': 'original clay tiles',
          'rc_mat_replacement_clay': 'replacement clay tiles',
          'cb_concrete': 'concrete tiles',
          'cb_natural': 'natural slate',
          'rc_mat_artificial_slate': 'artificial slate',
          'rc_mat_fibre_cement': 'fibre cement slates',
          'rc_mat_aluminium': 'aluminium sheets',
          'cb_composite': 'composite slate',
          'rc_mat_asbestos_sheet': 'asbestos sheet',
        },
        otherCheckbox: 'cb_other_78',
        otherText: 'etRoofMaterialOther',
        pdfOptions: ['original clay tiles', 'replacement clay tiles', 'concrete tiles', 'natural slate', 'artificial slate', 'fibre cement slates', 'aluminium sheets', 'composite slate', 'asbestos sheet'],
      ),
    ],
    pdf:
        'Description: The pitched, mansard, flat roof covering to the main building, extension, porch, or bay window, other is formed in original or replacement clay tiles, concrete tiles, natural slate, artificial slate, fibre cement slates, aluminium sheets, composite slate, asbestos sheet, other material.',
  ),
  VerbatimRule(
    'e2_cond_other',
    'outside_property_about_roof_layout__other',
    '{E_ROOF_COVERING}',
    '{RC_ABOUT_TYPE_CONDITION}',
    [
      VerbatimToken(
        '{RC_TYPE_CONDITION}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Condition: Where visible, the covering appears in good, reasonable, fair, poor, very poor condition.',
  ),
  VerbatimRule(
    'e2_old_other',
    'outside_property_about_roof_layout__other',
    '{E_ROOF_COVERING}',
    '{OLD_ROOF_COVERING}',
    [
    ],
    whenField: 'cb_old_roof_covering',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e2_asbestos_other',
    'outside_property_about_roof_layout__other',
    '{E_ROOF_COVERING_MATERIAL}',
    '{MATERIAL_COMPOSITE}',
    [
    ],
    whenField: 'cb_composite',
    whenValue: 'true',
    whenAny: [['rc_mat_asbestos_sheet', 'true']],
  ),
  VerbatimRule(
    'e2_flat_desc',
    'outside_property_about_roof_layout__flat',
    '{E_ROOF_COVERING}',
    '{RC_FLAT_ABOUT}',
    [
      VerbatimToken(
        '{RC_MATERIAL}',
        options: {
          'cb_mineral_felt': 'mineral felt',
          'rc_flat_hp_felt': 'high-performance felt',
          'cb_rubber': 'rubber membrane',
          'cb_single_ply_membrane': 'single-ply membrane',
          'rc_flat_grp': 'GRP fibreglass',
          'rc_flat_asphalt': 'asphalt',
          'cb_fiberglass': 'fibreglass',
          'rc_flat_lead': 'lead',
        },
        otherCheckbox: 'cb_other_78',
        otherText: 'etRoofMaterialOther',
        pdfOptions: ['mineral felt', 'high-performance felt', 'rubber membrane', 'single-ply membrane', 'GRP fibreglass', 'asphalt', 'fibreglass', 'lead'],
      ),
    ],
    pdf:
        'Flat roof coverings: The flat roof covering over the building is formed in mineral felt, high-performance felt, rubber membrane, single-ply membrane, GRP fibreglass, asphalt, fibreglass, lead, other material.',
  ),
  VerbatimRule(
    'e2_flat_cond',
    'outside_property_about_roof_layout__flat',
    '{E_ROOF_COVERING}',
    '{RC_FLAT_CONDITION}',
    [
      VerbatimToken(
        '{RC_TYPE_CONDITION}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Condition: Where visible, the covering appears in good, reasonable, fair, poor, very poor condition.',
  ),
  VerbatimRule(
    'e2_flat_felt',
    'outside_property_about_roof_layout__flat',
    '{E_ROOF_COVERING_MATERIAL}',
    '{FLAT_MATERIAL_MINERAL_FELT}',
    [
    ],
    whenField: 'cb_mineral_felt',
    whenValue: 'true',
    whenAny: [['rc_flat_hp_felt', 'true']],
  ),
  VerbatimRule(
    'e2_flat_norepair',
    'outside_property_about_roof_layout__flat',
    '{E_ROOF_COVERING}',
    '{RC_FLAT_NO_REPAIR}',
    [
    ],
    whenField: 'actv_condition',
    whenValue: 'Good',
    whenAny: [['actv_condition', 'Reasonable'], ['actv_condition', 'Fair'], ['actv_condition', 'Poor'], ['actv_condition', 'Very poor']],
  ),
  VerbatimRule(
    'e2_flat_old',
    'outside_property_about_roof_layout__flat',
    '{E_ROOF_COVERING}',
    '{OLD_ROOF_COVERING_FLAT}',
    [
    ],
    whenField: 'cb_old_roof_covering',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e2_cond_weathered',
    'outside_property_roof_covering_weathered_layout',
    '{E_ROOF_COVERING}',
    '{RC_ABOUT_TYPE_CONDITION}',
    [
      VerbatimToken(
        '{RC_TYPE_CONDITION}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Condition: Where visible, the covering appears in good, reasonable, fair, poor, very poor condition.',
    whenField: 'cb_weathered',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e2_flashing',
    'outside_property_roof_covering_flashing_layout',
    '{E_ROOF_COVERING}',
    '{E_RC_FLASHING}',
    [
      VerbatimToken(
        '{RC_FLASHING}',
        options: {
          'cb_lead': 'lead',
          'cb_mortar': 'mortar',
          'cb_tiles': 'clay tiles',
          'rc_fl_mineral_felt': 'mineral felt',
          'rc_fl_bitumen_tape': 'bitumen tape',
          'rc_fl_lead_substitute': 'lead substitute',
        },
        otherCheckbox: 'cb_other_33',
        otherText: 'et_other_87',
        pdfOptions: ['lead', 'mortar', 'clay tiles', 'mineral felt', 'bitumen tape', 'lead substitute'],
      ),
    ],
    pdf:
        'Flashings: The waterproofing at the junction of the roof covering and wall (called the flashing) appears to be formed in lead, mortar, clay tiles, mineral felt, bitumen tape, lead substitute, other.',
  ),
  VerbatimRule(
    'e2_flashing_cond',
    'outside_property_roof_covering_flashing_layout',
    '{E_ROOF_COVERING}',
    '{E_RC_FLASHING_CONDITION}',
    [
      VerbatimToken(
        '{RC_FLASHING_CONDITION}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Poor', 'Defective'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'poor', 'defective'],
      ),
    ],
    pdf:
        'Condition: Where visible, the flashings appear in good, reasonable, poor, defective condition.',
  ),
  VerbatimRule(
    'e2_ridge',
    'outside_property_roof_covering_ridge_tiles_layout',
    '{E_ROOF_COVERING}',
    '{E_RC_RIDGE_TILES}',
    [
      VerbatimToken(
        '{RC_RIDGE_TILES}',
        options: {
          'rc_ridge_clay': 'clay',
          'cb_concrete': 'concrete',
        },
        otherCheckbox: 'cb_other_62',
        otherText: 'et_other_101',
        pdfOptions: ['clay', 'concrete'],
      ),
    ],
    pdf:
        'Ridge tiles: The covering along the top of the roof structure, called the ridge tiles, is assumed to be formed in clay, concrete, other material.',
  ),
  VerbatimRule(
    'e2_ridge_cond',
    'outside_property_roof_covering_ridge_tiles_layout',
    '{E_ROOF_COVERING}',
    '{E_RC_RIDGE_TILES_CONDITION}',
    [
      VerbatimToken(
        '{RC_RIDGE_TILES_CONDITION}',
        dropdown: 'actv_formed_in',
        dropdownOptions: ['Good', 'Reasonable', 'Poor', 'Defective'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'poor', 'defective'],
      ),
    ],
    pdf:
        'Condition: Where visible, they appear in good, reasonable, poor, defective condition.',
  ),
  VerbatimRule(
    'e2_hip',
    'outside_property_roof_covering_hip_tiles_layout',
    '{E_ROOF_COVERING}',
    '{E_RC_HIP_TILES}',
    [
      VerbatimToken(
        '{RC_HIP_TILES}',
        options: {
          'rc_hip_clay': 'clay',
          'cb_concrete': 'concrete',
        },
        otherCheckbox: 'cb_other_62',
        otherText: 'et_other_101',
        pdfOptions: ['clay', 'concrete'],
      ),
    ],
    pdf:
        'Hip tiles: The covering along the junction of the roof slopes, called the hip tiles, is assumed to be formed in clay, concrete, other material.',
  ),
  VerbatimRule(
    'e2_hip_cond',
    'outside_property_roof_covering_hip_tiles_layout',
    '{E_ROOF_COVERING}',
    '{E_RC_HIP_TILES_CONDITION}',
    [
      VerbatimToken(
        '{RC_HIP_TILES_CONDITION}',
        dropdown: 'actv_formed_in',
        dropdownOptions: ['Good', 'Reasonable', 'Poor', 'Defective'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'poor', 'defective'],
      ),
    ],
    pdf:
        'Condition: Where visible, they appear in good, reasonable, poor, defective condition.',
  ),
  VerbatimRule(
    'e2_valley',
    'outside_property_roof_covering_valley_gutters_layout',
    '{E_ROOF_COVERING}',
    '{E_RC_VALLEY_GUTTERS}',
    [
      VerbatimToken(
        '{RC_VALLEY_GUTTERS}',
        options: {
          'rc_vg_lead': 'lead',
          'rc_vg_mortar': 'mortar',
        },
        otherCheckbox: 'rc_vg_other',
        otherText: 'rc_vg_other_text',
        pdfOptions: ['lead', 'mortar'],
      ),
    ],
    pdf:
        'Valley Gutters: The valley gutters are formed in lead, mortar, other material.',
  ),
  VerbatimRule(
    'e2_valley_cond',
    'outside_property_roof_covering_valley_gutters_layout',
    '{E_ROOF_COVERING}',
    '{E_RC_VALLEY_GUTTERS_CONDITION}',
    [
      VerbatimToken(
        '{RC_VALLEY_GUTTERS_CONDITION}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Poor', 'Blocked'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'poor', 'blocked'],
      ),
    ],
    pdf:
        'Condition: Where visible, they appear in good, reasonable, poor, blocked condition.',
  ),
  VerbatimRule(
    'e2_parapet',
    'outside_property_roof_covering_parapet_wall_layout',
    '{E_ROOF_COVERING}',
    '{E_RC_PARAPET_WALL}',
    [
      VerbatimToken(
        '{RC_PARAPET_WALL_BUILT_WITH}',
        options: {
          'cb_bricks': 'brick',
          'rc_pw_stone': 'stone',
          'rc_pw_rendered_masonry': 'rendered masonry',
          'cb_concrete': 'concrete',
        },
        otherCheckbox: 'cb_other_44',
        otherText: 'et_other_101',
        pdfOptions: ['brick', 'stone', 'rendered masonry', 'concrete'],
      ),
    ],
    pdf:
        'Parapet walls: The parapet wall(s) are constructed of brick, stone, rendered masonry, concrete, other.',
  ),
  VerbatimRule(
    'e2_parapet_coping',
    'outside_property_roof_covering_parapet_wall_layout',
    '{E_ROOF_COVERING}',
    '{E_RC_PARAPET_COPING}',
    [
      VerbatimToken(
        '{RC_PARAPET_COPING}',
        options: {
          'rc_pc_stone': 'stone',
          'rc_pc_tiles': 'tiles',
          'rc_pc_concrete': 'concrete',
          'rc_pc_engineering_brick': 'engineering brick',
          'rc_pc_metal': 'metal',
        },
        otherCheckbox: 'rc_pc_other',
        otherText: 'rc_pc_other_text',
        pdfOptions: ['stone', 'tiles', 'concrete', 'engineering brick', 'metal'],
      ),
    ],
    pdf:
        'Coping: The parapet coping is formed in stone, tiles, concrete, engineering brick, metal, other material.',
  ),
  VerbatimRule(
    'e2_parapet_cond',
    'outside_property_roof_covering_parapet_wall_layout',
    '{E_ROOF_COVERING}',
    '{E_RC_PARAPET_WALL_CONDITION}',
    [
      VerbatimToken(
        '{RC_PARAPET_WALL_CONDITION}',
        dropdown: 'android_material_design_spinner3',
        dropdownOptions: ['Good', 'Reasonable', 'Poor', 'Defective'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'poor', 'defective'],
      ),
    ],
    pdf:
        'Condition: Where visible, these elements appear in good, reasonable, poor, defective condition.',
  ),
  VerbatimRule(
    'e2_deflection',
    'outside_property_roof_covering_deflection_layout',
    '{E_RC_DEFLECTION_STATUS}',
    '{DEFLECTION_MINOR}',
    [
      VerbatimToken(
        '{RC_DEFLECTION_STATUS_LOCATION}',
        options: {
          'rc_df_all': 'all',
          'cb_front_45': 'front',
          'cb_rear_47': 'rear',
          'cb_side_41': 'side',
        },
        pdfOptions: ['all', 'front', 'rear', 'side'],
      ),
    ],
    pdf:
        'Roof line deflection: Minor undulation or deflection to all, front, rear, side roof slopes were observed.',
  ),
  VerbatimRule(
    'e2_struct_ok',
    'outside_property_roof_covering_roof_structure_layout',
    '{E_ROOF_COVERING_ROOF_CONDITION}',
    '{RC_ROOF_CONDITION_OK}',
    [
    ],
    whenField: 'actv_status',
    whenValue: 'No repair required',
  ),
  VerbatimRule(
    'e2_struct_defect',
    'outside_property_roof_covering_roof_structure_layout',
    '{E_ROOF_COVERING_ROOF_CONDITION}',
    '{RC_ROOF_CONDITION_INVESTIGATE}',
    [
      VerbatimToken(
        '{RC_ROOF_INVESTIGATE_LOCATION}',
        options: {
          'cb_front_39': 'front',
          'cb_rear_20': 'rear',
          'cb_side_78': 'side',
        },
        pdfOptions: ['front', 'rear', 'side'],
      ),
    ],
    pdf:
        'Repair defect: The surface of the front, rear, side roof slope(s) of the building is significantly distorted, uneven or undulating.',
    whenField: 'actv_status',
    whenValue: 'Repair defect',
  ),
  VerbatimRule(
    'e2_tiles_soon',
    'activity_outside_property_roof_repair_tiles',
    '{E_RC_TILES}',
    '{REPAIR_SOON}',
    [
      VerbatimToken(
        '{RC_ROOF_REPAIR_TILES_ISSUE}',
        options: {
          'rc_rt_loose': 'loose',
          'rc_rt_missing': 'missing',
          'rc_rt_lifted': 'lifted',
          'rc_rt_slipped': 'slipped',
          'rc_rt_cracked': 'cracked',
          'rc_rt_broken': 'broken',
          'rc_rt_distorted': 'distorted',
        },
        otherCheckbox: 'rc_rt_other',
        otherText: 'rc_rt_other_text',
        pdfOptions: ['loose', 'missing', 'lifted', 'slipped', 'cracked', 'broken', 'distorted'],
      ),
    ],
    pdf:
        'Repair soon: One or more tiles, slates, are loose, missing, lifted, slipped, cracked, broken, distorted, other.',
    whenField: 'actv_condition',
    whenValue: 'Repair soon',
  ),
  VerbatimRule(
    'e2_tiles_now',
    'activity_outside_property_roof_repair_tiles',
    '{E_RC_TILES}',
    '{REPAIR_NOW}',
    [
      VerbatimToken(
        '{RC_ROOF_REPAIR_TILES_ISSUE}',
        options: {
          'rc_rt_loose': 'loose',
          'rc_rt_missing': 'missing',
          'rc_rt_lifted': 'lifted',
          'rc_rt_slipped': 'slipped',
          'rc_rt_cracked': 'cracked',
          'rc_rt_broken': 'broken',
          'rc_rt_distorted': 'distorted',
        },
        otherCheckbox: 'rc_rt_other',
        otherText: 'rc_rt_other_text',
        pdfOptions: ['loose', 'missing', 'lifted', 'slipped', 'cracked', 'broken', 'distorted'],
      ),
    ],
    pdf:
        'Repair now: One or more tiles, slates, roof covering sections are severely or significantly loose, missing, lifted, slipped, cracked, broken, distorted, other.',
    whenField: 'actv_condition',
    whenValue: 'Repair now',
  ),
  VerbatimRule(
    'e2_tiles_leaking',
    'activity_outside_property_roof_repair_tiles',
    '{E_RC_TILES}',
    '{LEAKING}',
    [
    ],
    whenField: 'actv_condition',
    whenValue: 'Leaking',
  ),
  VerbatimRule(
    'e2_spreading',
    'activity_outside_property_roof_spreading_repair',
    '{E_ROOF_COVERING_REPAIR}',
    '{RC_ROOF_SPREADING}',
    [
      VerbatimToken(
        '{RC_ROOF_SPREADING_LOCATION}',
        options: {
          'rc_rs_all': 'all',
          'rc_rs_front': 'front',
          'rc_rs_side': 'side',
          'rc_rs_rear': 'rear',
        },
        pdfOptions: ['all', 'front', 'side', 'rear'],
      ),
    ],
    pdf:
        'Roof Spreading: The roof slopes to all, front, side, and rear of the building appear uneven or undulating, and the adjoining wall appears distorted, cracked, bowing or leaning outwards.',
  ),
  VerbatimRule(
    'e2_flatrepair_soon',
    'activity_outside_property_roof_repair_flat_roof',
    '{E_RC_FLAT_ROOF_REPAIR}',
    '{REPAIR_SOON}',
    [
      VerbatimToken(
        '{RC_FLAT_ROOF_REPAIR_COVERED}',
        options: {
          'rc_fr_weathered': 'weathered',
          'rc_fr_blistered': 'blistered',
          'rc_fr_split': 'split',
          'rc_fr_torn': 'torn',
          'rc_fr_worn': 'worn',
          'rc_fr_ponding': 'ponding',
          'rc_fr_damaged': 'damaged',
        },
        otherCheckbox: 'rc_fr_other',
        otherText: 'rc_fr_other_text',
        pdfOptions: ['weathered', 'blistered', 'split', 'torn', 'worn', 'ponding', 'damaged'],
      ),
    ],
    pdf:
        'Repair Flat roof: The flat roof covering is weathered, blistered, split, torn, worn, ponding, damaged, other.',
    whenField: 'actv_condition',
    whenValue: 'Repair soon',
  ),
  VerbatimRule(
    'e2_flatrepair_now',
    'activity_outside_property_roof_repair_flat_roof',
    '{E_RC_FLAT_ROOF_REPAIR}',
    '{REPAIR_NOW}',
    [
      VerbatimToken(
        '{RC_FLAT_ROOF_REPAIR_COVERED}',
        options: {
          'rc_fr_weathered': 'weathered',
          'rc_fr_blistered': 'blistered',
          'rc_fr_split': 'split',
          'rc_fr_torn': 'torn',
          'rc_fr_worn': 'worn',
          'rc_fr_ponding': 'ponding',
          'rc_fr_damaged': 'damaged',
        },
        otherCheckbox: 'rc_fr_other',
        otherText: 'rc_fr_other_text',
        pdfOptions: ['weathered', 'blistered', 'split', 'torn', 'worn', 'ponding', 'damaged'],
      ),
    ],
    whenField: 'actv_condition',
    whenValue: 'Repair now',
  ),
  VerbatimRule(
    'e2_parapetrepair_soon',
    'activity_outside_property_roof_repair_parapet_wall',
    '{E_RC_PARAPET_WALL_REPAIR}',
    '{REPAIR_SOON}',
    [
      VerbatimToken(
        '{RC_PARAPET_WALL_REPAIR_SUBJECT}',
        options: {
          'rc_pr_rendering': 'rendering',
          'rc_pr_copping': 'copping',
          'rc_pr_flashing': 'flashing',
        },
        otherCheckbox: 'rc_pr_subj_other',
        otherText: 'rc_pr_subj_other_text',
        pdfOptions: ['rendering', 'copping', 'flashing'],
      ),
      VerbatimToken(
        '{RC_PARAPET_WALL_REPAIR_ISSUE}',
        options: {
          'rc_pr_damaged': 'damaged',
          'rc_pr_loose': 'loose',
          'rc_pr_partly_missing': 'partly missing',
          'rc_pr_cracked': 'cracked',
          'rc_pr_poorly_secured': 'poorly secured',
        },
        otherCheckbox: 'rc_pr_iss_other',
        otherText: 'rc_pr_iss_other_text',
        pdfOptions: ['damaged', 'loose', 'partly missing', 'cracked', 'poorly secured'],
      ),
    ],
    pdf:
        'Repair parapet: The rendering, copping, flashing, other of the parapet(s) of the roof are damaged, loose, partly missing, cracked, poorly secured, other.',
    pdfMore: [
      'This should be repaired soon, repaired now.',
    ],
    whenField: 'actv_condition',
    whenValue: 'Repair soon',
  ),
  VerbatimRule(
    'e2_parapetrepair_now',
    'activity_outside_property_roof_repair_parapet_wall',
    '{E_RC_PARAPET_WALL_REPAIR}',
    '{REPAIR_NOW}',
    [
      VerbatimToken(
        '{RC_PARAPET_WALL_REPAIR_SUBJECT}',
        options: {
          'rc_pr_rendering': 'rendering',
          'rc_pr_copping': 'copping',
          'rc_pr_flashing': 'flashing',
        },
        otherCheckbox: 'rc_pr_subj_other',
        otherText: 'rc_pr_subj_other_text',
        pdfOptions: ['rendering', 'copping', 'flashing'],
      ),
      VerbatimToken(
        '{RC_PARAPET_WALL_REPAIR_ISSUE}',
        options: {
          'rc_pr_damaged': 'damaged',
          'rc_pr_loose': 'loose',
          'rc_pr_partly_missing': 'partly missing',
          'rc_pr_cracked': 'cracked',
          'rc_pr_poorly_secured': 'poorly secured',
        },
        otherCheckbox: 'rc_pr_iss_other',
        otherText: 'rc_pr_iss_other_text',
        pdfOptions: ['damaged', 'loose', 'partly missing', 'cracked', 'poorly secured'],
      ),
    ],
    whenField: 'actv_condition',
    whenValue: 'Repair now',
  ),
  VerbatimRule(
    'e2_parapetrepair_hazard',
    'activity_outside_property_roof_repair_parapet_wall',
    '{E_RC_PARAPET_WALL_REPAIR}',
    '{REPAIR_NOW_SAFETY_HAZARD}',
    [
    ],
    whenField: 'cb_safety_hazard',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e2_verge',
    'activity_outside_property_roof_repair_verge',
    '{E_RC_VERGE_REPAIR}',
    '{REPAIR_SOON}',
    [
      VerbatimToken(
        '{RC_VERGE_REPAIR_ITEM}',
        options: {
          'rc_vr_mortar': 'mortar',
          'rc_vr_tiles': 'tiles',
          'rc_vr_slates': 'slates',
          'rc_vr_clips': 'clips',
          'rc_vr_caps': 'caps',
        },
        otherCheckbox: 'rc_vr_item_other',
        otherText: 'rc_vr_item_other_text',
        pdfOptions: ['mortar', 'tiles', 'slates', 'clips', 'caps'],
      ),
      VerbatimToken(
        '{RC_VERGE_REPAIR_ISSUE}',
        options: {
          'rc_vr_damaged': 'damaged',
          'rc_vr_cracked': 'cracked',
          'rc_vr_loose': 'loose',
        },
        otherCheckbox: 'rc_vr_iss_other',
        otherText: 'rc_vr_iss_other_text',
        pdfOptions: ['damaged', 'cracked', 'loose'],
      ),
    ],
    pdf:
        'Repair verge: The mortar, tiles, slates, clips, caps, other items along the edge of the roof, called the verge, are damaged, cracked, loose, other.',
  ),
  VerbatimRule(
    'e2_vgrepair_soon',
    'activity_outside_property_roof_repair_valley_gutters',
    '{E_ROOF_COVERING_REPAIR}',
    '{E_RC_VALLEY_GUTTERS_REPAIR}',
    [
      VerbatimToken(
        '{RC_VALLEY_GUTTERS_REPAIR_LOCATION}',
        options: {
          'rc_vg_all': 'all',
          'rc_vg_front': 'front',
          'rc_vg_side': 'side',
          'rc_vg_rear': 'rear',
        },
        pdfOptions: ['all', 'front', 'side', 'rear'],
      ),
      VerbatimToken(
        '{RC_VALLEY_GUTTERS_REPAIR_ISSUE}',
        options: {
          'rc_vgi_blocked': 'blocked',
          'rc_vgi_loose_mortar': 'has loose mortar',
          'rc_vgi_misaligned': 'poorly aligned',
        },
        pdfOptions: ['blocked', 'has loose mortar', 'poorly aligned'],
      ),
    ],
    pdf:
        'Repair valley gutters: The valley gutter at the junction of the roofs to all, front, side, rear, of the building is blocked, has loose mortar, poorly aligned.',
    pdfMore: [
      'This should be repaired soon, now.',
    ],
    whenField: 'actv_condition',
    whenValue: 'Repair soon',
  ),
  VerbatimRule(
    'e2_vgrepair_now',
    'activity_outside_property_roof_repair_valley_gutters',
    '{E_ROOF_COVERING_REPAIR}',
    '{E_RC_VALLEY_GUTTERS_REPAIR_NOW}',
    [
      VerbatimToken(
        '{RC_VALLEY_GUTTERS_REPAIR_LOCATION}',
        options: {
          'rc_vg_all': 'all',
          'rc_vg_front': 'front',
          'rc_vg_side': 'side',
          'rc_vg_rear': 'rear',
        },
        pdfOptions: ['all', 'front', 'side', 'rear'],
      ),
      VerbatimToken(
        '{RC_VALLEY_GUTTERS_REPAIR_ISSUE}',
        options: {
          'rc_vgi_blocked': 'blocked',
          'rc_vgi_loose_mortar': 'has loose mortar',
          'rc_vgi_misaligned': 'poorly aligned',
        },
        pdfOptions: ['blocked', 'has loose mortar', 'poorly aligned'],
      ),
    ],
    whenField: 'actv_condition',
    whenValue: 'Repair now',
  ),
  VerbatimRule(
    'e2_flrepair_soon',
    'activity_outside_property_roof_repair_flashing',
    '{E_RC_FLASHING_REPAIR}',
    '{REPAIR_SOON}',
    [
    ],
    pdf:
        'Repair flashing: The waterproofing at the junction of the roof covering and wall is damaged or defective.',
    pdfMore: [
      'This should be repaired soon, repaired now.',
    ],
    whenField: 'actv_condition',
    whenValue: 'Repair soon',
  ),
  VerbatimRule(
    'e2_flrepair_now',
    'activity_outside_property_roof_repair_flashing',
    '{E_RC_FLASHING_REPAIR}',
    '{REPAIR_NOW}',
    [
    ],
    whenField: 'actv_condition',
    whenValue: 'Repair now',
  ),
  VerbatimRule(
    'e2_flrepair_damp',
    'activity_outside_property_roof_repair_flashing',
    '{E_RC_FLASHING_REPAIR}',
    '{CAUSING_DAMP}',
    [
    ],
    whenField: 'cb_causing_damp',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e2_ridgerepair_soon',
    'activity_outside_property_roof_repair_ridge_tiles',
    '{E_RC_RIDGE_TILES_REPAIR}',
    '{REPAIR_SOON}',
    [
    ],
    pdf:
        'Repair ridge tiles: The covering along the top of the roof structure called, the ridge tiles, is damaged or defective.',
    pdfMore: [
      'This should be repaired soon, repaired now.',
    ],
    whenField: 'actv_condition',
    whenValue: 'Repair soon',
  ),
  VerbatimRule(
    'e2_ridgerepair_now',
    'activity_outside_property_roof_repair_ridge_tiles',
    '{E_RC_RIDGE_TILES_REPAIR}',
    '{REPAIR_NOW}',
    [
    ],
    whenField: 'actv_condition',
    whenValue: 'Repair now',
  ),
  VerbatimRule(
    'e2_hiprepair_soon',
    'activity_outside_property_roof_repair_hip_tiles',
    '{E_RC_HIP_TILES_REPAIR}',
    '{REPAIR_SOON}',
    [
    ],
    pdf:
        'Repair hip tile: The covering along the slope of the roof structure (called the hip tiles) is damaged or defective.',
    pdfMore: [
      'This should be repaired soon, repaired now.',
    ],
    whenField: 'actv_condition',
    whenValue: 'Repair soon',
  ),
  VerbatimRule(
    'e2_hiprepair_now',
    'activity_outside_property_roof_repair_hip_tiles',
    '{E_RC_HIP_TILES_REPAIR}',
    '{REPAIR_NOW}',
    [
    ],
    whenField: 'actv_condition',
    whenValue: 'Repair now',
  ),
  VerbatimRule(
    'e2_general_maintenance',
    'activity_outside_property_roof_covering_summary',
    '{E_ROOF_COVERING}',
    '{GENERAL_MAINTENANCE}',
    [
    ],
    whenField: 'cb_general_maintenance',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e3_desc',
    'activity_outside_property_rwg_about',
    '{E_RAINWATER_GOODS_ABOUT}',
    '{RWG_ABOUT_TYPE}',
    [
      VerbatimToken(
        '{RWG_TYPE}',
        options: {
          'rwg_pvc': 'PVC',
          'cb_cast_iron': 'cast iron',
          'rwg_aluminium': 'aluminium',
          'rwg_steel': 'steel',
          'cb_concrete': 'concrete',
          'cb_asbestos_cement': 'asbestos cement',
        },
        otherCheckbox: 'cb_other_697',
        otherText: 'et_other_427',
        pdfOptions: ['PVC', 'cast iron', 'aluminium', 'steel', 'concrete', 'asbestos cement'],
      ),
    ],
    pdf:
        'Description: The rainwater goods comprise PVC, cast iron, aluminium, steel, concrete, asbestos cement, other, gutters, downpipes, hoppers, and associated fittings.',
  ),
  VerbatimRule(
    'e3_cond',
    'activity_outside_property_rwg_about',
    '{E_RAINWATER_GOODS_ABOUT}',
    '{RWG_ABOUT_CONDITION}',
    [
      VerbatimToken(
        '{RWG_CONDITION}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Condition: Where visible, the rainwater goods appear in good, reasonable, fair, poor, very poor condition, consistent with their age and type.',
  ),
  VerbatimRule(
    'e3_asbestos',
    'activity_outside_property_rwg_about',
    '{E_RAINWATER_GOODS_ABOUT}',
    '{RWG_IF_TYPE_ASBESTOS_CEMENT}',
    [
    ],
    whenField: 'cb_asbestos_cement',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e3_shared',
    'activity_outside_property_rwg_about',
    '{E_RAINWATER_GOODS_ABOUT}',
    '{RAINWATER_GOODS_SHARED}',
    [
    ],
    whenField: 'cb_Shared',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e3_general',
    'activity_outside_property_rwg_about',
    '{E_RAINWATER_GOODS_ABOUT}',
    '{RWG_STANDARD_TEXT}',
    [
    ],
    whenField: 'actv_condition',
    whenValue: 'Good',
    whenAny: [['actv_condition', 'Reasonable'], ['actv_condition', 'Fair'], ['actv_condition', 'Poor'], ['actv_condition', 'Very poor']],
  ),
  VerbatimRule(
    'e3_damaged_soon',
    'activity_outside_property_rwg__repair_pipes_gutters',
    '{E_RAINWATER_GOODS_ABOUT}',
    '{RWG_REPAIR_SOON}',
    [
      VerbatimToken(
        '{RWG_REPAIR_DEFECT}',
        options: {
          'rwg_dm_cracked': 'cracked',
          'rwg_dm_distorted': 'distorted',
          'rwg_dm_broken': 'broken',
          'rwg_dm_split': 'split',
          'rwg_dm_missing': 'missing',
        },
        otherCheckbox: 'rwg_dm_other',
        otherText: 'rwg_dm_other_text',
        pdfOptions: ['cracked', 'distorted', 'broken', 'split', 'missing'],
      ),
    ],
    pdf:
        'Damaged Sections: Sections of the gutters or downpipes are cracked, distorted, broken, split, missing, other.',
    pdfMore: [
      'This should be repaired soon, repaired now.',
    ],
    whenField: 'actv_condition',
    whenValue: 'Repair soon',
  ),
  VerbatimRule(
    'e3_damaged_now',
    'activity_outside_property_rwg__repair_pipes_gutters',
    '{E_RAINWATER_GOODS_ABOUT}',
    '{RWG_REPAIR_NOW}',
    [
      VerbatimToken(
        '{RWG_REPAIR_DEFECT}',
        options: {
          'rwg_dm_cracked': 'cracked',
          'rwg_dm_distorted': 'distorted',
          'rwg_dm_broken': 'broken',
          'rwg_dm_split': 'split',
          'rwg_dm_missing': 'missing',
        },
        otherCheckbox: 'rwg_dm_other',
        otherText: 'rwg_dm_other_text',
        pdfOptions: ['cracked', 'distorted', 'broken', 'split', 'missing'],
      ),
    ],
    whenField: 'actv_condition',
    whenValue: 'Repair now',
  ),
  VerbatimRule(
    'e3_slope',
    'activity_outside_property_rwg_insufficient_slope',
    '{E_RAINWATER_GOODS_ABOUT}',
    '{RWG_IF_TYPE_IF_INSUFFICIENT_SLOPE}',
    [
    ],
    whenField: 'cb_insufficient_slope',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e3_leakage',
    'activity_outside_property_rwg_leakage',
    '{E_RAINWATER_GOODS_ABOUT}',
    '{RWG_LEAKAGE}',
    [
    ],
    whenField: 'cb_leakage',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e3_conn_soon',
    'activity_outside_property_rwg_defective_connections',
    '{E_RAINWATER_GOODS_ABOUT}',
    '{RWG_CONNECTIONS_SOON}',
    [
      VerbatimToken(
        '{RWG_CONNECTION_DEFECT}',
        options: {
          'rwg_cn_loose': 'loose',
          'rwg_cn_missing': 'missing',
          'rwg_cn_leaking': 'leaking',
          'rwg_cn_displaced': 'displaced',
          'rwg_cn_defective': 'defective',
        },
        otherCheckbox: 'rwg_cn_other',
        otherText: 'rwg_cn_other_text',
        pdfOptions: ['loose', 'missing', 'leaking', 'displaced', 'defective'],
      ),
    ],
    pdf:
        'Defective Connections: One or more gutter or downpipe joints and connections are loose, missing, leaking, displaced, defective, other.',
    pdfMore: [
      'This should be repaired soon, now.',
    ],
    whenField: 'actv_condition',
    whenValue: 'Repair soon',
  ),
  VerbatimRule(
    'e3_conn_now',
    'activity_outside_property_rwg_defective_connections',
    '{E_RAINWATER_GOODS_ABOUT}',
    '{RWG_CONNECTIONS_NOW}',
    [
      VerbatimToken(
        '{RWG_CONNECTION_DEFECT}',
        options: {
          'rwg_cn_loose': 'loose',
          'rwg_cn_missing': 'missing',
          'rwg_cn_leaking': 'leaking',
          'rwg_cn_displaced': 'displaced',
          'rwg_cn_defective': 'defective',
        },
        otherCheckbox: 'rwg_cn_other',
        otherText: 'rwg_cn_other_text',
        pdfOptions: ['loose', 'missing', 'leaking', 'displaced', 'defective'],
      ),
    ],
    whenField: 'actv_condition',
    whenValue: 'Repair now',
  ),
  VerbatimRule(
    'e3_corrosion',
    'activity_outside_property_rwg_corrosion',
    '{E_RAINWATER_GOODS_ABOUT}',
    '{RWG_CORROSION}',
    [
      VerbatimToken(
        '{RWG_CORROSION_LEVEL}',
        dropdown: 'actv_corrosion',
        dropdownOptions: ['Light', 'Moderate', 'Significant'],
        lower: true,
        pdfOptions: ['light', 'moderate', 'significant'],
      ),
    ],
    pdf:
        'Corrosion: Sections of the rainwater goods exhibit light, moderate, significant corrosion.',
  ),
  VerbatimRule(
    'e3_gullies',
    'activity_outside_property_rwg_blocked_gullies',
    '{E_RAINWATER_GOODS_ABOUT}',
    '{RWG_BLOCKED_GULLIES}',
    [
      VerbatimToken(
        '{RWG_GULLY_STATE}',
        dropdown: 'actv_gully_state',
        dropdownOptions: ['Partially blocked', 'Fully blocked'],
        lower: true,
        pdfOptions: ['partially blocked', 'fully blocked'],
      ),
    ],
    pdf:
        'Blocked Gullies: One or more drainage gullies serving the rainwater system appear partially blocked, fully blocked.',
  ),
  VerbatimRule(
    'e4_desc_solid',
    'activity_outside_property_main_walls_about_wall',
    '{E_MAIN_WALLS}',
    '{E4_DESCRIPTION}',
    [
      VerbatimToken(
        '{WALL_LOCATION}',
        options: {
          'e4w_loc_main_building': 'main building',
          'e4w_loc_extension_s': 'extension(s)',
        },
        otherCheckbox: 'cb_other_832',
        otherText: 'et_other_133',
        pdfOptions: ['main building', 'extension(s)'],
      ),
      VerbatimToken(
        '{WALL_THICKNESS}',
        text: 'et_thickness',
      ),
      VerbatimToken(
        '{WALL_TYPE}',
        constant: 'solid brick',
      ),
    ],
    pdf:
        'Description: The external walls of the main building, extension(s), other, are constructed of (type 000) mm solid brick, cavity brick, cavity blockwork, timber frame, rendered masonry, pebble dash masonry, other construction type(s).',
  ),
  VerbatimRule(
    'e4_cond_solid',
    'activity_outside_property_main_walls_about_wall',
    '{E_MAIN_WALLS}',
    '{E4_CONDITION}',
    [
      VerbatimToken(
        '{WALL_CONDITION_VALUE}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Condition: Where visible, the walls appear in good, reasonable, fair, poor, very poor condition, consistent with their age and type of construction.',
  ),
  VerbatimRule(
    'e4_painted_solid',
    'activity_outside_property_main_walls_about_wall',
    '{E_MAIN_WALLS}',
    '{E4_PAINTED}',
    [
    ],
    whenField: 'cb_painted',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e4_desc_cbrick',
    'activity_outside_property_main_walls_about_wall__cavity_brick_wall',
    '{E_MAIN_WALLS}',
    '{E4_DESCRIPTION}',
    [
      VerbatimToken(
        '{WALL_LOCATION}',
        options: {
          'e4w_loc_main_building': 'main building',
          'e4w_loc_extension_s': 'extension(s)',
        },
        otherCheckbox: 'cb_other_832',
        otherText: 'et_other_133',
        pdfOptions: ['main building', 'extension(s)'],
      ),
      VerbatimToken(
        '{WALL_THICKNESS}',
        text: 'et_thickness',
      ),
      VerbatimToken(
        '{WALL_TYPE}',
        constant: 'cavity brick',
      ),
    ],
    pdf:
        'Description: The external walls of the main building, extension(s), other, are constructed of (type 000) mm solid brick, cavity brick, cavity blockwork, timber frame, rendered masonry, pebble dash masonry, other construction type(s).',
  ),
  VerbatimRule(
    'e4_cond_cbrick',
    'activity_outside_property_main_walls_about_wall__cavity_brick_wall',
    '{E_MAIN_WALLS}',
    '{E4_CONDITION}',
    [
      VerbatimToken(
        '{WALL_CONDITION_VALUE}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Condition: Where visible, the walls appear in good, reasonable, fair, poor, very poor condition, consistent with their age and type of construction.',
  ),
  VerbatimRule(
    'e4_painted_cbrick',
    'activity_outside_property_main_walls_about_wall__cavity_brick_wall',
    '{E_MAIN_WALLS}',
    '{E4_PAINTED}',
    [
    ],
    whenField: 'cb_painted',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e4_desc_cblock',
    'activity_outside_property_main_walls_about_wall__cavity_block_wall',
    '{E_MAIN_WALLS}',
    '{E4_DESCRIPTION}',
    [
      VerbatimToken(
        '{WALL_LOCATION}',
        options: {
          'e4w_loc_main_building': 'main building',
          'e4w_loc_extension_s': 'extension(s)',
        },
        otherCheckbox: 'cb_other_832',
        otherText: 'et_other_133',
        pdfOptions: ['main building', 'extension(s)'],
      ),
      VerbatimToken(
        '{WALL_THICKNESS}',
        text: 'et_thickness',
      ),
      VerbatimToken(
        '{WALL_TYPE}',
        constant: 'cavity blockwork',
      ),
    ],
    pdf:
        'Description: The external walls of the main building, extension(s), other, are constructed of (type 000) mm solid brick, cavity brick, cavity blockwork, timber frame, rendered masonry, pebble dash masonry, other construction type(s).',
  ),
  VerbatimRule(
    'e4_cond_cblock',
    'activity_outside_property_main_walls_about_wall__cavity_block_wall',
    '{E_MAIN_WALLS}',
    '{E4_CONDITION}',
    [
      VerbatimToken(
        '{WALL_CONDITION_VALUE}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Condition: Where visible, the walls appear in good, reasonable, fair, poor, very poor condition, consistent with their age and type of construction.',
  ),
  VerbatimRule(
    'e4_painted_cblock',
    'activity_outside_property_main_walls_about_wall__cavity_block_wall',
    '{E_MAIN_WALLS}',
    '{E4_PAINTED}',
    [
    ],
    whenField: 'cb_painted',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e4_desc_stud',
    'activity_outside_property_main_walls_about_wall__cavity_stud_wall',
    '{E_MAIN_WALLS}',
    '{E4_DESCRIPTION}',
    [
      VerbatimToken(
        '{WALL_LOCATION}',
        options: {
          'e4w_loc_main_building': 'main building',
          'e4w_loc_extension_s': 'extension(s)',
        },
        otherCheckbox: 'cb_other_832',
        otherText: 'et_other_133',
        pdfOptions: ['main building', 'extension(s)'],
      ),
      VerbatimToken(
        '{WALL_THICKNESS}',
        text: 'et_thickness',
      ),
      VerbatimToken(
        '{WALL_TYPE}',
        constant: 'timber frame',
      ),
    ],
    pdf:
        'Description: The external walls of the main building, extension(s), other, are constructed of (type 000) mm solid brick, cavity brick, cavity blockwork, timber frame, rendered masonry, pebble dash masonry, other construction type(s).',
  ),
  VerbatimRule(
    'e4_cond_stud',
    'activity_outside_property_main_walls_about_wall__cavity_stud_wall',
    '{E_MAIN_WALLS}',
    '{E4_CONDITION}',
    [
      VerbatimToken(
        '{WALL_CONDITION_VALUE}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Condition: Where visible, the walls appear in good, reasonable, fair, poor, very poor condition, consistent with their age and type of construction.',
  ),
  VerbatimRule(
    'e4_painted_stud',
    'activity_outside_property_main_walls_about_wall__cavity_stud_wall',
    '{E_MAIN_WALLS}',
    '{E4_PAINTED}',
    [
    ],
    whenField: 'cb_painted',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e4_desc_other',
    'activity_outside_property_main_walls_about_wall__other',
    '{E_MAIN_WALLS}',
    '{E4_DESCRIPTION}',
    [
      VerbatimToken(
        '{WALL_LOCATION}',
        options: {
          'e4w_loc_main_building': 'main building',
          'e4w_loc_extension_s': 'extension(s)',
        },
        otherCheckbox: 'cb_other_832',
        otherText: 'et_other_133',
        pdfOptions: ['main building', 'extension(s)'],
      ),
      VerbatimToken(
        '{WALL_THICKNESS}',
        text: 'et_thickness',
      ),
      VerbatimToken(
        '{WALL_TYPE}',
        text: 'other',
      ),
    ],
    pdf:
        'Description: The external walls of the main building, extension(s), other, are constructed of (type 000) mm solid brick, cavity brick, cavity blockwork, timber frame, rendered masonry, pebble dash masonry, other construction type(s).',
  ),
  VerbatimRule(
    'e4_cond_other',
    'activity_outside_property_main_walls_about_wall__other',
    '{E_MAIN_WALLS}',
    '{E4_CONDITION}',
    [
      VerbatimToken(
        '{WALL_CONDITION_VALUE}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Condition: Where visible, the walls appear in good, reasonable, fair, poor, very poor condition, consistent with their age and type of construction.',
  ),
  VerbatimRule(
    'e4_painted_other',
    'activity_outside_property_main_walls_about_wall__other',
    '{E_MAIN_WALLS}',
    '{E4_PAINTED}',
    [
    ],
    whenField: 'cb_painted',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e4_desc_rendered',
    'activity_outside_property_main_walls_about_wall__rendered_masonry',
    '{E_MAIN_WALLS}',
    '{E4_DESCRIPTION}',
    [
      VerbatimToken(
        '{WALL_LOCATION}',
        options: {
          'e4w_loc_main_building': 'main building',
          'e4w_loc_extension_s': 'extension(s)',
        },
        otherCheckbox: 'cb_other_832',
        otherText: 'et_other_133',
        pdfOptions: ['main building', 'extension(s)'],
      ),
      VerbatimToken(
        '{WALL_THICKNESS}',
        text: 'et_thickness',
      ),
      VerbatimToken(
        '{WALL_TYPE}',
        constant: 'rendered masonry',
      ),
    ],
    pdf:
        'Description: The external walls of the main building, extension(s), other, are constructed of (type 000) mm solid brick, cavity brick, cavity blockwork, timber frame, rendered masonry, pebble dash masonry, other construction type(s).',
  ),
  VerbatimRule(
    'e4_cond_rendered',
    'activity_outside_property_main_walls_about_wall__rendered_masonry',
    '{E_MAIN_WALLS}',
    '{E4_CONDITION}',
    [
      VerbatimToken(
        '{WALL_CONDITION_VALUE}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Condition: Where visible, the walls appear in good, reasonable, fair, poor, very poor condition, consistent with their age and type of construction.',
  ),
  VerbatimRule(
    'e4_painted_rendered',
    'activity_outside_property_main_walls_about_wall__rendered_masonry',
    '{E_MAIN_WALLS}',
    '{E4_PAINTED}',
    [
    ],
    whenField: 'cb_painted',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e4_desc_pebble',
    'activity_outside_property_main_walls_about_wall__pebble_dash_masonry',
    '{E_MAIN_WALLS}',
    '{E4_DESCRIPTION}',
    [
      VerbatimToken(
        '{WALL_LOCATION}',
        options: {
          'e4w_loc_main_building': 'main building',
          'e4w_loc_extension_s': 'extension(s)',
        },
        otherCheckbox: 'cb_other_832',
        otherText: 'et_other_133',
        pdfOptions: ['main building', 'extension(s)'],
      ),
      VerbatimToken(
        '{WALL_THICKNESS}',
        text: 'et_thickness',
      ),
      VerbatimToken(
        '{WALL_TYPE}',
        constant: 'pebble dash masonry',
      ),
    ],
    pdf:
        'Description: The external walls of the main building, extension(s), other, are constructed of (type 000) mm solid brick, cavity brick, cavity blockwork, timber frame, rendered masonry, pebble dash masonry, other construction type(s).',
  ),
  VerbatimRule(
    'e4_cond_pebble',
    'activity_outside_property_main_walls_about_wall__pebble_dash_masonry',
    '{E_MAIN_WALLS}',
    '{E4_CONDITION}',
    [
      VerbatimToken(
        '{WALL_CONDITION_VALUE}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Condition: Where visible, the walls appear in good, reasonable, fair, poor, very poor condition, consistent with their age and type of construction.',
  ),
  VerbatimRule(
    'e4_painted_pebble',
    'activity_outside_property_main_walls_about_wall__pebble_dash_masonry',
    '{E_MAIN_WALLS}',
    '{E4_PAINTED}',
    [
    ],
    whenField: 'cb_painted',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e4_cladding',
    'activity_outside_property_main_walls_cladding',
    '{E_MAIN_WALLS}',
    '{E4_CLADDING}',
    [
      VerbatimToken(
        '{WALL_CLADDING}',
        options: {
          'e4c_facing_brickwork': 'facing brickwork',
          'e4c_natural_or_reconstituted_stone': 'natural or reconstituted stone',
          'e4c_timber_cladding': 'timber cladding',
          'e4c_plastic_panelling_boards': 'plastic panelling boards',
          'e4c_weatherboarding': 'weatherboarding',
          'e4c_fibre_cement_boards': 'fibre cement boards',
          'e4c_upvc_cladding': 'uPVC cladding',
          'e4c_fibre_cement_panels': 'fibre cement panels',
          'e4c_composite_cladding_panels': 'composite cladding panels',
          'e4c_glass_curtain_walling': 'glass curtain walling',
          'e4c_hanging_tiles_including_shingle_or_plain_tiles': 'hanging tiles (including shingle or plain tiles)',
          'e4c_aluminium_cladding_panels': 'aluminium cladding panels',
          'e4c_terracotta_cladding_tiles': 'terracotta cladding tiles',
        },
        otherCheckbox: 'e4c_other',
        otherText: 'e4c_other_text',
        pdfOptions: ['facing brickwork', 'natural or reconstituted stone', 'timber cladding', 'plastic panelling boards', 'weatherboarding', 'fibre cement boards', 'uPVC cladding', 'fibre cement panels', 'composite cladding panels', 'glass curtain walling', 'hanging tiles (including shingle or plain tiles)', 'aluminium cladding panels', 'terracotta cladding tiles'],
      ),
    ],
    pdf:
        'Cladding: The external wall finish or cladding comprises facing brickwork, natural or reconstituted stone, timber cladding, plastic panelling boards.',
    pdfMore: [
      'weatherboarding, fibre cement boards, uPVC cladding, fibre cement panels, composite cladding panels, glass curtain walling, hanging tiles (including shingle or plain tiles), aluminium cladding panels, terracotta cladding tiles, other finishes.',
    ],
  ),
  VerbatimRule(
    'e4_ews1',
    'activity_outside_property_main_walls_ews1',
    '{E_MAIN_WALLS}',
    '{E4_EWS1_CLADDING}',
    [
      VerbatimToken(
        '{EWS1_EXTENT}',
        dropdown: 'actv_ews1_extent',
        dropdownOptions: ['Partially', 'Predominantly'],
        lower: true,
        pdfOptions: ['partially', 'predominantly'],
      ),
      VerbatimToken(
        '{EWS1_TYPES}',
        options: {
          'e4e_brick_slip': 'brick-slip',
          'e4e_brick_effect_outer_face': 'brick-effect outer face',
          'e4e_rainscreen_boards': 'rainscreen boards',
          'e4e_terracotta_tiles': 'terracotta tiles',
          'e4e_compressed_composite_boards': 'compressed composite boards',
          'e4e_aluminium_panels': 'aluminium panels',
          'e4e_glass_reinforced_concrete_grc_panels': 'glass reinforced concrete (GRC) panels',
          'e4e_glass_curtain_walling': 'glass curtain walling',
          'e4e_hanging_tiles_including_shingle_or_plain_tiles': 'hanging tiles (including shingle or plain tiles)',
          'e4e_aluminium_cladding_panels': 'aluminium cladding panels',
        },
        pdfOptions: ['brick-slip', 'brick-effect outer face', 'rainscreen boards', 'terracotta tiles', 'compressed composite boards', 'aluminium panels', 'glass reinforced concrete (GRC) panels', 'glass curtain walling', 'hanging tiles (including shingle or plain tiles)', 'aluminium cladding panels'],
      ),
    ],
    pdf:
        'EWS1 Cladding: The external walls are partially or predominantly cladded with a brick-slip, brick-effect outer face, rainscreen boards, terracotta tiles, compressed composite boards, aluminium panels, glass reinforced concrete (GRC) panels, glass curtain walling, hanging tiles (including shingle or plain tiles), aluminium cladding panels, etc.',
  ),
  VerbatimRule(
    'e4_ews1_not',
    'activity_outside_property_main_walls_ews1',
    '{E_MAIN_WALLS}',
    '{E4_EWS1_NOT_REQUIRED}',
    [
    ],
    whenField: 'actv_ews1',
    whenValue: 'EWS1 form not required',
  ),
  VerbatimRule(
    'e4_ews1_req',
    'activity_outside_property_main_walls_ews1',
    '{E_MAIN_WALLS}',
    '{E4_EWS1_REQUIRED}',
    [
    ],
    whenField: 'actv_ews1',
    whenValue: 'EWS1 form required',
  ),
  VerbatimRule(
    'e4_moisture',
    'activity_outside_property_main_walls_damp',
    '{E_MAIN_WALLS}',
    '{E4_MOISTURE_READINGS}',
    [
    ],
    whenField: 'actv_status',
    whenValue: 'No damp found',
    whenAny: [['actv_status', 'Damp found']],
  ),
  VerbatimRule(
    'e4_nodamp',
    'activity_outside_property_main_walls_damp',
    '{E_MAIN_WALLS}',
    '{E4_NO_DAMP}',
    [
    ],
    whenField: 'actv_status',
    whenValue: 'No damp found',
  ),
  VerbatimRule(
    'e4_damp',
    'activity_outside_property_main_walls_damp',
    '{E_MAIN_WALLS}',
    '{E4_DAMP_FOUND}',
    [
      VerbatimToken(
        '{DAMP_LOCATIONS}',
        text: 'et_location_677',
      ),
    ],
    pdf:
        'Damp found: Elevated moisture readings were recorded to sections of the internal wall surfaces that include (enter locations).',
    whenField: 'actv_status',
    whenValue: 'Damp found',
  ),
  VerbatimRule(
    'e4_pen',
    'activity_outside_property_main_walls_damp',
    '{E_MAIN_WALLS}',
    '{E4_PENETRATING}',
    [
      VerbatimToken(
        '{DAMP_CAUSES}',
        options: {
          'e4d_cause_overflowing_gutter': 'overflowing gutter',
          'e4d_cause_roof_leak': 'roof leak',
          'e4d_cause_leaking_downpipe': 'leaking downpipe',
          'e4d_cause_bridged_dpc': 'bridged DPC',
          'e4d_cause_blocked_gully': 'blocked gully',
        },
        otherCheckbox: 'e4d_cause_other',
        otherText: 'e4d_cause_other_text',
        pdfOptions: ['overflowing gutter', 'roof leak', 'leaking downpipe', 'bridged DPC', 'blocked gully'],
      ),
    ],
    pdf:
        'Penetrating damp cause: This may have been affected by penetrating damp probably caused by overflowing gutter, roof leak, leaking downpipe, bridged DPC, blocked gully, other.',
    whenField: 'actv_status',
    whenValue: 'Damp found',
  ),
  VerbatimRule(
    'e4_repair_opts',
    'activity_outside_property_main_walls_damp',
    '{E_MAIN_WALLS}',
    '{E4_REPAIR_OPTIONS}',
    [
      VerbatimToken(
        '{DAMP_REPAIRS}',
        options: {
          'e4d_rep_gutters': 'gutters',
          'e4d_rep_roof_covering': 'roof covering',
          'e4d_rep_downpipes': 'downpipes',
          'e4d_rep_damp_proof_course': 'damp-proof course',
          'e4d_rep_blocked_gullies': 'blocked gullies',
          'e4d_rep_damaged_drainage': 'damaged drainage',
        },
        otherCheckbox: 'e4d_rep_other',
        otherText: 'e4d_rep_other_text',
        pdfOptions: ['gutters', 'roof covering', 'downpipes', 'damp-proof course', 'blocked gullies', 'damaged drainage'],
      ),
    ],
    pdf:
        'This may involve repairs to the gutters, roof covering, downpipes, damp-proof course, blocked gullies, damaged drainage, other, as appropriate.',
    whenField: 'actv_status',
    whenValue: 'Damp found',
  ),
  VerbatimRule(
    'e4_investigate',
    'activity_outside_property_main_walls_damp',
    '{E_MAIN_WALLS}',
    '{E4_INVESTIGATE_CAUSE}',
    [
    ],
    whenField: 'cb_unknown_cause',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e4_rising',
    'activity_outside_property_main_walls_damp',
    '{E_MAIN_WALLS}',
    '{E4_RISING_DAMP}',
    [
    ],
    whenField: 'cb_rising_damp',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e4_drain',
    'activity_outside_property_main_walls_damp',
    '{E_MAIN_WALLS}',
    '{E4_INSTALL_DRAIN_GUTTERING}',
    [
    ],
    whenField: 'cb_install_french_gutters',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e4_dpc',
    'activity_outside_property_main_walls_dpc',
    '{E_MAIN_WALLS}',
    '{E4_DPC}',
    [
      VerbatimToken(
        '{DPC_STATE}',
        dropdown: 'actv_status',
        dropdownOptions: ['Visible', 'Partially visible', 'Not visible'],
        lower: true,
        pdfOptions: ['visible', 'partially visible', 'not visible'],
      ),
    ],
    pdf:
        'Damp-proof course: The walls have a barrier against dampness rising from the ground (called a damp-proof course or DPC is visible, partially visible, not visible; one would normally be expected for a property of this age and type.',
  ),
  VerbatimRule(
    'e4_dpc_material',
    'activity_outside_property_main_walls_dpc',
    '{E_MAIN_WALLS}',
    '{E4_DPC_MATERIAL}',
    [
      VerbatimToken(
        '{DPC_MATERIAL}',
        options: {
          'e4p_plastic': 'plastic',
          'e4p_felt': 'felt',
          'e4p_slates': 'slates',
          'e4p_engineering_bricks': 'engineering bricks',
        },
        otherCheckbox: 'e4p_other',
        otherText: 'e4p_other_text',
        pdfOptions: ['plastic', 'felt', 'slates', 'engineering bricks'],
      ),
    ],
    pdf:
        'The DPC is assumed to consist of plastic, felt, slates, engineering bricks, other.',
  ),
  VerbatimRule(
    'e4_dpc_adequacy',
    'activity_outside_property_main_walls_dpc',
    '{E_MAIN_WALLS}',
    '{E4_DPC_ADEQUACY}',
    [
    ],
    whenField: 'actv_status',
    whenValue: 'Visible',
    whenAny: [['actv_status', 'Partially visible'], ['actv_status', 'Not visible']],
  ),
  VerbatimRule(
    'e4_treatment',
    'activity_outside_property_main_walls_dpc_treatment',
    '{E_MAIN_WALLS}',
    '{E4_DPC_TREATMENT}',
    [
      VerbatimToken(
        '{DPC_TREATMENT}',
        options: {
          'e4t_damp_proof_course_treatment': 'damp proof course treatment',
          'e4t_wall_ventilation_apparatus': 'wall ventilation apparatus',
          'e4t_ventilation_holes': 'ventilation holes',
        },
        otherCheckbox: 'e4t_other',
        otherText: 'e4t_other_text',
        pdfOptions: ['damp proof course treatment', 'wall ventilation apparatus', 'ventilation holes'],
      ),
    ],
    pdf:
        'DPC Treatment noted: I noted evidence of damp proof course treatment, wall ventilation apparatus, ventilation holes, other in the property.',
  ),
  VerbatimRule(
    'e4_removed',
    'activity_outside_property_main_walls_removed_wall',
    '{E_MAIN_WALLS}',
    '{E4_REMOVED_WALL}',
    [
      VerbatimToken(
        '{REMOVED_LOCATION}',
        options: {
          'e4r_lounge': 'lounge',
          'e4r_kitchen': 'kitchen',
          'e4r_bedroom': 'bedroom',
        },
        otherCheckbox: 'cb_other_1020',
        otherText: 'et_other_522',
        pdfOptions: ['lounge', 'kitchen', 'bedroom'],
      ),
    ],
    pdf:
        'Removed wall: An external wall to the lounge, kitchen, bedroom, other appears to have been removed as part of previous alterations.',
  ),
  VerbatimRule(
    'e4_removed_defect',
    'activity_outside_property_main_walls_removed_wall',
    '{E_MAIN_WALLS}',
    '{E4_REMOVED_DEFECT}',
    [
      VerbatimToken(
        '{REMOVED_DEFECTS}',
        options: {
          'e4rd_cracking': 'cracking',
          'e4rd_distortions': 'distortions',
        },
        otherCheckbox: 'e4rd_other',
        otherText: 'e4rd_other_text',
        pdfOptions: ['cracking', 'distortions'],
      ),
    ],
    pdf:
        'Defect noted: I noted cracking, distortions, other in the surrounding wall surfaces.',
  ),
  VerbatimRule(
    'e4_extensions',
    'activity_outside_property_main_walls_extensions',
    '{E_MAIN_WALLS}',
    '{E4_EXTENSIONS}',
    [
      VerbatimToken(
        '{EXT_ALTERATIONS}',
        options: {
          'e4x_wall_removal': 'wall removal',
          'e4x_new_openings': 'new openings',
          'e4x_replacement_lintels': 'replacement lintels',
          'e4x_structural_alterations': 'structural alterations',
          'e4x_building_extension_works': 'building extension works',
        },
        otherCheckbox: 'e4x_other',
        otherText: 'e4x_other_text',
        pdfOptions: ['wall removal', 'new openings', 'replacement lintels', 'structural alterations', 'building extension works'],
      ),
    ],
    pdf:
        'These include wall removal, new openings, replacement lintels, structural alterations, building extension works, other alterations.',
  ),
  VerbatimRule(
    'e4_cwi',
    'activity_outside_property_main_wall_repairs_cavity_wall_insulation',
    '{E_MAIN_WALLS}',
    '{E4_CAVITY_WALL_INSULATION}',
    [
    ],
    whenField: 'cb_not_inspected',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e4_thin',
    'activity_outside_property_main_wall_repairs_thin_slim_wall',
    '{E_MAIN_WALLS}',
    '{E4_THIN_WALL}',
    [
      VerbatimToken(
        '{THIN_WALLS}',
        options: {
          'e4tw_front': 'front',
          'e4tw_rear': 'rear',
          'e4tw_side': 'side',
        },
        pdfOptions: ['front', 'rear', 'side'],
      ),
      VerbatimToken(
        '{THIN_LOCATIONS}',
        options: {
          'e4tl_main_building': 'main building',
          'e4tl_extension': 'extension',
        },
        otherCheckbox: 'cb_other_423',
        otherText: 'et_other_883',
        pdfOptions: ['main building', 'extension'],
      ),
    ],
    pdf:
        'Thin wall: The external wall to the front, rear, side walls of the main building, extension, other is not thick enough and vulnerable to damp problems and heat loss.',
  ),
  VerbatimRule(
    'e4_trees',
    'activity_outside_property_main_wall_repairs_near_by_tress',
    '{E_MAIN_WALLS}',
    '{E4_TREES}',
    [
    ],
    whenField: 'actv_trees',
    whenValue: 'Trees',
  ),
  VerbatimRule(
    'e4_tree_defects',
    'activity_outside_property_main_wall_repairs_near_by_tress',
    '{E_MAIN_WALLS}',
    '{E4_TREE_DEFECTS}',
    [
      VerbatimToken(
        '{TREE_DEFECTS}',
        options: {
          'e4td_cracking': 'cracking',
          'e4td_distortion': 'distortion',
          'e4td_heave': 'heave',
        },
        otherCheckbox: 'e4td_other',
        otherText: 'e4td_other_text',
        pdfOptions: ['cracking', 'distortion', 'heave'],
      ),
    ],
    pdf:
        'Tree defects noted: There are trees located close to the property, and I noted defects that may be associated with their influence, including cracking, distortion, heave, other observed defects.',
    whenField: 'actv_trees',
    whenValue: 'Tree defects noted',
  ),
  VerbatimRule(
    'e4_mv_0',
    'activity_outside_property_main_walls_movements',
    '{E_MAIN_WALLS}',
    '{E4_MOVE_0}',
    [
    ],
    whenField: 'actv_movement_status',
    whenValue: 'Minor subsidence',
  ),
  VerbatimRule(
    'e4_mv_1',
    'activity_outside_property_main_walls_movements',
    '{E_MAIN_WALLS}',
    '{E4_MOVE_1}',
    [
    ],
    whenField: 'actv_movement_status',
    whenValue: 'Significant subsidence',
  ),
  VerbatimRule(
    'e4_mv_2',
    'activity_outside_property_main_walls_movements',
    '{E_MAIN_WALLS}',
    '{E4_MOVE_2}',
    [
    ],
    whenField: 'actv_movement_status',
    whenValue: 'No structural movement',
  ),
  VerbatimRule(
    'e4_mv_3',
    'activity_outside_property_main_walls_movements',
    '{E_MAIN_WALLS}',
    '{E4_MOVE_3}',
    [
    ],
    whenField: 'actv_movement_status',
    whenValue: 'Normal defects',
  ),
  VerbatimRule(
    'e4_mv_recent',
    'activity_outside_property_main_walls_movements',
    '{E_MAIN_WALLS}',
    '{E4_MOVE_RECENT}',
    [
      VerbatimToken(
        '{MOVE_WALLS}',
        options: {
          'e4m_w_front': 'front',
          'e4m_w_side': 'side',
          'e4m_w_rear': 'rear',
        },
        pdfOptions: ['front', 'side', 'rear'],
      ),
      VerbatimToken(
        '{MOVE_LOCATIONS}',
        options: {
          'e4m_l_main_building': 'main building',
          'e4m_l_back_addition': 'back addition',
          'e4m_l_extension': 'extension',
          'e4m_l_bay_window': 'bay window',
          'e4m_l_porch': 'porch',
        },
        otherCheckbox: 'e4m_l_other',
        otherText: 'e4m_l_other_text',
        pdfOptions: ['main building', 'back addition', 'extension', 'bay window', 'porch'],
      ),
      VerbatimToken(
        '{MOVE_CAUSES}',
        options: {
          'e4m_c_settlement': 'settlement',
          'e4m_c_subsidence': 'subsidence',
          'e4m_c_nearby_vegetation': 'nearby vegetation',
          'e4m_c_point_loading': 'point loading',
          'e4m_c_wall_tie_damage': 'wall tie damage',
        },
        otherCheckbox: 'e4m_c_other',
        otherText: 'e4m_c_other_text',
        pdfOptions: ['settlement', 'subsidence', 'nearby vegetation', 'point loading', 'wall tie damage'],
      ),
    ],
    pdf:
        'Recent defects: The front, side, rear walls of the main building, back addition, extension, bay window, porch, other areas have been damaged by movement cracks potentially arising from settlement, subsidence, nearby vegetation, point loading, wall tie damage, other causes, and this is considered structurally significant.',
    whenField: 'actv_movement_status',
    whenValue: 'Recent defects',
  ),
  VerbatimRule(
    'e4_mv_recurring',
    'activity_outside_property_main_walls_movements',
    '{E_MAIN_WALLS}',
    '{E4_MOVE_RECURRING}',
    [
      VerbatimToken(
        '{MOVE_LOCATIONS_RECURRING}',
        options: {
          'e4m_r_main_building': 'main building',
          'e4m_r_back_addition': 'back addition',
          'e4m_r_extension': 'extension',
          'e4m_r_bay_window': 'bay window',
          'e4m_r_porch': 'porch',
        },
        otherCheckbox: 'e4m_r_other',
        otherText: 'e4m_r_other_text',
        pdfOptions: ['main building', 'back addition', 'extension', 'bay window', 'porch'],
      ),
    ],
    pdf:
        'Recurring defects: The outside wall(s) to the main building, back addition, extension, bay window, porch, other have been repaired, indicating that the building has been affected by previous movement.',
    whenField: 'actv_movement_status',
    whenValue: 'Recurring defects',
  ),
  VerbatimRule(
    'e4_mv_thermal',
    'activity_outside_property_main_walls_movements',
    '{E_MAIN_WALLS}',
    '{E4_MOVE_THERMAL}',
    [
    ],
    whenField: 'actv_movement_status',
    whenValue: 'Differential thermal movement',
  ),
  VerbatimRule(
    'e4_mv_rods',
    'activity_outside_property_main_walls_movements',
    '{E_MAIN_WALLS}',
    '{E4_MOVE_RODS}',
    [
    ],
    whenField: 'actv_movement_status',
    whenValue: 'Restraint steel rods',
  ),
  VerbatimRule(
    'e4_spall',
    'activity_outside_property_main_wall_repairs_spalling',
    '{E_MAIN_WALLS}',
    '{E4_SPALLING}',
    [
      VerbatimToken(
        '{SPALL_SEVERITY}',
        dropdown: 'actv_severity',
        dropdownOptions: ['Minor', 'Moderate', 'Significant'],
        lower: true,
        pdfOptions: ['minor', 'moderate', 'significant'],
      ),
    ],
    pdf:
        'Spalled Brickwork: A few bricks exhibit minor, moderate, significant deterioration (this is called spalling).',
  ),
  VerbatimRule(
    'e4_spall_damp',
    'activity_outside_property_main_wall_repairs_spalling',
    '{E_MAIN_WALLS}',
    '{E4_SPALLING_DAMP}',
    [
    ],
    whenField: 'cb_causing_damp',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e4_pointing',
    'activity_outside_property_main_wall_repairs_pointing',
    '{E_MAIN_WALLS}',
    '{E4_POINTING}',
    [
      VerbatimToken(
        '{POINTING_DEFECTS}',
        options: {
          'e4pt_eroded': 'eroded',
          'e4pt_cracked': 'cracked',
          'e4pt_loose': 'loose',
          'e4pt_missing': 'missing',
          'e4pt_damaged': 'damaged',
        },
        otherCheckbox: 'e4pt_other',
        otherText: 'e4pt_other_text',
        pdfOptions: ['eroded', 'cracked', 'loose', 'missing', 'damaged'],
      ),
    ],
    pdf:
        'Repair pointing: The mortar between the bricks (known as the pointing) to parts of the building is eroded, cracked, loose, missing, damaged, other.',
  ),
  VerbatimRule(
    'e4_pointing_damp',
    'activity_outside_property_main_wall_repairs_pointing',
    '{E_MAIN_WALLS}',
    '{E4_POINTING_DAMP}',
    [
    ],
    whenField: 'cb_causing_damp',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e4_render',
    'activity_outside_property_main_wall_repairs_render',
    '{E_MAIN_WALLS}',
    '{E4_RENDER}',
    [
      VerbatimToken(
        '{RENDER_DEFECTS}',
        options: {
          'e4rn_cracked': 'cracked',
          'e4rn_eroded': 'eroded',
          'e4rn_loose': 'loose',
          'e4rn_missing': 'missing',
          'e4rn_damaged': 'damaged',
        },
        pdfOptions: ['cracked', 'eroded', 'loose', 'missing', 'damaged'],
      ),
    ],
    pdf:
        'Repair render: Parts of the render coating to the building are cracked, eroded, loose, missing, damaged.',
  ),
  VerbatimRule(
    'e4_render_hazard',
    'activity_outside_property_main_wall_repairs_render',
    '{E_MAIN_WALLS}',
    '{E4_RENDER_HAZARD}',
    [
    ],
    whenField: 'cb_hazard',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e4_render_damp',
    'activity_outside_property_main_wall_repairs_render',
    '{E_MAIN_WALLS}',
    '{E4_RENDER_DAMP}',
    [
    ],
    whenField: 'cb_causing_damp',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e4_walltie_prev',
    'activity_outside_property_main_wall_repairs_wall_the_repair',
    '{E_MAIN_WALLS}',
    '{E4_WALL_TIES_PREVIOUS}',
    [
    ],
    whenField: 'actv_status',
    whenValue: 'Wall Ties defects',
  ),
  VerbatimRule(
    'e4_walltie_defect',
    'activity_outside_property_main_wall_repairs_wall_the_repair',
    '{E_MAIN_WALLS}',
    '{E4_WALL_TIES_DEFECT}',
    [
    ],
    whenField: 'actv_status',
    whenValue: 'Repair defect',
  ),
  VerbatimRule(
    'e4_lintel_win',
    'activity_outside_property_main_wall_repairs_lintel',
    '{E_MAIN_WALLS}',
    '{E4_LINTEL}',
    [
      VerbatimToken(
        '{LINTEL_WALLS}',
        options: {
          'e4l_w_front': 'front',
          'e4l_w_side': 'side',
          'e4l_w_rear': 'rear',
        },
        otherCheckbox: 'e4l_w_other',
        otherText: 'e4l_w_other_text',
        pdfOptions: ['front', 'side', 'rear'],
      ),
      VerbatimToken(
        '{LINTEL_LOCATIONS}',
        options: {
          'e4l_l_main_building': 'main building',
          'e4l_l_back_addition': 'back addition',
          'e4l_l_extension': 'extension',
          'e4l_l_bay_window': 'bay window',
        },
        otherCheckbox: 'e4l_l_other',
        otherText: 'e4l_l_other_text',
        pdfOptions: ['main building', 'back addition', 'extension', 'bay window'],
      ),
    ],
    pdf:
        'Lintel defect: The lintel (the beam supporting the masonry above a door or window opening), including a brick arch where applicable, in the front, side, rear, other wall of the main building, back addition, extension, bay window, other is damaged, cracked, or distorted.',
  ),
  VerbatimRule(
    'e4_lintel_minor_win',
    'activity_outside_property_main_wall_repairs_lintel',
    '{E_MAIN_WALLS}',
    '{E4_LINTEL_MINOR}',
    [
    ],
    whenField: 'actv_condition',
    whenValue: 'Minor defects',
  ),
  VerbatimRule(
    'e4_lintel_major_win',
    'activity_outside_property_main_wall_repairs_lintel',
    '{E_MAIN_WALLS}',
    '{E4_LINTEL_SIGNIFICANT}',
    [
    ],
    whenField: 'actv_condition',
    whenValue: 'Significant defect',
  ),
  VerbatimRule(
    'e4_lintel_door',
    'activity_outside_property_main_wall_repairs_lintel__door',
    '{E_MAIN_WALLS}',
    '{E4_LINTEL}',
    [
      VerbatimToken(
        '{LINTEL_WALLS}',
        options: {
          'e4l_w_front': 'front',
          'e4l_w_side': 'side',
          'e4l_w_rear': 'rear',
        },
        otherCheckbox: 'e4l_w_other',
        otherText: 'e4l_w_other_text',
        pdfOptions: ['front', 'side', 'rear'],
      ),
      VerbatimToken(
        '{LINTEL_LOCATIONS}',
        options: {
          'e4l_l_main_building': 'main building',
          'e4l_l_back_addition': 'back addition',
          'e4l_l_extension': 'extension',
          'e4l_l_bay_window': 'bay window',
        },
        otherCheckbox: 'e4l_l_other',
        otherText: 'e4l_l_other_text',
        pdfOptions: ['main building', 'back addition', 'extension', 'bay window'],
      ),
    ],
    pdf:
        'Lintel defect: The lintel (the beam supporting the masonry above a door or window opening), including a brick arch where applicable, in the front, side, rear, other wall of the main building, back addition, extension, bay window, other is damaged, cracked, or distorted.',
  ),
  VerbatimRule(
    'e4_lintel_minor_door',
    'activity_outside_property_main_wall_repairs_lintel__door',
    '{E_MAIN_WALLS}',
    '{E4_LINTEL_MINOR}',
    [
    ],
    whenField: 'actv_condition',
    whenValue: 'Minor defects',
  ),
  VerbatimRule(
    'e4_lintel_major_door',
    'activity_outside_property_main_wall_repairs_lintel__door',
    '{E_MAIN_WALLS}',
    '{E4_LINTEL_SIGNIFICANT}',
    [
    ],
    whenField: 'actv_condition',
    whenValue: 'Significant defect',
  ),
  VerbatimRule(
    'e4_sill',
    'activity_outside_property_main_wall_repairs_window_sills',
    '{E_MAIN_WALLS}',
    '{E4_WINDOWSILL}',
    [
      VerbatimToken(
        '{SILL_WALLS}',
        options: {
          'e4s_w_front': 'front',
          'e4s_w_side': 'side',
          'e4s_w_rear': 'rear',
        },
        otherCheckbox: 'e4s_w_other',
        otherText: 'e4s_w_other_text',
        pdfOptions: ['front', 'side', 'rear'],
      ),
      VerbatimToken(
        '{SILL_LOCATIONS}',
        options: {
          'e4s_l_main_building': 'main building',
          'e4s_l_back_addition': 'back addition',
          'e4s_l_extension': 'extension',
          'e4s_l_bay_window': 'bay window',
        },
        otherCheckbox: 'e4s_l_other',
        otherText: 'e4s_l_other_text',
        pdfOptions: ['main building', 'back addition', 'extension', 'bay window'],
      ),
      VerbatimToken(
        '{SILL_DEFECTS}',
        options: {
          'e4s_d_damaged': 'damaged',
          'e4s_d_rotten': 'rotten',
          'e4s_d_cracked': 'cracked',
          'e4s_d_distorted': 'distorted',
        },
        otherCheckbox: 'e4s_d_other',
        otherText: 'e4s_d_other_text',
        pdfOptions: ['damaged', 'rotten', 'cracked', 'distorted'],
      ),
    ],
    pdf:
        'Windowsill defect: The windowsill(s) to the front, side, rear, other wall of the main building, back addition, extension, bay window, other is damaged, rotten, cracked, distorted, other.',
  ),
  VerbatimRule(
    'e4_sill_minor',
    'activity_outside_property_main_wall_repairs_window_sills',
    '{E_MAIN_WALLS}',
    '{E4_SILL_MINOR}',
    [
    ],
    whenField: 'actv_condition',
    whenValue: 'Minor Defect',
  ),
  VerbatimRule(
    'e4_sill_major',
    'activity_outside_property_main_wall_repairs_window_sills',
    '{E_MAIN_WALLS}',
    '{E4_SILL_SIGNIFICANT}',
    [
    ],
    whenField: 'actv_condition',
    whenValue: 'Significant Defect',
  ),
  VerbatimRule(
    'e4_general',
    'activity_outside_property_main_walls_main_screen',
    '{E_MAIN_WALLS}',
    '{E4_GENERAL_MAINTENANCE}',
    [
    ],
    whenField: 'cb_general_maintenance',
    whenValue: 'true',
  ),
  // <<verbatim-rules-end>>
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
      if (rule.whenField != null) {
        bool hit(String? f, String? v) =>
            (answers[f] ?? '').trim().toLowerCase() == (v ?? '').toLowerCase();
        if (!hit(rule.whenField, rule.whenValue) &&
            !rule.whenAny.any((p) => hit(p[0], p[1]))) {
          continue;
        }
      }
      final master = rule.master == '@chimney'
          ? InspectionPhraseEngine._chimneyPhraseCodeFromAnswers(
              answers,
              fallbackIsMulti: false,
            )
          : rule.master;
      var text = _phraseTexts['$master::${rule.sub}'] ?? '';
      if (text.isEmpty) continue;
      var complete = true;
      var count = 0;
      for (final token in rule.tokens) {
        final items = _verbatimTokenItems(token, answers);
        if (items.isEmpty && token.optional) {
          text = text.replaceAll(token.token, '');
          continue;
        }
        if (items.isEmpty) {
          complete = false;
          break;
        }
        if (count == 0) count = items.length;
        var value = InspectionPhraseEngine._toWords(items);
        if (token.cap) value = InspectionPhraseEngine._capitalizeFirst(value);
        text = text.replaceAll(token.token, value);
      }
      if (!complete) continue;
      if (rule.isAre) {
        text = text.replaceAll('{IS_ARE}', count > 1 ? 'are' : 'is');
      }
      out.addAll(InspectionPhraseEngine._split(
        InspectionPhraseEngine._normalize(text),
      ));
    }
    return out;
  }

  List<String> _verbatimTokenItems(
    VerbatimToken token,
    Map<String, String> answers,
  ) {
    if (token.constant != null) return [token.constant!];
    if (token.dropdown != null) {
      final v = (answers[token.dropdown] ?? '').trim();
      return v.isEmpty ? const [] : [token.lower ? v.toLowerCase() : v];
    }
    if (token.text != null) {
      final v = (answers[token.text] ?? '').trim();
      return v.isEmpty ? const [] : [v];
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
    return items;
  }
}
