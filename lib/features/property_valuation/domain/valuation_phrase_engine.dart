/// Live-preview phrase engine for Valuation screens.
///
/// Produces RICS-standard professional narrative text that reads as if
/// hand-written by a chartered surveyor.  Each handler converts field
/// answers into descriptive full sentences suitable for inclusion in a
/// formal valuation report.
class ValuationPhraseEngine {
  const ValuationPhraseEngine();

  // ─── public entry point ──────────────────────────────────────────────

  List<String> buildPhrases(String screenId, Map<String, String> answers) {
    switch (screenId) {
      // ── Valuation Details ──
      case 'general_details':
        return _generalDetails(answers);
      case 'new_build_property':
        return _newBuildProperty(answers);

      // ── Property Assessment ──
      case 'no_of_rooms':
        return _noOfRooms(answers);
      case 'accommodation_summary':
        return _accommodationSummary(answers);
      case 'location_amenities':
        return _locationAmenities(answers);
      case 'road':
        return _road(answers);

      // ── Property Inspection – Outside ──
      case 'val_pitched_roof':
        return _pitchedRoof(answers);
      case 'val_flat_roof':
        return _flatRoof(answers);
      case 'val_other_roof':
        return _otherRoof(answers);
      case 'val_flashings':
        return _standardPid(
          answers,
          componentName: 'flashings',
          componentArticle: 'The',
          componentVerb: 'are',
          cbIds: ['cb_lead_fl', 'cb_zinc_fl', 'cb_mortar_fl', 'cb_capped_fl', 'cb_vented_fl'],
          cbLabels: {'cb_lead_fl': 'lead', 'cb_zinc_fl': 'zinc', 'cb_mortar_fl': 'mortar', 'cb_capped_fl': 'capped', 'cb_vented_fl': 'vented'},
          otherCb: 'cb_other_429',
          otherText: 'et_other_222',
          conditionKey: 'actv_condition_flashings',
          notesKey: 'et_notes_flashings',
          remarksKey: 'et_general_remarks_flashings',
        );
      case 'val_rainwater_goods':
        return _standardPid(
          answers,
          componentName: 'rainwater goods',
          componentArticle: 'The',
          componentVerb: 'are',
          cbIds: ['cb_cast_iron', 'cb_alum', 'cb_upvc_rw', 'cb_asbestos_rw'],
          cbLabels: {'cb_cast_iron': 'cast iron', 'cb_alum': 'aluminium', 'cb_upvc_rw': 'UPVC', 'cb_asbestos_rw': 'asbestos cement'},
          otherCb: 'cb_other_723',
          otherText: 'et_other_477',
          conditionKey: 'actv_condition_rainwater',
          notesKey: 'et_notes_rainwater',
          remarksKey: 'et_general_remarks_rainwater',
        );
      case 'val_chimney_stacks':
        return _standardPid(
          answers,
          componentName: 'chimney stacks',
          componentArticle: 'The',
          componentVerb: 'are',
          descriptionTemplate: '{ARTICLE} {COMPONENT} are of {MATERIALS} construction.',
          cbIds: ['cb_brick_cs', 'cb_stone_cs', 'cb_rendered_cs'],
          cbLabels: {'cb_brick_cs': 'brick', 'cb_stone_cs': 'stone', 'cb_rendered_cs': 'rendered'},
          otherCb: 'cb_other_922',
          otherText: 'et_other_177',
          conditionKey: 'actv_condition_chimney',
          notesKey: 'et_notes_chimney',
          remarksKey: 'et_general_remarks_chimney',
        );
      case 'val_walls_type':
        return _wallsType(answers);
      case 'val_wall_tie_corrosion':
        return _wallTieCorrosion(answers);
      case 'val_floor_ext':
        return _floorExt(answers);
      case 'val_dpc':
        return _standardPid(
          answers,
          componentName: 'damp proof course',
          componentArticle: 'The',
          componentVerb: 'is',
          descriptionTemplate: '{ARTICLE} {COMPONENT} is of {MATERIALS} type.',
          cbIds: [
            'cb_eng_brick', 'cb_felt_dpc', 'cb_plastic_dpc',
            'cb_slate_dpc', 'cb_injected_dpc', 'cb_electro_osmotic',
          ],
          cbLabels: {
            'cb_eng_brick': 'engineering brick',
            'cb_felt_dpc': 'felt',
            'cb_plastic_dpc': 'plastic',
            'cb_slate_dpc': 'slate',
            'cb_injected_dpc': 'injected',
            'cb_electro_osmotic': 'electro-osmotic',
          },
          otherCb: 'cb_other_457',
          otherText: 'et_other_115',
          conditionKey: 'actv_condition_dpc',
          notesKey: 'et_notes_dpc',
          remarksKey: 'et_general_remarks_dpc',
        );
      case 'val_sub_floor_vents':
        return _subFloorVents(answers);
      case 'val_decorations_ext':
        return _standardPid(
          answers,
          componentName: 'external decorations',
          componentArticle: 'The',
          componentVerb: 'comprise',
          descriptionTemplate: '{ARTICLE} {COMPONENT} comprise {MATERIALS} finishes.',
          cbIds: ['cb_lead_de', 'cb_paint_de', 'cb_stain_de'],
          cbLabels: {'cb_lead_de': 'lead', 'cb_paint_de': 'paint', 'cb_stain_de': 'stain'},
          otherCb: 'cb_other_895',
          otherText: 'et_other_315',
          conditionKey: 'actv_condition_dec_ext',
          notesKey: 'et_notes_dec_ext',
          remarksKey: 'et_general_remarks_dec_ext',
        );
      case 'val_garage':
        return _garage(answers);
      case 'val_outbuildings':
        return _outbuildings(answers);
      case 'val_site':
        return _site(answers);
      case 'val_drainage':
        return _drainage(answers);

      // ── Property Inspection – Inside ──
      case 'val_roof_space':
        return _roofSpace(answers);
      case 'val_ceilings':
        return _standardPid(
          answers,
          componentName: 'ceilings',
          componentArticle: 'The',
          componentVerb: 'are',
          descriptionTemplate: '{ARTICLE} {COMPONENT} are of {MATERIALS} construction.',
          cbIds: ['cb_plasterboard', 'cb_lath', 'cb_asbestos_cl', 'cb_fibreboard', 'cb_polystyrene_tiles'],
          cbLabels: {
            'cb_plasterboard': 'plasterboard',
            'cb_lath': 'lath and plaster',
            'cb_asbestos_cl': 'asbestos',
            'cb_fibreboard': 'fibreboard',
            'cb_polystyrene_tiles': 'polystyrene tile',
          },
          otherCb: 'cb_other_690',
          otherText: 'et_other_571',
          conditionKey: 'actv_condition_ceilings',
          notesKey: 'et_notes_ceilings',
          remarksKey: 'et_general_remarks_ceilings',
        );
      case 'val_walls_internal':
        return _standardPid(
          answers,
          componentName: 'internal walls and partitions',
          componentArticle: 'The',
          componentVerb: 'are',
          descriptionTemplate: '{ARTICLE} {COMPONENT} are of {MATERIALS} construction.',
          cbIds: ['cb_solid_wi', 'cb_stud', 'cb_dry_lined', 'cb_removed_wi'],
          cbLabels: {
            'cb_solid_wi': 'solid',
            'cb_stud': 'stud partition',
            'cb_dry_lined': 'dry-lined',
            'cb_removed_wi': 'removed section',
          },
          otherCb: 'cb_other_914',
          otherText: 'et_other_791',
          conditionKey: 'actv_condition_walls_int',
          notesKey: 'et_notes_walls_int',
          remarksKey: 'et_general_remarks_walls_int',
        );
      case 'val_chimney_breasts':
        return _chimneyBreasts(answers);
      case 'val_external_joinery':
        return _externalJoinery(answers);
      case 'val_internal_fittings':
        return _internalFittings(answers);
      case 'val_decorations_int':
        return _standardPid(
          answers,
          componentName: 'internal decorations',
          componentArticle: 'The',
          componentVerb: 'comprise',
          descriptionTemplate: '{ARTICLE} {COMPONENT} comprise {MATERIALS} finishes throughout.',
          cbIds: ['cb_artex', 'cb_paint_di', 'cb_wallpaper'],
          cbLabels: {
            'cb_artex': 'artex textured',
            'cb_paint_di': 'painted',
            'cb_wallpaper': 'wallpapered',
          },
          otherCb: 'cb_other_504',
          otherText: 'et_other_278',
          conditionKey: 'actv_condition_dec_int',
          notesKey: 'et_notes_dec_int',
          remarksKey: 'et_general_remarks_dec_int',
        );
      case 'val_damp_meter':
        return _dampMeter(answers);
      case 'val_timber_defects':
        return _timberDefects(answers);
      case 'val_electric_material':
        return _electricMaterial(answers);
      case 'val_gas':
        return _gasSupply(answers);
      case 'val_water':
        return _waterSupply(answers);
      case 'val_hot_water_central_heating':
        return _hotWaterCH(answers);
      case 'val_smoke_detectors':
        return _smokeDetectors(answers);

      // ── Condition & Restrictions ──
      case 'overall_condition':
        return _overallCondition(answers);
      case 'other_matters':
        return _otherMatters(answers);
      case 'energy_performance':
        return _energyPerformance(answers);

      // ── Valuation & Completion ──
      case 'valuation':
        return _valuation(answers);
      case 'general_remarks':
        return _generalRemarks(answers);

      // ── Floor Plan ──
      case 'scan_floor_plan':
        return const ['Floor plan scanned during the valuation inspection.'];

      default:
        return const [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  static bool _isChecked(String? value) {
    final v = (value ?? '').toLowerCase();
    return v == 'true' || v == '1' || v == 'yes';
  }

  static String _val(Map<String, String> a, String key) =>
      (a[key] ?? '').trim();

  static List<String> _checkedLabels(
    Map<String, String> answers,
    List<String> ids,
    Map<String, String> labels,
  ) {
    final result = <String>[];
    for (final id in ids) {
      if (_isChecked(answers[id])) {
        result.add(labels[id] ?? id);
      }
    }
    return result;
  }

  static String _toWords(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first;
    return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
  }

  static void _addOther(
    List<String> items,
    Map<String, String> answers,
    String checkboxId,
    String textId,
  ) {
    if (_isChecked(answers[checkboxId])) {
      final text = _val(answers, textId);
      items.add(text.isEmpty ? 'other' : text.toLowerCase());
    }
  }

  /// Map a raw condition string to a professional RICS narrative sentence.
  static String _conditionPhrase(String condition, {String component = ''}) {
    final lc = condition.toLowerCase().trim();
    final prefix = component.isNotEmpty
        ? 'The $component'
        : 'The overall condition';

    switch (lc) {
      case 'satisfactory':
      case 'good':
        return '$prefix is considered ${lc == 'good' ? 'good' : 'satisfactory'}, '
            'commensurate with the age and type of construction. '
            'No immediate repair work is considered necessary at this stage. '
            'Ongoing routine maintenance should be undertaken to preserve the current condition and prevent deterioration.';
      case 'reasonable':
        return '$prefix is considered reasonable for a property of this age and type of construction. '
            'No immediate repair work is considered necessary at this stage. '
            'Ongoing routine maintenance should be carried out in the normal way to preserve the current condition.';
      case 'unsatisfactory':
      case 'poor':
      case 'unsatisfactory and poor':
        return '$prefix is considered unsatisfactory and remedial work is necessary. '
            'It is recommended that a suitably qualified specialist be instructed to carry out a detailed investigation '
            'and to advise on the scope and cost of the necessary remedial works.';
      case '1':
        return '$prefix has been assessed as Condition Rating 1. '
            'No immediate repair work is considered necessary at this stage. '
            'Ongoing routine maintenance should be undertaken to preserve the current condition and prevent deterioration.';
      case '2':
        return '$prefix has been assessed as Condition Rating 2. '
            'Defects requiring repair or replacement have been identified, but these are not considered to be serious or urgent at the present time. '
            'Budget provision should be made for the recommended works.';
      case '3':
        return '$prefix has been assessed as Condition Rating 3. '
            'Serious defects have been identified that require urgent attention and may pose a risk to the safety or structural integrity of the property. '
            'Immediate further investigation by a suitably qualified specialist is strongly recommended.';
      default:
        if (condition.isNotEmpty) {
          return '$prefix has been assessed as $condition.';
        }
        return '';
    }
  }

  /// Append a rich condition note + any user-entered detail notes.
  static void _addConditionNotes(
    List<String> phrases,
    Map<String, String> answers,
    String conditionKey,
    String notesKey, {
    String component = '',
  }) {
    final condition = _val(answers, conditionKey);
    if (condition.isNotEmpty) {
      phrases.add(_conditionPhrase(condition, component: component));
    }
    final lc = condition.toLowerCase();
    if (lc == 'unsatisfactory' || lc == 'poor' || lc == 'unsatisfactory and poor' || lc == '3') {
      final notes = _val(answers, notesKey);
      if (notes.isNotEmpty) {
        phrases.add(notes);
      }
    }
  }

  /// Append user-typed remarks directly (already surveyor-written prose).
  static void _addRemarks(
    List<String> phrases,
    Map<String, String> answers,
    String remarksKey,
  ) {
    final remarks = _val(answers, remarksKey);
    if (remarks.isNotEmpty) {
      phrases.add(remarks);
    }
  }

  /// Convert a number string to a word for counts up to 20.
  static String _numberWord(String n) {
    const words = {
      '1': 'one', '2': 'two', '3': 'three', '4': 'four', '5': 'five',
      '6': 'six', '7': 'seven', '8': 'eight', '9': 'nine', '10': 'ten',
      '11': 'eleven', '12': 'twelve', '13': 'thirteen', '14': 'fourteen',
      '15': 'fifteen', '16': 'sixteen', '17': 'seventeen', '18': 'eighteen',
      '19': 'nineteen', '20': 'twenty',
    };
    return words[n.trim()] ?? n.trim();
  }

  /// Pluralise a room label if count > 1.
  static String _pluralRoom(String count, String singular) {
    final n = int.tryParse(count.trim()) ?? 1;
    if (n <= 1) return singular;
    // Special plurals
    if (singular == 'WC') return 'WCs';
    if (singular == 'conservatory') return 'conservatories';
    if (singular == 'utility room') return 'utility rooms';
    return '${singular}s';
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STANDARD PID SCREEN (generic material + condition + remarks)
  // ═══════════════════════════════════════════════════════════════════════

  List<String> _standardPid(
    Map<String, String> answers, {
    required String componentName,
    String componentArticle = 'The',
    String componentVerb = 'are',
    String? descriptionTemplate,
    required List<String> cbIds,
    required Map<String, String> cbLabels,
    String? otherCb,
    String? otherText,
    required String conditionKey,
    required String notesKey,
    required String remarksKey,
  }) {
    final phrases = <String>[];
    final items = _checkedLabels(answers, cbIds, cbLabels);
    if (otherCb != null && otherText != null) {
      _addOther(items, answers, otherCb, otherText);
    }
    if (items.isNotEmpty) {
      if (descriptionTemplate != null) {
        phrases.add(descriptionTemplate
            .replaceAll('{ARTICLE}', componentArticle)
            .replaceAll('{COMPONENT}', componentName)
            .replaceAll('{MATERIALS}', _toWords(items)));
      } else {
        phrases.add('$componentArticle $componentName $componentVerb of ${_toWords(items)} construction, '
            'which is consistent with the original building specification for a property of this age and type.');
      }
    }
    _addConditionNotes(phrases, answers, conditionKey, notesKey, component: componentName);
    _addRemarks(phrases, answers, remarksKey);
    return phrases;
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  VALUATION DETAILS
  // ═══════════════════════════════════════════════════════════════════════

  List<String> _generalDetails(Map<String, String> answers) {
    final phrases = <String>[];

    final status = _val(answers, 'actv_status');
    final finishes = _val(answers, 'actv_finishes');
    final carpeted = _val(answers, 'actv_carpeted');
    if (status.isNotEmpty || finishes.isNotEmpty || carpeted.isNotEmpty) {
      final buf = StringBuffer('At the time of inspection, the property was ');
      final parts = <String>[];
      if (status.isNotEmpty) parts.add(status.toLowerCase());
      if (finishes.isNotEmpty) parts.add('with ${finishes.toLowerCase()} finishes');
      if (carpeted.isNotEmpty) parts.add('${carpeted.toLowerCase()} carpeted throughout');
      buf.write('${parts.join(', ')}.');
      phrases.add(buf.toString());
    }

    final reason = _val(answers, 'actv_vl_reason');
    if (reason.isNotEmpty) {
      phrases.add('The purpose of this valuation is for $reason.');
    }

    final weather = _val(answers, 'actv_weather');
    if (weather.isNotEmpty) {
      phrases.add('At the time of my inspection, the weather conditions were ${weather.toLowerCase()}. '
          'It should be noted that certain defects may be more or less apparent depending on the prevailing weather conditions at the time of inspection.');
    }

    final tenure = _val(answers, 'actv_tenure');
    if (tenure.isNotEmpty) {
      phrases.add('The property is held on a ${tenure.toLowerCase()} basis. '
          'Your legal adviser should confirm the precise terms and any obligations arising from the tenure.');
    }

    final type = _val(answers, 'actv_type');
    final subType = _val(answers, 'actv_sub_type');
    if (type.isNotEmpty) {
      final buf = StringBuffer('The property is a ');
      if (subType.isNotEmpty) buf.write('${subType.toLowerCase()} ');
      buf.write('${type.toLowerCase()}.');
      phrases.add(buf.toString());
    }

    if (type == 'Flat') {
      final flatType = _val(answers, 'actv_flat_type');
      final buildType = _val(answers, 'actv_build_type');
      if (flatType.isNotEmpty || buildType.isNotEmpty) {
        final buf = StringBuffer('The flat is ');
        final parts = <String>[];
        if (flatType.isNotEmpty) parts.add('of ${flatType.toLowerCase()} type');
        if (buildType.isNotEmpty) parts.add('within a ${buildType.toLowerCase()} building');
        buf.write('${parts.join(' ')}.');
        phrases.add(buf.toString());
      }
    }

    final estateType = _val(answers, 'actv_estate_type');
    if (estateType.isNotEmpty) {
      phrases.add('The property is situated on a ${estateType.toLowerCase()} estate.');
    }

    final construction = _checkedLabels(answers, [
      'cb_non_traditional_construction', 'cb_LPS', 'cb_concrete',
      'cb_steel', 'cb_timber', 'cb_modular',
    ], {
      'cb_non_traditional_construction': 'pre-cast reinforced concrete (PRC)',
      'cb_LPS': 'large panel system',
      'cb_concrete': 'concrete',
      'cb_steel': 'steel frame',
      'cb_timber': 'timber frame',
      'cb_modular': 'modular',
    });
    final systemType = _val(answers, 'et_system_type');
    if (construction.isNotEmpty) {
      var text = 'The property is of non-traditional ${_toWords(construction)} construction';
      if (systemType.isNotEmpty) text += ', identified as the $systemType system';
      phrases.add('$text. Your legal adviser should confirm whether a structural certificate or warranty is available.');
    }

    final age = _val(answers, 'et_age');
    final extAge = _val(answers, 'et_age_extension');
    if (age.isNotEmpty) {
      var text = 'Based on my professional knowledge of the area, construction methods, and architectural styles, I estimate the property was built circa $age';
      if (extAge.isNotEmpty) text += ', with an extension or alteration added circa $extAge';
      phrases.add('$text. This estimate is provided for guidance purposes and should be verified by your legal adviser through title deeds or local authority records where appropriate.');
    }

    if (_isChecked(answers['cb_is_listed_building'])) {
      phrases.add('The property is a listed building. Your legal adviser should advise on the implications of this building status, including restrictions on alterations and maintenance obligations.');
    }

    return phrases;
  }

  List<String> _newBuildProperty(Map<String, String> answers) {
    final phrases = <String>[];
    final builder = _val(answers, 'et_builder_name');
    if (builder.isNotEmpty) {
      phrases.add('The property is a new build development constructed by $builder.');
    }

    final stage = _val(answers, 'actv_work_stage');
    if (stage.isNotEmpty) {
      phrases.add('At the time of my inspection, the construction works were at the ${stage.toLowerCase()} stage. '
          'The valuation is provided on the basis that the property will be completed to a satisfactory standard '
          'in accordance with the approved plans and specifications.');
    }

    final warranty = _val(answers, 'actv_warranty');
    if (warranty.isNotEmpty) {
      phrases.add('The property benefits from a $warranty structural warranty. '
          'Your legal adviser should confirm the precise terms, duration, and transferability of this warranty cover.');
    }

    final incentives = _val(answers, 'et_incentives');
    if (incentives.isNotEmpty) {
      phrases.add('I am advised that the following incentives are being offered by the developer: $incentives. '
          'These incentives have been taken into consideration in arriving at my valuation figure, '
          'in accordance with RICS guidance on the treatment of incentives.');
    }

    final date = _val(answers, 'in_date');
    if (date.isNotEmpty) {
      phrases.add('The inspection was carried out on $date.');
    }

    return phrases;
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  PROPERTY ASSESSMENT
  // ═══════════════════════════════════════════════════════════════════════

  List<String> _noOfRooms(Map<String, String> answers) {
    final phrases = <String>[];
    final rooms = <String>[];

    void addRoom(String key, String singular) {
      final v = _val(answers, key);
      if (v.isNotEmpty && v != '0') {
        rooms.add('${_numberWord(v)} ${_pluralRoom(v, singular)}');
      }
    }

    addRoom('et_liv', 'reception room');
    addRoom('et_kit', 'kitchen');
    addRoom('et_bed', 'bedroom');
    addRoom('et_bath', 'bathroom');
    addRoom('et_wc', 'WC');
    addRoom('et_ut', 'utility room');
    addRoom('et_con', 'conservatory');

    final otherName = _val(answers, 'et_other_name');
    final otherCount = _val(answers, 'et_other');
    if (otherCount.isNotEmpty && otherCount != '0') {
      final name = otherName.isNotEmpty ? otherName.toLowerCase() : 'other room';
      rooms.add('${_numberWord(otherCount)} ${_pluralRoom(otherCount, name)}');
    }

    if (rooms.isNotEmpty) {
      phrases.add('The property provides accommodation comprising ${_toWords(rooms)}.');
    }
    return phrases;
  }

  List<String> _accommodationSummary(Map<String, String> answers) {
    final phrases = <String>[];

    final parking = _checkedLabels(answers, [
      'cb_garage', 'cb_single', 'cb_double', 'cb_parking_space',
      'cb_car_port', 'cb_none',
    ], {
      'cb_garage': 'a garage',
      'cb_single': 'a single garage',
      'cb_double': 'a double garage',
      'cb_parking_space': 'an allocated parking space',
      'cb_car_port': 'a car port',
      'cb_none': 'no dedicated parking',
    });
    _addOther(parking, answers, 'cb_other_720', 'et_other_792');
    if (parking.isNotEmpty) {
      phrases.add('Off-street parking is provided by way of ${_toWords(parking)}.');
    }

    final location = _val(answers, 'actv_parking_location');
    if (location.isNotEmpty) {
      phrases.add('The parking is located to the ${location.toLowerCase()} of the property.');
    }

    if (_isChecked(answers['cb_external_outbuildings'])) {
      final desc = _val(answers, 'et_describe');
      if (desc.isNotEmpty) {
        phrases.add('The property includes external outbuildings comprising $desc. '
            'These were inspected as part of this survey where accessible.');
      } else {
        phrases.add('The property includes external outbuildings, which were inspected as part of this survey where accessible.');
      }
    }
    if (_isChecked(answers['cb_external_garden'])) {
      phrases.add('The property benefits from garden areas to the front and/or rear. '
          'The gardens were inspected as part of this survey.');
    }

    return phrases;
  }

  List<String> _locationAmenities(Map<String, String> answers) {
    final phrases = <String>[];

    final location = _val(answers, 'actv_location');
    if (location.isNotEmpty) {
      phrases.add('The property is situated within an established ${location.toLowerCase()} area, '
          'which is considered to be a desirable location for properties of this type.');
    }

    final closeTo = _checkedLabels(answers, [
      'cb_local_amenities', 'cb_conservation_area',
    ], {
      'cb_local_amenities': 'local amenities including schools, shops, and transport links',
      'cb_conservation_area': 'a designated conservation area',
    });
    _addOther(closeTo, answers, 'cb_other_close_to', 'et_other_close_to');
    if (closeTo.isNotEmpty) {
      phrases.add('The property is conveniently located close to ${_toWords(closeTo)}.');
    }

    final env = _checkedLabels(answers, [
      'cb_pollution', 'cb_emfs', 'cb_adverse_neighbouring',
    ], {
      'cb_pollution': 'potential pollution sources',
      'cb_emfs': 'electromagnetic field sources',
      'cb_adverse_neighbouring': 'adverse neighbouring uses',
    });
    _addOther(env, answers, 'cb_other_env', 'et_other_env');
    if (env.isNotEmpty) {
      phrases.add('I noted ${_toWords(env)} in the vicinity of the property, '
          'which may have an adverse effect on the value, saleability, or desirability of the property. '
          'Further enquiries with the relevant local authority are recommended.');
    }

    if (_isChecked(answers['cb_adverse_neighbouring'])) {
      final desc = _val(answers, 'et_adverse_describe');
      if (desc.isNotEmpty) phrases.add(desc);
    }

    return phrases;
  }

  List<String> _road(Map<String, String> answers) {
    final phrases = <String>[];
    final types = _checkedLabels(answers, [
      'cb_adopted', 'cb_private', 'cb_made', 'cb_partly_made', 'cb_unmade',
    ], {
      'cb_adopted': 'an adopted highway maintained at public expense',
      'cb_private': 'a private road',
      'cb_made': 'a made-up road',
      'cb_partly_made': 'a partly made-up road',
      'cb_unmade': 'an unmade road',
    });
    if (types.isNotEmpty) {
      phrases.add('The property fronts onto ${_toWords(types)}.');
    }
    final cost = _val(answers, 'et_cost_of_making_up');
    if (cost.isNotEmpty) {
      phrases.add('The estimated cost of making up the road to an adoptable standard is $cost. '
          'Your legal adviser should confirm any potential liability for road-making charges and '
          'whether any Section 38 agreement is in place with the highway authority.');
    }
    return phrases;
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  PROPERTY INSPECTION – OUTSIDE (custom screens)
  // ═══════════════════════════════════════════════════════════════════════

  List<String> _pitchedRoof(Map<String, String> answers) {
    final phrases = <String>[];
    final items = _checkedLabels(answers, [
      'cb_tile', 'cb_natural_slate', 'cb_artificial_slate',
      'cb_stone_pr', 'cb_thatch', 'cb_original_pr', 'cb_replaced_pr',
    ], {
      'cb_tile': 'tile',
      'cb_natural_slate': 'natural slate',
      'cb_artificial_slate': 'artificial slate',
      'cb_stone_pr': 'stone',
      'cb_thatch': 'thatch',
      'cb_original_pr': 'original',
      'cb_replaced_pr': 'replacement',
    });
    _addOther(items, answers, 'cb_other_909', 'et_other_777');
    if (items.isNotEmpty) {
      phrases.add('The main roof is of pitched construction, covered with ${_toWords(items)} materials, '
          'which is a typical covering for a property of this age and construction type. '
          'The roof surfaces were inspected from ground level using binoculars where necessary to supplement the visual assessment.');
    }
    _addConditionNotes(phrases, answers, 'actv_condition_pitched_roof', 'et_notes_pitched_roof', component: 'pitched roof covering');

    if (_isChecked(answers['cb_partial_view_pr'])) {
      phrases.add('Only a partial view of the roof was possible from ground level due to the height and configuration of the building. '
          'A more detailed inspection from a scaffold or elevated platform may reveal additional defects not visible from the ground. '
          'A specialist roofing inspection should be considered as part of the property\'s ongoing maintenance regime.');
    }
    final vis = _val(answers, 'actv_visibility_pr');
    if (vis.isNotEmpty) {
      phrases.add('The visibility from ground level was ${vis.toLowerCase()}.');
    }
    final visCond = _val(answers, 'actv_visibility_condition_pr');
    if (visCond.isNotEmpty) {
      phrases.add(_conditionPhrase(visCond, component: 'visible portion of the roof'));
    }
    if (visCond.toLowerCase() == 'unsatisfactory') {
      final vn = _val(answers, 'et_visibility_notes_pr');
      if (vn.isNotEmpty) phrases.add(vn);
    }
    final vent = _val(answers, 'actv_roof_ventilation_pr');
    if (vent.isNotEmpty) {
      phrases.add('Roof ventilation is provided and appears ${vent.toLowerCase()}.');
    }

    _addRemarks(phrases, answers, 'et_general_remarks_pitched_roof');
    return phrases;
  }

  List<String> _flatRoof(Map<String, String> answers) {
    final phrases = <String>[];
    final items = _checkedLabels(answers, [
      'cb_felt_fr', 'cb_asphalt_fr', 'cb_lead_fr', 'cb_zinc_fr',
    ], {
      'cb_felt_fr': 'mineral felt',
      'cb_asphalt_fr': 'asphalt',
      'cb_lead_fr': 'lead',
      'cb_zinc_fr': 'zinc',
    });
    _addOther(items, answers, 'cb_other_883', 'et_other_824');
    if (items.isNotEmpty) {
      phrases.add('The flat roof covering is of ${_toWords(items)} construction. '
          'Flat roof coverings have a comparatively limited serviceable lifespan and require regular maintenance checks. '
          'Even where the general condition may appear satisfactory, repairs or replacement should be anticipated in the future.');
    }
    _addConditionNotes(phrases, answers, 'actv_condition_flat_roof', 'et_notes_flat_roof', component: 'flat roof covering');

    if (_isChecked(answers['cb_partial_view_fr'])) {
      phrases.add('Only a partial view of the flat roof was possible at the time of inspection. '
          'A full inspection from an elevated position may reveal additional defects not visible from the ground.');
    }
    final visCond = _val(answers, 'actv_visibility_condition_fr');
    if (visCond.isNotEmpty) {
      phrases.add(_conditionPhrase(visCond, component: 'visible portion of the flat roof'));
    }
    if (visCond.toLowerCase() == 'unsatisfactory') {
      final vn = _val(answers, 'et_visibility_notes_fr');
      if (vn.isNotEmpty) phrases.add(vn);
    }
    final vent = _val(answers, 'actv_roof_ventilation_fr');
    if (vent.isNotEmpty) {
      phrases.add('Roof ventilation is provided and appears ${vent.toLowerCase()}.');
    }

    _addRemarks(phrases, answers, 'et_general_remarks_flat_roof');
    return phrases;
  }

  List<String> _otherRoof(Map<String, String> answers) {
    final phrases = <String>[];
    final roofName = _val(answers, 'et_other_roof_name');

    final pitched = _checkedLabels(answers, [
      'cb_tile_or', 'cb_natural_slate_or', 'cb_artificial_slate_or',
      'cb_stone_or', 'cb_thatch_or', 'cb_original_or', 'cb_replaced_or',
    ], {
      'cb_tile_or': 'tile',
      'cb_natural_slate_or': 'natural slate',
      'cb_artificial_slate_or': 'artificial slate',
      'cb_stone_or': 'stone',
      'cb_thatch_or': 'thatch',
      'cb_original_or': 'original',
      'cb_replaced_or': 'replacement',
    });
    _addOther(pitched, answers, 'cb_other_909_or', 'et_other_777_or');

    final flat = _checkedLabels(answers, [
      'cb_felt_or', 'cb_asphalt_or', 'cb_lead_or', 'cb_zinc_or',
    ], {
      'cb_felt_or': 'mineral felt',
      'cb_asphalt_or': 'asphalt',
      'cb_lead_or': 'lead',
      'cb_zinc_or': 'zinc',
    });
    _addOther(flat, answers, 'cb_other_883_or', 'et_other_824_or');

    final label = roofName.isNotEmpty ? roofName : 'The secondary roof';
    final allItems = [...pitched, ...flat];
    if (allItems.isNotEmpty) {
      phrases.add('$label is covered with ${_toWords(allItems)} materials, '
          'which is consistent with the original building specification for a property of this age and type. '
          'The roof surfaces were inspected from ground level using binoculars where necessary to supplement the visual assessment.');
    }

    _addConditionNotes(phrases, answers, 'actv_condition_other_roof', 'et_notes_other_roof', component: 'secondary roof covering');

    if (_isChecked(answers['cb_partial_view_or'])) {
      phrases.add('Only a partial view of the secondary roof was possible from ground level due to the height and configuration of the building. '
          'A more detailed inspection from an elevated position may reveal additional defects not visible from the ground.');
    }
    final visCond = _val(answers, 'actv_visibility_condition_or');
    if (visCond.isNotEmpty) {
      phrases.add(_conditionPhrase(visCond, component: 'visible portion of the secondary roof'));
    }
    if (visCond.toLowerCase() == 'unsatisfactory') {
      final vn = _val(answers, 'et_visibility_notes_or');
      if (vn.isNotEmpty) phrases.add(vn);
    }
    final vent = _val(answers, 'actv_roof_ventilation_or');
    if (vent.isNotEmpty) {
      phrases.add('Roof ventilation to the secondary roof is provided and appears ${vent.toLowerCase()}.');
    }

    _addRemarks(phrases, answers, 'et_general_remarks_other_roof');
    return phrases;
  }

  List<String> _wallsType(Map<String, String> answers) {
    final phrases = <String>[];
    final items = _checkedLabels(answers, [
      'cb_solid_wt', 'cb_cavity_wt', 'cb_timber_frame_wt',
      'cb_stone_wt', 'cb_brick_wt', 'cb_single_skin_wt', 'cb_render_wt',
    ], {
      'cb_solid_wt': 'solid',
      'cb_cavity_wt': 'cavity',
      'cb_timber_frame_wt': 'timber frame',
      'cb_stone_wt': 'stone',
      'cb_brick_wt': 'brick',
      'cb_single_skin_wt': 'single skin',
      'cb_render_wt': 'rendered',
    });
    _addOther(items, answers, 'cb_other_1009', 'et_other_142');
    if (items.isNotEmpty) {
      phrases.add('The principal external walls are of ${_toWords(items)} construction, '
          'which is consistent with the original building specification for a property of this age and type.');
    }
    _addConditionNotes(phrases, answers, 'actv_condition_walls', 'et_notes_walls', component: 'external walls');

    final thickness = _val(answers, 'et_wall_thickness');
    if (thickness.isNotEmpty) {
      phrases.add('The measured wall thickness is approximately $thickness, which is consistent with the identified construction type.');
    }

    final movement = _val(answers, 'actv_building_movement');
    if (movement.isNotEmpty) {
      phrases.add('A careful examination was made of all accessible wall surfaces for evidence of structural movement, '
          'including cracking, distortion, bulging, or displacement of masonry. '
          'Evidence of building movement was noted: ${movement.toLowerCase()}. '
          'So far as can be seen from this single inspection, the movement appears to be '
          'generally consistent with properties of this age and type of construction.');
    }

    if (_isChecked(answers['cb_risk_of_further_movement'])) {
      phrases.add('There is considered to be a risk of further progressive movement. '
          'A specialist structural engineer\'s report is strongly recommended before exchange of contracts '
          'to assess the significance of the movement and advise on any necessary remedial measures.');
    }

    _addRemarks(phrases, answers, 'et_general_remarks_walls');
    return phrases;
  }

  List<String> _wallTieCorrosion(Map<String, String> answers) {
    final phrases = <String>[];
    if (_isChecked(answers['cb_wall_tie_corrosion'])) {
      phrases.add('Evidence of wall tie corrosion was noted during the inspection, '
          'as indicated by horizontal cracking in the mortar bed joints at regular intervals. '
          'This is a potentially serious structural defect which, if left untreated, '
          'may compromise the structural integrity of the external wall leaves. '
          'A specialist survey by a qualified wall tie specialist is strongly recommended '
          'before exchange of contracts to assess the extent of the corrosion and advise on remedial measures.');
    }
    _addRemarks(phrases, answers, 'et_general_remarks_wall_tie');
    return phrases;
  }

  List<String> _floorExt(Map<String, String> answers) {
    final phrases = <String>[];

    // Ground floor
    final gf = _checkedLabels(answers, [
      'cb_solid_gf', 'cb_timber_gf',
    ], {
      'cb_solid_gf': 'solid concrete',
      'cb_timber_gf': 'suspended timber',
    });
    _addOther(gf, answers, 'cb_other_327', 'et_other_469');
    if (gf.isNotEmpty) {
      phrases.add('The ground floor is of ${_toWords(gf)} construction. '
          'The floor coverings were not lifted during the inspection, and the condition of the floor structure '
          'could only be assessed from the general feel and level of the floors when walked upon.');
    }
    _addConditionNotes(phrases, answers, 'actv_condition_floor_ext', 'et_notes_floor_ext', component: 'ground floor');
    _addRemarks(phrases, answers, 'et_general_remarks_floor_ext');

    // Upper floor
    final uf = _checkedLabels(answers, [
      'cb_solid_uf', 'cb_timber_uf',
    ], {
      'cb_solid_uf': 'solid concrete',
      'cb_timber_uf': 'suspended timber',
    });
    _addOther(uf, answers, 'cb_other_327_u', 'et_other_469_u');
    if (uf.isNotEmpty) {
      phrases.add('The upper floors are of ${_toWords(uf)} construction. '
          'No significant deflection or unevenness was noted when the floors were walked upon during the inspection.');
    }
    _addConditionNotes(phrases, answers, 'actv_condition_upper_floor', 'et_notes_upper_floor', component: 'upper floors');
    _addRemarks(phrases, answers, 'et_general_remarks_upper_floor');

    return phrases;
  }

  List<String> _subFloorVents(Map<String, String> answers) {
    final phrases = <String>[];
    final vents = _val(answers, 'actv_sub_floor_vents');
    if (vents.isNotEmpty) {
      if (vents.toLowerCase() == 'adequate') {
        phrases.add('Sub-floor ventilation is provided by airbricks at appropriate intervals and appears adequate '
            'for the size and configuration of the property. Adequate ventilation is essential to prevent the '
            'build-up of moisture beneath the floor, which can lead to timber decay and fungal attack.');
      } else if (vents.toLowerCase() == 'inadequate') {
        phrases.add('Sub-floor ventilation appears inadequate for the size and configuration of the property. '
            'Additional airbricks or alternative ventilation measures should be installed at the earliest opportunity '
            'to reduce the risk of timber decay, fungal attack, and dampness to the sub-floor timbers.');
      } else {
        phrases.add('Sub-floor ventilation has been assessed as ${vents.toLowerCase()}.');
      }
    }
    _addConditionNotes(phrases, answers, 'actv_condition_sub_floor', 'et_notes_sub_floor', component: 'sub-floor ventilation');
    _addRemarks(phrases, answers, 'et_general_remarks_sub_floor');
    return phrases;
  }

  List<String> _garage(Map<String, String> answers) {
    final phrases = <String>[];
    final type = _val(answers, 'actv_garage_type');
    final number = _val(answers, 'actv_number_of_garage');
    if (type.isNotEmpty || number.isNotEmpty) {
      final buf = StringBuffer('The property includes ');
      if (number.isNotEmpty && number != '1') {
        buf.write('${_numberWord(number)} ');
      } else {
        buf.write('a ');
      }
      if (type.isNotEmpty) buf.write('${type.toLowerCase()} ');
      buf.write(number != '1' && number.isNotEmpty ? 'garages' : 'garage');
      buf.write(', which was inspected as part of this survey.');
      phrases.add(buf.toString());
    }
    _addConditionNotes(phrases, answers, 'actv_condition_garage', 'et_notes_garage', component: 'garage');
    _addRemarks(phrases, answers, 'et_general_remarks_garage');
    return phrases;
  }

  List<String> _outbuildings(Map<String, String> answers) {
    final phrases = <String>[];
    final desc = _val(answers, 'et_outbuilding_describe');
    if (desc.isNotEmpty) {
      phrases.add('The property includes outbuildings comprising $desc. '
          'The outbuildings were inspected as part of this survey where accessible.');
    }
    _addConditionNotes(phrases, answers, 'actv_condition_outbuildings', 'et_notes_outbuildings', component: 'outbuildings');
    _addRemarks(phrases, answers, 'et_general_remarks_outbuildings');
    return phrases;
  }

  List<String> _site(Map<String, String> answers) {
    final phrases = <String>[];
    final fencing = _checkedLabels(answers, [
      'cb_fences', 'cb_retaining_walls', 'cb_hedges', 'cb_walls_site',
      'cb_railings', 'cb_none_site', 'cb_wire_mesh',
    ], {
      'cb_fences': 'fences',
      'cb_retaining_walls': 'retaining walls',
      'cb_hedges': 'hedges',
      'cb_walls_site': 'walls',
      'cb_railings': 'railings',
      'cb_none_site': 'no defined boundaries',
      'cb_wire_mesh': 'wire mesh fencing',
    });
    _addOther(fencing, answers, 'cb_other_720_site', 'et_other_792_site');
    if (fencing.isNotEmpty) {
      phrases.add('The site boundaries are defined by ${_toWords(fencing)}. '
          'The boundaries were inspected from within the site and from adjacent public areas where accessible.');
    }
    if (_isChecked(answers['cb_boundaries_well_defined'])) {
      phrases.add('The boundaries appear well defined and clearly identifiable on the ground. '
          'Your legal adviser should confirm the precise extent of the boundaries from the title deeds.');
    }
    if (_isChecked(answers['cb_trees_within_root'])) {
      phrases.add('Trees were noted within root influencing distance of the property. '
          'Your legal adviser should confirm whether any Tree Preservation Orders are in place. '
          'The proximity of the trees may influence the property\'s foundations and drainage, '
          'and specialist arboricultural advice should be obtained if any works to the trees are proposed.');
    }
    _addConditionNotes(phrases, answers, 'actv_condition_site', 'et_notes_site', component: 'site boundaries');
    _addRemarks(phrases, answers, 'et_general_remarks_site');
    return phrases;
  }

  List<String> _drainage(Map<String, String> answers) {
    final phrases = <String>[];
    final items = _checkedLabels(answers, [
      'cb_mains_dr', 'cb_septic_tank', 'cb_cess_pit',
      'cb_private_dr', 'cb_shared_dr',
    ], {
      'cb_mains_dr': 'mains drainage',
      'cb_septic_tank': 'a septic tank',
      'cb_cess_pit': 'a cess pit',
      'cb_private_dr': 'a private system',
      'cb_shared_dr': 'a shared system',
    });
    _addOther(items, answers, 'cb_other_299', 'et_other_120');
    if (items.isNotEmpty) {
      phrases.add('The property is served by ${_toWords(items)}. '
          'The drainage system was not tested as part of this inspection.');
    }
    if (_isChecked(answers['cb_test_required'])) {
      phrases.add('A full drainage survey, including a CCTV inspection of the underground pipework, is recommended '
          'to confirm the condition, adequacy, and functionality of the system. '
          'Your legal adviser should confirm any shared drainage responsibilities and associated maintenance obligations.');
    }
    _addConditionNotes(phrases, answers, 'actv_condition_drainage', 'et_notes_drainage', component: 'drainage');
    _addRemarks(phrases, answers, 'et_general_remarks_drainage');
    return phrases;
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  PROPERTY INSPECTION – INSIDE (custom screens)
  // ═══════════════════════════════════════════════════════════════════════

  List<String> _roofSpace(Map<String, String> answers) {
    final phrases = <String>[];
    final material = _checkedLabels(answers, [
      'cb_trussed', 'cb_rafters', 'cb_purlins',
      'cb_braced_lined', 'cb_unlined', 'cb_no_access_statereason',
    ], {
      'cb_trussed': 'trussed rafter',
      'cb_rafters': 'traditional rafter and purlin',
      'cb_purlins': 'purlin',
      'cb_braced_lined': 'braced and lined',
      'cb_unlined': 'unlined',
      'cb_no_access_statereason': 'no access',
    });
    if (material.contains('no access')) {
      phrases.add('Access to the roof space was not possible at the time of inspection. '
          'Accordingly, the condition of the roof timbers, insulation, water tanks, and any associated pipework '
          'could not be assessed. This should be considered a limitation of this inspection.');
    } else if (material.isNotEmpty) {
      phrases.add('The roof space was entered and inspected where accessible. '
          'The roof structure is of ${_toWords(material)} construction, '
          'which is consistent with the original building specification for a property of this age and type.');
    }

    final limitations = _checkedLabels(answers, [
      'cb_stored_items', 'cb_boarded', 'cb_insulation',
    ], {
      'cb_stored_items': 'stored items restricting access',
      'cb_boarded': 'boarding over the joists',
      'cb_insulation': 'insulation between the joists',
    });
    _addOther(limitations, answers, 'cb_other_766', 'et_other_580');
    if (limitations.isNotEmpty) {
      phrases.add('The inspection of the roof space was limited by ${_toWords(limitations)}, '
          'which prevented a full examination of all areas. '
          'Concealed defects may exist in those areas that could not be inspected.');
    }

    _addConditionNotes(phrases, answers, 'actv_condition_roof_space', 'et_notes_roof_space', component: 'roof space');
    _addRemarks(phrases, answers, 'et_general_remarks_roof_space');
    return phrases;
  }

  List<String> _chimneyBreasts(Map<String, String> answers) {
    final phrases = <String>[];
    final items = _checkedLabels(answers, [
      'cb_used', 'cb_sealed', 'cb_vents', 'cb_no_vents', 'cb_removed_cb',
    ], {
      'cb_used': 'in use',
      'cb_sealed': 'sealed',
      'cb_vents': 'fitted with ventilation',
      'cb_no_vents': 'without ventilation',
      'cb_removed_cb': 'removed',
    });
    _addOther(items, answers, 'cb_other_1033', 'et_other_829');
    if (items.isNotEmpty) {
      phrases.add('The chimney breasts within the property are ${_toWords(items)}.');
      if (items.contains('without ventilation')) {
        phrases.add('Where chimney breasts have been sealed without adequate ventilation, there is a significant risk '
            'of condensation and dampness accumulating within the redundant flue. '
            'Appropriate ventilation grilles should be installed to each sealed fireplace opening to ensure adequate air circulation.');
      }
      if (items.contains('removed')) {
        phrases.add('Where chimney breasts have been removed at lower levels, your legal adviser should confirm that '
            'Building Regulations approval was obtained for the works and that adequate structural support '
            'has been provided to the remaining chimney stack and breast above.');
      }
    }
    _addConditionNotes(phrases, answers, 'actv_condition_chimney_br', 'et_notes_chimney_br', component: 'chimney breasts');
    _addRemarks(phrases, answers, 'et_general_remarks_chimney_br');
    return phrases;
  }

  List<String> _externalJoinery(Map<String, String> answers) {
    final phrases = <String>[];
    final frameMaterials = <String>[];
    final glazingTypes = <String>[];

    // Separate frame materials from glazing types
    for (final entry in {
      'cb_timber_ej': 'timber',
      'cb_galvanised': 'galvanised steel',
      'cb_aluminium': 'aluminium',
      'cb_upvc_ej': 'UPVC',
    }.entries) {
      if (_isChecked(answers[entry.key])) frameMaterials.add(entry.value);
    }
    for (final entry in {
      'cb_single_glazed': 'single glazed',
      'cb_double_glazed': 'double glazed',
      'cb_triple_glazed': 'triple glazed',
    }.entries) {
      if (_isChecked(answers[entry.key])) glazingTypes.add(entry.value);
    }
    _addOther(frameMaterials, answers, 'cb_other_948', 'et_other_438');

    if (frameMaterials.isNotEmpty || glazingTypes.isNotEmpty) {
      final buf = StringBuffer('The windows and external joinery are of ');
      if (frameMaterials.isNotEmpty) buf.write('${_toWords(frameMaterials)} frame construction');
      if (frameMaterials.isNotEmpty && glazingTypes.isNotEmpty) buf.write(', ');
      if (glazingTypes.isNotEmpty) buf.write('${_toWords(glazingTypes)}');
      buf.write('. The windows were inspected from both the interior and exterior of the property where accessible.');
      phrases.add(buf.toString());
    }
    _addConditionNotes(phrases, answers, 'actv_condition_ext_joinery', 'et_notes_ext_joinery', component: 'windows and external joinery');
    _addRemarks(phrases, answers, 'et_general_remarks_ext_joinery');
    return phrases;
  }

  List<String> _internalFittings(Map<String, String> answers) {
    final phrases = <String>[];
    final items = _checkedLabels(answers, [
      'cb_kitchen_units', 'cb_utility', 'cb_bath_fittings',
    ], {
      'cb_kitchen_units': 'kitchen units and worktops',
      'cb_utility': 'utility room fittings',
      'cb_bath_fittings': 'bathroom and sanitary fittings',
    });
    _addOther(items, answers, 'cb_other_673', 'et_other_534');
    if (items.isNotEmpty) {
      phrases.add('The internal fittings include ${_toWords(items)}. '
          'These were visually inspected as part of this survey. '
          'No tests were carried out to the plumbing or waste systems.');
    }
    _addConditionNotes(phrases, answers, 'actv_condition_int_fittings', 'et_notes_int_fittings', component: 'internal fittings');
    _addRemarks(phrases, answers, 'et_general_remarks_int_fittings');
    return phrases;
  }

  List<String> _dampMeter(Map<String, String> answers) {
    final phrases = <String>[];
    final meter = _val(answers, 'actv_damp_meter');
    if (meter.isNotEmpty) {
      if (meter == 'Damp Found') {
        phrases.add('Moisture readings were taken with a calibrated electronic moisture meter at representative points '
            'to the internal faces of external walls. Elevated moisture levels were detected.');
        final loc = _val(answers, 'et_damp_found');
        if (loc.isNotEmpty) {
          phrases.add('Elevated readings were noted at $loc. '
              'Further investigation by a specialist damp surveyor is recommended to establish the cause, extent, '
              'and appropriate remedial treatment for the dampness identified.');
        }
      } else if (meter.toLowerCase() == 'no damp') {
        phrases.add('Moisture readings were taken with a calibrated electronic moisture meter at representative points '
            'to the internal faces of external walls at both ground and upper floor levels where accessible. '
            'At the time of my inspection, the readings obtained were within acceptable parameters, '
            'and no visible signs of dampness, staining, or efflorescence were observed.');
      } else {
        phrases.add('Damp meter readings indicated: ${meter.toLowerCase()}.');
      }
    }
    _addConditionNotes(phrases, answers, 'actv_condition_damp', 'et_notes_damp', component: 'dampness');
    _addRemarks(phrases, answers, 'et_general_remarks_damp');
    return phrases;
  }

  List<String> _timberDefects(Map<String, String> answers) {
    final phrases = <String>[];
    final items = _checkedLabels(answers, [
      'cb_dry_rot', 'cb_wet_rot', 'cb_beetle_infestation',
    ], {
      'cb_dry_rot': 'dry rot',
      'cb_wet_rot': 'wet rot',
      'cb_beetle_infestation': 'beetle infestation',
    });
    _addOther(items, answers, 'cb_other_375', 'et_other_835');
    if (items.isNotEmpty) {
      phrases.add('Evidence of ${_toWords(items)} was noted during the inspection. '
          'This is a potentially serious defect which, if left untreated, may spread and cause significant damage to the building fabric. '
          'A specialist timber and damp report is strongly recommended before exchange of contracts '
          'to establish the full extent of the defect, the risk of spread, and the cost of remedial treatment.');
    }
    _addConditionNotes(phrases, answers, 'actv_condition_timber', 'et_notes_timber', component: 'timber');
    _addRemarks(phrases, answers, 'et_general_remarks_timber');
    return phrases;
  }

  List<String> _electricMaterial(Map<String, String> answers) {
    final phrases = <String>[];

    // Material section
    final material = _checkedLabels(answers, [
      'cb_rubber_cable', 'cb_upvc_el', 'cb_mixed_el',
    ], {
      'cb_rubber_cable': 'rubber sheathed cable',
      'cb_upvc_el': 'modern PVC sheathed cable',
      'cb_mixed_el': 'a mixture of old and new wiring',
    });
    _addOther(material, answers, 'cb_other_194', 'et_other_423');
    if (material.isNotEmpty) {
      phrases.add('Where visible, the electrical wiring is ${_toWords(material)}. '
          'Only a limited visual inspection of the electrical installation was possible, '
          'as the majority of the wiring is concealed within the building fabric.');
    }
    _addConditionNotes(phrases, answers, 'actv_condition_electric', 'et_notes_electric', component: 'electrical installation');
    _addRemarks(phrases, answers, 'et_general_remarks_electric');

    // Age section
    final age = _checkedLabels(answers, [
      'cb_modern', 'cb_old', 'cb_later_alterations', 'cb_diy',
    ], {
      'cb_modern': 'modern',
      'cb_old': 'dated',
      'cb_later_alterations': 'with later alterations',
      'cb_diy': 'with evidence of DIY work',
    });
    _addOther(age, answers, 'cb_other_550', 'et_other_199');
    if (age.isNotEmpty) {
      phrases.add('The electrical installation appears ${_toWords(age)}. '
          'A current Electrical Installation Condition Report (EICR), carried out by a competent electrician registered '
          'with an appropriate Part P scheme, should be obtained to confirm the safety and adequacy of the installation.');
    }
    _addConditionNotes(phrases, answers, 'actv_age_condition', 'et_age_notes', component: 'electrical system age');
    _addRemarks(phrases, answers, 'et_generals_remarks_electric_age');

    return phrases;
  }

  List<String> _gasSupply(Map<String, String> answers) {
    final phrases = <String>[];
    final supply = _val(answers, 'actv_gas_supply');
    if (supply.isNotEmpty) {
      if (supply.toLowerCase() == 'mains') {
        phrases.add('The property is connected to mains gas supply. '
            'The gas installation was not tested as part of this inspection. '
            'A current Gas Safety Certificate, issued by a Gas Safe registered engineer, '
            'should be obtained to confirm the safety and adequacy of the installation.');
      } else if (supply.toLowerCase() == 'none') {
        phrases.add('The property does not have a gas supply connected at the present time.');
      } else {
        phrases.add('The gas supply is ${supply.toLowerCase()}. '
            'A current Gas Safety Certificate, issued by a Gas Safe registered engineer, should be obtained.');
      }
    }
    _addConditionNotes(phrases, answers, 'actv_condition_gas', 'et_notes_gas', component: 'gas installation');
    _addRemarks(phrases, answers, 'et_general_remarks_gas');
    return phrases;
  }

  List<String> _waterSupply(Map<String, String> answers) {
    final phrases = <String>[];
    final supply = _val(answers, 'actv_water_supply');
    if (supply.isNotEmpty) {
      if (supply.toLowerCase() == 'mains') {
        phrases.add('The property is connected to mains water supply. '
            'The water supply system was not tested as part of this inspection.');
      } else if (supply.toLowerCase() == 'private') {
        phrases.add('The property is served by a private water supply. '
            'Your legal adviser should confirm the adequacy, quality, and any regulatory requirements '
            'associated with the private supply, including water testing and maintenance obligations.');
      } else {
        phrases.add('The water supply is ${supply.toLowerCase()}. '
            'Your legal adviser should confirm the terms and adequacy of this supply.');
      }
    }
    _addConditionNotes(phrases, answers, 'actv_condition_water', 'et_notes_water', component: 'water supply');
    _addRemarks(phrases, answers, 'et_general_remarks_water');
    return phrases;
  }

  List<String> _hotWaterCH(Map<String, String> answers) {
    final phrases = <String>[];
    final fuelSources = <String>[];
    final heatingTypes = <String>[];
    final coverageTypes = <String>[];

    for (final e in {
      'cb_lpg': 'LPG',
      'cb_gas_hw': 'gas',
      'cb_electric_hw': 'electric',
      'cb_solid_hw': 'solid fuel',
      'cb_oil': 'oil',
    }.entries) {
      if (_isChecked(answers[e.key])) fuelSources.add(e.value);
    }
    for (final e in {
      'cb_radiators': 'radiators',
      'cb_warm_air': 'warm air',
      'cb_storage': 'storage heaters',
    }.entries) {
      if (_isChecked(answers[e.key])) heatingTypes.add(e.value);
    }
    for (final e in {
      'cb_full': 'full',
      'cb_part': 'partial',
      'cb_none_hw': 'none',
    }.entries) {
      if (_isChecked(answers[e.key])) coverageTypes.add(e.value);
    }
    _addOther(fuelSources, answers, 'cb_other_657', 'et_other_301');

    if (fuelSources.isNotEmpty) {
      phrases.add('The hot water and central heating system is fuelled by ${_toWords(fuelSources)}.');
    }
    if (heatingTypes.isNotEmpty) {
      phrases.add('Heat is distributed throughout the property by ${_toWords(heatingTypes)}.');
    }
    if (coverageTypes.isNotEmpty) {
      final coverage = coverageTypes.first;
      if (coverage == 'none') {
        phrases.add('No central heating system is installed within the property at the present time.');
      } else {
        phrases.add('The system provides $coverage central heating coverage to the accommodation.');
      }
    }
    if (phrases.isNotEmpty) {
      phrases.add('The heating system was not tested as part of this inspection. '
          'A current service record should be obtained to confirm the system has been regularly maintained. '
          'The boiler and associated system should be serviced annually by a suitably qualified engineer '
          'in accordance with the manufacturer\'s instructions and current regulations.');
    }
    _addConditionNotes(phrases, answers, 'actv_condition_hw_ch', 'et_notes_hw_ch', component: 'heating system');
    _addRemarks(phrases, answers, 'et_general_remarks_hw_ch');
    return phrases;
  }

  List<String> _smokeDetectors(Map<String, String> answers) {
    final phrases = <String>[];
    if (_isChecked(answers['cb_mains_powered'])) {
      phrases.add('Mains-powered smoke detectors were noted to be installed within the property. '
          'The detectors should be tested regularly in accordance with the manufacturer\'s guidelines '
          'and replaced in accordance with the recommended service life. '
          'Carbon monoxide detectors should also be installed where gas or solid fuel appliances are present.');
    } else {
      phrases.add('I was unable to confirm the presence of mains-powered smoke detectors within the property. '
          'It is strongly recommended that appropriate smoke detectors are installed on every floor, '
          'along with carbon monoxide detectors where gas or solid fuel appliances are present, '
          'in accordance with current Building Regulations and fire safety guidance.');
    }
    _addRemarks(phrases, answers, 'et_general_remarks_smoke');
    return phrases;
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  CONDITION & RESTRICTIONS
  // ═══════════════════════════════════════════════════════════════════════

  List<String> _overallCondition(Map<String, String> answers) {
    final phrases = <String>[];
    final condition = _val(answers, 'actv_overall_condition');
    if (condition.isNotEmpty) {
      phrases.add('Having regard to the age, type, and style of the property, and based upon my thorough inspection, '
          '${_conditionPhrase(condition, component: 'overall condition of the property')}');
    }
    final restrictions = _val(answers, 'et_restrictions');
    if (restrictions.isNotEmpty) {
      phrases.add('The following restrictions or matters that may affect the value or use of the property should be noted: $restrictions');
    }
    return phrases;
  }

  List<String> _otherMatters(Map<String, String> answers) {
    final phrases = <String>[];

    final _matters = {
      'cb_building_regs': (String notes) => notes.isNotEmpty
          ? 'Your legal adviser should confirm that Building Regulations approval and, where applicable, '
              'planning permission were obtained for all relevant works carried out to the property. $notes'
          : 'Your legal adviser should confirm that Building Regulations approval and, where applicable, '
              'planning permission were obtained for all relevant works carried out to the property.',
      'cb_guarantees': (String notes) => notes.isNotEmpty
          ? 'The property benefits from guarantees or warranties. $notes '
              'Your legal adviser should confirm the precise terms, duration, and transferability of these guarantees.'
          : 'The property benefits from guarantees or warranties. '
              'Your legal adviser should confirm the precise terms, duration, and transferability of these guarantees.',
      'cb_rights_of_way': (String notes) => notes.isNotEmpty
          ? 'Rights of way or easements may affect the property. $notes '
              'Your legal adviser should make full enquiries regarding any rights of way, easements, or wayleaves that may exist.'
          : 'Rights of way or easements may affect the property. '
              'Your legal adviser should make full enquiries regarding any such rights.',
      'cb_contamination': (String notes) => notes.isNotEmpty
          ? 'The property may be affected by land contamination. $notes '
              'An environmental search and, if appropriate, a Phase 1 desktop environmental assessment is recommended.'
          : 'The property may be affected by land contamination. '
              'An environmental search and, if appropriate, a Phase 1 desktop environmental assessment is recommended.',
      'cb_flooding': (String notes) => notes.isNotEmpty
          ? 'The property may be at risk of flooding from one or more sources. $notes '
              'A comprehensive flood risk search is recommended and the availability and cost of flood insurance should be confirmed.'
          : 'The property may be at risk of flooding from one or more sources. '
              'A comprehensive flood risk search is recommended and the availability and cost of flood insurance should be confirmed.',
      'cb_emfs_om': (String notes) => notes.isNotEmpty
          ? 'The property may be affected by electromagnetic fields from nearby sources such as overhead power lines or substations. $notes'
          : 'The property may be affected by electromagnetic fields from nearby sources such as overhead power lines or substations.',
      'cb_mining': (String notes) => notes.isNotEmpty
          ? 'The property may be affected by historical or current mining activity in the area. $notes '
              'A mining search is recommended to establish the extent of any mining-related risk.'
          : 'The property may be affected by historical or current mining activity in the area. '
              'A mining search is recommended to establish the extent of any mining-related risk.',
      'cb_flying_freehold': (String notes) => notes.isNotEmpty
          ? 'The property includes a flying freehold element. $notes '
              'Your legal adviser should confirm the legal implications, including any indemnity insurance requirements and maintenance obligations.'
          : 'The property includes a flying freehold element. '
              'Your legal adviser should confirm the legal implications, including any indemnity insurance requirements and maintenance obligations.',
      'cb_radon': (String notes) => notes.isNotEmpty
          ? 'The property is situated in an area identified as being potentially affected by radon gas. $notes '
              'A radon test is recommended, and appropriate mitigation measures should be considered if elevated levels are detected.'
          : 'The property is situated in an area identified as being potentially affected by radon gas. '
              'A radon test is recommended, and appropriate mitigation measures should be considered if elevated levels are detected.',
    };

    final _notesKeys = {
      'cb_building_regs': 'et_notes_building_regs',
      'cb_guarantees': 'et_notes_guarantees',
      'cb_rights_of_way': 'et_notes_rights',
      'cb_contamination': 'et_notes_contamination',
      'cb_flooding': 'et_notes_flooding',
      'cb_emfs_om': 'et_notes_emfs',
      'cb_mining': 'et_notes_mining',
      'cb_flying_freehold': 'et_notes_flying',
      'cb_radon': 'et_notes_radon',
    };

    for (final cbKey in _matters.keys) {
      if (_isChecked(answers[cbKey])) {
        final notes = _val(answers, _notesKeys[cbKey]!);
        phrases.add(_matters[cbKey]!(notes));
      }
    }

    return phrases;
  }

  List<String> _energyPerformance(Map<String, String> answers) {
    final phrases = <String>[];

    phrases.add('We have not prepared the Energy Performance Certificate (EPC) for this property. '
        'Where an EPC has been made available to us, the ratings are presented below for information purposes only. '
        'We have not verified these ratings and cannot comment on their accuracy or completeness.');

    final currentRating = _val(answers, 'actv_epc_current_rating');
    final currentScore = _val(answers, 'et_epc_current_score');
    final potentialRating = _val(answers, 'actv_epc_potential_rating');
    final potentialScore = _val(answers, 'et_epc_potential_score');

    if (currentRating.isNotEmpty || currentScore.isNotEmpty) {
      final parts = <String>[];
      if (currentRating.isNotEmpty) parts.add('Band $currentRating');
      if (currentScore.isNotEmpty) parts.add('Score $currentScore');
      phrases.add('Current Energy Performance: ${parts.join(', ')}.');
    }
    if (potentialRating.isNotEmpty || potentialScore.isNotEmpty) {
      final parts = <String>[];
      if (potentialRating.isNotEmpty) parts.add('Band $potentialRating');
      if (potentialScore.isNotEmpty) parts.add('Score $potentialScore');
      phrases.add('Potential Energy Performance: ${parts.join(', ')}.');
    }

    final envCurrent = _val(answers, 'et_env_impact_current');
    final envPotential = _val(answers, 'et_env_impact_potential');
    if (envCurrent.isNotEmpty || envPotential.isNotEmpty) {
      final buf = StringBuffer('Environmental Impact: ');
      final parts = <String>[];
      if (envCurrent.isNotEmpty) parts.add('Current $envCurrent');
      if (envPotential.isNotEmpty) parts.add('Potential $envPotential');
      buf.write('${parts.join(', ')}.');
      phrases.add(buf.toString());
    }

    final ref = _val(answers, 'et_epc_reference');
    if (ref.isNotEmpty) {
      phrases.add('EPC Reference: $ref.');
    }

    final notes = _val(answers, 'et_epc_notes');
    if (notes.isNotEmpty) phrases.add(notes);

    return phrases;
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  VALUATION & COMPLETION
  // ═══════════════════════════════════════════════════════════════════════

  List<String> _valuation(Map<String, String> answers) {
    final phrases = <String>[];

    final purchasePrice = _val(answers, 'et_purchase_price');
    if (purchasePrice.isNotEmpty) {
      phrases.add('I am advised that the agreed purchase price for the property is $purchasePrice.');
    }
    final estimatedValue = _val(answers, 'et_estimated_value');
    if (estimatedValue.isNotEmpty) {
      phrases.add('The pre-inspection estimated value provided to us was $estimatedValue.');
    }

    if (_isChecked(answers['cb_open_market_value'])) {
      phrases.add('In my opinion, the open market value of the property, subject to the assumptions, '
          'special assumptions, and conditions set out in this report, '
          'is considered to be adequate security for the proposed mortgage advance. '
          'This valuation has been prepared in accordance with the RICS Valuation — Global Standards.');
    }

    final share = _val(answers, 'et_value_of_share');
    if (share.isNotEmpty) {
      phrases.add('The value attributable to the applicant\'s share of the property is assessed at $share.');
    }

    final pct = _val(answers, 'et_share');
    if (pct.isNotEmpty) {
      phrases.add('The applicant\'s share represents $pct% of the whole property.');
    }

    final afterWorks = _val(answers, 'et_after_works_value');
    if (afterWorks.isNotEmpty) {
      phrases.add('The estimated market value of the property following satisfactory completion '
          'of the recommended essential repair works is $afterWorks.');
    }

    final retention = _val(answers, 'et_retention');
    if (retention.isNotEmpty) {
      phrases.add('A retention of $retention is recommended to cover the cost of the essential repair works '
          'identified in this report. The retention should not be released until satisfactory completion '
          'of the works has been confirmed.');
    }

    if (_isChecked(answers['cb_suitable_security'])) {
      phrases.add('In my opinion, the property provides suitable security for mortgage lending purposes, '
          'subject to the conditions and recommendations set out in this report.');
    }

    return phrases;
  }

  List<String> _generalRemarks(Map<String, String> answers) {
    final phrases = <String>[];

    final remarks = _val(answers, 'et_general_remarks');
    if (remarks.isNotEmpty) phrases.add(remarks);

    final clientNotes = _val(answers, 'et_client_notes');
    if (clientNotes.isNotEmpty) phrases.add(clientNotes);

    final agentNotes = _val(answers, 'et_agent_notes');
    if (agentNotes.isNotEmpty) phrases.add(agentNotes);

    final instructions = _val(answers, 'et_special_instructions');
    if (instructions.isNotEmpty) {
      phrases.add(instructions);
    }

    return phrases;
  }
}
