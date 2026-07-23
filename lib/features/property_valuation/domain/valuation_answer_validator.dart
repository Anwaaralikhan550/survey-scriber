/// Validation rules for answers that would otherwise produce contradictory
/// valuation prose. These rules do not alter the inspection tree or fields.
class ValuationAnswerValidator {
  const ValuationAnswerValidator._();

  static List<String> validateScreen(
    String screenId,
    Map<String, String> answers,
  ) {
    final errors = <String>[];
    if (screenId == 'accommodation_summary' &&
        _checked(answers, 'cb_none') &&
        _countChecked(answers, const [
              'cb_garage',
              'cb_single',
              'cb_double',
              'cb_parking_space',
              'cb_car_port',
              'cb_other_720',
            ]) >
            0) {
      errors.add(
        'No dedicated parking cannot be selected with another parking type.',
      );
    }

    if (screenId == 'road' &&
        _countChecked(answers, const [
              'cb_adopted',
              'cb_private',
              'cb_made',
              'cb_partly_made',
              'cb_unmade',
            ]) >
            1) {
      errors.add('Select one road type for the property approach.');
    }

    if (screenId == 'general_details') {
      _validateYear(errors, answers, 'et_age', 'Year Built');
      _validateYear(errors, answers, 'et_age_extension', 'Age of Extension');
    }

    if (screenId == 'no_of_rooms') {
      final otherCount = _value(answers, 'et_other');
      if (otherCount.isNotEmpty &&
          otherCount != '0' &&
          _value(answers, 'et_other_name').isEmpty) {
        errors.add('Name the Other Room when an Other Room count is entered.');
      }
    }

    _requireOtherDetail(
      errors,
      answers,
      checkboxId: 'cb_other_720',
      detailId: 'et_other_792',
      label: 'parking',
    );
    _requireOtherDetail(
      errors,
      answers,
      checkboxId: 'cb_other_909',
      detailId: 'et_other_777',
      label: 'roof construction',
    );
    _requireOtherDetail(
      errors,
      answers,
      checkboxId: 'cb_other_883',
      detailId: 'et_other_824',
      label: 'roof covering',
    );
    return errors;
  }

  static List<String> validateSurvey(
    Map<String, Map<String, String>> answersByScreen,
  ) {
    final errors = <String>[];
    for (final entry in answersByScreen.entries) {
      errors.addAll(validateScreen(entry.key, entry.value));
    }
    return errors;
  }

  static bool _checked(Map<String, String> answers, String key) {
    final value = _value(answers, key);
    return value == 'true' || value == '1' || value == 'yes';
  }

  static int _countChecked(Map<String, String> answers, List<String> keys) =>
      keys.where((key) => _checked(answers, key)).length;

  static String _value(Map<String, String> answers, String key) =>
      (answers[key] ?? '').trim().toLowerCase();

  static void _requireOtherDetail(
    List<String> errors,
    Map<String, String> answers, {
    required String checkboxId,
    required String detailId,
    required String label,
  }) {
    if (_checked(answers, checkboxId) && _value(answers, detailId).isEmpty) {
      errors.add('Provide a description when Other $label is selected.');
    }
  }

  static void _validateYear(
    List<String> errors,
    Map<String, String> answers,
    String key,
    String label,
  ) {
    final raw = (answers[key] ?? '').trim();
    if (raw.isEmpty) return;
    final year = int.tryParse(raw);
    final maximum = DateTime.now().year + 1;
    if (year == null || year < 1000 || year > maximum) {
      errors.add('$label must be a four-digit year between 1000 and $maximum.');
    }
  }
}

/// Raised before export so a contradictory valuation can never become a
/// client-facing PDF or DOCX report.
class ValuationReportValidationException implements Exception {
  const ValuationReportValidationException(this.errors);

  final List<String> errors;

  @override
  String toString() =>
      'Valuation report cannot be generated:\n${errors.join('\n')}';
}
