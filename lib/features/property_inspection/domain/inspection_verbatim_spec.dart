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
  VerbatimRule(
    'e5_desc',
    'activity_outside_property_windows_aboutwindow',
    '{E_WINDOWS}',
    '{E5_DESCRIPTION}',
    [
      VerbatimToken(
        '{WIN_TYPES}',
        options: {
          'e5t_replacement': 'replacement',
          'e5t_original': 'original',
          'e5t_old': 'old',
          'e5t_pvcu': 'PVCu',
          'e5t_timber': 'timber',
          'e5t_old_style_timber_sash': 'old style timber sash',
          'e5t_modern_pvc_sash': 'modern PVC sash',
          'e5t_modern_timber_sash': 'modern timber sash',
          'e5t_aluminium': 'aluminium',
          'e5t_composite': 'composite',
        },
        otherCheckbox: 'cb_other_895',
        otherText: 'et_other_220',
        pdfOptions: ['replacement', 'original', 'old', 'PVCu', 'timber', 'old style timber sash', 'modern PVC sash', 'modern timber sash', 'aluminium', 'composite'],
      ),
    ],
    pdf:
        'Description: The windows are formed of replacement, original, old, PVCu, timber, old style timber sash, modern PVC sash, modern timber sash, aluminium, composite, other framed units.',
  ),
  VerbatimRule(
    'e5_glazing',
    'activity_outside_property_windows_aboutwindow',
    '{E_WINDOWS}',
    '{E5_GLAZING}',
    [
      VerbatimToken(
        '{WIN_GLAZING}',
        options: {
          'e5g_single_glazing': 'single glazing',
          'e5g_double_glazing': 'double glazing',
          'e5g_triple_glazing': 'triple glazing',
          'e5g_secondary_glazing': 'secondary glazing',
          'e5g_decorative_glazing': 'decorative glazing',
        },
        otherCheckbox: 'e5g_other',
        otherText: 'e5g_other_text',
        pdfOptions: ['single glazing', 'double glazing', 'triple glazing', 'secondary glazing', 'decorative glazing'],
      ),
    ],
    pdf:
        'Glazing: The glazing comprises single glazing, double glazing, triple glazing, secondary glazing, decorative glazing, other.',
  ),
  VerbatimRule(
    'e5_bs_no',
    'activity_outside_property_windows_aboutwindow',
    '{E_WINDOWS}',
    '{E5_NO_BS_EN}',
    [
    ],
    whenField: 'actv_status',
    whenValue: 'No BS EN',
  ),
  VerbatimRule(
    'e5_bs_yes',
    'activity_outside_property_windows_aboutwindow',
    '{E_WINDOWS}',
    '{E5_BS_EN_NOTED}',
    [
    ],
    whenField: 'actv_status',
    whenValue: 'BS EN noted',
  ),
  VerbatimRule(
    'e5_condition',
    'activity_outside_property_windows_aboutwindow',
    '{E_WINDOWS}',
    '{E5_CONDITION}',
    [
      VerbatimToken(
        '{WIN_CONDITION}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Condition: Where visible and operated during the inspection, the windows appear in good, reasonable, fair, poor, very poor condition, consistent with their age and type.',
  ),
  VerbatimRule(
    'e5_very_poor',
    'activity_outside_property_windows_aboutwindow',
    '{E_WINDOWS}',
    '{E5_VERY_POOR}',
    [
    ],
    whenField: 'actv_condition',
    whenValue: 'Very poor',
  ),
  VerbatimRule(
    'e5_replacement',
    'activity_outside_property_windows_aboutwindow',
    '{E_WINDOWS}',
    '{E5_REPLACEMENT}',
    [
    ],
    whenField: 'e5t_replacement',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e5_old_sash',
    'activity_outside_property_windows_aboutwindow',
    '{E_WINDOWS}',
    '{E5_OLD_SASH}',
    [
    ],
    whenField: 'e5t_old_style_timber_sash',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e5_seals',
    'activity_outside_property_windows_aboutwindow',
    '{E_WINDOWS}',
    '{E5_GLAZING_SEALS}',
    [
      VerbatimToken(
        '{SEAL_CONDITION}',
        dropdown: 'actv_seals',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Glazing seals: The external sealant around the window frames appears in good, reasonable, fair, poor, very poor condition.',
  ),
  VerbatimRule(
    'e5_sill',
    'activity_outside_property_windows_sill_projection',
    '{E_WINDOWS}',
    '{E5_SILL_PROJECTION}',
    [
      VerbatimToken(
        '{SILL_SEALING}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Properly', 'Fairly', 'Poorly'],
        lower: true,
        pdfOptions: ['properly', 'fairly', 'poorly'],
      ),
    ],
    pdf:
        'The junctions between the window frames and the surrounding wall openings appear to be properly, fairly, poorly sealed.',
    whenField: 'actv_projection_type',
    whenValue: 'Sill projection',
  ),
  VerbatimRule(
    'e5_sill_defect',
    'activity_outside_property_windows_sill_projection',
    '{E_WINDOWS}',
    '{E5_SILL_DEFECT}',
    [
      VerbatimToken(
        '{SILL_DEFECTS}',
        options: {
          'e5sd_adequate': 'adequate',
          'e5sd_properly_installed': 'properly installed',
          'e5sd_properly_drained': 'properly drained',
          'e5sd_cracked': 'cracked',
          'e5sd_defective': 'defective',
        },
        pdfOptions: ['adequate', 'properly installed', 'properly drained', 'cracked', 'defective'],
      ),
    ],
    pdf:
        'Sill defect: The windowsill projection beyond the face of the wall does not appear to be adequate, properly installed, properly drained, cracked, defective.',
    whenField: 'actv_projection_type',
    whenValue: 'Sill defect',
  ),
  VerbatimRule(
    'e5_repair',
    'activity_outside_property_windows_repairs_repair_window',
    '{E_WINDOWS}',
    '{E5_REPAIR_WINDOWS}',
    [
      VerbatimToken(
        '{REPAIR_LOCATIONS}',
        options: {
          'e5rl_lounge': 'lounge',
          'e5rl_dining_room': 'dining room',
          'e5rl_bedroom': 'bedroom',
          'e5rl_kitchen': 'kitchen',
        },
        otherCheckbox: 'cb_other_471',
        otherText: 'et_other_175',
        pdfOptions: ['lounge', 'dining room', 'bedroom', 'kitchen'],
      ),
      VerbatimToken(
        '{REPAIR_DEFECTS}',
        options: {
          'e5rd_have_damaged_lock_s': 'have damaged lock(s)',
          'e5rd_have_missing_lock_s': 'have missing lock(s)',
          'e5rd_are_difficult_to_open': 'are difficult to open',
          'e5rd_are_badly_worn': 'are badly worn',
          'e5rd_are_rotten': 'are rotten',
          'e5rd_have_broken_glass': 'have broken glass',
          'e5rd_have_failed_glazing': 'have failed glazing',
          'e5rd_are_in_disrepair': 'are in disrepair',
          'e5rd_are_severely_damaged': 'are severely damaged',
          'e5rd_present_a_safety_or_security_risk': 'present a safety or security risk',
          'e5rd_have_other_defects': 'have other defects',
        },
        pdfOptions: ['have damaged lock(s)', 'have missing lock(s)', 'are difficult to open', 'are badly worn', 'are rotten', 'have broken glass', 'have failed glazing', 'are in disrepair', 'are severely damaged', 'present a safety or security risk', 'have other defects'],
      ),
    ],
    pdf:
        'Repair windows: The window(s) in the lounge, dining room, bedroom, kitchen, other, have damaged lock(s), have missing lock(s), are difficult to open, are badly worn, are rotten, have broken glass, have failed glazing, are in disrepair, are severely damaged, present a safety or security risk, have other defects.',
    pdfMore: [
      'Where the defects are minor and do not present a safety or security risk, repairs should be carried out soon to prevent further deterioration.',
    ],
  ),
  VerbatimRule(
    'e5_velux',
    'activity_outside_property_windows_velux_window',
    '{E_WINDOWS}',
    '{E5_VELUX}',
    [
      VerbatimToken(
        '{VELUX_TYPES}',
        options: {
          'e5vt_roof_windows': 'roof windows',
          'e5vt_roof_skylights': 'roof skylights',
          'e5vt_velux_roof_windows': 'Velux roof windows',
        },
        otherCheckbox: 'cb_other_629',
        otherText: 'et_other_290',
        pdfOptions: ['roof windows', 'roof skylights', 'Velux roof windows'],
      ),
      VerbatimToken(
        '{VELUX_MATERIALS}',
        options: {
          'e5vm_timber': 'timber',
          'e5vm_pvcu': 'PVCu',
          'e5vm_aluminium': 'aluminium',
        },
        otherCheckbox: 'cb_other_610',
        otherText: 'et_other_816',
        pdfOptions: ['timber', 'PVCu', 'aluminium'],
      ),
      VerbatimToken(
        '{VELUX_GLAZING}',
        options: {
          'e5vg_double': 'double',
          'e5vg_triple': 'triple',
        },
        pdfOptions: ['double', 'triple'],
      ),
    ],
    pdf:
        'Roof Velux Windows: Type: The property incorporates roof windows, roof skylights, Velux roof windows, other.',
    pdfMore: [
      'These are formed in timber, PVCu, aluminium, other construction with double, triple glazing.',
    ],
  ),
  VerbatimRule(
    'e5_velux_cond',
    'activity_outside_property_windows_velux_window',
    '{E_WINDOWS}',
    '{E5_VELUX_CONDITION}',
    [
      VerbatimToken(
        '{VELUX_CONDITION}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Condition: Where visible, they appear in good, reasonable, fair, poor, very poor condition.',
  ),
  VerbatimRule(
    'e5_windowsills',
    'activity_outside_property_windows_windowsills',
    '{E_WINDOWS}',
    '{E5_WINDOWSILLS}',
    [
      VerbatimToken(
        '{SILL_MATERIALS}',
        options: {
          'e5sm_pvcu': 'PVCu',
          'e5sm_timber': 'timber',
          'e5sm_brick': 'brick',
          'e5sm_tiles': 'tiles',
          'e5sm_concrete': 'concrete',
        },
        otherCheckbox: 'e5sm_other',
        otherText: 'e5sm_other_text',
        pdfOptions: ['PVCu', 'timber', 'brick', 'tiles', 'concrete'],
      ),
    ],
    pdf:
        'Windowsills: The windowsills are formed in PVCu, timber, brick, tiles, concrete, other material.',
  ),
  VerbatimRule(
    'e5_windowsills_cond',
    'activity_outside_property_windows_windowsills',
    '{E_WINDOWS}',
    '{E5_WINDOWSILLS_CONDITION}',
    [
      VerbatimToken(
        '{SILL_CONDITION}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Condition: Where visible, they appear in good, reasonable, fair, poor, very poor condition.',
  ),
  VerbatimRule(
    'e5_operation',
    'activity_outside_property_windows_operation',
    '{E_WINDOWS}',
    '{E5_OPERATION}',
    [
      VerbatimToken(
        '{WIN_OPERATION}',
        dropdown: 'actv_operation',
        dropdownOptions: ['Freely', 'With minor with resistance', 'With difficulty'],
        lower: true,
        pdfOptions: ['freely', 'with minor with resistance', 'with difficulty'],
      ),
    ],
    pdf:
        'Operation: The windows selected for operation opened and closed freely, with minor with resistance, with difficulty.',
  ),
  VerbatimRule(
    'e5_defective_op',
    'activity_outside_property_windows_defective_operation',
    '{E_WINDOWS}',
    '{E5_DEFECTIVE_OPERATION}',
    [
      VerbatimToken(
        '{WIN_DEFECTIVE_OPERATION}',
        options: {
          'e5do_stick_during_operation': 'stick during operation',
          'e5do_fail_to_close_correctly': 'fail to close correctly',
          'e5do_fail_to_lock_securely': 'fail to lock securely',
          'e5do_require_adjustment': 'require adjustment',
          'e5do_have_damaged_hinges': 'have damaged hinges',
          'e5do_have_defective_handles': 'have defective handles',
          'e5do_have_defective_locking_mechanisms': 'have defective locking mechanisms',
        },
        pdfOptions: ['stick during operation', 'fail to close correctly', 'fail to lock securely', 'require adjustment', 'have damaged hinges', 'have defective handles', 'have defective locking mechanisms'],
      ),
    ],
    pdf:
        'Defective Operation One or more windows were found to: • stick during operation • fail to close correctly • fail to lock securely • require adjustment • have damaged hinges • have defective handles • have defective locking mechanisms Repairs or adjustment should be undertaken to maintain security and weather resistance.',
  ),
  VerbatimRule(
    'e5_failed_units',
    'activity_outside_property_windows_failed_glazed_units',
    '{E_WINDOWS}',
    '{E5_FAILED_UNITS}',
    [
      VerbatimToken(
        '{FAILED_UNIT_SIGNS}',
        options: {
          'e5fg_internal_condensation': 'internal condensation',
          'e5fg_misting': 'misting',
          'e5fg_failed_seals': 'failed seals',
        },
        pdfOptions: ['internal condensation', 'misting', 'failed seals'],
      ),
    ],
    pdf:
        'Failed Glazed Units: One or more double-glazed units exhibit internal condensation, misting, failed seals.',
  ),
  VerbatimRule(
    'e5_damaged_glazing',
    'activity_outside_property_windows_damaged_glazing',
    '{E_WINDOWS}',
    '{E5_DAMAGED_GLAZING}',
    [
      VerbatimToken(
        '{DAMAGED_PANES}',
        options: {
          'e5dg_cracked': 'cracked',
          'e5dg_broken': 'broken',
          'e5dg_chipped': 'chipped',
          'e5dg_damaged': 'damaged',
        },
        pdfOptions: ['cracked', 'broken', 'chipped', 'damaged'],
      ),
    ],
    pdf:
        'Damaged Glazing: One or more panes are cracked, broken, chipped, damaged.',
  ),
  VerbatimRule(
    'e5_glazing_hazard',
    'activity_outside_property_windows_damaged_glazing',
    '{E_WINDOWS}',
    '{E5_GLAZING_HAZARD}',
    [
    ],
    whenField: 'cb_hazard',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e5_timber',
    'activity_outside_property_windows_timber_windows',
    '{E_WINDOWS}',
    '{E5_TIMBER_WINDOWS}',
    [
      VerbatimToken(
        '{TIMBER_ISSUES}',
        options: {
          'e5tw_localised_weathering': 'localised weathering',
          'e5tw_paint_deterioration': 'paint deterioration',
          'e5tw_minor_decay': 'minor decay',
        },
        otherCheckbox: 'e5tw_other',
        otherText: 'e5tw_other_text',
        pdfOptions: ['localised weathering', 'paint deterioration', 'minor decay'],
      ),
    ],
    pdf:
        'Timber Windows: Where timber windows are present, localised weathering, paint deterioration, minor decay, other issues may occur as part of their normal service life.',
  ),
  VerbatimRule(
    'e5_condensation',
    'activity_outside_property_windows_condensation',
    '{E_WINDOWS}',
    '{E5_CONDENSATION}',
    [
    ],
    whenField: 'cb_condensation',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e5_fire_trap',
    'activity_outside_property_windows_repairs_no_fire_escape_risk',
    '{E_WINDOWS}',
    '{E5_FIRE_TRAP}',
    [
      VerbatimToken(
        '{FIRE_LOCATIONS}',
        options: {
          'e5fl_lounge': 'lounge',
          'e5fl_dining_room': 'dining room',
          'e5fl_bedroom': 'bedroom',
          'e5fl_study': 'study',
        },
        otherCheckbox: 'cb_other_175',
        otherText: 'et_other_308',
        pdfOptions: ['lounge', 'dining room', 'bedroom', 'study'],
      ),
      VerbatimToken(
        '{FIRE_OPENINGS}',
        options: {
          'e5fo_no_opening': 'no opening',
          'e5fo_a_small_opening': 'a small opening',
        },
        pdfOptions: ['no opening', 'a small opening'],
      ),
    ],
    pdf:
        'The affected window(s) in the lounge, dining room, bedroom, study, other room have no opening, a small opening, creating a potential safety hazard.',
  ),
  VerbatimRule(
    'e4_intro',
    'activity_outside_property_main_walls_main_screen',
    '{E_MAIN_WALLS}',
    '{STANDARD_TEXT}',
    [
    ],
    first: true,
    whenField: 'android_material_design_spinner4',
    whenValue: '1',
    whenAny: [['android_material_design_spinner4', '2'], ['android_material_design_spinner4', '3']],
  ),
  VerbatimRule(
    'e5_intro',
    'activity_outside_property_windows_main_screen',
    '{E_WINDOWS}',
    '{WINDOWS_STANDARD_TEXT}',
    [
    ],
    first: true,
    whenField: 'android_material_design_spinner4',
    whenValue: '1',
    whenAny: [['android_material_design_spinner4', '2'], ['android_material_design_spinner4', '3']],
  ),
  VerbatimRule(
    'e6_intro',
    'activity_outside_property_out_side_doors_about_doors',
    '{E_OUTSIDE_DOORS}',
    '{STANDARD_TEXT}',
    [
    ],
    first: true,
    whenField: 'actv_condition',
    whenValue: 'Good',
    whenAny: [['actv_condition', 'Reasonable'], ['actv_condition', 'Fair'], ['actv_condition', 'Poor'], ['actv_condition', 'Very poor']],
  ),
  VerbatimRule(
    'e6_desc',
    'activity_outside_property_out_side_doors_about_doors',
    '{E_OUTSIDE_DOORS}',
    '{E6_DESCRIPTION}',
    [
      VerbatimToken(
        '{DOOR_TYPES}',
        options: {
          'e6t_replacement': 'replacement',
          'e6t_original': 'original',
          'e6t_old': 'old',
          'e6t_front': 'front',
          'e6t_rear': 'rear',
          'e6t_side': 'side',
          'e6t_patio': 'patio',
          'e6t_french': 'French',
          'e6t_bi_fold': 'bi-fold',
        },
        otherCheckbox: 'cb_other_859',
        otherText: 'et_other_179',
        pdfOptions: ['replacement', 'original', 'old', 'front', 'rear', 'side', 'patio', 'French', 'bi-fold'],
      ),
    ],
    pdf:
        'Description: The property incorporates replacement, original, old, front, rear, side, patio, French, bi-fold, other doors.',
  ),
  VerbatimRule(
    'e6_material',
    'activity_outside_property_out_side_doors_about_doors',
    '{E_OUTSIDE_DOORS}',
    '{E6_MATERIAL}',
    [
      VerbatimToken(
        '{DOOR_MATERIALS}',
        options: {
          'e6m_timber': 'timber',
          'e6m_pvcu': 'PVCu',
          'e6m_composite': 'composite',
          'e6m_aluminium': 'aluminium',
          'e6m_steel': 'steel',
        },
        otherCheckbox: 'e6m_other',
        otherText: 'e6m_other_text',
        pdfOptions: ['timber', 'PVCu', 'composite', 'aluminium', 'steel'],
      ),
    ],
    pdf:
        'The external doors are formed of timber, PVCu, composite, aluminium, steel, other material.',
  ),
  VerbatimRule(
    'e6_glazing',
    'activity_outside_property_out_side_doors_about_doors',
    '{E_OUTSIDE_DOORS}',
    '{E6_GLAZING}',
    [
      VerbatimToken(
        '{DOOR_GLAZING}',
        options: {
          'e6g_single_glazing': 'single glazing',
          'e6g_double_glazing': 'double glazing',
          'e6g_triple_glazing': 'triple glazing',
          'e6g_decorative_glazing': 'decorative glazing',
        },
        otherCheckbox: 'e6g_other',
        otherText: 'e6g_other_text',
        pdfOptions: ['single glazing', 'double glazing', 'triple glazing', 'decorative glazing'],
      ),
    ],
    pdf:
        'Glazing: The glazed sections comprise single glazing, double glazing, triple glazing, decorative glazing, other.',
  ),
  VerbatimRule(
    'e6_bs_no',
    'activity_outside_property_out_side_doors_about_doors',
    '{E_OUTSIDE_DOORS}',
    '{E6_NO_BS_EN}',
    [
    ],
    whenField: 'actv_status',
    whenValue: 'No BS EN noted',
  ),
  VerbatimRule(
    'e6_bs_yes',
    'activity_outside_property_out_side_doors_about_doors',
    '{E_OUTSIDE_DOORS}',
    '{E6_BS_EN_NOTED}',
    [
    ],
    whenField: 'actv_status',
    whenValue: 'BS EN noted',
  ),
  VerbatimRule(
    'e6_condition',
    'activity_outside_property_out_side_doors_about_doors',
    '{E_OUTSIDE_DOORS}',
    '{E6_CONDITION}',
    [
      VerbatimToken(
        '{DOOR_CONDITION}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Condition: Where visible and operated during the inspection, the doors appear in good, reasonable, fair, poor, very poor condition, consistent with their age and type.',
  ),
  VerbatimRule(
    'e6_very_poor',
    'activity_outside_property_out_side_doors_about_doors',
    '{E_OUTSIDE_DOORS}',
    '{E6_VERY_POOR}',
    [
    ],
    whenField: 'actv_condition',
    whenValue: 'Very poor',
  ),
  VerbatimRule(
    'e6_replacement',
    'activity_outside_property_out_side_doors_about_doors',
    '{E_OUTSIDE_DOORS}',
    '{E6_REPLACEMENT}',
    [
    ],
    whenField: 'e6t_replacement',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e6_seals',
    'activity_outside_property_out_side_doors_about_doors',
    '{E_OUTSIDE_DOORS}',
    '{E6_GLAZING_SEALS}',
    [
      VerbatimToken(
        '{DOOR_SEAL_CONDITION}',
        dropdown: 'actv_seals',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Glazing seals: The external sealant around the door frames appears in good, reasonable, fair, poor, very poor condition.',
  ),
  VerbatimRule(
    'e6_repair',
    'activity_outside_property_out_side_doors_repairs_repair_out_side_doors',
    '{E_OUTSIDE_DOORS}',
    '{E6_REPAIR_DOORS}',
    [
      VerbatimToken(
        '{REPAIR_LOCATIONS}',
        options: {
          'e6rl_lounge': 'lounge',
          'e6rl_dining_room': 'dining room',
          'e6rl_bedroom': 'bedroom',
          'e6rl_kitchen': 'kitchen',
        },
        otherCheckbox: 'cb_other_337',
        otherText: 'et_other_362',
        pdfOptions: ['lounge', 'dining room', 'bedroom', 'kitchen'],
      ),
      VerbatimToken(
        '{REPAIR_DEFECTS}',
        options: {
          'e6rd_have_damaged_lock_s': 'have damaged lock(s)',
          'e6rd_have_missing_lock_s': 'have missing lock(s)',
          'e6rd_are_difficult_to_open': 'are difficult to open',
          'e6rd_are_badly_worn': 'are badly worn',
          'e6rd_are_rotten': 'are rotten',
          'e6rd_have_broken_glass': 'have broken glass',
          'e6rd_have_failed_glazing': 'have failed glazing',
          'e6rd_are_in_disrepair': 'are in disrepair',
          'e6rd_are_severely_damaged': 'are severely damaged',
          'e6rd_present_a_safety_or_security_risk': 'present a safety or security risk',
          'e6rd_have_other_defects': 'have other defects',
        },
        pdfOptions: ['have damaged lock(s)', 'have missing lock(s)', 'are difficult to open', 'are badly worn', 'are rotten', 'have broken glass', 'have failed glazing', 'are in disrepair', 'are severely damaged', 'present a safety or security risk', 'have other defects'],
      ),
    ],
    pdf:
        'Repair doors: The door(s) in the lounge, dining room, bedroom, kitchen, other, have damaged lock(s), have missing lock(s), are difficult to open, are badly worn, are rotten, have broken glass, have failed glazing, are in disrepair, are severely damaged, present a safety or security risk, have other defects.',
    pdfMore: [
      'Where the defects are minor and do not present a safety or security risk, repairs should be carried out soon to prevent further deterioration.',
    ],
  ),
  VerbatimRule(
    'e6_thresholds',
    'activity_outside_property_out_side_doors_thresholds',
    '{E_OUTSIDE_DOORS}',
    '{E6_THRESHOLDS}',
    [
      VerbatimToken(
        '{THRESHOLD_CONDITION}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Thresholds: The door thresholds appear in good, reasonable, fair, poor, very poor condition.',
  ),
  VerbatimRule(
    'e6_operation',
    'activity_outside_property_out_side_doors_operation',
    '{E_OUTSIDE_DOORS}',
    '{E6_OPERATION}',
    [
      VerbatimToken(
        '{DOOR_OPERATION}',
        dropdown: 'actv_operation',
        dropdownOptions: ['Freely', 'With resistance', 'With difficulty'],
        lower: true,
        pdfOptions: ['freely', 'with resistance', 'with difficulty'],
      ),
    ],
    pdf:
        'Operation: The doors selected for operation opened and closed freely, with resistance, with difficulty.',
  ),
  VerbatimRule(
    'e6_security',
    'activity_outside_property_out_side_doors_security',
    '{E_OUTSIDE_DOORS}',
    '{E6_SECURITY}',
    [
      VerbatimToken(
        '{DOOR_LOCKS}',
        options: {
          'e6lk_multi_point_locking': 'multi-point locking',
          'e6lk_mortice_locks': 'mortice locks',
          'e6lk_cylinder_locks': 'cylinder locks',
          'e6lk_night_latches': 'night latches',
          'e6lk_combination_of_locking_systems': 'combination of locking systems',
        },
        pdfOptions: ['multi-point locking', 'mortice locks', 'cylinder locks', 'night latches', 'combination of locking systems'],
      ),
      VerbatimToken(
        '{DOOR_SECURITY_LEVEL}',
        dropdown: 'actv_seciruty_offered',
        dropdownOptions: ['Reasonable', 'Adequate', 'Inadequate'],
        lower: true,
        pdfOptions: ['reasonable', 'adequate', 'inadequate'],
      ),
    ],
    pdf:
        'Security: The doors are fitted with multi-point locking, mortice locks, cylinder locks, night latches, combination of locking systems.',
    pdfMore: [
      'The level of security appears reasonable, adequate, inadequate based upon a visual inspection only.',
    ],
  ),
  VerbatimRule(
    'e6_inadequate_lock',
    'activity_outside_property_out_side_doors_repairs_inadequate_lock_location',
    '{E_OUTSIDE_DOORS}',
    '{E6_INADEQUATE_LOCK}',
    [
      VerbatimToken(
        '{LOCK_LOCATIONS}',
        options: {
          'e6il_main': 'main',
          'e6il_rear': 'rear',
          'e6il_side': 'side',
          'e6il_patio': 'patio',
          'e6il_sliding_patio_doors': 'sliding patio doors',
          'e6il_french_doors': 'French doors',
          'e6il_bi_fold_doors': 'bi-fold doors',
        },
        otherCheckbox: 'cb_other_il',
        otherText: 'et_other_il',
        pdfOptions: ['main', 'rear', 'side', 'patio', 'sliding patio doors', 'French doors', 'bi-fold doors'],
      ),
    ],
    pdf:
        'Inadequate Lock: The locking arrangements to the main, rear, side, patio, sliding patio doors, French doors, or bi-fold doors, other door(s), do not meet current security standards and present a security risk.',
  ),
  VerbatimRule(
    'e6_defective_op',
    'activity_outside_property_out_side_doors_defective_operation',
    '{E_OUTSIDE_DOORS}',
    '{E6_DEFECTIVE_OPERATION}',
    [
      VerbatimToken(
        '{DOOR_DEFECTIVE_OPERATION}',
        options: {
          'e6do_stick_during_operation': 'stick during operation',
          'e6do_fail_to_close_correctly': 'fail to close correctly',
          'e6do_require_adjustment': 'require adjustment',
          'e6do_have_damaged_hinges': 'have damaged hinges',
          'e6do_have_defective_handles': 'have defective handles',
          'e6do_have_defective_locking_mechanisms': 'have defective locking mechanisms',
          'e6do_be_distorted': 'be distorted',
          'e6do_have_localised_decay': 'have localised decay',
          'e6do_have_damaged_frames': 'have damaged frames',
        },
        pdfOptions: ['stick during operation', 'fail to close correctly', 'require adjustment', 'have damaged hinges', 'have defective handles', 'have defective locking mechanisms', 'be distorted', 'have localised decay', 'have damaged frames'],
      ),
    ],
    pdf:
        'Defective Operation One or more external doors were found to: • stick during operation • fail to close correctly • require adjustment • have damaged hinges • have defective handles • have defective locking mechanisms • be distorted • have localised decay • have damaged frames Repairs or adjustment should be undertaken to maintain security, weather resistance, and ease of operation.',
  ),
  VerbatimRule(
    'e6_timber',
    'activity_outside_property_out_side_doors_timber_doors',
    '{E_OUTSIDE_DOORS}',
    '{E6_TIMBER_DOORS}',
    [
      VerbatimToken(
        '{TIMBER_DOOR_ISSUES}',
        options: {
          'e6td_localised_weathering': 'localised weathering',
          'e6td_paint_deterioration': 'paint deterioration',
          'e6td_surface_splitting': 'surface splitting',
          'e6td_minor_decay': 'minor decay',
        },
        pdfOptions: ['localised weathering', 'paint deterioration', 'surface splitting', 'minor decay'],
      ),
    ],
    pdf:
        'Timber Doors: Where timber external doors are present, localised weathering, paint deterioration, surface splitting, minor decay may occur as part of their normal service life.',
  ),
  VerbatimRule(
    'e6_patio',
    'activity_outside_property_out_side_doors_patio_french',
    '{E_OUTSIDE_DOORS}',
    '{E6_PATIO_FRENCH}',
    [
      VerbatimToken(
        '{PATIO_DOORS}',
        options: {
          'e6pf_sliding_patio_doors': 'sliding patio doors',
          'e6pf_french_doors': 'French doors',
          'e6pf_bi_fold_doors': 'bi-fold doors',
        },
        otherCheckbox: 'e6pf_other',
        otherText: 'e6pf_other_text',
        pdfOptions: ['sliding patio doors', 'French doors', 'bi-fold doors'],
      ),
    ],
    pdf:
        'Patio and French Doors: The property incorporates sliding patio doors, French doors, bi-fold doors, other similar doors.',
  ),
  VerbatimRule(
    'e6_general',
    'activity_outside_property_out_side_doors_patio_french',
    '{E_OUTSIDE_DOORS}',
    '{E6_GENERAL_MAINTENANCE}',
    [
    ],
    whenField: 'cb_general_maintenance',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e7c_loc',
    'activity_outside_property_conservatory_porch_location_construction',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_C_LOCATION}',
    [
      VerbatimToken(
        '{CP_LOCATIONS}',
        options: {
          'e7cl_front': 'front',
          'e7cl_side': 'side',
          'e7cl_rear': 'rear',
        },
        otherCheckbox: 'e7cl_other',
        otherText: 'e7cl_other_text',
        pdfOptions: ['front', 'side', 'rear'],
      ),
      VerbatimToken(
        '{CP_WALLS}',
        options: {
          'e7cw_single_glazed': 'single-glazed',
          'e7cw_double_glazed': 'double-glazed',
          'e7cw_triple_glazed': 'triple-glazed',
          'e7cw_pvc_framed': 'PVC framed',
          'e7cw_timber_framed': 'timber framed',
          'e7cw_aluminium_framed': 'aluminium framed',
          'e7cw_steel_framed': 'steel framed',
        },
        otherCheckbox: 'e7cw_other',
        otherText: 'e7cw_other_text',
        pdfOptions: ['single-glazed', 'double-glazed', 'triple-glazed', 'PVC framed', 'timber framed', 'aluminium framed', 'steel framed'],
      ),
    ],
    pdf:
        'Conservatory: The conservatory(s) is located to the front, side, rear, other of the building.',
    pdfMore: [
      'The walls comprise single-glazed, double-glazed, triple-glazed, PVC framed, timber framed, aluminium framed, steel framed, other wall sections.',
    ],
  ),
  VerbatimRule(
    'e7c_bregs',
    'activity_outside_property_conservatory_porch_location_construction',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_C_BUILDING_REGULATIONS}',
    [
    ],
    whenField: 'cb_building_regulations',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e7c_roof',
    'activity_outside_property_conservatory_porch_roof',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_C_ROOF}',
    [
      VerbatimToken(
        '{CP_ROOF_MATERIALS}',
        options: {
          'e7cr_glass': 'glass',
          'e7cr_polycarbonate_sheets': 'polycarbonate sheets',
          'e7cr_solid_insulated_panels': 'solid insulated panels',
          'e7cr_roofing_tiles': 'roofing tiles',
        },
        otherCheckbox: 'e7cr_other',
        otherText: 'e7cr_other_text',
        pdfOptions: ['glass', 'polycarbonate sheets', 'solid insulated panels', 'roofing tiles'],
      ),
    ],
    pdf:
        'Roof: The roof is formed in glass, polycarbonate sheets, solid insulated panels, roofing tiles, other materials.',
  ),
  VerbatimRule(
    'e7c_doors',
    'activity_outside_property_conservatory_porch_doors',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_C_DOORS_WINDOWS}',
    [
      VerbatimToken(
        '{CP_DOORS_WINDOWS}',
        options: {
          'e7cd_single_glazed': 'single-glazed',
          'e7cd_double_glazed': 'double-glazed',
          'e7cd_triple_glazed': 'triple-glazed',
          'e7cd_pvc': 'PVC',
          'e7cd_timber': 'timber',
          'e7cd_aluminium': 'aluminium',
          'e7cd_steel_framed': 'steel-framed',
        },
        pdfOptions: ['single-glazed', 'double-glazed', 'triple-glazed', 'PVC', 'timber', 'aluminium', 'steel-framed'],
      ),
    ],
    pdf:
        'Doors and Windows: The conservatory comprises single-glazed, double-glazed, triple-glazed, PVC, timber, aluminium, steel-framed door(s), and window(s).',
  ),
  VerbatimRule(
    'e7c_floor',
    'activity_outside_property_conservatory_porch_floor',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_C_FLOOR}',
    [
      VerbatimToken(
        '{CP_FLOOR_CONSTRUCTION}',
        options: {
          'e7cfc_solid_concrete': 'solid concrete',
          'e7cfc_suspended_timber': 'suspended timber',
        },
        otherCheckbox: 'e7cfc_other',
        otherText: 'e7cfc_other_text',
        pdfOptions: ['solid concrete', 'suspended timber'],
      ),
      VerbatimToken(
        '{CP_FLOOR_COVERING}',
        options: {
          'e7cfv_timber': 'timber',
          'e7cfv_carpet': 'carpet',
          'e7cfv_tiles': 'tiles',
          'e7cfv_laminated_flooring': 'laminated flooring',
          'e7cfv_vinyl': 'vinyl',
        },
        otherCheckbox: 'e7cfv_other',
        otherText: 'e7cfv_other_text',
        pdfOptions: ['timber', 'carpet', 'tiles', 'laminated flooring', 'vinyl'],
      ),
    ],
    pdf:
        'Floor: The floor is of solid concrete, suspended timber, other construction, and the floor is covered with timber, carpet, tiles, laminated flooring, vinyl, other covering(s).',
  ),
  VerbatimRule(
    'e7c_bs_no',
    'activity_outside_property_conservatory_porch_safety_glass_rating',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_C_NO_BS_EN}',
    [
    ],
    whenField: 'actv_status',
    whenValue: 'No BS EN noted',
  ),
  VerbatimRule(
    'e7c_bs_yes',
    'activity_outside_property_conservatory_porch_safety_glass_rating',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_C_BS_EN_NOTED}',
    [
    ],
    whenField: 'actv_status',
    whenValue: 'BS EN noted',
  ),
  VerbatimRule(
    'e7c_cond',
    'activity_outside_property_porch_condition',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_C_CONDITION}',
    [
      VerbatimToken(
        '{CP_CONDITION}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Condition: Where visible and operated during the inspection, the doors appear in good, reasonable, fair, poor, very poor condition, consistent with their age and type.',
  ),
  VerbatimRule(
    'e7c_vpoor',
    'activity_outside_property_porch_condition',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_C_VERY_POOR}',
    [
    ],
    whenField: 'actv_condition',
    whenValue: 'Very poor',
  ),
  VerbatimRule(
    'e7c_unstable',
    'activity_outside_property_porch_poor_condition',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_C_UNSTABLE}',
    [
    ],
    whenField: 'cb_not_inspected',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e7c_joint',
    'activity_outside_property_porch_open_to_building',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_C_JOINT_DEFECTS}',
    [
    ],
    whenField: 'cb_not_inspected',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e7p_loc',
    'activity_outside_property_conservatory_porch_location_construction__location_and_construction',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_P_LOCATION}',
    [
      VerbatimToken(
        '{CP_LOCATIONS}',
        options: {
          'e7pl_front': 'front',
          'e7pl_side': 'side',
          'e7pl_rear': 'rear',
        },
        otherCheckbox: 'e7pl_other',
        otherText: 'e7pl_other_text',
        pdfOptions: ['front', 'side', 'rear'],
      ),
      VerbatimToken(
        '{CP_WALLS}',
        options: {
          'e7pw_single_glazed': 'single-glazed',
          'e7pw_double_glazed': 'double-glazed',
          'e7pw_triple_glazed': 'triple-glazed',
          'e7pw_pvc_framed': 'PVC framed',
          'e7pw_timber_framed': 'timber framed',
          'e7pw_aluminium_framed': 'aluminium framed',
          'e7pw_steel_framed': 'steel framed',
        },
        otherCheckbox: 'e7pw_other',
        otherText: 'e7pw_other_text',
        pdfOptions: ['single-glazed', 'double-glazed', 'triple-glazed', 'PVC framed', 'timber framed', 'aluminium framed', 'steel framed'],
      ),
    ],
    pdf:
        'Porch: The porch(s) located to the front, side, rear, other of the building.',
    pdfMore: [
      'The walls comprise single-glazed, double-glazed, triple-glazed, PVC framed, timber framed, aluminium framed, steel framed, other wall sections.',
    ],
  ),
  VerbatimRule(
    'e7p_bregs',
    'activity_outside_property_conservatory_porch_location_construction__location_and_construction',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_P_BUILDING_REGULATIONS}',
    [
    ],
    whenField: 'cb_building_regulations',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e7p_roof',
    'activity_outside_property_conservatory_porch_roof__roof',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_P_ROOF}',
    [
      VerbatimToken(
        '{CP_ROOF_MATERIALS}',
        options: {
          'e7pr_glass': 'glass',
          'e7pr_polycarbonate_sheets': 'polycarbonate sheets',
          'e7pr_solid_insulated_panels': 'solid insulated panels',
          'e7pr_roofing_tiles': 'roofing tiles',
        },
        otherCheckbox: 'e7pr_other',
        otherText: 'e7pr_other_text',
        pdfOptions: ['glass', 'polycarbonate sheets', 'solid insulated panels', 'roofing tiles'],
      ),
    ],
    pdf:
        'Roof: The roof is formed in glass, polycarbonate sheets, solid insulated panels, roofing tiles, other materials.',
  ),
  VerbatimRule(
    'e7p_doors',
    'activity_outside_property_conservatory_porch_doors__doors',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_P_DOORS_WINDOWS}',
    [
      VerbatimToken(
        '{CP_DOORS_WINDOWS}',
        options: {
          'e7pd_single_glazed': 'single-glazed',
          'e7pd_double_glazed': 'double-glazed',
          'e7pd_triple_glazed': 'triple-glazed',
          'e7pd_pvc': 'PVC',
          'e7pd_timber': 'timber',
          'e7pd_aluminium': 'aluminium',
          'e7pd_steel_framed': 'steel-framed',
        },
        pdfOptions: ['single-glazed', 'double-glazed', 'triple-glazed', 'PVC', 'timber', 'aluminium', 'steel-framed'],
      ),
    ],
    pdf:
        'Doors and Windows: The porch comprises single-glazed, double-glazed, triple-glazed, PVC, timber, aluminium, steel-framed door(s), and window(s).',
  ),
  VerbatimRule(
    'e7p_floor',
    'activity_outside_property_conservatory_porch_floor__floor',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_P_FLOOR}',
    [
      VerbatimToken(
        '{CP_FLOOR_CONSTRUCTION}',
        options: {
          'e7pfc_solid_concrete': 'solid concrete',
          'e7pfc_suspended_timber': 'suspended timber',
        },
        otherCheckbox: 'e7pfc_other',
        otherText: 'e7pfc_other_text',
        pdfOptions: ['solid concrete', 'suspended timber'],
      ),
      VerbatimToken(
        '{CP_FLOOR_COVERING}',
        options: {
          'e7pfv_timber': 'timber',
          'e7pfv_carpet': 'carpet',
          'e7pfv_tiles': 'tiles',
          'e7pfv_laminated_flooring': 'laminated flooring',
          'e7pfv_vinyl': 'vinyl',
        },
        otherCheckbox: 'e7pfv_other',
        otherText: 'e7pfv_other_text',
        pdfOptions: ['timber', 'carpet', 'tiles', 'laminated flooring', 'vinyl'],
      ),
    ],
    pdf:
        'Floor: The floor is of solid concrete, suspended timber, other construction, and the floor is covered with timber, carpet, tiles, laminated flooring, vinyl, other covering(s).',
  ),
  VerbatimRule(
    'e7p_bs_no',
    'activity_outside_property_conservatory_porch_safety_glass_rating__safety_glass_rating',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_P_NO_BS_EN}',
    [
    ],
    whenField: 'actv_status',
    whenValue: 'No BS EN noted',
  ),
  VerbatimRule(
    'e7p_bs_yes',
    'activity_outside_property_conservatory_porch_safety_glass_rating__safety_glass_rating',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_P_BS_EN_NOTED}',
    [
    ],
    whenField: 'actv_status',
    whenValue: 'BS EN noted',
  ),
  VerbatimRule(
    'e7p_cond',
    'activity_outside_property_porch_condition__condition',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_P_CONDITION}',
    [
      VerbatimToken(
        '{CP_CONDITION}',
        dropdown: 'actv_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Condition: Where visible and operated during the inspection, the doors appear in good, reasonable, fair, poor, very poor condition, consistent with their age and type.',
  ),
  VerbatimRule(
    'e7p_vpoor',
    'activity_outside_property_porch_condition__condition',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_P_VERY_POOR}',
    [
    ],
    whenField: 'actv_condition',
    whenValue: 'Very poor',
  ),
  VerbatimRule(
    'e7p_unstable',
    'activity_outside_property_porch_poor_condition__poor_condition',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_P_UNSTABLE}',
    [
    ],
    whenField: 'cb_not_inspected',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e7p_joint',
    'activity_outside_property_porch_open_to_building__open_to_building',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_P_JOINT_DEFECTS}',
    [
    ],
    whenField: 'cb_not_inspected',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e7c_repair',
    'activity_outside_property_conservatory_porch_repairs',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_C_REPAIR}',
    [
      VerbatimToken(
        '{CP_REPAIR_ELEMENTS}',
        options: {
          'e7cre_door_s': 'door(s)',
          'e7cre_window_s': 'window(s)',
          'e7cre_glazing': 'glazing',
          'e7cre_roof': 'roof',
          'e7cre_floor': 'floor',
          'e7cre_wall_s': 'wall(s)',
          'e7cre_rainwater_goods': 'rainwater goods',
        },
        otherCheckbox: 'e7cre_other',
        otherText: 'e7cre_other_text',
        pdfOptions: ['door(s)', 'window(s)', 'glazing', 'roof', 'floor', 'wall(s)', 'rainwater goods'],
      ),
      VerbatimToken(
        '{CP_REPAIR_DEFECTS}',
        options: {
          'e7crd_cracked': 'cracked',
          'e7crd_damaged': 'damaged',
          'e7crd_rotten': 'rotten',
          'e7crd_leaking': 'leaking',
          'e7crd_damp': 'damp',
          'e7crd_have_failed': 'have failed',
          'e7crd_are_misted': 'are misted',
          'e7crd_present_a_safety_hazard': 'present a safety hazard',
        },
        otherCheckbox: 'e7crd_other',
        otherText: 'e7crd_other_text',
        pdfOptions: ['cracked', 'damaged', 'rotten', 'leaking', 'damp', 'have failed', 'are misted', 'present a safety hazard'],
      ),
    ],
    pdf:
        'Repair conservatory: The conservatory door(s), window(s), glazing, roof, floor, wall(s), rainwater goods, other are cracked, damaged, rotten, leaking, damp, have failed, are misted, present a safety hazard, other.',
    whenField: 'actv_cp',
    whenValue: 'Conservatory',
  ),
  VerbatimRule(
    'e7p_repair',
    'activity_outside_property_conservatory_porch_repairs',
    '{E_CONSERVATORY_PORCHES}',
    '{E7_P_REPAIR}',
    [
      VerbatimToken(
        '{CP_REPAIR_ELEMENTS}',
        options: {
          'e7pre_door': 'door',
          'e7pre_window_s': 'window(s)',
          'e7pre_glazing': 'glazing',
          'e7pre_roof': 'roof',
          'e7pre_floor': 'floor',
          'e7pre_wall_s': 'wall(s)',
          'e7pre_rainwater_goods': 'rainwater goods',
        },
        otherCheckbox: 'e7pre_other',
        otherText: 'e7pre_other_text',
        pdfOptions: ['door', 'window(s)', 'glazing', 'roof', 'floor', 'wall(s)', 'rainwater goods'],
      ),
      VerbatimToken(
        '{CP_REPAIR_DEFECTS}',
        options: {
          'e7prd_cracked': 'cracked',
          'e7prd_damaged': 'damaged',
          'e7prd_rotten': 'rotten',
          'e7prd_leaking': 'leaking',
          'e7prd_damp': 'damp',
          'e7prd_have_failed': 'have failed',
          'e7prd_are_misted_over': 'are misted over',
          'e7prd_present_a_safety_hazard': 'present a safety hazard',
        },
        otherCheckbox: 'e7prd_other',
        otherText: 'e7prd_other_text',
        pdfOptions: ['cracked', 'damaged', 'rotten', 'leaking', 'damp', 'have failed', 'are misted over', 'present a safety hazard'],
      ),
    ],
    pdf:
        'Repair porch: The porch door, window(s), glazing, roof, floor, wall(s), rainwater goods, other are cracked, damaged, rotten, leaking, damp, have failed, are misted over, present a safety hazard, other.',
    whenField: 'actv_cp',
    whenValue: 'Porch',
  ),
  VerbatimRule(
    'e7_not_applicable',
    'activity_outside_property_conservatory_porch_not_inspected',
    '{E_CONSERVATORY_PORCHES}',
    '{NOT_INSPECTED_NOT_APPLICABLE}',
    [
    ],
    whenField: 'cb_not_applicable',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e8_inspected',
    'activity_outside_property_other_joinery_and_finishes_main_screen',
    '{E_OTHER_JOINERY_AND_FINISHES}',
    '{E8_INSPECTED}',
    [
    ],
    first: true,
    whenField: 'actv_condition',
    whenValue: '1',
    whenAny: [['actv_condition', '2'], ['actv_condition', '3']],
  ),
  VerbatimRule(
    'e8_desc',
    'activity_outside_property_other_joinery_and_finishes_main_screen',
    '{E_OTHER_JOINERY_AND_FINISHES}',
    '{E8_DESCRIPTION}',
    [
      VerbatimToken(
        '{JOINERY_MATERIALS}',
        options: {
          'e8m_timber': 'timber',
          'e8m_pvcu': 'PVCu',
          'e8m_aluminium': 'aluminium',
          'e8m_asbestos_board': 'asbestos board',
          'e8m_cement_board': 'cement board',
          'e8m_fibre_cement': 'fibre cement',
          'e8m_slates': 'slates',
        },
        otherCheckbox: 'cb_other_397',
        otherText: 'et_other_393',
        pdfOptions: ['timber', 'PVCu', 'aluminium', 'asbestos board', 'cement board', 'fibre cement', 'slates'],
      ),
    ],
    pdf:
        'Description: The external eaves-level joinery comprises timber, PVCu, aluminium, asbestos board, cement board, fibre cement, slates, other materials.',
  ),
  VerbatimRule(
    'e8_decorations',
    'activity_outside_property_other_joinery_and_finishes_main_screen',
    '{E_OTHER_JOINERY_AND_FINISHES}',
    '{E8_DECORATIONS}',
    [
      VerbatimToken(
        '{JOINERY_DECORATIONS}',
        dropdown: 'actv_decorations',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Weathered', 'Poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'weathered', 'poor'],
      ),
    ],
    pdf:
        'Decorations: The external painted or stained finishes appear in good, reasonable, fair, weathered, poor condition.',
  ),
  VerbatimRule(
    'e8_condition',
    'activity_outside_property_other_joinery_and_finishes_main_screen',
    '{E_OTHER_JOINERY_AND_FINISHES}',
    '{E8_CONDITION}',
    [
      VerbatimToken(
        '{JOINERY_CONDITION}',
        dropdown: 'actv_joinery_condition',
        dropdownOptions: ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'],
        lower: true,
        pdfOptions: ['good', 'reasonable', 'fair', 'poor', 'very poor'],
      ),
    ],
    pdf:
        'Condition: Where visible, these elements appear in good, reasonable, fair, poor, very poor condition, consistent with their age and construction.',
  ),
  VerbatimRule(
    'e8_asbestos',
    'activity_outside_property_other_joinery_and_finishes_main_screen',
    '{E_OTHER_JOINERY_AND_FINISHES}',
    '{E8_ASBESTOS_CEMENT}',
    [
    ],
    whenField: 'cb_open_runoffs',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e8_general',
    'activity_outside_property_other_joinery_and_finishes_main_screen',
    '{E_OTHER_JOINERY_AND_FINISHES}',
    '{E8_GENERAL_MAINTENANCE}',
    [
    ],
    whenField: 'cb_general_maintenance',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e8_repair',
    'activity_outside_property_other_joinery_and_finishes_repairs',
    '{E_OTHER_JOINERY_AND_FINISHES}',
    '{E8_REPAIR}',
    [
      VerbatimToken(
        '{JOINERY_ITEMS}',
        options: {
          'e8i_fascias': 'fascias',
          'e8i_soffits': 'soffits',
          'e8i_barge_boards': 'barge boards',
          'e8i_verge_clips': 'verge clips',
          'e8i_timber_cladding': 'timber cladding',
        },
        otherCheckbox: 'cb_other_289',
        otherText: 'et_other_178',
        pdfOptions: ['fascias', 'soffits', 'barge boards', 'verge clips', 'timber cladding'],
      ),
      VerbatimToken(
        '{JOINERY_LOCATIONS}',
        options: {
          'e8l_main_building': 'main building',
          'e8l_back_addition': 'back addition',
          'e8l_extension': 'extension',
          'e8l_bay_window': 'bay window',
          'e8l_garage': 'garage',
        },
        otherCheckbox: 'cb_other_269',
        otherText: 'et_other_567',
        pdfOptions: ['main building', 'back addition', 'extension', 'bay window', 'garage'],
      ),
      VerbatimToken(
        '{JOINERY_DEFECTS}',
        options: {
          'e8d_rotted': 'rotted',
          'e8d_damaged': 'damaged',
          'e8d_poorly_secured': 'poorly secured',
          'e8d_incomplete': 'incomplete',
          'e8d_missing': 'missing',
        },
        otherCheckbox: 'cb_other_777',
        otherText: 'et_other_473',
        pdfOptions: ['rotted', 'damaged', 'poorly secured', 'incomplete', 'missing'],
      ),
    ],
    pdf:
        'Repair: The fascias, soffits, barge boards, verge clips, timber cladding, other to the main building, back addition, extension, bay window, garage, other are rotted, damaged, poorly secured, incomplete, missing, other.',
  ),
  VerbatimRule(
    'e8_hazard',
    'activity_outside_property_other_joinery_and_finishes_repairs',
    '{E_OTHER_JOINERY_AND_FINISHES}',
    '{E8_HAZARD}',
    [
    ],
    whenField: 'cb_safety_hazard',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e8_not_inspected',
    'activity_outside_property_other_joinery_finishes_not_inspected',
    '{E_OTHER_JOINERY_AND_FINISHES}',
    '{E8_NOT_INSPECTED}',
    [
    ],
    whenField: 'cb_not_inspected',
    whenValue: 'true',
  ),
  VerbatimRule(
    'e8_weathering',
    'activity_outside_property_other_joinery_and_finishes_timber_weathering',
    '{E_OTHER_JOINERY_AND_FINISHES}',
    '{E8_TIMBER_WEATHERING}',
    [
      VerbatimToken(
        '{WEATHERING_LEVEL}',
        dropdown: 'actv_weathering',
        dropdownOptions: ['Minor', 'Moderate', 'Significant'],
        lower: true,
        pdfOptions: ['minor', 'moderate', 'significant'],
      ),
    ],
    pdf:
        'Timber Weathering: Exposed timber joinery exhibits minor, moderate, significant weathering.',
  ),
  VerbatimRule(
    'e8_decay',
    'activity_outside_property_other_joinery_and_finishes_timber_decay',
    '{E_OTHER_JOINERY_AND_FINISHES}',
    '{E8_TIMBER_DECAY}',
    [
      VerbatimToken(
        '{TIMBER_DECAY_SIGNS}',
        options: {
          'e8td_localised_wet_rot': 'localised wet rot',
          'e8td_surface_decay': 'surface decay',
          'e8td_timber_deterioration': 'timber deterioration',
        },
        cap: true,
        pdfOptions: ['localised wet rot', 'surface decay', 'timber deterioration'],
      ),
    ],
    pdf:
        'Timber Decay: Localised wet rot, surface decay, timber deterioration was observed.',
  ),
  VerbatimRule(
    'e8_defective',
    'activity_outside_property_other_joinery_and_finishes_defective_joinery',
    '{E_OTHER_JOINERY_AND_FINISHES}',
    '{E8_DEFECTIVE_JOINERY}',
    [
      VerbatimToken(
        '{JOINERY_DEFECT_LIST}',
        options: {
          'e8dj_loose_fascias': 'loose fascias',
          'e8dj_loose_soffits': 'loose soffits',
          'e8dj_damaged_bargeboards': 'damaged bargeboards',
          'e8dj_open_joints': 'open joints',
          'e8dj_defective_fixings': 'defective fixings',
          'e8dj_weathered_decoration': 'weathered decoration',
          'e8dj_localised_timber_decay': 'localised timber decay',
          'e8dj_distorted_joinery': 'distorted joinery',
          'e8dj_minor_impact_damage': 'minor impact damage',
        },
        pdfOptions: ['loose fascias', 'loose soffits', 'damaged bargeboards', 'open joints', 'defective fixings', 'weathered decoration', 'localised timber decay', 'distorted joinery', 'minor impact damage'],
      ),
    ],
    pdf:
        'Defective Joinery One or more defects were observed, including: • Loose fascias • Loose soffits • Damaged bargeboards • Open joints • Defective fixings • Weathered decoration • Localised timber decay • Distorted joinery • Minor impact damage Repairs should be undertaken to prevent further deterioration and maintain weather resistance.',
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
