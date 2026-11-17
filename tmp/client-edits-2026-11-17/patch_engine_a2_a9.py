P = 'lib/features/property_valuation/domain/valuation_phrase_engine.dart'
s = open(P, encoding='utf8', newline='').read()
nl = '\r\n' if '\r\n' in s else '\n'
s = s.replace('\r\n', '\n')


def sub(old, new, count=1):
    global s
    assert s.count(old) == count, (s.count(old), old[:60])
    s = s.replace(old, new)


# A8: "associated fittings" is fixed text. Old ticks keep printing the same words.
sub("""    'cb_rw_hoppers': 'hoppers',
    'cb_rw_fittings': 'associated fittings',
  };""", """    'cb_rw_hoppers': 'hoppers',
  };
  static const _rainwaterMaterialIds = ['cb_rw_pvc', 'cb_rw_cast', 'cb_rw_alum', 'cb_rw_steel', 'cb_rw_concrete', 'cb_rw_asbestos'];""")
sub("""      case 'val_rainwater_goods':
        final l = _clientList(a, _rainwaterIds, otherCb: 'cb_rw_other', otherText: 'et_rw_other_text');
        return l.isEmpty ? const [] : ['The rainwater goods comprise $l.'];""",
    """      case 'val_rainwater_goods':
        // Client 17 Nov: "and associated fittings" is part of the sentence, not a tick.
        final items = _checkedLabels(a, _rainwaterMaterialIds, _rainwaterIds);
        _addOther(items, a, 'cb_rw_other', 'et_rw_other_text');
        items.addAll(_checkedLabels(a, const ['cb_rw_gutters', 'cb_rw_down', 'cb_rw_hoppers'], _rainwaterIds));
        return items.isEmpty ? const [] : ['The rainwater goods comprise ${items.join(', ')}, and associated fittings.'];""")

# A5: three roofs, three sentences.
sub("""      case 'val_rainwater_goods':
        // Client 17 Nov""", """      case 'val_flat_roof':
        final l = _clientList(a, _flatRoofIds, otherCb: 'cb_fr_other', otherText: 'et_fr_other_text');
        return l.isEmpty ? const [] : ['The flat roof covering is formed in $l.'];
      case 'val_other_roof':
        final l = _clientList(a, _otherRoofIds, otherCb: 'cb_or_other', otherText: 'et_or_other_text');
        if (l.isEmpty) return const [];
        final name = _val(a, 'et_other_roof_name');
        final subject = name.isEmpty ? 'The other roof' : _capitalizeFirst(name);
        return ['$subject covering is formed in $l.'];
      case 'val_rainwater_goods':
        // Client 17 Nov""")
sub("""  static const _rainwaterIds = {""", """  static const _flatRoofIds = {
    'cb_fr_felt': 'mineral felt',
    'cb_fr_rubber': 'rubber membrane',
    'cb_fr_single': 'single-ply membrane',
  };
  static const _otherRoofIds = {
    'cb_or_clay': 'clay tiles',
    'cb_or_concrete': 'concrete tiles',
    'cb_or_natural': 'natural slate',
    'cb_or_artificial': 'artificial slate',
    'cb_or_fibre': 'fibre cement slates',
    'cb_or_metal': 'metal sheeting',
    'cb_or_felt': 'mineral felt',
    'cb_or_rubber': 'rubber membrane',
    'cb_or_single': 'single-ply membrane',
  };
  static const _oilFuelIds = {'cb_ol_oil': 'Oil-fired', 'cb_ol_lpg': 'LPG-fired'};
  static const _oilTankIds = {'cb_ot_plastic': 'plastic', 'cb_ot_metal': 'metal'};
  static const _oilWhereIds = {
    'cb_ol_front': 'front garden',
    'cb_ol_side': 'side garden',
    'cb_ol_rear': 'rear garden',
  };
  static const _rainwaterIds = {""")

# A3: Dated beside the meter location. A2: Oil / LPG tank.
sub("""        final l = _clientList(a, _elecMeterIds, otherCb: 'cb_em_other', otherText: 'et_em_other_text');
        return l.isEmpty
            ? const []
            : ['There is a mains electricity supply connected to the property, and the meter unit is located $l.'];""",
    """        final l = _clientList(a, _elecMeterIds, otherCb: 'cb_em_other', otherText: 'et_em_other_text');
        return [
          if (l.isNotEmpty)
            'There is a mains electricity supply connected to the property, and the meter unit is located $l.',
          if (_isChecked(a['cb_em_dated'])) 'The meter unit is dated.',
        ];
      case 'val_oil_lpg':
        final fuel = _checkedLabels(a, _oilFuelIds.keys.toList(), _oilFuelIds).join(' / ');
        if (fuel.isEmpty) return const [];
        final tank = _clientList(a, _oilTankIds, otherCb: 'cb_ot_other', otherText: 'et_ot_other_text');
        final where = _clientList(a, _oilWhereIds, otherCb: 'cb_ol_other', otherText: 'et_ol_other_text');
        return [
          'The property is served by an $fuel heating system'
              '${tank.isEmpty ? '' : ' with ${_article(tank)} $tank fuel storage tank(s)'}'
              '${where.isEmpty ? '' : ' located at the $where'}.',
        ];""")

# A9: Wet Rot beside Dry Rot.
sub("""          'cb_svt_rot': 'Extensive Dry Rot',
        },""", """          'cb_svt_rot': 'Extensive Dry Rot',
          'cb_svt_wet': 'Extensive Wet Rot',
        },""")

# A4: date of extension inside the Extension sentence.
sub("""    if (extended.isNotEmpty) {
      phrases.add('The property has been extended to provide ${_toWords(extended)} accommodation.');
    }""", """    // Client 17 Nov: Age of Extension (Date of Extension) is printed inside the Extension sentence.
    final extYear = _val(answers, 'et_age_extension');
    final extWhen = extYear.isEmpty ? '' : ' in $extYear';
    if (extended.isNotEmpty) {
      phrases.add('The property has been extended$extWhen to provide ${_toWords(extended)} accommodation.');
    } else if (extYear.isNotEmpty) {
      phrases.add('The property has been extended in $extYear.');
    }""")
open(P, 'w', encoding='utf8', newline='').write(s.replace('\n', nl))

V = 'lib/features/property_valuation/domain/valuation_answer_validator.dart'
v = open(V, encoding='utf8', newline='').read()
vnl = '\r\n' if '\r\n' in v else '\n'
v = v.replace('\r\n', '\n')
old = """    return errors;
  }

  /// All screens' errors."""
new = """    for (final pair in const [
      ['cb_fr_other', 'et_fr_other_text', 'flat roof covering'],
      ['cb_or_other', 'et_or_other_text', 'other roof covering'],
      ['cb_ot_other', 'et_ot_other_text', 'fuel storage tank'],
      ['cb_ol_other', 'et_ol_other_text', 'fuel storage tank location'],
    ]) {
      _requireOtherDetail(errors, answers, checkboxId: pair[0], detailId: pair[1], label: pair[2]);
    }
    if (screenId == 'val_oil_lpg' &&
        !_checked(answers, 'cb_ol_oil') &&
        !_checked(answers, 'cb_ol_lpg') &&
        _countChecked(answers, const [
              'cb_ot_plastic',
              'cb_ot_metal',
              'cb_ot_other',
              'cb_ol_front',
              'cb_ol_side',
              'cb_ol_rear',
              'cb_ol_other',
            ]) >
            0) {
      errors.add('Tick Oil-fired or LPG-fired for the fuel storage tank.');
    }
    return errors;
  }

  /// All screens' errors."""
assert v.count(old) == 1
v = v.replace(old, new)
open(V, 'w', encoding='utf8', newline='').write(v.replace('\n', vnl))
print('ok')
