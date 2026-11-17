P = 'lib/features/property_valuation/domain/valuation_phrase_engine.dart'
s = open(P, encoding='utf8', newline='').read()
nl = '\r\n' if '\r\n' in s else '\n'
s = s.replace('\r\n', '\n')


def sub(old, new):
    global s
    assert s.count(old) == 1, (s.count(old), old[:60])
    s = s.replace(old, new)


# A6 Limitations (the sample report's block under Restrictions; wording is the Home Survey grounds limitations).
sub("""      case 'val_oil_lpg':""", """      case 'val_limitations':
        return [
          'The inspection of the grounds was visual only. Underground services, buried structures, and concealed defects '
              'could not be inspected or confirmed as part of this inspection.',
          if (_isChecked(a['cb_lim_no_restrictions']))
            'No inspection restrictions: There were no unusual restrictions affecting my inspection of the grounds '
                'within the apparent ownership of the property.',
          if (_isChecked(a['cb_lim_no_rear_access']))
            'Restricted access: Access to the rear or external elevations of the property was not available. '
                'Consequently, I was unable to inspect or comment on the condition or composition of the rear grounds. '
                'Comments are limited to those external areas that were visible and accessible at the time of the inspection.',
        ];
      case 'val_oil_lpg':""")

# A10 Reinstatement Value + Higher Reinstatement Value (client, 17 Nov 2026).
sub("""          'subject to the conditions and recommendations set out in this report.');
    }

    return phrases;
  }

  List<String> _generalRemarks""", """          'subject to the conditions and recommendations set out in this report.');
    }

    final reinstatement = _val(answers, 'et_reinstatement_value');
    if (reinstatement.isNotEmpty) {
      // "£517,000 (Five Hundred and Seventeen Thousand Pounds)": figures and words, no pence.
      final amount = formatPriceBracketed(reinstatement)
          .replaceFirst('.00 [', ' [')
          .replaceAll('[', '(')
          .replaceAll(']', ')');
      phrases.add(
          'The reinstatement cost of your home represents the estimated cost of completely rebuilding the property '
          'if it is destroyed, for example, by fire. This figure differs from the market value of the property, '
          'as it relates solely to the cost of materials and labour required to reconstruct the building to its '
          'current form. The estimated reinstatement cost for this property is $amount.');
    }
    if (_isChecked(answers['cb_higher_reinstatement'])) {
      phrases.add('The reinstatement cost exceeds the purchase price; this is not unusual and does not indicate an error.');
    }

    return phrases;
  }

  List<String> _generalRemarks""")
open(P, 'w', encoding='utf8', newline='').write(s.replace('\n', nl))
print('ok')
